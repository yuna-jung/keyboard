import XCTest

// NOTE: `TranslationKnowledgeBase.swift` and `TranslationKnowledgeBase.json`
// must have their Xcode "Target Membership" checked for RunnerTests too
// (in addition to the font_keyboard extension target they're auto-added to
// via the synchronized folder) for this file to compile/run — see the
// setup notes handed back alongside this file. Without that, `entries`
// loads empty and every "should match" assertion below fails loudly,
// which is itself a signal the target membership step was skipped.

/// Matcher-level tests: pure pattern-matching correctness, no network, no
/// GPT call. These verify `TranslationKnowledgeBase` finds the right
/// entries and — just as importantly — does NOT fire on ordinary uses of
/// common words that happen to appear inside a slang phrase (mother, ate,
/// chief, period, cooked, serving).
final class TranslationKnowledgeBaseTests: XCTestCase {

    private let kb = TranslationKnowledgeBase.shared

    // MARK: - Positive cases (should match)

    func testMatches_motherIsMothering() {
        XCTAssertTrue(kb.matchedEntryIDs(for: "Mother is mothering again.").contains("mother_is_mothering"))
    }

    func testMatches_understoodTheAssignment() {
        XCTAssertTrue(kb.matchedEntryIDs(for: "He understood the assignment.").contains("understood_the_assignment"))
    }

    func testMatches_thisAintItChief() {
        XCTAssertTrue(kb.matchedEntryIDs(for: "This ain't it, chief.").contains("this_aint_it_chief"))
    }

    func testMatches_ateAndLeftNoCrumbs() {
        XCTAssertTrue(kb.matchedEntryIDs(for: "She ate and left no crumbs.").contains("ate"))
    }

    func testMatches_deluluIsTheSolulu() {
        XCTAssertTrue(kb.matchedEntryIDs(for: "Delulu is the solulu.").contains("delulu"))
    }

    // Bare "delulu" (whole_word, no sentence around it) should still match —
    // it's a coined slang word with low collision risk, unlike bare "ate".
    func testMatches_bareDelulu() {
        XCTAssertTrue(kb.matchedEntryIDs(for: "I'm so delulu about this.").contains("delulu"))
    }

    func testMatches_flexBareAndGerund() {
        XCTAssertTrue(kb.matchedEntryIDs(for: "flex").contains("flex"))
        XCTAssertTrue(kb.matchedEntryIDs(for: "stop flexing").contains("flex"))
        XCTAssertTrue(kb.matchedEntryIDs(for: "he's always flexing his new car").contains("flex"))
    }

    // "flex" is genuinely ambiguous (slang "show off" vs. literal "bend a
    // muscle") the same way "roman_empire"/"im_cooked" are — the pattern
    // deliberately still fires here; disambiguation is the entry's
    // `guideline`'s job at the GPT level, not the matcher's. This test only
    // documents that expectation (see `testNoMatch_romanEmpireLiteralHistory`
    // for the same pattern elsewhere in this file).
    func testMatches_flexLiteralMuscleContext_patternStillFires() {
        XCTAssertTrue(kb.matchedEntryIDs(for: "Flex your muscles before you start lifting.").contains("flex"))
    }

    func testMatches_bias_possessiveAndFandomConstructs() {
        XCTAssertTrue(kb.matchedEntryIDs(for: "who's your bias").contains("bias"))
        XCTAssertTrue(kb.matchedEntryIDs(for: "who is your bias").contains("bias"))
        XCTAssertTrue(kb.matchedEntryIDs(for: "my bias is Jimin").contains("bias"))
        XCTAssertTrue(kb.matchedEntryIDs(for: "his bias changed again").contains("bias"))
        XCTAssertTrue(kb.matchedEntryIDs(for: "her bias is the maknae").contains("bias"))
        XCTAssertTrue(kb.matchedEntryIDs(for: "their bias is so talented").contains("bias"))
        XCTAssertTrue(kb.matchedEntryIDs(for: "ult bias").contains("bias"))
        XCTAssertTrue(kb.matchedEntryIDs(for: "ultimate bias reveal").contains("bias"))
        XCTAssertTrue(kb.matchedEntryIDs(for: "bias list update").contains("bias"))
    }

    // The standalone-message pattern is anchored to the ENTIRE normalized
    // message (`^bias[?!.]*$`), not a bare substring — deliberately narrow
    // per the KB design note on this entry, since an unanchored "bias"
    // whole_word match would collide constantly with the everyday
    // "prejudice" sense.
    func testMatches_bias_standaloneAnchoredMessage() {
        XCTAssertTrue(kb.matchedEntryIDs(for: "bias").contains("bias"))
        XCTAssertTrue(kb.matchedEntryIDs(for: "bias?").contains("bias"))
        XCTAssertTrue(kb.matchedEntryIDs(for: "Bias!!").contains("bias"))
    }

    func testNoMatch_bias_literalPrejudiceSentences() {
        XCTAssertFalse(kb.matchedEntryIDs(for: "I have a bias against modern architecture.").contains("bias"))
        XCTAssertFalse(kb.matchedEntryIDs(for: "There's clear media bias in this article.").contains("bias"))
        XCTAssertFalse(kb.matchedEntryIDs(for: "unconscious bias training at work").contains("bias"))
        XCTAssertFalse(kb.matchedEntryIDs(for: "gender bias in hiring decisions").contains("bias"))
    }

    func testMatches_bianWreckerVsBiasWreckedMe_areDistinctEntries() {
        XCTAssertTrue(kb.matchedEntryIDs(for: "Jimin is such a bias wrecker.").contains("bias_wrecker"))
        XCTAssertTrue(kb.matchedEntryIDs(for: "My bias wrecked me again.").contains("bias_wrecked_me"))
        // And each sentence should NOT also fire the other entry.
        XCTAssertFalse(kb.matchedEntryIDs(for: "Jimin is such a bias wrecker.").contains("bias_wrecked_me"))
        XCTAssertFalse(kb.matchedEntryIDs(for: "My bias wrecked me again.").contains("bias_wrecker"))
    }

    func testMatches_letHimCookVsImCooked_areDistinctEntries() {
        XCTAssertTrue(kb.matchedEntryIDs(for: "Let him cook.").contains("let_him_cook"))
        XCTAssertTrue(kb.matchedEntryIDs(for: "I'm cooked for tomorrow's exam.").contains("im_cooked"))
    }

    // Third-person question form of both entries, contrasted in the same
    // sentence — both are expected to fire simultaneously here since the
    // sentence genuinely poses both the "doomed" and "on a roll" readings
    // for GPT to resolve from context.
    func testMatches_cookedThirdPersonQuestionForm_bothEntriesFire() {
        let ids = kb.matchedEntryIDs(for: "is he actually cooked, or is he cooking rn")
        XCTAssertTrue(ids.contains("im_cooked"))
        XCTAssertTrue(ids.contains("let_him_cook"))
    }

    // The declarative progressive form ("she's cooking dinner...") must NOT
    // fire either entry — this is exactly the literal-food collision the
    // question-form-only pattern restriction on `let_him_cook` exists to
    // avoid (see its `guideline`).
    func testNoMatch_cookingDeclarative_thirdPerson() {
        let ids = kb.matchedEntryIDs(for: "she's cooking dinner for us tonight")
        XCTAssertFalse(ids.contains("im_cooked"))
        XCTAssertFalse(ids.contains("let_him_cook"))
    }

    // MARK: - Negative cases (should NOT match — common-word false positives)

    func testNoMatch_motherLiteral() {
        XCTAssertFalse(kb.matchedEntryIDs(for: "My mother is coming tomorrow.").contains("mother_is_mothering"))
    }

    func testNoMatch_chiefLiteral() {
        XCTAssertFalse(kb.matchedEntryIDs(for: "The chief called a meeting.").contains("this_aint_it_chief"))
    }

    func testNoMatch_ateLiteral() {
        XCTAssertFalse(kb.matchedEntryIDs(for: "He ate dinner before the concert.").contains("ate"))
    }

    func testNoMatch_periodLiteral_menstrual() {
        XCTAssertFalse(kb.matchedEntryIDs(for: "Her period started yesterday.").contains("thats_on_period"))
    }

    func testNoMatch_periodLiteral_duration() {
        XCTAssertFalse(kb.matchedEntryIDs(for: "We waited for a two-hour period.").contains("thats_on_period"))
    }

    func testNoMatch_cookedLiteral() {
        let ids = kb.matchedEntryIDs(for: "I'm cooking dinner tonight.")
        XCTAssertFalse(ids.contains("im_cooked"))
        XCTAssertFalse(ids.contains("let_him_cook"))
    }

    func testNoMatch_servingLiteral() {
        XCTAssertFalse(kb.matchedEntryIDs(for: "The waiter is serving drinks at table 3.").contains("serving_face"))
    }

    // Regression test for a missing leading `\b` on the `its_giving` regex
    // pattern: "it's giving\b" (no leading boundary) would incorrectly
    // match the tail of "spir[it's giving]" embedded inside "spirit's".
    // The fixed pattern is "\bit's giving\b" (leading boundary added).
    func testNoMatch_itsGiving_embeddedInLongerWord() {
        XCTAssertFalse(kb.matchedEntryIDs(for: "The spirit's giving her chills tonight.").contains("its_giving"))
        // Sanity check the entry still fires for its actual intended usage.
        XCTAssertTrue(kb.matchedEntryIDs(for: "It's giving villain era.").contains("its_giving"))
    }

    // Regression test for the same missing-leading-boundary class of bug on
    // the `serving_face` regex pattern: "serving \w+ face" (no leading
    // boundary) would incorrectly match the tail of "pre[serving a diva
    // face]" embedded inside "preserving".
    func testNoMatch_servingFaceRegex_embeddedInLongerWord() {
        XCTAssertFalse(kb.matchedEntryIDs(for: "He was preserving a diva face the whole meeting.").contains("serving_face"))
    }

    // "sending me" as a standalone pattern was removed (Option A) because it
    // collided with ordinary literal sentences about sending a file/message.
    // Only the more specific "this is/that's sending me" / "this sent me"
    // constructions remain registered.
    func testNoMatch_sendingMeLiteral_file() {
        XCTAssertFalse(kb.matchedEntryIDs(for: "Are you sending me the file?").contains("this_is_sending_me"))
    }

    func testNoMatch_sendingMeLiteral_messages() {
        XCTAssertFalse(kb.matchedEntryIDs(for: "Stop sending me messages.").contains("this_is_sending_me"))
    }

    func testNoMatch_romanEmpireLiteralHistory() {
        // The pattern itself will still fire here (this is the known
        // literal/figurative ambiguity the entry's `guideline` exists to
        // resolve at the GPT level, per the generation-level checklist) —
        // this test only documents that expectation, it does not assert
        // non-matching, since matcher-level can't disambiguate intent.
        XCTAssertTrue(kb.matchedEntryIDs(for: "The Roman Empire fell in 476 AD.").contains("roman_empire"))
    }

    // MARK: - Matching quality: no bare-`contains`, dedup, max 3

    func testNoBareContains_wholeWordPatternRequiresBoundaries() {
        // "babygirl" is a `whole_word` pattern matched via `\bbabygirl\b`,
        // NOT `String.contains`. A synthetic string where "babygirl" is
        // embedded with no boundary on either side must NOT match — a bare
        // `contains` check would incorrectly match this.
        XCTAssertFalse(kb.matchedEntryIDs(for: "xbabygirlz").contains("babygirl"))
        // Same word WITH boundaries on both sides must match.
        XCTAssertTrue(kb.matchedEntryIDs(for: "You're such a babygirl.").contains("babygirl"))
    }

    func testDedup_noDuplicateEntryIDs() {
        // "ate and left no crumbs" contains two patterns of the SAME entry
        // ("ate and left no crumbs" and "ate that") — must still report the
        // entry only once.
        let ids = kb.matchedEntryIDs(for: "She really ate and left no crumbs, ate that up completely.")
        let ateCount = ids.filter { $0 == "ate" }.count
        XCTAssertEqual(ateCount, 1)
    }

    func testMaxThreeEntries() {
        let text = """
        Mother is mothering, he understood the assignment, this ain't it chief, \
        she ate and left no crumbs, and delulu is the solulu, and touch grass.
        """
        XCTAssertLessThanOrEqual(kb.matchedEntryIDs(for: text).count, 3)
    }

    // MARK: - Normalization

    func testNormalization_smartQuotes() {
        // Curly apostrophe (\u{2019}) should normalize the same as a
        // straight one for "it's giving".
        XCTAssertTrue(kb.matchedEntryIDs(for: "it\u{2019}s giving villain era").contains("its_giving"))
    }

    func testNormalization_caseInsensitive() {
        XCTAssertTrue(kb.matchedEntryIDs(for: "TOUCH GRASS").contains("touch_grass"))
    }

    // MARK: - No match at all

    func testNoMatch_returnsEmptyForOrdinaryChat() {
        XCTAssertTrue(kb.matchedEntryIDs(for: "See you tomorrow, let's grab lunch.").isEmpty)
    }

    func testBuildReference_nilWhenNoMatch() {
        XCTAssertNil(kb.buildReference(for: "See you tomorrow, let's grab lunch.", targetLanguage: "Korean"))
    }

    func testBuildReference_includesKoreanOnlyForKoreanTarget() {
        let koReference = kb.buildReference(for: "He understood the assignment.", targetLanguage: "Korean")
        XCTAssertNotNil(koReference)
        XCTAssertTrue(koReference?.contains("Preferred Korean expressions") ?? false)

        let enReference = kb.buildReference(for: "He understood the assignment.", targetLanguage: "English")
        XCTAssertNotNil(enReference)
        XCTAssertFalse(enReference?.contains("Preferred Korean expressions") ?? true)
    }

    func testBuildReference_preferredExpressionsHaveNoTrailingPeriod() {
        let reference = kb.buildReference(for: "He understood the assignment.", targetLanguage: "Korean")
        XCTAssertNotNil(reference)
        // "제대로 해냈네." in the JSON has a trailing period; the rendered
        // reference should have stripped it to "제대로 해냈네" per the
        // "don't bake in punctuation" requirement.
        XCTAssertTrue(reference?.contains("제대로 해냈네\n") ?? false)
        XCTAssertFalse(reference?.contains("제대로 해냈네.\n") ?? true)
    }
}
