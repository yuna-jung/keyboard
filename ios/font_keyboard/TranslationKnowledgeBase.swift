// MARK: - TranslationKnowledgeBase
//
// Meme/slang reference layer for the translate tab. Sits BETWEEN
// `TranslationDB` (exact-match static phrasebook, checked first) and the
// GPT call: on a `TranslationDB` miss, this searches a bundled JSON table
// for figurative expressions (memes, fandom slang, idioms) that GPT tends
// to mistranslate literally, and — if something matches — builds a short
// "Potential translation references" block that gets appended as an EXTRA
// system message, after the fixed system-prompt + few-shot block.
//
// This is NOT a phrase substitution table. It never produces translated
// text itself; it only hands GPT meaning/guideline/candidate-wording
// context so the model can decide, in the full sentence's context, how
// (or whether) to apply it. `preferred_translations` are candidates, not
// answers — GPT can adapt or ignore them.

import Foundation

// MARK: - Decodable model

private enum KBMatchType: String, Decodable {
    case exactPhrase = "exact_phrase"
    case wholeWord = "whole_word"
    case regex
}

private struct KBPattern: Decodable {
    let value: String
    let match: KBMatchType
    let priority: Int
}

private struct KBEntry: Decodable {
    let id: String
    let patterns: [KBPattern]
    let meaning: String
    let guideline: String
    let preferredTranslations: [String: [String]]
    let category: String

    enum CodingKeys: String, CodingKey {
        case id, patterns, meaning, guideline, category
        case preferredTranslations = "preferred_translations"
    }
}

private struct KBRoot: Decodable {
    let version: Int
    let entries: [KBEntry]
}

// MARK: - Loader / matcher

final class TranslationKnowledgeBase {
    static let shared = TranslationKnowledgeBase()

    private let entries: [KBEntry]
    private let compiled: [CompiledPattern]

    private struct CompiledPattern {
        let entryIndex: Int
        let patternValue: String
        let priority: Int
        let regex: NSRegularExpression
    }

    /// Fail-safe: any problem loading/parsing the bundled JSON leaves
    /// `entries`/`compiled` empty, so `buildReference` always returns `nil`
    /// and the existing (KB-less) translation path is unaffected.
    private init() {
        guard
            let url = Bundle(for: TranslationKnowledgeBase.self)
                .url(forResource: "TranslationKnowledgeBase", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            #if DEBUG
            print("🔥 [TranslationKB] bundle resource not found — KB disabled, falling back to KB-less translation")
            #endif
            self.entries = []
            self.compiled = []
            return
        }

        do {
            let root = try JSONDecoder().decode(KBRoot.self, from: data)
            self.entries = root.entries
            self.compiled = Self.compilePatterns(for: root.entries)
        } catch {
            #if DEBUG
            print("🔥 [TranslationKB] JSON decode failed (\(error.localizedDescription)) — KB disabled, falling back to KB-less translation")
            #endif
            self.entries = []
            self.compiled = []
        }
    }

    private static func compilePatterns(for entries: [KBEntry]) -> [CompiledPattern] {
        var result: [CompiledPattern] = []
        for (idx, entry) in entries.enumerated() {
            for pattern in entry.patterns {
                let regexString: String
                switch pattern.match {
                case .exactPhrase, .wholeWord:
                    // Word-boundary-delimited literal match — NOT a bare
                    // `contains`. Escaping the literal text keeps any regex
                    // metacharacters in the phrase (apostrophes, etc.) inert.
                    regexString = "\\b" + NSRegularExpression.escapedPattern(for: pattern.value) + "\\b"
                case .regex:
                    regexString = pattern.value
                }
                guard let regex = try? NSRegularExpression(pattern: regexString, options: [.caseInsensitive]) else {
                    // Malformed pattern in the data file — skip just this
                    // pattern rather than failing the whole KB load.
                    continue
                }
                result.append(CompiledPattern(entryIndex: idx, patternValue: pattern.value, priority: pattern.priority, regex: regex))
            }
        }
        return result
    }

    // MARK: - Normalization

    /// Smart-quote → straight-quote normalization + whitespace trim/collapse.
    /// Deliberately does NOT strip internal punctuation — patterns like
    /// "it's giving" rely on the apostrophe surviving.
    private func normalize(_ text: String) -> String {
        let quoteMap: [Character: Character] = [
            "\u{2018}": "'", "\u{2019}": "'", "\u{201B}": "'",
            "\u{201C}": "\"", "\u{201D}": "\"", "\u{201F}": "\"",
        ]
        var t = String(text.map { quoteMap[$0] ?? $0 })
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        while t.contains("  ") { t = t.replacingOccurrences(of: "  ", with: " ") }
        return t
    }

    // MARK: - Matching

    private struct Hit {
        let entryIndex: Int
        let patternValue: String
        let score: Int
    }

    /// One hit per entry (best-scoring pattern wins), sorted by score
    /// descending. Score favors higher `priority` first, then longer
    /// pattern text — both "priority" and "pattern length" factor in per
    /// the matching spec.
    private func matches(for text: String) -> [Hit] {
        guard !compiled.isEmpty else { return [] }
        let normalized = normalize(text)
        guard !normalized.isEmpty else { return [] }
        let fullRange = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)

        var bestByEntry: [Int: Hit] = [:]
        for cp in compiled {
            guard cp.regex.firstMatch(in: normalized, options: [], range: fullRange) != nil else { continue }
            let score = cp.priority * 1000 + cp.patternValue.count
            if let existing = bestByEntry[cp.entryIndex], existing.score >= score { continue }
            bestByEntry[cp.entryIndex] = Hit(entryIndex: cp.entryIndex, patternValue: cp.patternValue, score: score)
        }
        return bestByEntry.values.sorted { $0.score > $1.score }
    }

    /// Top-3 hits (by score) — the one place the "max 3" cap is applied.
    /// Both `matchedEntryIDs` and `buildReference` go through this so they
    /// can never drift out of sync with each other.
    private func topHits(for text: String) -> [Hit] {
        Array(matches(for: text).prefix(3))
    }

    /// Matched entry ids only (already capped at 3, same as `buildReference`
    /// applies), in priority order, without building the formatted
    /// reference text. Exists mainly as a testable surface for matcher-level
    /// unit tests (the private `KBEntry`/`KBPattern` model types aren't
    /// visible outside this file, so tests assert against ids rather than
    /// reaching into the decoded model directly) — this method runs the
    /// exact same matching path `buildReference` uses.
    func matchedEntryIDs(for text: String) -> [String] {
        topHits(for: text).map { entries[$0.entryIndex].id }
    }

    // MARK: - Reference block generation

    /// Strips a single trailing period so preferred expressions aren't
    /// copied into the reference with punctuation baked in — the model is
    /// expected to fit its own sentence-final punctuation to context.
    /// Mirrors `sanitizeTranslationOutput`'s same one-period-only rule
    /// (leaves "!", "?", and "..." alone since those carry tone).
    private func trimTrailingPeriod(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespaces)
        if t.hasSuffix(".") && !t.hasSuffix("..") {
            t = String(t.dropLast())
        }
        return t
    }

    /// Builds the "Potential translation references" system-message block
    /// for up to 3 matched entries, or `nil` if nothing matched (in which
    /// case the caller should not add an extra system message at all).
    ///
    /// - Parameters:
    ///   - text: the raw user input (`effectiveInput`) — never logged.
    ///   - targetLanguage: one of `translateLangs`'s English language names
    ///     (e.g. "Korean", "English"). `preferred_translations.ko` is only
    ///     included when this is exactly "Korean".
    func buildReference(for text: String, targetLanguage: String) -> String? {
        let hits = topHits(for: text)
        guard !hits.isEmpty else { return nil }

        let includeKorean = (targetLanguage == "Korean")
        var blocks: [String] = []
        var matchedIDs: [String] = []

        for hit in hits {
            let entry = entries[hit.entryIndex]
            matchedIDs.append(entry.id)
            let familyLabel = entry.patterns.first?.value ?? hit.patternValue

            var block = "- Expression family: \"\(familyLabel)\"\n"
            block += "  Meaning: \(entry.meaning)\n"
            block += "  Guidance: \(entry.guideline)\n"
            if includeKorean, let koList = entry.preferredTranslations["ko"], !koList.isEmpty {
                block += "  Preferred Korean expressions:\n"
                for expr in koList {
                    block += "  - \(trimTrailingPeriod(expr))\n"
                }
            }
            blocks.append(block)
        }

        var result = "Potential translation references:\n\n"
        result += blocks.joined(separator: "\n")
        result += "\n"
        result += "These references are contextual hints, not mandatory translations.\n"
        result += "Use them only when they fit the full sentence.\n"
        result += "Choose or adapt the most natural expression for the target language and context.\n"
        result += "Do not copy a preferred expression mechanically if it does not fit."

        #if DEBUG
        // Match ids and static pattern text are KB content, not user data —
        // safe to log. The user's input/translation output are NOT logged
        // here, only lengths.
        print("🔥 [TranslationKB] matched=\(matchedIDs) referenceLength=\(result.count) inputLength=\(text.count)")
        #endif

        return result
    }
}
