import UIKit
import AudioToolbox
import os

// MARK: - Constants

private let mainPink = UIColor(red: 1, green: 0.42, blue: 0.62, alpha: 1)

// MARK: - GIPHY

// API keys live in Secrets.swift (gitignored). See ios/Secrets.sample.swift.
private let giphyApiKey = Secrets.giphyApiKey
private let openAIKey = Secrets.openAIKey

struct GiphyImage {
    let id: String
    let previewURL: URL
    let originalURL: URL
}

// MARK: - Font Style System

struct FontStyleDef {
    let name: String
    let convert: (String) -> String
}

private func _oc(_ t: String, _ u: Int, _ l: Int, _ d: Int? = nil, _ x: [Int: Int] = [:]) -> String {
    var r = ""
    for s in t.unicodeScalars {
        let v = Int(s.value)
        if let e = x[v] { r += String(UnicodeScalar(e)!) }
        else if v >= 0x41 && v <= 0x5A { r += String(UnicodeScalar(u + v - 0x41)!) }
        else if v >= 0x61 && v <= 0x7A { r += String(UnicodeScalar(l + v - 0x61)!) }
        else if let d = d, v >= 0x30 && v <= 0x39 { r += String(UnicodeScalar(d + v - 0x30)!) }
        else { r += String(s) }
    }
    return r
}

private func _cc(_ t: String, _ c: String) -> String {
    var r = ""; for ch in t { r.append(ch); if !ch.isWhitespace { r += c } }; return r
}

private func _cm(_ t: String, _ m: [Character: String]) -> String {
    t.map { m[$0] ?? String($0) }.joined()
}

private let _udMap: [Character: String] = [
    "a":"ɐ","b":"q","c":"ɔ","d":"p","e":"ǝ","f":"ɟ","g":"ƃ","h":"ɥ","i":"ᴉ","j":"ɾ",
    "k":"ʞ","l":"l","m":"ɯ","n":"u","o":"o","p":"d","q":"b","r":"ɹ","s":"s","t":"ʇ",
    "u":"n","v":"ʌ","w":"ʍ","x":"x","y":"ʎ","z":"z",
    "A":"∀","B":"ᗺ","C":"Ɔ","D":"ᗡ","E":"Ǝ","F":"Ⅎ","G":"⅁","H":"H","I":"I","J":"ſ",
    "K":"ʞ","L":"˥","M":"W","N":"N","O":"O","P":"Ԁ","Q":"Q","R":"ᴚ","S":"S","T":"⊥",
    "U":"∩","V":"Λ","W":"M","X":"X","Y":"⅄","Z":"Z",
    "1":"Ɩ","2":"ᄅ","3":"Ɛ","4":"ㄣ","5":"ϛ","6":"9","7":"ㄥ","8":"8","9":"6","0":"0",
    ".":"˙",",":"'","!":"¡","?":"¿","(":")",")":"(",
]
private func _ud(_ t: String) -> String { String(t.map { _udMap[$0] ?? String($0) }.joined().reversed()) }

private let _scMap: [Character: String] = [
    "a":"ᴀ","b":"ʙ","c":"ᴄ","d":"ᴅ","e":"ᴇ","f":"ꜰ","g":"ɢ","h":"ʜ","i":"ɪ","j":"ᴊ",
    "k":"ᴋ","l":"ʟ","m":"ᴍ","n":"ɴ","o":"ᴏ","p":"ᴘ","q":"q","r":"ʀ","s":"s","t":"ᴛ",
    "u":"ᴜ","v":"ᴠ","w":"ᴡ","x":"x","y":"ʏ","z":"ᴢ",
]

// Alien-looking glyphs (Canadian Aboriginal syllabics & Cherokee)
private let _alienMap: [Character: String] = [
    "a":"ᗩ","b":"ᗷ","c":"ᑕ","d":"ᗪ","e":"ᗴ","f":"ᖴ","g":"ᘜ","h":"ᕼ","i":"I","j":"ᒍ",
    "k":"ᛕ","l":"ᒪ","m":"ᗰ","n":"ᑎ","o":"O","p":"ᑭ","q":"ᑫ","r":"ᖇ","s":"ᔕ","t":"ᖶ",
    "u":"ᑌ","v":"ᐯ","w":"ᗯ","x":"᙭","y":"Ƴ","z":"ᘔ",
    "A":"ᗩ","B":"ᗷ","C":"ᑕ","D":"ᗪ","E":"ᗴ","F":"ᖴ","G":"ᘜ","H":"ᕼ","I":"I","J":"ᒍ",
    "K":"ᛕ","L":"ᒪ","M":"ᗰ","N":"ᑎ","O":"O","P":"ᑭ","Q":"ᑫ","R":"ᖇ","S":"ᔕ","T":"ᖶ",
    "U":"ᑌ","V":"ᐯ","W":"ᗯ","X":"᙭","Y":"Ƴ","Z":"ᘔ",
]

// Slightly cursive — mix of math italic + Sundanese/Cyrillic look-alikes
private let _slightlyCursiveMap: [Character: String] = [
    "a":"ᥲ","b":"𝘣","c":"ᥴ","d":"ᦔ","e":"ᥱ",
    "f":"𝘧","g":"g","h":"һ","i":"і","j":"𝘫",
    "k":"𝘬","l":"ᥣ","m":"𝘮","n":"𝘯","o":"𝘰",
    "p":"𝘱","q":"𝘲","r":"r","s":"s","t":"𝗍",
    "u":"ᥙ","v":"᥎","w":"𝘸","x":"𝘹","y":"ᥡ",
    "z":"𝘻",
    "A":"ᥲ","B":"𝘣","C":"ᥴ","D":"ᦔ","E":"ᥱ",
    "F":"𝘧","G":"g","H":"һ","I":"і","J":"𝘫",
    "K":"𝘬","L":"ᥣ","M":"𝘮","N":"𝘯","O":"𝘰",
    "P":"𝘱","Q":"𝘲","R":"r","S":"s","T":"𝗍",
    "U":"ᥙ","V":"᥎","W":"𝘸","X":"𝘹","Y":"ᥡ",
    "Z":"𝘻",
]

private let _itX: [Int: Int] = [0x68: 0x210E]
private let _scX: [Int: Int] = [0x42:0x212C,0x45:0x2130,0x46:0x2131,0x48:0x210B,0x49:0x2110,0x4C:0x2112,0x4D:0x2133,0x52:0x211B,0x65:0x212F,0x67:0x210A,0x6F:0x2134]
private let _goX: [Int: Int] = [0x43:0x212D,0x48:0x210C,0x49:0x2111,0x52:0x211C,0x5A:0x2128]
private let _dbX: [Int: Int] = [0x43:0x2102,0x48:0x210D,0x4E:0x2115,0x50:0x2119,0x51:0x211A,0x52:0x211D,0x5A:0x2124]
private let _mirrorMap: [Character: String] = [
    "A":"A","B":"ᙠ","C":"Ↄ","D":"ᗡ","E":"Ǝ","F":"ꟻ","G":"Ꭾ","H":"H","I":"I","J":"Ⴑ",
    "K":"K","L":"⅃","M":"M","N":"N","O":"O","P":"ꟼ","Q":"Q","R":"Я","S":"Ƨ","T":"T",
    "U":"U","V":"V","W":"W","X":"X","Y":"Y","Z":"Z",
    "a":"ɒ","b":"d","c":"ɔ","d":"b","e":"ɘ","f":"ʇ","g":"ǫ","h":"ʜ","i":"i","j":"į",
    "k":"k","l":"l","m":"m","n":"n","o":"o","p":"q","q":"p","r":"ɿ","s":"ƨ","t":"ƚ",
    "u":"u","v":"v","w":"w","x":"x","y":"y","z":"z",
    "0":"0","1":"1","2":"2","3":"Ɛ","4":"4","5":"5","6":"6","7":"7","8":"8","9":"9"
]
private let _supMap: [Character: String] = [
    "A":"ᴬ","B":"ᴮ","C":"ᶜ","D":"ᴰ","E":"ᴱ","F":"ᶠ","G":"ᴳ","H":"ᴴ","I":"ᴵ","J":"ᴶ",
    "K":"ᴷ","L":"ᴸ","M":"ᴹ","N":"ᴺ","O":"ᴼ","P":"ᴾ","Q":"Q","R":"ᴿ","S":"ˢ","T":"ᵀ",
    "U":"ᵁ","V":"ⱽ","W":"ᵂ","X":"ˣ","Y":"ʸ","Z":"ᶻ",
    "a":"ᵃ","b":"ᵇ","c":"ᶜ","d":"ᵈ","e":"ᵉ","f":"ᶠ","g":"ᵍ","h":"ʰ","i":"ⁱ","j":"ʲ",
    "k":"ᵏ","l":"ˡ","m":"ᵐ","n":"ⁿ","o":"ᵒ","p":"ᵖ","q":"q","r":"ʳ","s":"ˢ","t":"ᵗ",
    "u":"ᵘ","v":"ᵛ","w":"ʷ","x":"ˣ","y":"ʸ","z":"ᶻ",
    "0":"⁰","1":"¹","2":"²","3":"³","4":"⁴","5":"⁵","6":"⁶","7":"⁷","8":"⁸","9":"⁹"
]
private let _subMap: [Character: String] = [
    "a":"ₐ","b":"♭","c":"꜀","d":"d","e":"ₑ","f":"բ","g":"₉","h":"ₕ","i":"ᵢ","j":"ⱼ",
    "k":"ₖ","l":"ₗ","m":"ₘ","n":"ₙ","o":"ₒ","p":"ₚ","q":"q","r":"ᵣ","s":"ₛ","t":"ₜ",
    "u":"ᵤ","v":"ᵥ","w":"w","x":"ₓ","y":"ᵧ","z":"z",
    "A":"ₐ","B":"♭","C":"꜀","D":"D","E":"ₑ","F":"բ","G":"₉","H":"ₕ","I":"ᵢ","J":"ⱼ",
    "K":"ₖ","L":"ₗ","M":"ₘ","N":"ₙ","O":"ₒ","P":"ₚ","Q":"Q","R":"ᵣ","S":"ₛ","T":"ₜ",
    "U":"ᵤ","V":"ᵥ","W":"W","X":"ₓ","Y":"ᵧ","Z":"Z",
    "0":"₀","1":"₁","2":"₂","3":"₃","4":"₄","5":"₅","6":"₆","7":"₇","8":"₈","9":"₉"
]
private let _runeMap: [Character: String] = [
    "A":"ᚨ","B":"ᛒ","C":"ᚲ","D":"ᛞ","E":"ᛖ","F":"ᚠ","G":"ᚷ","H":"ᚺ","I":"ᛁ","J":"ᛃ",
    "K":"ᚲ","L":"ᛚ","M":"ᛗ","N":"ᚾ","O":"ᛟ","P":"ᛈ","Q":"ᛩ","R":"ᚱ","S":"ᛋ","T":"ᛏ",
    "U":"ᚢ","V":"ᚡ","W":"ᚹ","X":"ᛪ","Y":"ᚤ","Z":"ᛉ",
    "a":"ᚨ","b":"ᛒ","c":"ᚲ","d":"ᛞ","e":"ᛖ","f":"ᚠ","g":"ᚷ","h":"ᚺ","i":"ᛁ","j":"ᛃ",
    "k":"ᚲ","l":"ᛚ","m":"ᛗ","n":"ᚾ","o":"ᛟ","p":"ᛈ","q":"ᛩ","r":"ᚱ","s":"ᛋ","t":"ᛏ",
    "u":"ᚢ","v":"ᚡ","w":"ᚹ","x":"ᛪ","y":"ᚤ","z":"ᛉ"
]
private let _morseMap: [Character: String] = [
    "A":"·− ","B":"−··· ","C":"−·−· ","D":"−·· ","E":"· ","F":"··−· ","G":"−−· ","H":"···· ",
    "I":"·· ","J":"·−−− ","K":"−·− ","L":"·−·· ","M":"−− ","N":"−· ","O":"−−− ","P":"·−−· ",
    "Q":"−−·− ","R":"·−· ","S":"··· ","T":"− ","U":"··− ","V":"···− ","W":"·−− ","X":"−··− ",
    "Y":"−·−− ","Z":"−−·· ",
    "a":"·− ","b":"−··· ","c":"−·−· ","d":"−·· ","e":"· ","f":"··−· ","g":"−−· ","h":"···· ",
    "i":"·· ","j":"·−−− ","k":"−·− ","l":"·−·· ","m":"−− ","n":"−· ","o":"−−− ","p":"·−−· ",
    "q":"−−·− ","r":"·−· ","s":"··· ","t":"− ","u":"··− ","v":"···− ","w":"·−− ","x":"−··− ",
    "y":"−·−− ","z":"−−·· ",
    "0":"−−−−− ","1":"·−−−− ","2":"··−−− ","3":"···−− ","4":"····− ","5":"····· ",
    "6":"−···· ","7":"−−··· ","8":"−−−·· ","9":"−−−−· "
]

private let _leetMap: [Character: String] = [
    "a":"4","b":"8","e":"3","g":"9","i":"1","l":"1","o":"0","s":"5","t":"7","z":"2",
    "A":"4","B":"8","E":"3","G":"9","I":"1","L":"1","O":"0","S":"5","T":"7","Z":"2"
]
private let _wingMap: [Character: String] = [
    "a":"✈","b":"☀","c":"☁","d":"☂","e":"☃","f":"☄","g":"★","h":"☆","i":"☇","j":"☈",
    "k":"☉","l":"☊","m":"☋","n":"☌","o":"☍","p":"☎","q":"☏","r":"☐","s":"☑","t":"☒",
    "u":"☓","v":"☔","w":"☕","x":"☖","y":"☗","z":"☘",
    "A":"♠","B":"♡","C":"♢","D":"♣","E":"♤","F":"♥","G":"♦","H":"♧","I":"♨","J":"♩",
    "K":"♪","L":"♫","M":"♬","N":"♭","O":"♮","P":"♯","Q":"♰","R":"♱","S":"♲","T":"♳",
    "U":"♴","V":"♵","W":"♶","X":"♷","Y":"♸","Z":"♹"
]

/// Inverse of every `_cm`-driven map currently registered in fontStyles.
/// Maps a styled scalar (e.g. ᗩ) back to its plain ASCII counterpart, so a
/// follow-up font conversion can recognise the character.
///
/// Several source maps (`_alienMap`, `_slightlyCursiveMap`, `_subMap`) use the
/// same styled glyph for both upper and lowercase ASCII (e.g. `"s":"ᔕ"` and
/// `"S":"ᔕ"` in `_alienMap`). Swift's dictionary iteration order is
/// non-deterministic, so plain first-write-wins would let the case stored in
/// the inverse table flip between launches and corrupt re-conversions like
/// "miss" → "MISS". Prefer lowercase: lowercase is the natural rest state for
/// re-typing and matches the lowercase result the user expects.
private let _cmReverseMap: [UInt32: UInt32] = {
    var rev: [UInt32: UInt32] = [:]
    let sources: [[Character: String]] = [
        _alienMap, _slightlyCursiveMap, _scMap, _supMap, _subMap,
    ]
    for map in sources {
        for (asciiKey, styledValue) in map {
            guard let kScalar = asciiKey.unicodeScalars.first?.value,
                  let vScalar = styledValue.unicodeScalars.first?.value else { continue }
            // Skip identity entries (e.g. _slightlyCursiveMap "g" → "g").
            if kScalar == vScalar { continue }
            // Drop ASCII→ASCII fallbacks (e.g. _slightlyCursiveMap "S":"s",
            // "R":"r", "G":"g" — and _alienMap "i":"I", "o":"O"). Storing
            // these in the inverse table would make `normalizeToASCII`
            // rewrite plain typed letters into a different case.
            if vScalar < 0x80 { continue }
            let isLower = (kScalar >= 0x61 && kScalar <= 0x7A)
            if rev[vScalar] == nil || isLower { rev[vScalar] = kScalar }
        }
    }
    return rev
}()

/// Inverse of `_udMap` (Flip). The Flip style applies `_udMap` per character
/// and then reverses the whole string; to undo it we reverse-map each scalar
/// and reverse the resulting string back. Detection of any flipped scalar in
/// the input triggers the final reverse — see `normalizeToASCII`.
private let _udReverseMap: [UInt32: UInt32] = {
    var rev: [UInt32: UInt32] = [:]
    for (asciiKey, styledValue) in _udMap {
        guard let kScalar = asciiKey.unicodeScalars.first?.value,
              let vScalar = styledValue.unicodeScalars.first?.value else { continue }
        if kScalar == vScalar { continue }
        if rev[vScalar] == nil { rev[vScalar] = kScalar }
    }
    return rev
}()

let allFontCategories: [(String, [FontStyleDef])] = [
    (NSLocalizedString("font_cat_classic", bundle: Bundle(for: KeyboardViewController.self), comment: ""), [
        FontStyleDef(name: "Normal",       convert: { $0 }),
        FontStyleDef(name: "Italic",       convert: { _oc($0, 0x1D434, 0x1D44E, nil, _itX) }),
        FontStyleDef(name: "Bold",         convert: { _oc($0, 0x1D5D4, 0x1D5EE, 0x1D7EC) }),
        FontStyleDef(name: "Bold Italic",  convert: { _oc($0, 0x1D468, 0x1D482, 0x1D7CE) }),
        FontStyleDef(name: "Script",       convert: { _oc($0, 0x1D49C, 0x1D4B6, nil, _scX) }),
        FontStyleDef(name: "Bold Script",  convert: { _oc($0, 0x1D4D0, 0x1D4EA, nil) }),
        FontStyleDef(name: "Gothic",       convert: { _oc($0, 0x1D504, 0x1D51E, nil, _goX) }),
        FontStyleDef(name: "Typewriter",   convert: { _oc($0, 0x1D670, 0x1D68A, 0x1D7F6) }),
        FontStyleDef(name: "Outline",      convert: { _oc($0, 0x1D538, 0x1D552, 0x1D7D8, _dbX) }),
        FontStyleDef(name: "Comic",        convert: { _cm($0, _alienMap) }),
        FontStyleDef(name: "Cursive",      convert: { _cm($0, _slightlyCursiveMap) }),
    ]),
    (NSLocalizedString("font_cat_modern", bundle: Bundle(for: KeyboardViewController.self), comment: ""), [
        FontStyleDef(name: "Wide",         convert: { _oc($0, 0xFF21, 0xFF41, 0xFF10) }),
        FontStyleDef(name: "Dark",         convert: { _oc($0, 0x1D56C, 0x1D586, nil) }),
        FontStyleDef(name: "Sans",         convert: { _oc($0, 0x1D5A0, 0x1D5BA, 0x1D7E2) }),
        FontStyleDef(name: "Sans Italic",  convert: { _oc($0, 0x1D608, 0x1D622, nil) }),
        FontStyleDef(name: "Heavy",        convert: { _oc($0, 0x1D63C, 0x1D656, nil) }),
    ]),
    (NSLocalizedString("font_cat_bold", bundle: Bundle(for: KeyboardViewController.self), comment: ""), [
        FontStyleDef(name: "Serif Bold",   convert: { _oc($0, 0x1D400, 0x1D41A, 0x1D7CE) }),
        FontStyleDef(name: "Chunky",       convert: { _oc($0, 0x1F150, 0x1F150, nil) }),
        FontStyleDef(name: "Block",        convert: { _oc($0, 0x1F170, 0x1F170, nil) }),
    ]),
    (NSLocalizedString("font_cat_fun", bundle: Bundle(for: KeyboardViewController.self), comment: ""), [
        FontStyleDef(name: "Flip",         convert: { _ud($0) }),
        FontStyleDef(name: "Bubble",       convert: { _oc($0, 0x24B6, 0x24D0, nil) }),
        FontStyleDef(name: "Square",       convert: { _oc($0, 0x1F130, 0x1F130, nil) }),
        FontStyleDef(name: "Small Caps",   convert: { _cm($0, _scMap) }),
        FontStyleDef(name: "Sad",          convert: { _cc($0, "\u{0308}") }),
        FontStyleDef(name: "Happy",        convert: { _cc($0, "\u{0324}") }),
        FontStyleDef(name: "Clouds",       convert: { _cc($0, "\u{0353}\u{033D}") }),
        FontStyleDef(name: "Stinky",       convert: { _cc($0, "\u{0307}") }),
        FontStyleDef(name: "Wiggle",       convert: { _cc($0, "\u{0360}") }),
        FontStyleDef(name: "Rays",         convert: { _cc($0, "\u{033E}") }),
        FontStyleDef(name: "Skyline",      convert: { _cc($0, "\u{0332}") }),
        FontStyleDef(name: "Blinds",       convert: { _cc($0, "\u{0336}") }),
        FontStyleDef(name: "Arrows",       convert: { _cc($0, "\u{20D7}") }),
        FontStyleDef(name: "Super",        convert: { _cm($0, _supMap) }),
        FontStyleDef(name: "Cloudy",       convert: { $0.map { $0 == " " ? " " : "☁\($0)" }.joined() }),
    ]),
    (NSLocalizedString("font_cat_decorative", bundle: Bundle(for: KeyboardViewController.self), comment: ""), [
        FontStyleDef(name: "Overline",     convert: { _cc($0, "\u{0305}") }),
        FontStyleDef(name: "Sparkle",      convert: { _cc($0, "꙰") }),
        FontStyleDef(name: "Candy",        convert: { $0.map { $0 == " " ? " " : "♡\($0)♡" }.joined() }),
        FontStyleDef(name: "Pinched",      convert: { _cc($0, "\u{0303}") }),
    ]),
    (NSLocalizedString("font_cat_extra", bundle: Bundle(for: KeyboardViewController.self), comment: ""), [
        FontStyleDef(name: "Ringed",       convert: { _cc($0, "\u{030A}") }),
        FontStyleDef(name: "Dotted",       convert: { _cc($0, "\u{0323}") }),
        FontStyleDef(name: "Box",          convert: { $0.map { $0 == " " ? " " : "[\($0)]" }.joined() }),
        FontStyleDef(name: "Sub",          convert: { _cm($0, _subMap) }),
    ]),
    (NSLocalizedString("font_cat_unique", bundle: Bundle(for: KeyboardViewController.self), comment: ""), [
        FontStyleDef(name: "Chaos",        convert: { _cc($0, "\u{0489}") }),
        FontStyleDef(name: "Zalgo",        convert: { _cc($0, "\u{0334}\u{0308}\u{0330}") }),
        FontStyleDef(name: "Ancient",      convert: { _oc($0, 0x10300, 0x10300, nil) }),
        FontStyleDef(name: "Halo",         convert: { _cc($0, "\u{035C}") }),
    ]),
]

// Compatibility wrapper for dotArtToImage (uses first style = normal)
func convertText(_ text: String, style: Int) -> String {
    return text // unused fallback
}

// MARK: - Legacy FontStyle (kept for compatibility)

enum FontStyle: Int, CaseIterable {
    case normal, bold, italic, boldItalic, script, double, monospace, fullwidth, gothic, boldGothic, strike, underline

    var displayName: String {
        switch self {
        case .normal:     return "Normal"
        case .bold:       return "𝗕𝗼𝗹𝗱"
        case .italic:     return "𝘐𝘵𝘢𝘭𝘪𝘤"
        case .boldItalic: return "𝘽𝙤𝙡𝙙𝙄𝙩"
        case .script:     return "𝒮𝒸𝓇𝒾𝓅𝓉"
        case .double:     return "𝔻𝕠𝕦𝕓𝕝𝕖"
        case .monospace:  return "𝙼𝚘𝚗𝚘"
        case .fullwidth:  return "Ｆｕｌｌ"
        case .gothic:     return "𝔊𝔬𝔱𝔥𝔦𝔠"
        case .boldGothic: return "𝕭𝖔𝖑𝖉𝕲"
        case .strike:     return "S̶t̶r̶i̶k̶e̶"
        case .underline:  return "U̲n̲d̲e̲r̲"
        }
    }
}

// MARK: - Unicode Maps

private let boldMap: [Character: String] = [
    "A": "\u{1D400}", "B": "\u{1D401}", "C": "\u{1D402}", "D": "\u{1D403}",
    "E": "\u{1D404}", "F": "\u{1D405}", "G": "\u{1D406}", "H": "\u{1D407}",
    "I": "\u{1D408}", "J": "\u{1D409}", "K": "\u{1D40A}", "L": "\u{1D40B}",
    "M": "\u{1D40C}", "N": "\u{1D40D}", "O": "\u{1D40E}", "P": "\u{1D40F}",
    "Q": "\u{1D410}", "R": "\u{1D411}", "S": "\u{1D412}", "T": "\u{1D413}",
    "U": "\u{1D414}", "V": "\u{1D415}", "W": "\u{1D416}", "X": "\u{1D417}",
    "Y": "\u{1D418}", "Z": "\u{1D419}",
    "a": "\u{1D41A}", "b": "\u{1D41B}", "c": "\u{1D41C}", "d": "\u{1D41D}",
    "e": "\u{1D41E}", "f": "\u{1D41F}", "g": "\u{1D420}", "h": "\u{1D421}",
    "i": "\u{1D422}", "j": "\u{1D423}", "k": "\u{1D424}", "l": "\u{1D425}",
    "m": "\u{1D426}", "n": "\u{1D427}", "o": "\u{1D428}", "p": "\u{1D429}",
    "q": "\u{1D42A}", "r": "\u{1D42B}", "s": "\u{1D42C}", "t": "\u{1D42D}",
    "u": "\u{1D42E}", "v": "\u{1D42F}", "w": "\u{1D430}", "x": "\u{1D431}",
    "y": "\u{1D432}", "z": "\u{1D433}",
    "0": "\u{1D7CE}", "1": "\u{1D7CF}", "2": "\u{1D7D0}", "3": "\u{1D7D1}",
    "4": "\u{1D7D2}", "5": "\u{1D7D3}", "6": "\u{1D7D4}", "7": "\u{1D7D5}",
    "8": "\u{1D7D6}", "9": "\u{1D7D7}",
]

private let italicMap: [Character: String] = [
    "A": "\u{1D434}", "B": "\u{1D435}", "C": "\u{1D436}", "D": "\u{1D437}",
    "E": "\u{1D438}", "F": "\u{1D439}", "G": "\u{1D43A}", "H": "\u{1D43B}",
    "I": "\u{1D43C}", "J": "\u{1D43D}", "K": "\u{1D43E}", "L": "\u{1D43F}",
    "M": "\u{1D440}", "N": "\u{1D441}", "O": "\u{1D442}", "P": "\u{1D443}",
    "Q": "\u{1D444}", "R": "\u{1D445}", "S": "\u{1D446}", "T": "\u{1D447}",
    "U": "\u{1D448}", "V": "\u{1D449}", "W": "\u{1D44A}", "X": "\u{1D44B}",
    "Y": "\u{1D44C}", "Z": "\u{1D44D}",
    "a": "\u{1D44E}", "b": "\u{1D44F}", "c": "\u{1D450}", "d": "\u{1D451}",
    "e": "\u{1D452}", "f": "\u{1D453}", "g": "\u{1D454}", "h": "\u{210E}",
    "i": "\u{1D456}", "j": "\u{1D457}", "k": "\u{1D458}", "l": "\u{1D459}",
    "m": "\u{1D45A}", "n": "\u{1D45B}", "o": "\u{1D45C}", "p": "\u{1D45D}",
    "q": "\u{1D45E}", "r": "\u{1D45F}", "s": "\u{1D460}", "t": "\u{1D461}",
    "u": "\u{1D462}", "v": "\u{1D463}", "w": "\u{1D464}", "x": "\u{1D465}",
    "y": "\u{1D466}", "z": "\u{1D467}",
]

private let scriptMap: [Character: String] = [
    "A": "\u{1D49C}", "B": "\u{212C}",  "C": "\u{1D49E}", "D": "\u{1D49F}",
    "E": "\u{2130}",  "F": "\u{2131}",  "G": "\u{1D4A2}", "H": "\u{210B}",
    "I": "\u{2110}",  "J": "\u{1D4A5}", "K": "\u{1D4A6}", "L": "\u{2112}",
    "M": "\u{2133}",  "N": "\u{1D4A9}", "O": "\u{1D4AA}", "P": "\u{1D4AB}",
    "Q": "\u{1D4AC}", "R": "\u{211B}",  "S": "\u{1D4AE}", "T": "\u{1D4AF}",
    "U": "\u{1D4B0}", "V": "\u{1D4B1}", "W": "\u{1D4B2}", "X": "\u{1D4B3}",
    "Y": "\u{1D4B4}", "Z": "\u{1D4B5}",
    "a": "\u{1D4B6}", "b": "\u{1D4B7}", "c": "\u{1D4B8}", "d": "\u{1D4B9}",
    "e": "\u{212F}",  "f": "\u{1D4BB}", "g": "\u{210A}",  "h": "\u{1D4BD}",
    "i": "\u{1D4BE}", "j": "\u{1D4BF}", "k": "\u{1D4C0}", "l": "\u{1D4C1}",
    "m": "\u{1D4C2}", "n": "\u{1D4C3}", "o": "\u{2134}",  "p": "\u{1D4C5}",
    "q": "\u{1D4C6}", "r": "\u{1D4C7}", "s": "\u{1D4C8}", "t": "\u{1D4C9}",
    "u": "\u{1D4CA}", "v": "\u{1D4CB}", "w": "\u{1D4CC}", "x": "\u{1D4CD}",
    "y": "\u{1D4CE}", "z": "\u{1D4CF}",
]

private let gothicMap: [Character: String] = [
    "A": "\u{1D504}", "B": "\u{1D505}", "C": "\u{212D}",  "D": "\u{1D507}",
    "E": "\u{1D508}", "F": "\u{1D509}", "G": "\u{1D50A}", "H": "\u{210C}",
    "I": "\u{2111}",  "J": "\u{1D50D}", "K": "\u{1D50E}", "L": "\u{1D50F}",
    "M": "\u{1D510}", "N": "\u{1D511}", "O": "\u{1D512}", "P": "\u{1D513}",
    "Q": "\u{1D514}", "R": "\u{211C}",  "S": "\u{1D516}", "T": "\u{1D517}",
    "U": "\u{1D518}", "V": "\u{1D519}", "W": "\u{1D51A}", "X": "\u{1D51B}",
    "Y": "\u{1D51C}", "Z": "\u{2128}",
    "a": "\u{1D51E}", "b": "\u{1D51F}", "c": "\u{1D520}", "d": "\u{1D521}",
    "e": "\u{1D522}", "f": "\u{1D523}", "g": "\u{1D524}", "h": "\u{1D525}",
    "i": "\u{1D526}", "j": "\u{1D527}", "k": "\u{1D528}", "l": "\u{1D529}",
    "m": "\u{1D52A}", "n": "\u{1D52B}", "o": "\u{1D52C}", "p": "\u{1D52D}",
    "q": "\u{1D52E}", "r": "\u{1D52F}", "s": "\u{1D530}", "t": "\u{1D531}",
    "u": "\u{1D532}", "v": "\u{1D533}", "w": "\u{1D534}", "x": "\u{1D535}",
    "y": "\u{1D536}", "z": "\u{1D537}",
]

private let fullwidthMap: [Character: String] = [
    "A": "\u{FF21}", "B": "\u{FF22}", "C": "\u{FF23}", "D": "\u{FF24}",
    "E": "\u{FF25}", "F": "\u{FF26}", "G": "\u{FF27}", "H": "\u{FF28}",
    "I": "\u{FF29}", "J": "\u{FF2A}", "K": "\u{FF2B}", "L": "\u{FF2C}",
    "M": "\u{FF2D}", "N": "\u{FF2E}", "O": "\u{FF2F}", "P": "\u{FF30}",
    "Q": "\u{FF31}", "R": "\u{FF32}", "S": "\u{FF33}", "T": "\u{FF34}",
    "U": "\u{FF35}", "V": "\u{FF36}", "W": "\u{FF37}", "X": "\u{FF38}",
    "Y": "\u{FF39}", "Z": "\u{FF3A}",
    "a": "\u{FF41}", "b": "\u{FF42}", "c": "\u{FF43}", "d": "\u{FF44}",
    "e": "\u{FF45}", "f": "\u{FF46}", "g": "\u{FF47}", "h": "\u{FF48}",
    "i": "\u{FF49}", "j": "\u{FF4A}", "k": "\u{FF4B}", "l": "\u{FF4C}",
    "m": "\u{FF4D}", "n": "\u{FF4E}", "o": "\u{FF4F}", "p": "\u{FF50}",
    "q": "\u{FF51}", "r": "\u{FF52}", "s": "\u{FF53}", "t": "\u{FF54}",
    "u": "\u{FF55}", "v": "\u{FF56}", "w": "\u{FF57}", "x": "\u{FF58}",
    "y": "\u{FF59}", "z": "\u{FF5A}",
    "0": "\u{FF10}", "1": "\u{FF11}", "2": "\u{FF12}", "3": "\u{FF13}",
    "4": "\u{FF14}", "5": "\u{FF15}", "6": "\u{FF16}", "7": "\u{FF17}",
    "8": "\u{FF18}", "9": "\u{FF19}",
]

private let monospaceMap: [Character: String] = [
    "A": "\u{1D670}", "B": "\u{1D671}", "C": "\u{1D672}", "D": "\u{1D673}",
    "E": "\u{1D674}", "F": "\u{1D675}", "G": "\u{1D676}", "H": "\u{1D677}",
    "I": "\u{1D678}", "J": "\u{1D679}", "K": "\u{1D67A}", "L": "\u{1D67B}",
    "M": "\u{1D67C}", "N": "\u{1D67D}", "O": "\u{1D67E}", "P": "\u{1D67F}",
    "Q": "\u{1D680}", "R": "\u{1D681}", "S": "\u{1D682}", "T": "\u{1D683}",
    "U": "\u{1D684}", "V": "\u{1D685}", "W": "\u{1D686}", "X": "\u{1D687}",
    "Y": "\u{1D688}", "Z": "\u{1D689}",
    "a": "\u{1D68A}", "b": "\u{1D68B}", "c": "\u{1D68C}", "d": "\u{1D68D}",
    "e": "\u{1D68E}", "f": "\u{1D68F}", "g": "\u{1D690}", "h": "\u{1D691}",
    "i": "\u{1D692}", "j": "\u{1D693}", "k": "\u{1D694}", "l": "\u{1D695}",
    "m": "\u{1D696}", "n": "\u{1D697}", "o": "\u{1D698}", "p": "\u{1D699}",
    "q": "\u{1D69A}", "r": "\u{1D69B}", "s": "\u{1D69C}", "t": "\u{1D69D}",
    "u": "\u{1D69E}", "v": "\u{1D69F}", "w": "\u{1D6A0}", "x": "\u{1D6A1}",
    "y": "\u{1D6A2}", "z": "\u{1D6A3}",
    "0": "\u{1D7F6}", "1": "\u{1D7F7}", "2": "\u{1D7F8}", "3": "\u{1D7F9}",
    "4": "\u{1D7FA}", "5": "\u{1D7FB}", "6": "\u{1D7FC}", "7": "\u{1D7FD}",
    "8": "\u{1D7FE}", "9": "\u{1D7FF}",
]

// MARK: - Bold Italic Map

private let boldItalicMap: [Character: String] = [
    "A": "\u{1D468}", "B": "\u{1D469}", "C": "\u{1D46A}", "D": "\u{1D46B}",
    "E": "\u{1D46C}", "F": "\u{1D46D}", "G": "\u{1D46E}", "H": "\u{1D46F}",
    "I": "\u{1D470}", "J": "\u{1D471}", "K": "\u{1D472}", "L": "\u{1D473}",
    "M": "\u{1D474}", "N": "\u{1D475}", "O": "\u{1D476}", "P": "\u{1D477}",
    "Q": "\u{1D478}", "R": "\u{1D479}", "S": "\u{1D47A}", "T": "\u{1D47B}",
    "U": "\u{1D47C}", "V": "\u{1D47D}", "W": "\u{1D47E}", "X": "\u{1D47F}",
    "Y": "\u{1D480}", "Z": "\u{1D481}",
    "a": "\u{1D482}", "b": "\u{1D483}", "c": "\u{1D484}", "d": "\u{1D485}",
    "e": "\u{1D486}", "f": "\u{1D487}", "g": "\u{1D488}", "h": "\u{1D489}",
    "i": "\u{1D48A}", "j": "\u{1D48B}", "k": "\u{1D48C}", "l": "\u{1D48D}",
    "m": "\u{1D48E}", "n": "\u{1D48F}", "o": "\u{1D490}", "p": "\u{1D491}",
    "q": "\u{1D492}", "r": "\u{1D493}", "s": "\u{1D494}", "t": "\u{1D495}",
    "u": "\u{1D496}", "v": "\u{1D497}", "w": "\u{1D498}", "x": "\u{1D499}",
    "y": "\u{1D49A}", "z": "\u{1D49B}",
]

// MARK: - Double-Struck Map

private let doubleMap: [Character: String] = [
    "A": "\u{1D538}", "B": "\u{1D539}", "C": "\u{2102}",  "D": "\u{1D53B}",
    "E": "\u{1D53C}", "F": "\u{1D53D}", "G": "\u{1D53E}", "H": "\u{210D}",
    "I": "\u{1D540}", "J": "\u{1D541}", "K": "\u{1D542}", "L": "\u{1D543}",
    "M": "\u{1D544}", "N": "\u{2115}",  "O": "\u{1D546}", "P": "\u{2119}",
    "Q": "\u{211A}",  "R": "\u{211D}",  "S": "\u{1D54A}", "T": "\u{1D54B}",
    "U": "\u{1D54C}", "V": "\u{1D54D}", "W": "\u{1D54E}", "X": "\u{1D54F}",
    "Y": "\u{1D550}", "Z": "\u{2124}",
    "a": "\u{1D552}", "b": "\u{1D553}", "c": "\u{1D554}", "d": "\u{1D555}",
    "e": "\u{1D556}", "f": "\u{1D557}", "g": "\u{1D558}", "h": "\u{1D559}",
    "i": "\u{1D55A}", "j": "\u{1D55B}", "k": "\u{1D55C}", "l": "\u{1D55D}",
    "m": "\u{1D55E}", "n": "\u{1D55F}", "o": "\u{1D560}", "p": "\u{1D561}",
    "q": "\u{1D562}", "r": "\u{1D563}", "s": "\u{1D564}", "t": "\u{1D565}",
    "u": "\u{1D566}", "v": "\u{1D567}", "w": "\u{1D568}", "x": "\u{1D569}",
    "y": "\u{1D56A}", "z": "\u{1D56B}",
    "0": "\u{1D7D8}", "1": "\u{1D7D9}", "2": "\u{1D7DA}", "3": "\u{1D7DB}",
    "4": "\u{1D7DC}", "5": "\u{1D7DD}", "6": "\u{1D7DE}", "7": "\u{1D7DF}",
    "8": "\u{1D7E0}", "9": "\u{1D7E1}",
]

// MARK: - Bold Gothic Map

private let boldGothicMap: [Character: String] = [
    "A": "\u{1D56C}", "B": "\u{1D56D}", "C": "\u{1D56E}", "D": "\u{1D56F}",
    "E": "\u{1D570}", "F": "\u{1D571}", "G": "\u{1D572}", "H": "\u{1D573}",
    "I": "\u{1D574}", "J": "\u{1D575}", "K": "\u{1D576}", "L": "\u{1D577}",
    "M": "\u{1D578}", "N": "\u{1D579}", "O": "\u{1D57A}", "P": "\u{1D57B}",
    "Q": "\u{1D57C}", "R": "\u{1D57D}", "S": "\u{1D57E}", "T": "\u{1D57F}",
    "U": "\u{1D580}", "V": "\u{1D581}", "W": "\u{1D582}", "X": "\u{1D583}",
    "Y": "\u{1D584}", "Z": "\u{1D585}",
    "a": "\u{1D586}", "b": "\u{1D587}", "c": "\u{1D588}", "d": "\u{1D589}",
    "e": "\u{1D58A}", "f": "\u{1D58B}", "g": "\u{1D58C}", "h": "\u{1D58D}",
    "i": "\u{1D58E}", "j": "\u{1D58F}", "k": "\u{1D590}", "l": "\u{1D591}",
    "m": "\u{1D592}", "n": "\u{1D593}", "o": "\u{1D594}", "p": "\u{1D595}",
    "q": "\u{1D596}", "r": "\u{1D597}", "s": "\u{1D598}", "t": "\u{1D599}",
    "u": "\u{1D59A}", "v": "\u{1D59B}", "w": "\u{1D59C}", "x": "\u{1D59D}",
    "y": "\u{1D59E}", "z": "\u{1D59F}",
]

// MARK: - Convert Function

func convertText(_ text: String, style: FontStyle) -> String {
    switch style {
    case .normal:     return text
    case .bold:       return mapChars(text, boldMap)
    case .italic:     return mapChars(text, italicMap)
    case .boldItalic: return mapChars(text, boldItalicMap)
    case .script:     return mapChars(text, scriptMap)
    case .double:     return mapChars(text, doubleMap)
    case .monospace:  return mapChars(text, monospaceMap)
    case .fullwidth:  return mapChars(text, fullwidthMap)
    case .gothic:     return mapChars(text, gothicMap)
    case .boldGothic: return mapChars(text, boldGothicMap)
    case .strike:     return addCombining(text, "\u{0336}")
    case .underline:  return addCombining(text, "\u{0332}")
    }
}

private func mapChars(_ text: String, _ map: [Character: String]) -> String {
    var result = ""
    for ch in text {
        if let mapped = map[ch] {
            result += mapped
        } else {
            result.append(ch)
        }
    }
    return result
}

private func addCombining(_ text: String, _ combiner: String) -> String {
    var result = ""
    for ch in text {
        result.append(ch)
        if !ch.isWhitespace {
            result += combiner
        }
    }
    return result
}

// MARK: - KeyboardViewController

class KeyboardViewController: UIInputViewController, UIScrollViewDelegate, UIInputViewAudioFeedback {

    var enableInputClicksWhenVisible: Bool { true }


    // MARK: - Mode

    enum Mode: Int, CaseIterable {
        case fonts = 0, translate, calculator, emoticon, textTemplate, special, dotArt, gif, favorites, palette
        var title: String {
            let bundle = Bundle(for: KeyboardViewController.self)
            switch self {
            case .fonts:        return "Aa"
            case .translate:    return NSLocalizedString("tab_translate", bundle: bundle, comment: "")
            case .calculator:   return ""  // SF Symbol image used instead (plusminus.circle)
            case .emoticon:     return "( ◡̉̈ )"
            case .textTemplate: return "💬"
            case .special:      return "✦"
            case .dotArt:       return "⣿"
            case .gif:          return "GIF"
            case .favorites:    return "♥"
            case .palette:      return ""  // SF Symbol image used instead (paintpalette.fill)
            }
        }
        var fontSize: CGFloat {
            switch self {
            case .emoticon:  return 11
            case .special:   return 16
            case .dotArt:    return 16
            case .translate: return 12
            default:         return 14
            }
        }
    }

    // MARK: - Localization

    private func loc(_ key: String) -> String {
        NSLocalizedString(key, bundle: Bundle(for: type(of: self)), comment: "")
    }

    // MARK: - State

    private var currentMode: Mode = .fonts

    // MARK: - Theme

    enum KeyboardTheme: String, CaseIterable {
        case `default`
        case cottonCandy
        case lavender
        case pastelRainbow
        case soft
        case bubbleMint
        case retroCream
        case vintageGray
        case hotPink
    }

    private var currentTheme: KeyboardTheme {
        get {
            let raw = UserDefaults.standard.string(forKey: "fonkii_theme") ?? "default"
            return KeyboardTheme(rawValue: raw) ?? .default
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "fonkii_theme")
            // Default theme preserves the user's last-set accent color.
            // All other themes reset the accent color to their own default.
            if newValue != .default {
                let defaultColor = Self.defaultAccentColor(for: newValue)
                if let data = try? NSKeyedArchiver.archivedData(
                    withRootObject: defaultColor, requiringSecureCoding: false) {
                    UserDefaults.standard.set(data, forKey: "fonkii_accent_color")
                }
            }
            applyTheme()
        }
    }

    private static func defaultAccentColor(for theme: KeyboardTheme) -> UIColor {
        switch theme {
        case .default:       return UIColor(red: 1.0, green: 0.42, blue: 0.62, alpha: 1)
        case .cottonCandy:   return UIColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 1)
        case .lavender:      return UIColor(red: 0.80, green: 0.70, blue: 0.95, alpha: 1)
        case .pastelRainbow: return UIColor(red: 1.0, green: 0.61, blue: 0.71, alpha: 1)
        case .soft:          return UIColor(red: 1.0, green: 0.70, blue: 0.78, alpha: 1)
        case .bubbleMint:    return UIColor(red: 0.35, green: 0.75, blue: 0.45, alpha: 1)
        case .retroCream:    return UIColor(red: 0.55, green: 0.90, blue: 0.65, alpha: 1)
        case .vintageGray:   return UIColor(red: 0.35, green: 0.35, blue: 0.38, alpha: 1)
        case .hotPink:       return UIColor(red: 0.97, green: 0.65, blue: 0.73, alpha: 1)
        }
    }

    /// Normal key background — varies by theme.
    private var keyBG: UIColor {
        switch currentTheme {
        case .default:       return UIColor(white: 0.90, alpha: 1)
        case .cottonCandy:   return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        case .lavender:      return UIColor(red: 0.98, green: 0.96, blue: 1.0, alpha: 1)
        case .pastelRainbow: return UIColor(white: 1.0, alpha: 0.7)
        case .soft:          return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        case .bubbleMint:    return .clear   // gradient layer drawn in viewDidLayoutSubviews
        case .retroCream:    return UIColor(red: 0.97, green: 0.94, blue: 0.88, alpha: 1)
        case .vintageGray:   return UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
        case .hotPink:       return .white
        }
    }

    /// Space/backspace/shift key background — varies by theme.
    private var specialKeyBG: UIColor {
        switch currentTheme {
        case .default:       return UIColor(white: 0.90, alpha: 1)
        case .cottonCandy:   return UIColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 1)
        case .lavender:      return UIColor(red: 0.80, green: 0.70, blue: 0.95, alpha: 1)
        case .pastelRainbow: return UIColor(white: 1.0, alpha: 0.5)
        case .soft:          return UIColor(red: 0.97, green: 0.90, blue: 0.93, alpha: 1)
        case .bubbleMint:    return UIColor(red: 0.95, green: 0.85, blue: 0.90, alpha: 1)
        case .retroCream:    return UIColor(red: 0.93, green: 0.88, blue: 0.82, alpha: 1)
        case .vintageGray:   return UIColor(red: 0.80, green: 0.80, blue: 0.80, alpha: 1)
        case .hotPink:       return UIColor(red: 0.97, green: 0.65, blue: 0.73, alpha: 1)
        }
    }

    /// Overall keyboard background — solid color used by non-gradient themes.
    /// `.pastelRainbow` returns `.clear` because a CAGradientLayer handles the fill.
    private var keyboardBg: UIColor {
        switch currentTheme {
        case .default:       return .white
        case .cottonCandy:   return UIColor(red: 0.80, green: 0.95, blue: 0.95, alpha: 1)
        case .lavender:      return UIColor(red: 0.92, green: 0.88, blue: 0.98, alpha: 1)
        case .pastelRainbow: return .clear
        case .soft:          return UIColor(red: 0.92, green: 0.92, blue: 0.94, alpha: 1)
        case .bubbleMint:    return UIColor(red: 0.82, green: 0.95, blue: 0.85, alpha: 1)
        case .retroCream:    return .clear   // gradient layer handles the fill
        case .vintageGray:   return UIColor(white: 0.62, alpha: 1)
        case .hotPink:       return UIColor(white: 0.07, alpha: 1)
        }
    }

    /// Text color for a selected category button. Cotton Candy's accent pink is
    /// light enough that white text fails contrast; all other themes use white.
    private var selectedCatTextColor: UIColor {
        (currentTheme == .cottonCandy || currentTheme == .retroCream) ? .black : .white
    }

    /// Darker foreground color for translate tab arrow + target language label.
    /// Replaces accentColor where the accent is too light to read on pale backgrounds.
    private var translateAccentColor: UIColor {
        switch currentTheme {
        case .default:       return accentColor
        case .cottonCandy:   return UIColor(red: 0.90, green: 0.30, blue: 0.50, alpha: 1)
        case .lavender:      return UIColor(red: 0.55, green: 0.30, blue: 0.85, alpha: 1)
        case .pastelRainbow: return UIColor(red: 0.85, green: 0.35, blue: 0.55, alpha: 1)
        case .soft:          return UIColor(red: 0.85, green: 0.40, blue: 0.55, alpha: 1)
        case .bubbleMint:    return UIColor(red: 0.20, green: 0.65, blue: 0.40, alpha: 1)
        case .retroCream:    return .white
        case .vintageGray:   return UIColor(red: 0.40, green: 0.40, blue: 0.40, alpha: 1)
        case .hotPink:       return UIColor(red: 0.90, green: 0.45, blue: 0.55, alpha: 1)
        }
    }

    /// User-customizable accent color (default = mainPink). Persisted in
    /// UserDefaults. Default theme uses its own key ("accentColor_default") so
    /// switching between Default and other themes never clobbers each other's color.
    private var accentColor: UIColor {
        get {
            let key = currentTheme == .default ? "accentColor_default" : "fonkii_accent_color"
            if let data = UserDefaults.standard.data(forKey: key),
               let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
                return color
            }
            return mainPink
        }
        set {
            let key = currentTheme == .default ? "accentColor_default" : "fonkii_accent_color"
            if let data = try? NSKeyedArchiver.archivedData(
                withRootObject: newValue, requiringSecureCoding: false) {
                UserDefaults.standard.set(data, forKey: key)
            }
            applyTheme()
        }
    }

    private var gradientLayer: CAGradientLayer?

    /// Re-render the keyboard with the current theme + accent color.
    private func applyTheme() {
        applyGradientBackground()
        view.backgroundColor = keyboardBg
        showMode(currentMode)
    }

    private func applyGradientBackground() {
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
        let gl = CAGradientLayer()
        gl.startPoint = CGPoint(x: 0.5, y: 0)
        gl.endPoint   = CGPoint(x: 0.5, y: 1)
        switch currentTheme {
        case .pastelRainbow:
            gl.colors = [
                UIColor(red: 1.0, green: 0.95, blue: 0.80, alpha: 1).cgColor, // 연노랑
                UIColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 1).cgColor, // 연핑크
                UIColor(red: 0.80, green: 0.95, blue: 0.95, alpha: 1).cgColor, // 민트
            ]
            gl.locations = [0.0, 0.5, 1.0]
        case .retroCream:
            gl.colors = [
                UIColor(red: 0.20, green: 0.55, blue: 0.95, alpha: 1).cgColor, // 쨍한 파랑 (top)
                UIColor(red: 0.97, green: 0.94, blue: 0.88, alpha: 1).cgColor, // 아이보리 (bottom)
            ]
            gl.locations = [0.0, 1.0]
        default:
            return
        }
        gl.frame = view.bounds
        view.layer.insertSublayer(gl, at: 0)
        gradientLayer = gl
    }

    private func applyAccentColor() { applyTheme() }
    private var fontCatIndex = 0
    private var fontStyleIndex = 0
    private var selectedFontStyleName: String? = nil
    private var fontPickerExpanded = false
    private weak var fontCategoryRowView: UIView?
    private weak var fontToggleButton: UIButton?
    private weak var fontPickerRowView: UIView?
    private weak var fontPanel: UIView?
    private weak var fontPanelGridScroll: UIScrollView?
    /// Fonts-tab bottom bar height — held strongly so `fontPickerToggleTapped`
    /// can resize it on picker expand/collapse. Reset to nil at the start of
    /// every `buildFontsMode` and re-set when the bottom bar is actually
    /// added (cheonjiin-without-number returns early and leaves it nil).
    private var fontsBottomBarHeightConstraint: NSLayoutConstraint?

    // MARK: - Favorite fonts

    private static let favoriteFontsKey = "favoriteFonts"

    private func loadFavoriteFontNames() -> [String] {
        UserDefaults.standard.stringArray(forKey: Self.favoriteFontsKey) ?? []
    }

    private func saveFavoriteFontNames(_ names: [String]) {
        UserDefaults.standard.set(names, forKey: Self.favoriteFontsKey)
    }

    private func isFavoriteFont(_ name: String) -> Bool {
        loadFavoriteFontNames().contains(name)
    }

    /// Categories actually shown in the UI — prepends a "즐겨찾기" category
    /// holding the user's favorited fonts (if any) in the order saved.
    private let freeFontNames: Set<String> = ["Normal", "Bold", "Italic", "Sans", "Script"]

    /// Hard paywall: free tier gets zero free fonts (all of `freeFontNames`
    /// are premium-only). Flip the ternary to restore the old 5-free-fonts tier.
    private var effectiveFreeFontNames: Set<String> { isPremiumUser ? freeFontNames : [] }

    private func displayFontName(_ style: FontStyleDef) -> String {
        // 특수 변환(closure 기반, 시각적으로 이상해지는 것)은 이름 그대로 표시
        let special: Set<String> = ["Flip", "Cloudy", "Box", "Candy"]
        if special.contains(style.name) { return style.name }
        return style.convert(style.name)
    }

    private func visibleFontCategories() -> [(String, [FontStyleDef])] {
        let favNames = loadFavoriteFontNames()
        guard !favNames.isEmpty else { return allFontCategories }
        // Build a lookup of every FontStyleDef by name.
        var byName: [String: FontStyleDef] = [:]
        for (_, styles) in allFontCategories {
            for s in styles where byName[s.name] == nil { byName[s.name] = s }
        }
        let favDefs = favNames.compactMap { byName[$0] }
        return [(loc("font_cat_favorite"), favDefs)] + allFontCategories
    }
    private var isShifted = false
    private var isCapsLock = false
    private var lastFontShiftTime: Date?
    private var isNumberMode = false
    private var isSymbolPage2 = false
    /// Aa-tab keypad language: false = QWERTY, true = 한글 두벌식.
    /// Number mode (`isNumberMode`) takes precedence over this — when both
    /// would be true the number/symbol pad renders. The 한/영 button on the
    /// bottom bar flips this; switching also forces `isNumberMode = false`
    /// so a tap doesn't land on a stale digit/symbol page.
    private var isFontsKorean = false
    private var savedFontScrollOffset: CGPoint = .zero
    private weak var fontStyleScrollView: UIScrollView?
    private var savedEmoticonCatOffset: CGPoint = .zero
    private weak var emoticonCatScrollView: UIScrollView?
    private var savedSpecialCatOffset: CGPoint = .zero
    private weak var specialCatScrollView: UIScrollView?
    private var savedFandomCatOffset: CGPoint = .zero
    private weak var fandomCatScrollView: UIScrollView?
    private var savedGifCatOffset: CGPoint = .zero
    private weak var gifCatScrollView: UIScrollView?

    // MARK: - Views

    private var mainStack: UIStackView!
    private let modeBar = UIStackView()
    private let contentView = UIView()
    private var letterKeys: [UIButton] = []
    private var vintageGrayKeys: [UIButton] = []

    private var bubbleMintKeys: [UIButton] = []
    /// true while building translate-tab keyboard rows — makeLetterKey skips
    /// bubbleMintKeys.append for translate-tab keys.
    private var isBuildingTranslateLayout = false

    // MARK: - QWERTY Layout

    private let qwertyRows: [[String]] = [
        ["q","w","e","r","t","y","u","i","o","p"],
        ["a","s","d","f","g","h","j","k","l"],
        ["z","x","c","v","b","n","m"]
    ]

    // MARK: - Emoticon Data

    private lazy var emoticonCategories: [(String, [String])] = [
        (loc("kaomoji_happy"), ["(◕‿◕)", "(｡◕‿◕｡)", "ヽ(＾▽＾)ノ", "(★‿★)", "٩(◕‿◕)۶", "(*^▽^*)", "(≧◡≦)", "ヾ(＾∇＾)",
                  "ʕ ᐢ ᵕ ᐢ ʔ", "⌯⦁⩊⦁⌯ಣ", "≽^•༚• ྀི≼", "(՞•-•՞)", "૮₍ •̀ ⩊ •́ ₎ა", "໒꒰ྀི˶•⤙•˶꒱ྀིა",
                  "(๑˃́ꇴ˂̀๑)", "(๑>ᴗ<๑)", "(๑′ᴗ‵๑)", "(๑•᎑<๑)ｰ☆", "(´•᎑•`)♡",
                  "✪‿✪", "꜆₍ᐢ˶•ᴗ•˶ᐢ₎꜆", "( ՞ෆ ෆ՞ )",
                  "ツ", "㋡", "◡̎", "⎝⍥⎠", "( ◡̉̈ )"]),
        (loc("kaomoji_sad"), ["(；﹏；)", "(╥_╥)", "(T_T)", "(つ﹏⊂)", "(っ˘̩╭╮˘̩)っ", "(-_-)zzZ", "(ಥ_ಥ)", "(◞‸◟)",
                  "ʕ ﹷ ᴥ ﹷʔ", ".·°՞(っ-ᯅ-ς)՞°·.", "꒰ ᐢ ◞‸◟ᐢ꒱", "｡°(° ᷄ᯅ ᷅°)°｡",
                  "૮₍´›̥̥̥ ᜊ ‹̥̥̥ `₎ა", "( ˘•∽•˘ )", "໒꒰ ྀི ′̥̥̥ ᵔ ‵̥̥̥ ꒱ྀིა", "(ˊ̥̥̥̥̥ ³ ˋ̥̥̥̥̥)",
                  ".·´¯`(>▂<)´¯`·.", "（ｉДｉ）", "(•̩̩̩̩＿•̩̩̩̩)", "(•́ɞ•̀)",
                  "( •̥ ˍ •̥ )", "( ;ᯅ; )", "(っ◞‸◟c)", "₍ᐡඉ ̫ ඉᐡ₎",
                  "༼ ˃ɷ˂ഃ༽", "⚲_⚲", "(˘•̥-•̥˘)", "(•̥̥̥⌓•̥̥̥)", "⩌ ᯅ ⩌"]),
        (loc("kaomoji_angry"), ["( ᴖ_ᴖ )💢", "ᐡ ᵒ̴ – ᵒ̴ ᐡ💢", "ヽ(｀⌒´メ)ノ",
                  "̿' ̿'\\̵͇̿̿\\з=( ͡ °_̯͡° )=ε/̵͇̿̿/'̿'̿ ̿", "✧ `↼´˵", "ʕ •̀ o •́ ʔ",
                  "¸◕ˇ‸ˇ◕˛", "ʕ •̀ ω •́ ʔ", "(◟‸◞)", "(  '-'  ꐦ)",
                  "(◦`~´◦)", "( ｡ •̀ ⤙ •́ ｡ )", "ʕ•̀⤙•́ ʔ", "૮(•᷄‎ࡇ•᷅ )ა",
                  "( ò_ó)", "(   ꐦ •̀ ⤙ •́ )  =3", "૮(っ `O´  c)ა", "• ︡ᯅ•︠",
                  "/ᐠ •̀ ˕ •́ マ", "ʕ•̀ ω •́ʔ.:",
                  "◠̈"]),
        (loc("kaomoji_animal"), ["(=^･ω･^=)", "ʕ•ᴥ•ʔ", "(◕ᴥ◕)", "=^.^=", "(づ｡◕‿‿◕｡)づ", "ʕ·͡ᴥ·ʔ", "(^・ω・^ )", "≽^•⩊•^≼",
                  "ʕ•ᴥ•.ʔ", "ʕ๑•ﻌ•๑ʔ", "ʕ•͡ɛ•͡ʼʼʔ", "( ⁻(❢)⁻ )", "₍ᐢ•ᴥ•ᐢ₎", "(✦(ᴥ)✦)",
                  "ʕ òᴥó ʔ", "ʕ*•-•ʔฅ", "ʕ•̀д•́ʔﾉ", "/ᐠ ˵• ﻌ •˵マ", "꜀(^｡ ̫ ｡^꜀ )꜆੭",
                  "/.\\___/.\\ <(야옹)", "o(=´∇｀=)o", "/ᐠ - ̫ -マ", "(=･ｪ･=?", "●ᴥ●",
                  "૮₍ ՛◐ ᴥ ◐`₎ʖ", "໒( ̿･ ᴥ ̿･ )ʋ", "ᘳ´• ᴥ •`ᘰ", "૮ ｡ˊᯅˋ ა", "૮₍ •̀ᴥ•́ ₎ა",
                  "૮ ・ﻌ・ა", "ヽ(°ᴥ°)ﾉ", "(ᐡ -.- ᐡ)", "( ੭ ˙🐽˙ )੭", "( ˶˙🐽˙˵ ᐡ )",
                  "(՞•Ꙫ•՞)ﾉ?", "₍ᐢ`🐽´ᐢ₎", "₍՞ • 🐽 • ՞₎", "(´・(oo)・｀)", "𓃟",
                  "(̂•͈Ꙫ•͈⑅)̂ ୭", "₍ᐢ. ֑ .ᐢ₎", "( ᐢ, ,ᐢ)", "⎛⑉・⊝・⑉⎞", "•᷅ ʚ •᷄",
                  "ʚ(•Θ•)ɞ", "୧(•̀ө•́)୨", "(๑•̀ɞ•́๑)✧", "( • ɞ• )", "(・ε・)",
                  "(๑❛ө❛๑ )三", "（ˇ ⊖ˇ）", "( ˙◊˙ )", "( 'Θ')ﾉ", "𓆩(•࿉•)𓆪"]),
        (loc("kaomoji_love"), ["(♥ω♥)", "(づ￣³￣)づ", "( ˘ ³˘)♥", "(っ´▽`)っ♥", "(/^▽^)/♥", "(◍•ᴗ•◍)❤", "♡(˘▽˘>", "(˘⌣˘)♡",
                  "꜀(  ꜆-⩊-)꜆♡", "( ˶'ᵕ'🫶🏻)💕", "(⸝⸝´▽︎ `⸝⸝)", "( ⸝⸝⸝•   •⸝⸝⸝)",
                  "＞ ̫＜ ♡", "(ღˇᴗˇ)", "(๑•́ ₃ •̀๑)", "(●´□`)♡",
                  "( ๑ ❛ ڡ ❛ ๑ )❤", "⸜(♡ ॑ᗜ ॑♡)⸝", "•́ε•̀٥", "( ◜ᴗ◝ )♡",
                  "(ღ•͈ᴗ•͈ღ)♥", "໒( ♥ ◡ ♥ )७", "♡ ᐡ◕ ̫ ◕ᐡ ♡", "♥(〃´૩`〃)♥",
                  "( . ̫ .)💗", "(♡´౪`♡)", "( っ꒪⌓꒪)っ—̳͟͞͞♡", "૮ - ﻌ • ა ♥", "⁎⁍̴̆Ɛ⁍̴̆⁎"]),
        (loc("kaomoji_reaction"), ["(°ロ°)", "Σ(°△°)", "¯\\_(ツ)_/¯", "(-_-;)", "m(_ _)m", "(；一_一)", "╰(*°▽°*)╯", "(・o・)",
                  "･ᴗ･ )੭''", "( *´ᗜ`*)ﾉ", "(๑'• ֊ •'๑)੭", "٩( ´◡` )( ´◡` )۶", "_(._.)_",
                  "( •⍸• )", "c(   'o')っ", "(⊙_⊙)", "( ´o` )", "ᯤ ᯅ ᯤ",
                  "૮₍ •́ ₃•̀₎ა", "ϲ( ´•ϲ̲̃ ̲̃•` )ɔ", "( っ •‌ᜊ•‌ )う", "ˣ‿ˣ", "(๑•́‧̫•̀๑)",
                  "⊙△⊙", "⊙﹏⊙", "ㅇࡇㅇ?", "૮˘･_･˘ა", "( ･̆ω･̆ )",
                  "₍ᐢ - ̫ - ᐢ₎", "( > ~ < )💦", "•́.•̀", "•̆₃•̑", "( ᖛ ̫ ᖛ )",
                  "( • ̀ω•́ )✧", "(๑•̆૩•̆)", "👉🏻(˚ ˃̣̣̥ ▵ ˂̣̣̥ )꒱👈🏻💧", "˙∧˙", "（≩∇≨）",
                  "❛‿˂̵✧", "(  > ᴗ • )", "( ͡~ ͜ʖ ͡°)", "(･ω<)☆", "˶ˊᜊˋ˶ಣ"]),
        (loc("kaomoji_best"), ["ദ്ദിᐢ. .ᐢ₎", "ദ്ദി（• ˕ •マ.ᐟ", "ദ്ദി •⤙• )", "( ദ്ദി ˙ᗜ˙ )",
                  "ჱ̒՞ ̳ᴗ ̫ ᴗ ̳՞꒱", "(՞ •̀֊•́՞)ฅ", "ჱ̒^. ̫ .^）", "ദ്ദി*ˊᗜˋ*)",
                  "( 　'-' )ノദ്ദി)`-' )", "ჱ̒⸝⸝•̀֊•́⸝⸝)", "ദ്ദി  ॑꒳ ॑c)", "ദ്ദിᐢ- ̫-ᐢ₎",
                  "ദ്ദി˙∇˙)ว", "ദ്ദി  ॑꒳ ॑c)", "ദ്ദി（• ˕ •マ.ᐟ", "ദി՞˶ෆ . ෆ˶ ՞",
                  "( ദ്ദി ˙ᗜ˙ )", "👍🏻ᖛ ̫ ᖛ )", "ദ്ദി¯•ω•¯ )", "ദ്ദി•̀.̫•́✧",
                  "ദ്ദി ˘ ͜ʖ ˘)", "ദ്ദി  ͡° ͜ʖ ͡°)", "ദ്ദി❁´◡`❁)",
                  "ദ്ദി * ॑꒳ ॑*)⸝⋆｡✧♡", "ദ്ദി ≽^⎚˕⎚^≼ .ᐟ"]),
        // MARK: - 카오모지 큰 이모티콘 비활성화 (복구 시 주석 해제)
        /*
        ("큰 이모티콘", ["  　 　　 (\\ \\  /)\n　　 　 ( 'ㅅ' )\n 　  (\\ (\\ (\\  /) /) /)\n　   ('ㅅ' ( 'ㅅ' ) 'ㅅ')\n(\\ (\\ (\\ (\\  (\\   /) /) /) /) /)\n('ㅅ' ('ㅅ'  ( 'ㅅ' ) 'ㅅ') 'ㅅ')",
                       "|￣￣￣￣￣￣￣|\n| message\n|＿＿＿＿＿＿＿|\n(\\__/) ||\n(•ㅅ•).||\n/ . . . .づ",
                       "︧︠ᴖ ︨︡\nᖤ • ᴥ • ᖢ > 폼폼푸린",
                       "╭( ･ㅂ･)و ̑̑ 인누와 이짜시가\n╭( ･ㅂ･)ว 딱콩",
                       "(´･ω･`)･ω･`)\n/　　つ⊂　　＼　　내꺼",
                       ".╭◜◝ ͡  ◜◝\n(         ´ㅅ` )\n╰◟◞  ͜     둥실",
                       "｡ﾟﾟ･｡･ﾟﾟ｡\nﾟ。 I Love You\n　ﾟ･｡･",
                       "  (\\ \\     /)\n(´•ᴥ•`)\n૮♡૮ )o\n𝕃𝕠𝕧𝕖 𝕪𝕠𝕦!",
                       "{\\___/}\n( • ㅁ•)\n/ >🐰",
                       "＿人人人人人人人人＿\n＞　　아주좋아！ 　＜\n￣^Y^Y^Y^Y^Y^Y^Y￣",
                       "╭◜◝ ͡ ◜◝╮    몽실   ╭◜◝ ͡ ◜◝╮\n ( •ㅅ•    ) 몽실몽실 (   •ㅅ•  )\n ╰◟◞ ͜ ╭◜◝ ͡ ◜◝╮몽실몽실 ͜ ◟◞╯\n  몽몽실(  •ㅅ•   ) 몽실\n 몽실몽 ╰◟◞ ◟◞╯몽실몽실",
                       "쾅쾅쾅쾅쾅쾅쾅쾅쾅\n쾅쾅　　　　　쾅쾅\n쾅쾅（∩8ㅁ8）쾅쾅\n　＿/_ﾐつ/￣￣￣/\n　　＼/＿＿＿/",
                       "  　　　()♡()\n　　┏┻┻┻┓\n　┏┛★★★┗┓\n　┃♪･*･･*･♪┃\n┏┛　∧⑅⑅∧.　┗┓\n┃☆(๑•ω•๑)..☆┃祝",
                       "  ╭┈┈┈┈╯  ╰┈┈┈╮\n\n ╰┳┳╯   ╰┳┳╯\n\n  💧　    　　💧\n\n 💧  　   　　💧\n    ╰┈┈╯\n 💧╭━━━━━╮　💧\n    ┈┈┈┈\n　　💧     　　💧",
                       " 　　　　｜\n　　／￣￣￣＼\n　／　　∧　　＼\n　│　／川＼　│\n　＼／┏┻┓＼／\n。゛＃┃생┃゛。\n，。┃일┃＃。゛\n。゜＃┃축┃゛。゛\n，＊。┃하┃゜。＃\n＃゜。┃해┃゜＊。\n　　　┃☆┃\n　　　┗┯┛\n　∧∧　│\n　(*´∀`)│\n　　/　⊃",
                       "  \\(•_•)\n((>포기!\n/\\\n\n(•_•)\n<))>했지렁!\n/\\\n\n(•_•)\n<))╯인생!\n/\\\n\n\\(•_•)\n((>포기!\n/\\\n\n(•_•)\n<))>했지렁!\n/\\"]),
        */
    ]
    private var selectedEmoticonCat = 0

    // MARK: - Special Character Data

    private lazy var specialCategories: [(String, [String])] = [
        (loc("special_heart"),  ["♡", "♥", "❥", "❦", "❧", "☙", "▷♡◁", "♡̴", "ꕤ", "ʚ♡ɞ", "﹤𝟹",
                  "۵", "ლ", "ஐ", "(✿◡‿◡)", "♡̷",
                  "ꯁ", "ɞ", "ʚ", "εïз", "♡=͟͟͞͞ ³ ³", "»-♡→", "-\u{0060}♥´-", "-\u{0060}♡´-", "⸜♡⸝\u{200D}", "-ˋˏ ♡ ˎˊ-", "ʚ◡̈ɞ", "₊⁺♡̶₊⁺", "˚ෆ*₊",
                  "♡ᵎᵎᵎ"]),
        (loc("special_star_flower"), ["★", "☆", "✦", "✧", "✿", "❀", "✾", "❁", "✺", "❋", "✹", "✸",
                  "⁂", "✼", "✽", "❃", "❅", "❆", "⋆", "˚", "✶", "✵",
                  "⛤", "✰", "✮", "✪", "✳",
                  "☁ミ✲", "ミ★", "★彡", "☆彡", "✫彡", "ᯓ★", "⋰˚★", "⋰˚✩", "=͟͟͞͞ ͟͟͞͞𖤐", "*･☪·̩͙", "✩⡱", "֎", "☀\u{FE0E}", "☁\u{FE0E}", "☃"]),
        (loc("special_arrow"), ["→", "←", "↑", "↓", "➜", "⇒", "⟶", "⇄", "↔",
                  "↖", "↗", "↘", "↙", "⇐", "⇑", "⇓", "⇔", "⇕", "⇖", "⇗", "⇘", "⇙",
                  "↺", "↻", "⟰", "⟱", "⤴\u{FE0E}", "⤵\u{FE0E}", "↨", "⇅", "⇆",
                  "⇦", "⇧", "⇨", "⇩", "⌦", "⌫", "⇰", "⤶", "⤷", "➲", "⇣", "⇤", "⇥", "↰", "↱", "↲", "↳", "↶", "↷"
        ]),
        (loc("special_deco"),  ["꩜", "⁂", "✳\u{FE0E}", "❊", "✦", "❈", "⁕", "꧁", "꧂", "࿇", "꒰", "꒱",
                  "⌘", "⌥", "⇧", "⌫", "☯\u{FE0E}", "☸\u{FE0E}", "♾\u{FE0E}", "⚜\u{FE0E}",
                  "✡\u{FE0E}", "☪\u{FE0E}",
                  "※", "✥", "✤", "✣", "❖", "ꔛ", "ꕀ", "｡", "･", "∘", "•", "‥", "…",
                  "⌒", "˘", "‿", "⌣", "╰╯", "╭╮", "﹏", "﹋", "﹌", "︵", "︶",
                  "〔", "〕", "【", "】", "《", "》", "〈", "〉", "「", "」", "『", "』",
                  "౨ৎ", "୨୧", "೨౿", "𝝑𝝔", "𓊆", "𓊇"]),
        (loc("special_symbol"), ["©", "®", "™", "°", "%", "&", "@", "#", "$", "€", "£", "¥", "₩", "¢",
                "±", "×", "÷", "≠", "≈", "∞", "√", "π", "∑",
                "♩", "♪", "♫", "♬",
                "☎\u{FE0E}", "✉\u{FE0E}", "✂\u{FE0E}", "✏\u{FE0E}", "✒\u{FE0E}",
                "✄", "✎", "✓", "✔", "✆", "✉", "❛", "❜",
                "⛝", "⦸", "？", "﹖", "⁉", "⁇", "¿"]),
        (loc("special_shape"), ["■", "□", "▪", "▫", "▲", "△", "▶", "▷", "▼", "▽", "◀", "◁",
                "●", "○", "◆", "◇", "◉", "◎", "▣", "▤", "▥", "▦", "▧", "▨",
                "⛶"]),
        (loc("special_hieroglyph"), ["𓁹", "𓂡", "𓂢", "𓂩", "𓂽", "𓂾", "𓃀", "𓃒", "𓃔", "𓃗", "𓃙", "𓃟", "𓃡", "𓃩",
                   "𓃬", "𓃰", "𓃱", "𓃴", "𓃵", "𓃹", "𓃾", "𓄁", "𓄀", "𓄃", "𓄇", "𓅺", "𓅬", "𓆙",
                   "𓆟", "𓇼", "𓇽", "𓈉", "𓊍", "𓊎", "𓍳"]),
        (loc("special_pattern"), ["░", "▒", "▓", "█", "▌", "▐", "▀", "▄", "┼", "╬", "═", "║",
                "╔", "╗", "╚", "╝", "┌", "┐", "└", "┘", "├", "┤", "┬", "┴"]),
        (loc("special_deco_line"), ["════════════════", "────────────────", "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄",
                  "------------------------", "— — — — — — — —", "________________",
                  "················································", "┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈",
                  "·͜·♡·͜·♡·͜·♡·͜·♡·͜·", "ξ 3ξ 3ξ 3ξ 3ξ 3",
                  "≋≋≋≋≋≋≋≋≋≋≋≋≋≋≋≋", "⌇⌇⌇⌇⌇⌇⌇⌇⌇⌇⌇⌇⌇⌇⌇⌇",
                  "▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱", "·.·.·.·.·.·.·.·.·.·.·.·.·.·.·.",
                  "꒰꒰꒰꒰꒰꒰꒰꒰꒰꒰꒰꒰꒰꒰꒰꒰", "✦·········✦·········✦",
                  "┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉", "•·.·•·.·•·.·•·.·•·.·•",
                  "°·.·°·.·°·.·°·.·°·.·°", "﹏﹏﹏﹏﹏﹏﹏﹏﹏﹏﹏﹏", "︶⊹︶︶୨୧︶︶⊹︶︶⊹︶︶୨୧︶︶⊹︶︶⊹︶︶୨୧︶︶⊹︶︶⊹",
                  "⋆｡°✶⋆.༘⋆° ̥✩ ̥°̩̥·.°̩̥˚̩̩̥͙✩.˚｡⋆୨୧⋆｡˚·. ̥✩°̩̥‧̥·̊°ˎˊ✶˚ ༘✩*⋆｡˚⋆",
                  "━━━━━━━ʕ•㉨•ʔ━━━━━━━",
                  "⋆｡ﾟ☁︎｡⋆｡ ﾟ☾ ﾟ｡⋆⋆⁺₊⋆ ☾ ⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ☾ ⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ☾ ⋆⁺₊⋆ ☁︎",
                  "* ੈ♡‧₊˚* · ✧₊♡* ੈ✧‧₊˚* ੈ♡‧₊˚* · ✧₊♡* ੈ✧‧₊˚* ੈ♡‧₊˚* · ✧₊♡* ੈ✧‧₊˚",
                  ".⠈.⠈.⠈.⠈.⠈.⠈.⠈ .⠈.⠈.⠈.⠈.⠈.⠈.⠈..⠈.⠈.⠈.⠈.⠈.⠈.⠈ .⠈.⠈.⠈.⠈.⠈.⠈.⠈..⠈.⠈.⠈.⠈.",
                  "𖢔꙳𖡺𐂂𖡺❅*.𖥧𖥧𖢔꙳𖡺𐂂𖡺❅*.𖥧𖥧𖢔꙳𖡺𐂂𖡺❅*.𖥧𖥧𖢔꙳𖡺𐂂𖡺❅*.𖥧𖥧",
                  "-ˋˏ✄┈┈┈┈┈┈┈┈┈┈┈┈┈",
                  "☹☻☹☻☹☻☹☻☹☻☹☻☹☻☹☻☹☻☹☻☹",
                  "▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀",
                  "ꕀ ꕀ ᐝ ꕀ ꕀꕀ ꕀ ᐝ ꕀ ꕀꕀ ꕀ ᐝ ꕀ ꕀꕀ ꕀ ᐝ ꕀ ꕀ ♡˚✧₊⁎⁺˳✧༚♡˚✧₊⁎⁺˳✧༚♡˚✧₊⁎⁺˳✧༚♡˚✧₊⁎⁺˳♡ ⠂⠁⠈⠂⠄⠄⠂⠁⠁⠂⠄⠄⠂⠁⠁⠂⠂⠁⠈⠂⠄⠄⠂⠁⠁⠂⠄⠄⠂⠁⠁⠂ ♡･･･････♡ ･･･････♡ ･･･････♡ ･･･････♡ ･･･････♡",
                  "♩ ♪ ♫ ♬ ♩ ♪ ♫ ♬ ♩ ♪ ♫ ♬♩ ♪ ♫ ♬ ♩ ♪ ♫ ♬ ♩ ♪ ♫ ♬♩ ♪ ♫ ♬ ♩ ♪ ♫ ♬ ♩ ♪ ♫ ♬",
                  "♡･:* .🫧.: 🐠･:* .🫧.: ･♡:* .🫧.: 💙･:* .🫧.: 💎･♡:* . ･⭐︎:* .🫧.: ･♡:* . ･"]),
    ]
    private var selectedSpecialCat = 0

    /* MARK: - 기존 텍스트 대치 데이터 비활성화 (복구 시 주석 해제)
    // MARK: - Text Templates
    
    private let textTemplates: [(preview: String, full: String)] = [
        ("푸항항 ꉂꉂ(ᵔᗜᵔ*)", "푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*)"),
        ("🎷빠빠빠빠 굿모닝", "🎷🎺🎷🎷🎷🎺빠빠빠빠🎷🎷빠빠빠빠빠🎷🎷🎷🎺굿모닝🎷🎺🎺🎷🎷🎺🎺🎷빠빠빠빠빠🎷🎺🎺🎷🎺빠빠빠빠🎷🎺🎺굿모닝🎷🎺🎷🎺🎷🎷빠빠빠빠빠🎷🎷🎺🎺🎷🎺빠빠빠빠🎷🎷🎺🎷🎷뷰리풀데이🎷🎺🎺🎷🎷🎷빠빠빠빠빠🎷🎷🎺🎷이츠뷰리풀데이🎷🎷🎷🎺🎷🎷🎷🎺딩딩딩🎵🎶🎵굿모닝🎶🎵🎶딩딩딩🎵🎶🎵굿모닝🎶🎵🎶딩딩딩🎵🎶🎵🎷🎺🎷🎷🎷🎺빠빠빠빠🎷🎷빠빠빠빠빠🎷🎷🎷🎺굿모닝"),
        ("🌈아니 뭔 개소리냐고", "🌈💕🌟아니 뭔 개소리냐고💕❤️🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️"),
        ("🏢회사가기 시러요", "회사🏢가기 시러요😵왜 가야하지요🤬?그냥 돈💵주면 안돼요🤭?집🏡에 보내주세요🤪회사🏢가기 시러요😵왜 가야하지요🤬?그냥 돈💵주면 안돼요🤭?집🏡에 보내주세요🤪회사🏢가기 시러요😵왜 가야하지요🤬?그냥 돈💵주면 안돼요🤭?집🏡에 보내주세요🤪회사🏢가기 시러요😵왜 가야하지요🤬?그냥 돈💵주면 안돼요🤭?집🏡에 보내주세요🤪"),
        ("예~ 죄송하게 됐습니다", "예~🙋🏻‍♂️거참 🔥죄송하게🔥 됐습니다💤 🎊사죄의 🔈말씀🔈 드립니다🌟🎉 예~🙋🏻‍♂️거참 🔥죄송하게🔥 됐습니다💤 🎊사죄의 🔈말씀🔈 드립니다🌟🎉 예~🙋🏻‍♂️거참 🔥죄송하게🔥 됐습니다💤 🎊사죄의 🔈말씀🔈 드립니다🌟🎉 예~🙋🏻‍♂️거참 🔥죄송하게🔥 됐습니다💤 🎊사죄의 🔈말씀🔈 드립니다🌟🎉"),
        ("어떡해 너무 귀여워", "어떡해🙊너무💐🌸🌷귀여워🥰❤️ 어떡해🙊너무💐🌸🌷귀여워🥰❤️ 어떡해🙊너무💐🌸🌷귀여워🥰❤️ 어떡해🙊너무💐🌸🌷귀여워🥰❤️ 어떡해🙊너무💐🌸🌷귀여워🥰❤️ 어떡해🙊너무💐🌸🌷귀여워🥰❤️"),
        ("𝙒𝙝𝙮𝙧𝙖𝙣𝙤...", "𝙒𝙝𝙮𝙧𝙖𝙣𝙤... 𝙒𝙝𝙮𝙧𝙖𝙣𝙤... 𝙒𝙝𝙮𝙧𝙖𝙣𝙤... 𝙒𝙝𝙮𝙧𝙖𝙣𝙤... 𝙒𝙝𝙮𝙧𝙖𝙣𝙤... 𝙒𝙝𝙮𝙧𝙖𝙣𝙤..."),
        ("👥수군수군 마이크테스트", "👥👥👥👤👤👥👤👥(수군)👤👥👤👥👤👤👤👥👥👤👤(웅성)👤👥👤👥👤👥(웅성웅성)👤👥👤👥👥👤(수군수군)👤👤👤👥👤👥👤👥👥👥🗣📣아아마이크테스트👥👥👤👥👤👥👤👤(수군수군)👤👥👤👥👥👥👥👤👥👤(쑥덕쑥덕)"),
        ("ヲヲヲヲヲ...", "ヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲ"),
        ("🎺삘릴리 개굴개굴", "삘릴리 🎺개굴개굴 🐸삘릴리 🎺개굴개굴 🐸삘릴리🎺 개굴개굴 🐸삘릴리 🎺개굴개굴 🐸삘릴리 🎺개굴개굴 🐸삘릴리🎺 개굴개굴 🐸삘릴리삘릴리 🎺개굴개굴 🐸삘릴리 🎺개굴개굴 🐸삘릴리🎺 개굴개굴 🐸"),
        ("힘들 때 빗속에서 힙합", "난 힘들 때 빗속에서 힙합을 춰...｀、、｀ヽ｀ヽ｀、、ヽヽ、｀、ヽ｀ヽ｀ヽヽ｀ヽ｀、｀ヽ｀、ヽ｀｀、ヽ｀ヽ｀、ヽヽ｀ヽ、ヽ｀ヽ、ヽヽ｀ヽ｀、｀｀ヽ｀ヽ、ヽ、ヽ｀ヽ｀ヽ、ヽ｀ヽ｀、ヽヽ｀｀、ヽ｀、ヽヽ ዽ ヽ｀｀"),
        ("🚨긴급상황 발생", "🚨🚨🚨🚨🚨🚨애애애애앵‼️‼️‼️‼️‼️‼️🚨🚨🚨🚨🚨🚨📢📢📢📢📢📢📢긴급상황‼️‼️‼️긴급상황‼️‼️‼️‼️‼️📢📢📢📢📢📢📢🔊🔊🔊🔊🔊🔊 발생‼️‼️‼️🔊🔊🔊🔊🔊🔊🔊🔊🔊🔥🔥🔥🔥🔥🔥🔥"),
        ("끟ㅂ,,끄릅흡ㅁ😭", "끟ㅂ,,끄릅흡ㅁ끟ㅂ,,끄릅흡ㅁ😭 끟ㅂ,,끄릅흡ㅁ😭끟ㅂ,,끄릅흡ㅁ😭 끟ㅂ,,끄릅흡ㅁ😭끟ㅂ,,끄릅흡ㅁ😭 끟ㅂ,,끄릅흡ㅁ😭끟ㅂ,,끄릅흡ㅁ😭 끟ㅂ,,끄릅흡ㅁ😭끟ㅂ,,끄릅흡ㅁ😭 끟ㅂ,,끄릅흡ㅁ😭끟ㅂ,,끄릅흡ㅁ😭"),
        ("아 귀엽다 너무 귀여운데", "아 귀엽다 .. 너무 귀여운데 ? 아 귀여워 .. 귀엽다 .. 너무 귀여운데 ? 아 귀여워 .. 아 귀여워 .. 귀엽다 .. 너무 귀여운데 ? 아 귀여워 .. 귀엽다 .. 너무 귀여운데 ? 아 귀여워 .. 아 귀여워 .. 귀엽다 .. 너무 귀여운데 ? 아 귀여워 .. 귀엽다 .. 너무 귀여운데 ? 아 귀여워 .."),
        ("🌸나는 귀여우니깐 다괜찮아", "나는🌸귀여우니깐🌟다괜찮아🍬🍩 나는🌸귀여우니깐🌟다괜찮아🍬🍩 나는🌸귀여우니깐🌟다괜찮아🍬🍩 나는🌸귀여우니깐🌟다괜찮아🍬🍩 나는🌸귀여우니깐🌟다괜찮아🍬🍩 나는🌸귀여우니깐🌟다괜찮아🍬🍩"),
        ("냬~알걨섑니댸~", "(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~"),
        ("🐜개미는 오늘도 열심히", "개미는(뚠뚠)🐜🐜오늘도(뚠뚠)🐜🐜열심히 일을 하네(뚠뚠)🐜🐜개미는(뚠뚠)🐜🐜언제나(뚠뚠)🐜🐜열심히일을하네(뚠뚠)🐜🐜개미는아무말도하지않지만(띵가띵가)🐜🐜땀을뻘뻘흘리면서(띵가띵가)🐜🐜매일매일을살기위해서열심히일하네(띵가띵가)🐜🐜"),
        ("이얏호! 신난다💃", "이얏호! 신난다💃🕺 훌라😉훌라💨 허리를👯‍♂️ 돌려~🤹\u{200d}♀️ 이얏호! 신난다💃🕺 훌라😉훌라💨 허리를👯‍♂️ 돌려~🤹\u{200d}♀️ 이얏호! 신난다💃🕺 훌라😉훌라💨 허리를👯‍♂️ 돌려~🤹\u{200d}♀️ 이얏호! 신난다💃🕺 훌라😉훌라💨 허리를👯‍♂️ 돌려~🤹\u{200d}♀️"),
        ("👄말하기 전에 생각했나요", "말하기👄💬 전에 생각🤔💭 했나요❓ 말하기👄💬 전에 생각🤔💭 했나요❓ 말하기👄💬 전에 생각🤔💭 했나요❓ 말하기👄💬 전에 생각🤔💭 했나요❓ 말하기👄💬 전에 생각🤔💭 했나요❓ 말하기👄💬 전에 생각🤔💭 했나요❓ 말하기👄💬 전에 생각🤔💭 했나요❓"),
        ("ヽ｀비가 와ヽ｀ヽ｀", "ヽ｀、、ヽ｀ヽ｀、ヽ｀、ヽ｀｀｀、ヽ｀｀、ヽ｀、ヽ｀ヽ｀、、ヽ｀ヽ｀、ヽ｀、ヽ｀｀、ヽ｀비가 와、ヽ｀ヽ｀、、ヽ｀ヽ｀、ヽ｀、ヽ｀｀、ヽ｀、ヽ｀ヽ｀、、ヽ｀ヽ｀、ヽ(ノ；Д；)ノ ｀、、ヽ｀ヽ｀、ヽ｀｀、ヽ｀、ヽ｀ヽ｀｀、ヽ｀｀、、ヽ｀ヽ｀、、ヽ｀ヽ｀、｀、ヽ｀｀、ヽ｀、ヽ｀｀、、ヽ｀ヽヽ｀、ヽ｀｀、ヽ｀、ヽ｀ヽ｀、、ヽ｀ヽ"),
        ("엉엉 꺼이꺼이", "엉엉༼;´༎ຶ ۝ ༎ຶ༽༼;´༎ຶ ۝ ༎ຶ༽༼;´༎ຶ ۝ ༎ຶ༽( o̴̶̷̥᷅⌓o̴̶̷᷄ ) ( o̴̶̷̥᷅⌓o̴̶̷᷄ ) ( o̴̶̷̥᷅⌓o̴̶̷᷄ ) 허엉엉으엉엉엉 갸아앙ㅇ헝헝흐앙앙༼ ˃ɷ˂ഃ༽༼ ˃ɷ˂ഃ༽엉엉흐엉어허어엉ㅇ어ㅠㅓ허허허휴ㅠㅠㅠㅠㅎ어어유ㅠㅠㅠㅠ파하규ㅠㅠㅠ༼;´༎ຶ ۝ ༎ຶ༽༼;´༎ຶ ۝ ༎ຶ༽꺼이꺼이"),
        ("오잉⍤⃝오잉⍤⃝", "오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝"),
        ("죄송한 마음을 담아 ❤️", "죄송한 마음을 담아 ❤️ 작곡 작사를 해 보았어요 💕 정말 죄송합니다 😉 예쁘게 들어 주세요 💖 쏘리 쏘리 암 쏘리 🎵 내가 미안해 🎙🎙 한번만 봐줘! 😘 이쁘게 봐줘잉~ 😍 돌아와줘! ❣️ 사랑해줘~~ 🎤🎶🎶🎵 죄송한 마음을 담아 ❤️ 작곡 작사를 해 보았어요 💕 정말 죄송합니다 😉 예쁘게 들어 주세요 💖 쏘리 쏘리 암 쏘리 🎵 내가 미안해 🎙🎙 한번만 봐줘! 😘 이쁘게 봐줘잉~ 😍 돌아와줘! ❣️ 사랑해줘~~ 🎤🎶🎶🎵 죄송한 마음을 담아 ❤️ 작곡 작사를 해 보았어요 💕 정말 죄송합니다 😉 예쁘게 들어 주세요 💖 쏘리 쏘리 암 쏘리 🎵 내가 미안해 🎙🎙 한번만 봐줘!"),
        ("㉪㉻ 반복", "㉪㉻㉪㉻㉪㉻㉪㉻㉪㉻㉪㉻㉪㉻㉪㉻"),
        ("𐌅𐨛 𐌅𐨛", "𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛"),
        ("으이구 인간아", " 으이구 인간아 ᕙ( ︡\'︡益\'︠)ง 으이구 인간아 ᕙ( ︡\'︡益\'︠)ง  으이구 인간아 ᕙ( ︡\'︡益\'︠)ง 으이구 인간아 ᕙ( ︡\'︡益\'︠)ง  으이구 인간아 ᕙ( ︡\'︡益\'︠)ง 으이구 인간아 ᕙ( ︡\'︡益\'︠)ง"),
        ("일어난💤🛎⏰사람👥멘션💬남겨라🕰⏱💨", "일어난💤🛎⏰사람👥멘션💬남겨라🕰⏱💨일어난💤🛎⏰사람👥멘션💬남겨라🕰⏱💨일어난💤🛎⏰사람👥멘션💬남겨라🕰⏱💨일어난💤🛎⏰사람👥멘션💬남겨라🕰⏱💨일어난💤🛎⏰사람👥멘션💬남겨라🕰⏱💨일어난💤🛎⏰사람👥멘션💬남겨라🕰⏱💨일어난💤🛎⏰사람👥멘션💬남겨라🕰⏱💨"),
        ("⚡️⏰⚡️⏰⚡️⏰⚡️⏰⚡️다들 기상!!!!!", "⚡️⏰⚡️⏰⚡️⏰⚡️⏰⚡️다들 기상!!!!! ⏰⚡️⏰⚡️⏰⚡️⏰⚡️⏰⚡️⏰⚡️ ⏰⚡️⏰⚡️⏰⚡️⏰⚡️⏰⚡️⏰⚡️ 🔊 빠빠빠😄- 빠-? 빠 ?빠빠빠빠?‼- 🌝굿모닝🌞 빠빠빠 🕒🕞🕓🕗🕖빠 빠 🕘🕗🕚🕥🕦빠빠🕖🕢🕚🕥🕞빠빠 굿모닝💮🎉📞📣빠빠빠 빠 🕗🕞🕞빠 🕖🕢🕟🕓빠🕖🕖🕗빠빠 뷰티풀↗📣데이 ?~~~빠빠빠 빠 잇쳐 ?뷰티풀📣🌈데이🌌‼‼?⁉ 🔂🔂🔂🔂🔂🔂🔂🔂🔂🔂🔂 딩🔔🔔🔔🔔🔔딩🔔🔔딩🔔🔔🔔🔊🌞👍🔊 빠빠빠😄- 빠-? 빠 ?빠빠빠빠?‼- 🌝굿모닝🌞 빠빠빠 🕒🕞🕓🕗🕖빠 빠 🕘🕗🕚🕥🕦빠빠🕖🕢🕚🕥🕞빠빠 굿모닝 🔔🔔🔔🔔딩🔔🔔딩🔔🔔🔔🔊🔊 빠빠빠😄- 빠-? 빠 ?빠빠빠빠?‼- 🌝굿모닝🌞 빠빠빠 🕒🕞🕓🕗🕖빠 빠 🕘🕗🕚🕥🕦빠빠🕖🕢🕚🕥🕞빠빠 굿모닝💮🎉📞📣빠빠빠 빠 🕗🕞🕞빠 🕖🕢🕟🕓빠🕖🕖🕗빠빠 뷰티풀↗📣데이 ?~~~빠빠빠 빠 잇쳐 ?뷰티풀📣🌈데이🌌‼‼?⁉"),
        ("😫췌엣끼!!!🤧 아 쫌💢재채기 참아요~❗️", "😫췌엣끼!!!🤧 아 쫌💢재채기 참아요~❗️ 죄쫑해여😞... 😫췌엣끼!!!🤧 아 쫌💢재채기 참아요~❗️ 죄쫑해여😞... 😫췌엣끼!!!🤧 아 쫌💢재채기 참아요~❗️ 죄쫑해여😞... 😫췌엣끼!!!🤧 아 쫌💢재채기 참아요~❗️ 죄쫑해여😞..."),
        ("강조되고 반복되는 소리는🎙강아지를🐶", "강조되고 반복되는 소리는🎙강아지를🐶 불안하게 해요‼️〰️ 🤷‍♀️네? 다시요. 🙅‍♂️ 강조되고 반복되는 소리는 강아지를 불~안하게 한다구욧🙅‍♂️ 🤷‍♀️그럼 잘했다고 하지 말라구여? 💁‍♂️네에!! 아니요!!! (짝짝짝) 이렇게는 좋은게 아니에요⤴️~!!! 🤷‍♀️ 오...진짜?? 🤷‍♂️네에~!!!! 🐶 왈왈왈 🤷‍♀️ 허허허 이런소리 싫어해요 🤷‍♂️네에~!!!! 맞아요!! 그런소리를 하고있어요! 🐶ㅡㅡ왈왈왈 🤷‍♂️어어~~~그래그래 미키미키 💁‍♂️ 일로와 🙋‍♂️ 어이! 🙋‍♂️어잇 🙋‍♂️ 어잇 (짝짝) 🙋‍♂️ 어잇!!!! (짝짝) 🙋‍♂️ 어잇 🤸‍♀️ 미키 🤸"),
        ("🏫 야, 교수... 🤢 니가 그러케 👊 잘낫어", "🏫 야, 교수... 🤢 니가 그러케 👊 잘낫어,,,? 👿👿 니가 그러케 👊 공부 📖 잘해,,,? 👿👿 니가 그러케 👊 논문 ✏️ 잘써,,,? 👿👿 니가 그러케 👊 아는 게 🦀 만아,,,? 👿👿 🏫 야, 교수... 🤢 니가 그러케 👊 잘낫어,,,? 👿👿 니가 그러케 👊 공부 📖 잘해,,,? 👿👿 니가 그러케 👊 논문 ✏️ 잘써,,,? 👿👿 니가 그러케 👊 아는 게 🦀 만아,,,? 👿👿 🏫 야, 교수... 🤢 니가 그러케 👊 잘낫어,,,? 👿👿 니가 그러케 👊 공부 📖 잘해,,,? 👿👿 니가 그러케 👊 논문 ✏️ 잘써,,,? 👿👿 니가 그러케 👊 아는 게 🦀 만아,,,? 👿👿"),
        ("응~👌🏻 어쩔티비~ 📺💁🏻‍♂️ 저쩔티비~📺", "응~👌🏻 어쩔티비~ 📺💁🏻‍♂️ 저쩔티비~📺 💁🏻‍♀️ 안물티비~안궁티비~뇌절티비~우짤래미~ 저짤래미~ 쿠쿠루삥뽕🕺🏻 지금 화났죠?🔥😛 개킹받죠? 죽이고 싶죠? 🤗어차피 내가 사는곳 모르죠? 응~못 죽이죠?👊🏻🤟🏻 어~또 빡치죠? 😌아무것도 모르죠? 아무것도 못하죠?😉 그냥 화났죠? 냬~알걨섑니댸👏🏻🙃🙃 아무도 안물 안궁~🤣 물어본 사람?🙋🏻‍♀️ 궁금한 사람?🙋🏻‍♂️ 응 근데 어쩔티비죠? 약올리죠? 응~ 어쩔 저쩔 안물 안궁😚✌🏻"),
        ("뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓", "뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓ 뭐해욤❓"),
        ("우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮", "우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍...🤢 구웨에에엑🤮 우읍.."),
        ("수류탄이다!!! ( ˙ ∇˙)づ ⌒ (툭) 펑҉!҉", "수류탄이다!!! ( ˙ ∇˙)づ ⌒ (툭) 펑҉!҉ 펑҉퍼҉엉҉퍼҉어҉어҉퍼҉҉퍼҉엉҉퍼҉엉҉!҉!҉펑펑"),
        ("༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!!", "༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!!,༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!! ,༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!!,༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!! ,༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!!,༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!! ,༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!! ,༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!! ,༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!! ,༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!! ,༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!! ,༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!! ,༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!! ,༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!! ,༼;´༎ຶ۝༎ຶ༽우워어어어어엌!!!!!!!"),
        ("어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ", "어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ 어엥? ఠࡇఠ"),
        ("레전드다 .. ٩(╹⌓╹ )۶ 레전드가 나타났다 !!", "레전드다 .. ٩(╹⌓╹ )۶ 레전드가 나타났다 !! (● ˃̶̀ロ˂̶́)੭⁾⁾ 레전드다 .. ٩(╹⌓╹ )۶ 레전드가 나타났다 !! (● ˃̶̀ロ˂̶́)੭⁾⁾ 레전드다 .. ٩(╹⌓╹ )۶ 레전드가 나타났다 !! (● ˃̶̀ロ˂̶́)੭⁾⁾ 레전드다 .. ٩(╹⌓╹ )۶ 레전드가 나타났다 !! (● ˃̶̀ロ˂̶́)੭⁾⁾ 레전드다 .. ٩(╹⌓╹ )۶ 레전드가 나타났다 !! (● ˃̶̀ロ˂̶́)੭⁾⁾ 레전드다 .. ٩(╹⌓╹ )۶ 레전드가 나타났다 !! (● ˃̶̀ロ˂̶́)੭⁾⁾ 레전드다 .. ٩(╹⌓╹ )۶ 레전드가 나타났다 !! (● ˃̶̀ロ˂̶́)੭⁾⁾ 레전드다 .. ٩(╹⌓╹ )۶ 레전드가 나타났다 !!"),
        ("우리오파(于里烏播)개귀여어(凱歸蠡魚)", "우리오파(于里烏播)개귀여어(凱歸蠡魚)개예부다(凱叡部多)하고풍거(河鼓風去) 삭다해라(削多海蘿) 신의미모(神義美貌) 세상간지(世上間地) 매일이론(每日理論) 덕후마음(德厚馬音) 우리액희(于里液喜) 개귀여어(凱歸蠡魚) 하고풍거(河鼓風去) 삭다해라(削多海蘿) 매일이론(每日理論) 덕후마음(德厚馬音) 주접이라(主楪伊亽) 할지라도(轄地羅道) 내가알게(來駕謁揭) 모야시발(暮夜始發) 좌로인정(左虜人正) 우로인정(右虜人正) 압구루기(狎鷗漏器) 대굴대굴(大窟大窟)"),
        ("(ง˙∇˙)ง 덤벼! (ง˙∇˙)ง 덤비라규!", "(ง˙∇˙)ง 덤벼! (ง˙∇˙)ง 덤비라규! (ง˙∇˙)ว 퍽! 아 (ง˙∇˙)ง 덤벼! (ง˙∇˙)ง(ง˙∇˙)ง 덤벼! (ง˙∇˙)ง 덤비라규! (ง˙∇˙)ว 퍽! 아 (ง˙∇˙)ง 덤벼! (ง˙∇˙)ง(ง˙∇˙)ง 덤벼! (ง˙∇˙)ง 덤비라규! (ง˙∇˙)ว 퍽! 아 (ง˙∇˙)ง 덤벼! (ง˙∇˙)ง(ง˙∇˙)ง 덤벼! (ง˙∇˙)ง 덤비라규! (ง˙∇˙)ว 퍽! 아 (ง˙∇˙)ง 덤벼! (ง˙∇˙)ง"),
        ("1. 왜 그런 말을 했는지 1-1 어떠한 경위로", "1. 왜 그런 말을 했는지 1-1 어떠한 경위로 그런 말을 했는지 1-2 왜 그런 단어 선택을 했는지 1-3 평소에 그런 말을 자주 하는지 2. 그 말을 할 때 어떤 생각을 했는지 2-1 평소에 생각을 자주 하는 편인지 2-2 그 말을 떠올리면 어떤 생각이 드는지 2-3 말하기 전에 생각 했는지 3. 앞으로 어떻게 할 건지 3-1 어떤 생각을 가지고 살 건지 3-2 피해 보상은 생각해봤는지 3-3 보상을 한다면 어떤 방법으로 할건지 4. 최종 의견 4-1 최종적으로 어떤 생각을 하게 됐는지 4-2 앞으로 어떻게 할 건지")
    ]
    */

    // MARK: - Fandom Preset Data

    private struct FandomItem {
        let label: String       // button display text (English fallback)
        let output: String      // text inserted on tap
        var labelKey: String?   // localization key for display text (KO section only)
    }
    private struct FandomSection {
        let title: String
        let titleKey: String?
        let items: [FandomItem]
        init(title: String, titleKey: String? = nil, items: [FandomItem]) {
            self.title = title
            self.titleKey = titleKey
            self.items = items
        }
    }
    private struct FandomCategory {
        let title: String
        let sections: [FandomSection]
    }

    private let fandomCategories: [FandomCategory] = [
        FandomCategory(title: "MyList", sections: []),   // My List — no preset sections, custom phrases only
        FandomCategory(title: "Quick", sections: [
            FandomSection(title: "EN", items: [
                FandomItem(label: "On My Way",    output: _oc("On my way! 🏃", 0x1D5D4, 0x1D5EE, 0x1D7EC)),                         // Bold
                FandomItem(label: "BRB",          output: _oc("Be right back ✌️", 0x1D670, 0x1D68A, 0x1D7F6)),                      // Typewriter
                FandomItem(label: "Miss You",     output: _oc("Miss you already 🥺", 0x1D4D0, 0x1D4EA, nil)),                       // Bold Script
                FandomItem(label: "Let Me Know",  output: _oc("Let me know! 😊", 0x1D608, 0x1D622, nil)),                           // Sans Italic
                FandomItem(label: "Sounds Good",  output: _oc("Sounds good 👍", 0x1D63C, 0x1D656, nil)),                            // Heavy
                FandomItem(label: "Take Care",    output: _cm("Take care 🌸", _slightlyCursiveMap)),                                 // Cursive
                FandomItem(label: "Good Luck",    output: _cm("Good luck! 🍀", _alienMap)),                                    // Comic
                FandomItem(label: "Text Later",   output: _oc("I'll text you later 💬", 0x1D5A0, 0x1D5BA, 0x1D7E2)),               // Sans
                FandomItem(label: "OMG",          output: _oc("OMG 😭", 0x1D468, 0x1D482, 0x1D7CE)),                               // Bold Italic
                FandomItem(label: "Haha",         output: _oc("Haha 😂", 0x24B6, 0x24D0, nil)),                                     // Bubble
                FandomItem(label: "Same",         output: _oc("Same", 0x1D608, 0x1D622, nil)),                                      // Sans Italic
                FandomItem(label: "No Way",       output: _oc("No way!!", 0x1D5D4, 0x1D5EE, 0x1D7EC)),                             // Bold
                FandomItem(label: "For Real",     output: _oc("For real tho", 0x1D434, 0x1D44E, nil, _itX)),                        // Italic
                FandomItem(label: "Later",        output: _oc("Talk later! 👋", 0xFF21, 0xFF41, 0xFF10)),                           // Wide
                FandomItem(label: "Thank You",    output: _oc("Thank you so much 🙏", 0x1D49C, 0x1D4B6, nil, _scX)),               // Script
                FandomItem(label: "Sorry",        output: _cc("Sorry for the late reply 😅", "\u{0308}")),                          // Sad
                FandomItem(label: "Congrats",     output: _oc("Congrats!! 🎉", 0x1D538, 0x1D552, 0x1D7D8, _dbX)),                  // Outline
                FandomItem(label: "Love That",    output: _oc("Love that for you ✨", 0x1D4D0, 0x1D4EA, nil)),                      // Bold Script
            ]),
            FandomSection(title: "KO", items: [
                FandomItem(label: "On My Way",    output: "지금 가는 중! 🏃",      labelKey: "quick_on_way"),
                FandomItem(label: "BRB",          output: "잠깐만 기다려 ✌️",      labelKey: "quick_brb"),
                FandomItem(label: "Miss You",     output: "벌써 보고싶다 🥺",      labelKey: "quick_miss"),
                FandomItem(label: "Let Me Know",  output: "알려줘! 😊",            labelKey: "quick_let_know"),
                FandomItem(label: "Sounds Good",  output: "좋아 👍",               labelKey: "quick_sounds_good"),
                FandomItem(label: "Take Care",    output: "건강 챙겨 🌸",          labelKey: "quick_take_care"),
                FandomItem(label: "Good Luck",    output: "파이팅! 🍀",            labelKey: "quick_good_luck"),
                FandomItem(label: "Text Later",   output: "나중에 연락할게 💬",    labelKey: "quick_text_later"),
                FandomItem(label: "OMG",          output: "헐 😭",             labelKey: "quick_omg"),
                FandomItem(label: "Same",         output: "나도",              labelKey: "quick_same"),
                FandomItem(label: "No Way",       output: "말도 안돼!!",       labelKey: "quick_no_way"),
                FandomItem(label: "For Real",     output: "진짜로?",           labelKey: "quick_for_real"),
                FandomItem(label: "Later",        output: "이따 봐! 👋",       labelKey: "quick_later"),
                FandomItem(label: "Thank You",    output: "고마워 진짜 🙏",   labelKey: "quick_thank_you"),
                FandomItem(label: "Sorry",        output: "늦게 봤어 미안 😅", labelKey: "quick_sorry"),
                FandomItem(label: "Congrats",     output: "축하해!! 🎉",       labelKey: "quick_congrats"),
                FandomItem(label: "Love That",    output: "너무 좋다 ✨",      labelKey: "quick_love_that"),
            ]),
        ]),
        FandomCategory(title: "Daily", sections: [
            FandomSection(title: "EN", items: [
                FandomItem(label: "Good Morning",    output: _oc("Good morning! ☀️", 0x1D5A0, 0x1D5BA, 0x1D7E2)),                              // Sans
                FandomItem(label: "Morning",         output: _oc("Morning ☀️", 0xFF21, 0xFF41, 0xFF10)),                                       // Wide
                FandomItem(label: "Great Day",       output: _oc("Hope you have a great day.", 0x1D538, 0x1D552, 0x1D7D8, _dbX)),              // Outline
                FandomItem(label: "Doing Well",      output: _oc("Hope you're doing well.", 0x1D434, 0x1D44E, nil, _itX)),                     // Italic
                FandomItem(label: "Going Well",      output: _oc("Hope everything's going well!", 0x1D434, 0x1D44E, nil, _itX)),               // Italic
                FandomItem(label: "Slept Well",      output: _cm("Hope you slept well!", _slightlyCursiveMap)),                                // Cursive
                FandomItem(label: "What's Up",       output: _oc("Hey! What's up?", 0x1D608, 0x1D622, nil)),                                  // Sans Italic
                FandomItem(label: "Heyyy",           output: _oc("Heyyy", 0x24B6, 0x24D0, nil)),                                              // Bubble
                FandomItem(label: "Day Going",       output: _oc("How's your day going?", 0x1D608, 0x1D622, nil)),                            // Sans Italic
                FandomItem(label: "How've You Been", output: _oc("How have you been?", 0x1D49C, 0x1D4B6, nil, _scX)),                         // Script
                FandomItem(label: "Up To",           output: _oc("What are you up to?", 0x1D608, 0x1D622, nil)),                              // Sans Italic
                FandomItem(label: "Wyd",             output: _oc("Wyd?", 0x1D5D4, 0x1D5EE, 0x1D7EC)),                                        // Bold
                FandomItem(label: "Been Busy",       output: _oc("Been busy lately?", 0x1D434, 0x1D44E, nil, _itX)),                          // Italic
                FandomItem(label: "Checking In",     output: _oc("Just checking in.", 0x1D670, 0x1D68A, 0x1D7F6)),                            // Typewriter
                FandomItem(label: "You Good",        output: _oc("You good?", 0x1D468, 0x1D482, 0x1D7CE)),                                 // Bold Italic
                FandomItem(label: "Glad",            output: _cm("Glad to hear that.", _slightlyCursiveMap)),                                  // Cursive
                FandomItem(label: "Sounds Good",     output: _oc("Sounds good!", 0x1D5D4, 0x1D5EE, 0x1D7EC)),                                // Bold
                FandomItem(label: "Makes Sense",     output: _oc("That makes sense.", 0x1D5A0, 0x1D5BA, 0x1D7E2)),                            // Sans
                FandomItem(label: "I Get You",       output: _oc("I get you.", 0x1D434, 0x1D44E, nil, _itX)),                                 // Italic
                FandomItem(label: "No Worries",      output: _oc("No worries!", 0x24B6, 0x24D0, nil)),                                        // Bubble
                FandomItem(label: "Take Time",       output: _cm("Take your time!", _slightlyCursiveMap)),                                     // Cursive
                FandomItem(label: "Text Free",       output: _oc("Text me when you're free.", 0x1D608, 0x1D622, nil)),                         // Sans Italic
                FandomItem(label: "Talk Soon",       output: _oc("Talk to you soon.", 0x1D49C, 0x1D4B6, nil, _scX)),                          // Script
                FandomItem(label: "Catch Later",     output: _oc("Catch you later!", 0x1D608, 0x1D622, nil)),                                 // Sans Italic
                FandomItem(label: "Good One",        output: _oc("Have a good one!", 0x1D4D0, 0x1D4EA, nil)),                                 // Bold Script
                FandomItem(label: "Stay Safe",       output: _cm("Stay safe!", _slightlyCursiveMap)),                                          // Cursive
                FandomItem(label: "Take Care",       output: _oc("Take care!", 0x1D49C, 0x1D4B6, nil, _scX)),                                 // Script
                FandomItem(label: "Sweet Dreams",    output: _oc("Sweet dreams ✨", 0x1D4D0, 0x1D4EA, nil)),                                  // Bold Script
                FandomItem(label: "Good Night",      output: _oc("Good night! 🌙", 0x1D4D0, 0x1D4EA, nil)),                                   // Bold Script
                FandomItem(label: "Just Saw",        output: _oc("Sorry, just saw this!", 0x1D670, 0x1D68A, 0x1D7F6)),                        // Typewriter
                FandomItem(label: "Almost There",    output: _oc("Almost there. I'll text you when I get there.", 0x1D5A0, 0x1D5BA, 0x1D7E2)),// Sans
                FandomItem(label: "On My Way",       output: _oc("On my way!", 0x1D5D4, 0x1D5EE, 0x1D7EC)),                                   // Bold
                FandomItem(label: "Home",            output: _oc("Finally home 🫠", 0x1D670, 0x1D68A, 0x1D7F6)),                              // Typewriter
                FandomItem(label: "Tired",           output: _cc("I'm so tired lol", "\u{0308}")),                                             // Sad
                FandomItem(label: "Don't Overwork",  output: _cm("Don't work too hard 😭", _slightlyCursiveMap)),                              // Cursive
                FandomItem(label: "Eaten",           output: _oc("Did you eat yet?", 0x1D5A0, 0x1D5BA, 0x1D7E2)),                             // Sans
                FandomItem(label: "Miss You",        output: _oc("Miss you already.", 0x1D4D0, 0x1D4EA, nil)),                                // Bold Script
            ]),
            FandomSection(title: "KO", items: [
                FandomItem(label: "Good Morning",   output: "좋은 아침! ☀️",                      labelKey: "daily_good_morning"),
                FandomItem(label: "Great Day",      output: "오늘 하루도 잘 보내! ✨",             labelKey: "daily_great_day"),
                FandomItem(label: "What Doing",     output: "뭐해?",                               labelKey: "daily_what_doing"),
                FandomItem(label: "Weather",        output: "오늘 날씨 너무 좋다!!",               labelKey: "daily_weather"),
                FandomItem(label: "Ate",            output: "밥은 먹었어?",                        labelKey: "daily_ate"),
                FandomItem(label: "Fighting",       output: "오늘도 화이팅 🔥",                    labelKey: "daily_fighting"),
                FandomItem(label: "Tired",          output: "오늘 왜 이렇게 피곤하지",             labelKey: "daily_tired"),
                FandomItem(label: "Busy",           output: "나 오늘 너무 정신없다",               labelKey: "daily_busy"),
                FandomItem(label: "Going Home",     output: "나 지금 집 가는 중~🏃‍➡️",              labelKey: "daily_going_home"),
                FandomItem(label: "Text Home",      output: "이따가 집 가서 연락할게!",             labelKey: "daily_text_home"),
                FandomItem(label: "Safe Home",      output: "조심히 들어가! 도착하면 톡해~",       labelKey: "daily_safe_home"),
                FandomItem(label: "Arrived",        output: "집 도착했어?",                        labelKey: "daily_arrived"),
                FandomItem(label: "Rest",           output: "푹 쉬어!",                            labelKey: "daily_rest"),
                FandomItem(label: "No Overwork",    output: "너무 무리하지 마!",                   labelKey: "daily_dont_overwork"),
                FandomItem(label: "Hard Work",      output: "오늘도 고생 많았어 🥺",               labelKey: "daily_hard_work"),
                FandomItem(label: "Good Night",     output: "잘 자! 좋은 꿈 꿔 🌙",               labelKey: "daily_good_night"),
                FandomItem(label: "Weekend",        output: "주말 잘 보내 ☀️",                     labelKey: "daily_weekend"),
                FandomItem(label: "Bored",          output: "심심해 ㅠㅠ",                         labelKey: "daily_bored"),
                FandomItem(label: "Daebak",         output: "헐 대박ㅋㅋㅋㅋㅋ",                  labelKey: "daily_daebak"),
                FandomItem(label: "Agree",          output: "ㅇㅈ",                                labelKey: "daily_agree"),
                FandomItem(label: "Miss",           output: "보고싶어 🥺",                         labelKey: "daily_miss"),
            ]),
        ]),
        FandomCategory(title: "Cheer", sections: [
            /* 기존 Cheer EN 데이터 보존 (복구 시 주석 해제)
            FandomSection(title: "EN", items: [
                FandomItem(label: "Did So Well",      output: "You did so well today 🥺"),
                FandomItem(label: "So Proud",         output: "I'm so proud of you ✨"),
                FandomItem(label: "Thank You",        output: "Thank you for working so hard 💕"),
                FandomItem(label: "Rest Well",        output: "Please rest well and take care 🌸"),
                FandomItem(label: "Deserve Love",     output: "You deserve all the love 💫"),
                FandomItem(label: "Always Here",      output: "We'll always be here for you 🤍"),
                FandomItem(label: "Never Unnoticed",  output: "Your hard work never goes unnoticed 🙏"),
                FandomItem(label: "Better Place",     output: "You make the world a better place 💝"),
                FandomItem(label: "Thank Existing",   output: "Thank you for existing 🫶"),
                FandomItem(label: "Stay Healthy",     output: "Stay healthy, that's all we ask 💚"),
            }),
            */
            FandomSection(title: "EN", items: [
                FandomItem(label: "You Got This",    output: _oc("You got this! 🔥", 0x1D5D4, 0x1D5EE, 0x1D7EC)),                    // Bold
                FandomItem(label: "Love To See It",  output: _cm("We love to see it!", _slightlyCursiveMap)),                        // Cursive
                FandomItem(label: "Crushing It",     output: _oc("You're crushing it 💪", 0x1D63C, 0x1D656, nil)),                   // Heavy
                FandomItem(label: "Go Get Em",       output: _oc("Go get 'em! 🚀", 0x1D468, 0x1D482, 0x1D7CE)),                     // Bold Italic
                FandomItem(label: "Good Vibes",      output: _oc("Sending you all the good vibes.", 0x1D468, 0x1D482, 0x1D7CE)),   // Bold Italic
                FandomItem(label: "Nail It",         output: _oc("You're gonna nail it 💪", 0x1D5D4, 0x1D5EE, 0x1D7EC)),            // Bold
                FandomItem(label: "Fingers Crossed", output: _oc("Fingers crossed for you! 🤞", 0x1D434, 0x1D44E, nil, _itX)),      // Italic
                FandomItem(label: "Made For This",   output: _oc("You were made for this.", 0x1D4D0, 0x1D4EA, nil)),                 // Bold Script
                FandomItem(label: "Do Great",        output: _cm("I know you'll do great.", _slightlyCursiveMap)),                   // Cursive
                FandomItem(label: "So Proud",        output: _oc("So proud of you.", 0x1D49C, 0x1D4B6, nil, _scX)),                 // Script
                FandomItem(label: "Believe",         output: _oc("I believe in you.", 0x1D4D0, 0x1D4EA, nil)),                      // Bold Script
                FandomItem(label: "Proud Always",    output: _oc("Proud of you always.", 0x1D49C, 0x1D4B6, nil, _scX)),             // Script
                FandomItem(label: "Goes Well",       output: _oc("Hope everything goes well!", 0x1D434, 0x1D44E, nil, _itX)),       // Italic
                FandomItem(label: "Keep Shining",    output: _cc("Keep shining ✨", "꙰")),                                           // Sparkle
                FandomItem(label: "Doing Well",      output: _cm("You're doing so well.", _slightlyCursiveMap)),                     // Cursive
                FandomItem(label: "Best Of Luck",    output: _oc("Wishing you the best of luck!", 0x1D468, 0x1D482, 0x1D7CE)),      // Bold Italic
                FandomItem(label: "Don't Stress",    output: _oc("Don't stress too much 😭", 0x24B6, 0x24D0, nil)),                 // Bubble
                FandomItem(label: "Deep Breath",     output: _cm("Take a deep breath, you got this.", _slightlyCursiveMap)),         // Cursive
                FandomItem(label: "One Step",        output: _oc("One step at a time!", 0x1D434, 0x1D44E, nil, _itX)),              // Italic
            ]),
            /* 기존 Cheer KO 데이터 보존 (복구 시 주석 해제)
            FandomSection(title: "KO", items: [
                FandomItem(label: "Worked Hard",  output: "오늘도 수고했어 💕",       labelKey: "cheer_worked_hard"),
                FandomItem(label: "Cheering",     output: "항상 응원할게 ✨",         labelKey: "cheer_cheering"),
                FandomItem(label: "Thank You",    output: "존재해줘서 고마워 🥺",     labelKey: "cheer_thank_existing"),
                FandomItem(label: "Stay Healthy", output: "건강이 제일 중요해 🌸",    labelKey: "cheer_stay_healthy"),
                FandomItem(label: "Happy",        output: "너 덕분에 행복해 💫",      labelKey: "cheer_happy"),
                FandomItem(label: "Always Here",  output: "우리 항상 여기 있을게 🤍", labelKey: "cheer_always_here"),
                FandomItem(label: "Best",         output: "네가 최고야 👑",           labelKey: "cheer_best"),
                FandomItem(label: "Miss You",     output: "사랑해 보고싶다 ㅠㅠ 💕", labelKey: "cheer_miss_you"),
                FandomItem(label: "Hard Work",    output: "열심히 해줘서 고마워 🙏",  labelKey: "cheer_hard_work"),
                FandomItem(label: "Take It Easy", output: "쉬엄쉬엄 해도 돼 🫶",    labelKey: "cheer_take_easy"),
            }),
            */
            FandomSection(title: "KO", items: [
                FandomItem(label: "Cheer 1",  output: "존재 자체가 감동임 진짜로",                labelKey: "cheer_ko_1"),
                FandomItem(label: "Cheer 2",  output: "오늘도 덕분에 버텼다 고마워 🤍",          labelKey: "cheer_ko_2"),
                FandomItem(label: "Cheer 3",  output: "내 행복의 99%는 네 덕분이야",             labelKey: "cheer_ko_3"),
                FandomItem(label: "Cheer 4",  output: "아프지 말고 건강만 해, 그거면 돼",        labelKey: "cheer_ko_4"),
                FandomItem(label: "Cheer 5",  output: "항상 네 편이니까 기죽지 마",              labelKey: "cheer_ko_5"),
                FandomItem(label: "Cheer 6",  output: "네가 걷는 길은 다 정답이야",              labelKey: "cheer_ko_6"),
                FandomItem(label: "Cheer 7",  output: "언제나 늘 응원하고 있어",                 labelKey: "cheer_ko_7"),
                FandomItem(label: "Cheer 8",  output: "네가 주는 에너지가 진짜 커",              labelKey: "cheer_ko_8"),
                FandomItem(label: "Cheer 9",  output: "매일 매 순간 고마워",                     labelKey: "cheer_ko_9"),
                FandomItem(label: "Cheer 10", output: "세상이 억까해도 나는 네 편임 ㅇㅇ",      labelKey: "cheer_ko_10"),
                FandomItem(label: "Cheer 11", output: "네가 잘되면 내가 다 뿌듯해",             labelKey: "cheer_ko_11"),
                FandomItem(label: "Cheer 12", output: "너는 그냥 즐기기만 해, 응원은 내가 할게", labelKey: "cheer_ko_12"),
                FandomItem(label: "Cheer 13", output: "언제나 네 눈엔 예쁜 것만 담기길 ✨",     labelKey: "cheer_ko_13"),
            ]),
        ]),
        FandomCategory(title: "React", sections: [
            /* 기존 React EN 데이터 보존 (복구 시 주석 해제)
            FandomSection(title: "EN", items: [
                FandomItem(label: "No Way",      output: "No way!! 😱"),
                FandomItem(label: "So Cool",     output: "That's so cool 🔥"),
                FandomItem(label: "Obsessed",    output: "I'm obsessed 😭"),
                FandomItem(label: "Everything",  output: "This is everything 🙌"),
                FandomItem(label: "Can't Even",  output: "I can't even 💀"),
                FandomItem(label: "Crying",      output: "Literally crying rn 😭"),
                FandomItem(label: "Mind Blown",  output: "Mind blown 🤯"),
                FandomItem(label: "Best Ever",   output: "Best thing ever 👑"),
            }),
            */
            FandomSection(title: "EN", items: [
                FandomItem(label: "No Way 💀",          output: _oc("No way 💀", 0x1D5D4, 0x1D5EE, 0x1D7EC)),                      // Bold
                FandomItem(label: "Be So Real",          output: _oc("Be so for real right now.", 0x1D434, 0x1D44E, nil, _itX)),    // Italic
                FandomItem(label: "Actually Insane",     output: _oc("That's actually insane.", 0x1D468, 0x1D482, 0x1D7CE)),        // Bold Italic
                FandomItem(label: "I'm Crying 😭",       output: _cc("I'm crying 😭", "\u{0308}")),                                 // Sad
                FandomItem(label: "Stoppp 😭",           output: "sᴛOᴘᴘᴘ🫢"),
                FandomItem(label: "Ain't No Way",        output: _oc("Ain't no way.", 0x1D5D4, 0x1D5EE, 0x1D7EC)),                 // Bold
                FandomItem(label: "Sending Me",          output: _oc("This is sending me.", 0x1D608, 0x1D622, nil)),                // Sans Italic
                FandomItem(label: "Obsessed",            output: _oc("I'm obsessed.", 0x1D4D0, 0x1D4EA, nil)),                     // Bold Script
                FandomItem(label: "That's Wild",         output: _oc("That's wild.", 0x1D468, 0x1D482, 0x1D7CE)),               // Bold Italic
                FandomItem(label: "Real.",               output: _oc("Real.", 0x1D670, 0x1D68A, 0x1D7F6)),                         // Typewriter
                FandomItem(label: "Help 😭",             output: "🅗🅔🅛🅟"),
                FandomItem(label: "I'm Weak",            output: _cc("I'm weak.", "\u{0308}")),                                    // Sad
                FandomItem(label: "Okayyyy 👀",          output: _oc("Okayyyy I see you 👀", 0xFF21, 0xFF41, 0xFF10)),             // Wide
                FandomItem(label: "You Ate",             output: _oc("You ate.", 0x1D4D0, 0x1D4EA, nil)),                          // Bold Script
                FandomItem(label: "Goes Hard",           output: _oc("This goes hard.", 0x1D63C, 0x1D656, nil)),                   // Heavy
                FandomItem(label: "Main Character",      output: _oc("Main character energy.", 0x1D468, 0x1D482, 0x1D7CE)),        // Bold Italic
                FandomItem(label: "I'm Dead 😭",         output: "𝐈'𝐌 𝐃𝐄𝐀𝐃 ☠️"),
                FandomItem(label: "So Real",             output: _oc("You're so real for this.", 0x1D434, 0x1D44E, nil, _itX)),    // Italic
                FandomItem(label: "Lowkey Obsessed",     output: _cm("Lowkey obsessed.", _slightlyCursiveMap)),                    // Cursive
                FandomItem(label: "Lowkey Iconic",       output: _cm("Lowkey iconic.", _slightlyCursiveMap)),                      // Cursive
                FandomItem(label: "This Ate",            output: _oc("This ate.", 0x1D4D0, 0x1D4EA, nil)),                         // Bold Script
                FandomItem(label: "Brooo 😭",            output: "Brooo"),
                FandomItem(label: "So Funny 😭",         output: "Ⓦⓗⓨ ⓘⓢ ⓣⓗⓘⓢ ⓢⓞ ⓕⓤⓝⓝⓨ"),
                FandomItem(label: "Nobody Talking",      output: _oc("Why is nobody talking about this?", 0x1D434, 0x1D44E, nil, _itX)), // Italic
                FandomItem(label: "Ate That Up",         output: _oc("Oh you ate that up.", 0x1D4D0, 0x1D4EA, nil)),               // Bold Script
                FandomItem(label: "Crazy Work",          output: _oc("Nah this is crazy work.", 0x1D468, 0x1D482, 0x1D7CE)),   // Bold Italic
                FandomItem(label: "The Context 😭",      output: "𝚃𝚑𝚎 𝚌𝚘𝚗𝚝𝚎𝚡𝚝??"),
                FandomItem(label: "I Fear...",           output: _oc("I fear...", 0x1D434, 0x1D44E, nil, _itX)),                   // Italic
                FandomItem(label: "Top Tier",            output: _oc("This is top tier.", 0x1D63C, 0x1D656, nil)),                  // Heavy
                FandomItem(label: "We Are So Back",      output: _oc("We are so back.", 0x1D5D4, 0x1D5EE, 0x1D7EC)),               // Bold
            ]),
        ]),
        FandomCategory(title: "Slang", sections: [
            FandomSection(title: "EN", items: [
                FandomItem(label: "Slay",                    output: _oc("Slay", 0x1D4D0, 0x1D4EA, nil)),                          // Bold Script
                FandomItem(label: "Ate & Left No Crumbs",    output: _oc("Ate and left no crumbs.", 0x1D434, 0x1D44E, nil, _itX)), // Italic
                FandomItem(label: "No Cap 🧢",              output: _oc("No Cap 🧢", 0x1D5D4, 0x1D5EE, 0x1D7EC)),                 // Bold
                FandomItem(label: "Bet",                     output: _oc("Bet", 0x1D56C, 0x1D586, nil)),                           // Dark
                FandomItem(label: "Dead 💀",                 output: "Dead 💀"),
                FandomItem(label: "It's Giving",             output: _oc("It's Giving", 0x1D608, 0x1D622, nil)),                   // Sans Italic
                FandomItem(label: "Period.",                  output: _oc("Period.", 0x1D468, 0x1D482, 0x1D7CE)),                   // Bold Italic
                FandomItem(label: "Slaps",                   output: _oc("Slaps", 0x1D63C, 0x1D656, nil)),                         // Heavy
                FandomItem(label: "W / L",                   output: "W / L"),
                FandomItem(label: "Make It Make Sense",      output: "Make it make sense 😭"),
                FandomItem(label: "Rizz",                    output: _oc("Rizz", 0x1D49C, 0x1D4B6, nil, _scX)),                    // Script
                FandomItem(label: "Main Character Energy 🎬",output: _oc("Main Character Energy 🎬", 0x1D468, 0x1D482, 0x1D7CE)), // Bold Italic
                FandomItem(label: "Glow Up 🦋",             output: _cc("Glow Up 🦋", "꙰")),                                      // Sparkle
                FandomItem(label: "Understood The Assignment",output: _oc("Understood the Assignment", 0x1D670, 0x1D68A, 0x1D7F6)),// Typewriter
                FandomItem(label: "Iconic",                  output: _oc("Iconic", 0x1D4D0, 0x1D4EA, nil)),                        // Bold Script
                FandomItem(label: "Fire 🔥",                 output: "Fire 🔥"),
                FandomItem(label: "Delulu",                  output: _oc("Delulu", 0x24B6, 0x24D0, nil)),                          // Bubble
                FandomItem(label: "The Ick",                 output: _cc("The Ick", "\u{0308}")),                                   // Sad
                FandomItem(label: "Cringe",                  output: _cc("Cringe", "\u{0308}")),                                   // Sad
                FandomItem(label: "Mid",                     output: "Mid"),
                FandomItem(label: "Flop",                    output: _cc("Flop", "\u{0308}")),                                      // Sad
                FandomItem(label: "Out of Pocket",           output: "Out of Pocket"),
                FandomItem(label: "Sus 👀",                  output: _oc("Sus 👀", 0x1D504, 0x1D51E, nil, _goX)),                  // Gothic
                FandomItem(label: "Caught in 4K 📸",        output: _oc("Caught in 4K 📸", 0x1D5D4, 0x1D5EE, 0x1D7EC)),          // Bold
                FandomItem(label: "NPC",                     output: _oc("NPC", 0x1D670, 0x1D68A, 0x1D7F6)),                       // Typewriter
                FandomItem(label: "Situationship 🫠",        output: _cc("Situationship 🫠", "\u{0360}")),                          // Wiggle
                FandomItem(label: "Red Flag 🚩",             output: "Red Flag 🚩"),
                FandomItem(label: "Green Flag 🟢",           output: "Green Flag 🟢"),
                FandomItem(label: "Soft / Hard Launch",      output: "Soft Launch / Hard Launch"),
                FandomItem(label: "Bestie",                  output: "Bestie".map { $0 == " " ? " " : "♡\($0)♡" }.joined()),       // Candy
                FandomItem(label: "Vibe Check",              output: _oc("Vibe Check", 0x1D5A0, 0x1D5BA, 0x1D7E2)),                // Sans
                FandomItem(label: "Caught a Vibe",           output: "Caught a Vibe"),
                FandomItem(label: "Lock In",                 output: _oc("Lock In", 0x1F170, 0x1F170, nil)),                       // Block
                FandomItem(label: "About to Crash Out",      output: "I'm about to crash out"),
                FandomItem(label: "Let Them Cook",           output: "Let Them Cook"),
                FandomItem(label: "Aura",                    output: _cc("Aura", "\u{035C}")),                                      // Halo
                FandomItem(label: "In My Healing Era",       output: _oc("In my healing era", 0x1D49C, 0x1D4B6, nil, _scX)),     // Script
                FandomItem(label: "POV: 🎥",                 output: _oc("POV: 🎥", 0x1D5D4, 0x1D5EE, 0x1D7EC)),                  // Bold
                FandomItem(label: "Core Memory",             output: _oc("Core Memory", 0x1D49C, 0x1D4B6, nil, _scX)),             // Script
                FandomItem(label: "Living Rent Free",        output: _oc("Living rent free in my head.", 0x1D434, 0x1D44E, nil, _itX)), // Italic
            ]),
        ]),
        FandomCategory(title: "Chaotic", sections: [
            FandomSection(title: "KO", items: [
                FandomItem(label: "푸항항 ꉂꉂ(ᵔᗜᵔ*)",          output: "푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*) 푸항항 ꉂꉂ(ᵔᗜᵔ*)",          labelKey: "chaotic_01"),
                FandomItem(label: "🎷빠빠빠빠 굿모닝",          output: "🎷🎺🎷🎷🎷🎺빠빠빠빠🎷🎷빠빠빠빠빠🎷🎷🎷🎺굿모닝🎷🎺🎺🎷🎷🎺🎺🎷빠빠빠빠빠🎷🎺🎺🎷🎺빠빠빠빠🎷🎺🎺굿모닝🎷🎺🎷🎺🎷🎷빠빠빠빠빠🎷🎷🎺🎺🎷🎺빠빠빠빠🎷🎷🎺🎷🎷뷰리풀데이🎷🎺🎺🎷🎷🎷빠빠빠빠빠🎷🎷🎺🎷이츠뷰리풀데이🎷🎷🎷🎺🎷🎷🎷🎺딩딩딩🎵🎶🎵굿모닝🎶🎵🎶딩딩딩🎵🎶🎵굿모닝🎶🎵🎶딩딩딩🎵🎶🎵🎷🎺🎷🎷🎷🎺빠빠빠빠🎷🎷빠빠빠빠빠🎷🎷🎷🎺굿모닝",          labelKey: "chaotic_02"),
                FandomItem(label: "🌈아니 뭔 개소리냐고",        output: "🌈💕🌟아니 뭔 개소리냐고💕❤️🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️ 🌈💕🌟아니 뭔 개소리냐고💕❤️",        labelKey: "chaotic_03"),
                FandomItem(label: "🏢회사가기 시러요",            output: "회사🏢가기 시러요😵왜 가야하지요🤬?그냥 돈💵주면 안돼요🤭?집🏡에 보내주세요🤪회사🏢가기 시러요😵왜 가야하지요🤬?그냥 돈💵주면 안돼요🤭?집🏡에 보내주세요🤪회사🏢가기 시러요😵왜 가야하지요🤬?그냥 돈💵주면 안돼요🤭?집🏡에 보내주세요🤪회사🏢가기 시러요😵왜 가야하지요🤬?그냥 돈💵주면 안돼요🤭?집🏡에 보내주세요🤪",            labelKey: "chaotic_04"),
                FandomItem(label: "예~ 죄송하게 됐습니다",        output: "예~🙋🏻‍♂️거참 🔥죄송하게🔥 됐습니다💤 🎊사죄의 🔈말씀🔈 드립니다🌟🎉 예~🙋🏻‍♂️거참 🔥죄송하게🔥 됐습니다💤 🎊사죄의 🔈말씀🔈 드립니다🌟🎉 예~🙋🏻‍♂️거참 🔥죄송하게🔥 됐습니다💤 🎊사죄의 🔈말씀🔈 드립니다🌟🎉 예~🙋🏻‍♂️거참 🔥죄송하게🔥 됐습니다💤 🎊사죄의 🔈말씀🔈 드립니다🌟🎉",        labelKey: "chaotic_05"),
                FandomItem(label: "어떡해 너무 귀여워",           output: "어떡해🙊너무💐🌸🌷귀여워🥰❤️ 어떡해🙊너무💐🌸🌷귀여워🥰❤️ 어떡해🙊너무💐🌸🌷귀여워🥰❤️ 어떡해🙊너무💐🌸🌷귀여워🥰❤️ 어떡해🙊너무💐🌸🌷귀여워🥰❤️ 어떡해🙊너무💐🌸🌷귀여워🥰❤️",           labelKey: "chaotic_06"),
                FandomItem(label: "𝙒𝙝𝙮𝙧𝙖𝙣𝙤...",              output: "𝙒𝙝𝙮𝙧𝙖𝙣𝙤... 𝙒𝙝𝙮𝙧𝙖𝙣𝙤... 𝙒𝙝𝙮𝙧𝙖𝙣𝙤... 𝙒𝙝𝙮𝙧𝙖𝙣𝙤... 𝙒𝙝𝙮𝙧𝙖𝙣𝙤... 𝙒𝙝𝙮𝙧𝙖𝙣𝙤...",              labelKey: "chaotic_07"),
                FandomItem(label: "👥수군수군 마이크테스트",       output: "👥👥👥👤👤👥👤👥(수군)👤👥👤👥👤👤👤👥👥👤👤(웅성)👤👥👤👥👤👥(웅성웅성)👤👥👤👥👥👤(수군수군)👤👤👤👥👤👥👤👥👥👥🗣📣아아마이크테스트👥👥👤👥👤👥👤👤(수군수군)👤👥👤👥👥👥👥👤👥👤(쑥덕쑥덕)",       labelKey: "chaotic_08"),
                FandomItem(label: "ヲヲヲヲヲ...",               output: "ヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲヲ",               labelKey: "chaotic_09"),
                FandomItem(label: "🎺삘릴리 개굴개굴",           output: "삘릴리 🎺개굴개굴 🐸삘릴리 🎺개굴개굴 🐸삘릴리🎺 개굴개굴 🐸삘릴리 🎺개굴개굴 🐸삘릴리 🎺개굴개굴 🐸삘릴리🎺 개굴개굴 🐸삘릴리삘릴리 🎺개굴개굴 🐸삘릴리 🎺개굴개굴 🐸삘릴리🎺 개굴개굴 🐸",           labelKey: "chaotic_10"),
                FandomItem(label: "힘들 때 빗속에서 힙합",        output: "난 힘들 때 빗속에서 힙합을 춰...｀、、｀ヽ｀ヽ｀、、ヽヽ、｀、ヽ｀ヽ｀ヽヽ｀ヽ｀、｀ヽ｀、ヽ｀｀、ヽ｀ヽ｀、ヽヽ｀ヽ、ヽ｀ヽ、ヽヽ｀ヽ｀、｀｀ヽ｀ヽ、ヽ、ヽ｀ヽ｀ヽ、ヽ｀ヽ｀、ヽヽ｀｀、ヽ｀、ヽヽ ዽ ヽ｀｀",        labelKey: "chaotic_11"),
                FandomItem(label: "🚨긴급상황 발생",             output: "🚨🚨🚨🚨🚨🚨애애애애앵‼️‼️‼️‼️‼️‼️🚨🚨🚨🚨🚨🚨📢📢📢📢📢📢📢긴급상황‼️‼️‼️긴급상황‼️‼️‼️‼️‼️📢📢📢📢📢📢📢🔊🔊🔊🔊🔊🔊 발생‼️‼️‼️🔊🔊🔊🔊🔊🔊🔊🔊🔊🔥🔥🔥🔥🔥🔥🔥",             labelKey: "chaotic_12"),
                FandomItem(label: "끟ㅂ,,끄릅흡ㅁ😭",           output: "끟ㅂ,,끄릅흡ㅁ끟ㅂ,,끄릅흡ㅁ😭 끟ㅂ,,끄릅흡ㅁ😭끟ㅂ,,끄릅흡ㅁ😭 끟ㅂ,,끄릅흡ㅁ😭끟ㅂ,,끄릅흡ㅁ😭 끟ㅂ,,끄릅흡ㅁ😭끟ㅂ,,끄릅흡ㅁ😭 끟ㅂ,,끄릅흡ㅁ😭끟ㅂ,,끄릅흡ㅁ😭 끟ㅂ,,끄릅흡ㅁ😭끟ㅂ,,끄릅흡ㅁ😭",           labelKey: "chaotic_13"),
                FandomItem(label: "아 귀엽다 너무 귀여운데",      output: "아 귀엽다 .. 너무 귀여운데 ? 아 귀여워 .. 귀엽다 .. 너무 귀여운데 ? 아 귀여워 .. 아 귀여워 .. 귀엽다 .. 너무 귀여운데 ? 아 귀여워 .. 귀엽다 .. 너무 귀여운데 ? 아 귀여워 .. 아 귀여워 .. 귀엽다 .. 너무 귀여운데 ? 아 귀여워 .. 귀엽다 .. 너무 귀여운데 ? 아 귀여워 ..",      labelKey: "chaotic_14"),
                FandomItem(label: "🌸나는 귀여우니깐 다괜찮아",   output: "나는🌸귀여우니깐🌟다괜찮아🍬🍩 나는🌸귀여우니깐🌟다괜찮아🍬🍩 나는🌸귀여우니깐🌟다괜찮아🍬🍩 나는🌸귀여우니깐🌟다괜찮아🍬🍩 나는🌸귀여우니깐🌟다괜찮아🍬🍩 나는🌸귀여우니깐🌟다괜찮아🍬🍩",   labelKey: "chaotic_15"),
                FandomItem(label: "냬~알걨섑니댸~",              output: "(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~(☝ ՞ਊ ՞)냬~알걨섑니댸~",              labelKey: "chaotic_16"),
                FandomItem(label: "🐜개미는 오늘도 열심히",       output: "개미는(뚠뚠)🐜🐜오늘도(뚠뚠)🐜🐜열심히 일을 하네(뚠뚠)🐜🐜개미는(뚠뚠)🐜🐜언제나(뚠뚠)🐜🐜열심히일을하네(뚠뚠)🐜🐜개미는아무말도하지않지만(띵가띵가)🐜🐜땀을뻘뻘흘리면서(띵가띵가)🐜🐜매일매일을살기위해서열심히일하네(띵가띵가)🐜🐜",       labelKey: "chaotic_17"),
                FandomItem(label: "이얏호! 신난다💃",             output: "이얏호! 신난다💃🕺 훌라😉훌라💨 허리를👯‍♂️ 돌려~🤹\u{200d}♀️ 이얏호! 신난다💃🕺 훌라😉훌라💨 허리를👯‍♂️ 돌려~🤹\u{200d}♀️ 이얏호! 신난다💃🕺 훌라😉훌라💨 허리를👯‍♂️ 돌려~🤹\u{200d}♀️ 이얏호! 신난다💃🕺 훌라😉훌라💨 허리를👯‍♂️ 돌려~🤹\u{200d}♀️",             labelKey: "chaotic_18"),
                FandomItem(label: "👄말하기 전에 생각했나요",     output: "말하기👄💬 전에 생각🤔💭 했나요❓ 말하기👄💬 전에 생각🤔💭 했나요❓ 말하기👄💬 전에 생각🤔💭 했나요❓ 말하기👄💬 전에 생각🤔💭 했나요❓ 말하기👄💬 전에 생각🤔💭 했나요❓ 말하기👄💬 전에 생각🤔💭 했나요❓ 말하기👄💬 전에 생각🤔💭 했나요❓",     labelKey: "chaotic_19"),
                FandomItem(label: "1. 왜 그런 말을 했는지",       output: "1. 왜 그런 말을 했는지 1-1 어떠한 경위로 그런 말을 했는지 1-2 왜 그런 단어 선택을 했는지 1-3 평소에 그런 말을 자주 하는지 2. 그 말을 할 때 어떤 생각을 했는지 2-1 평소에 생각을 자주 하는 편인지 2-2 그 말을 떠올리면 어떤 생각이 드는지 2-3 말하기 전에 생각 했는지 3. 앞으로 어떻게 할 건지 3-1 어떤 생각을 가지고 살 건지 3-2 피해 보상은 생각해봤는지 3-3 보상을 한다면 어떤 방법으로 할건지 4. 최종 의견 4-1 최종적으로 어떤 생각을 하게 됐는지 4-2 앞으로 어떻게 할 건지",       labelKey: "chaotic_20"),
                FandomItem(label: "ヽ｀비가 와ヽ｀ヽ｀",          output: "ヽ｀、、ヽ｀ヽ｀、ヽ｀、ヽ｀｀｀、ヽ｀｀、ヽ｀、ヽ｀ヽ｀、、ヽ｀ヽ｀、ヽ｀、ヽ｀｀、ヽ｀비가 와、ヽ｀ヽ｀、、ヽ｀ヽ｀、ヽ｀、ヽ｀｀、ヽ｀、ヽ｀ヽ｀、、ヽ｀ヽ｀、ヽ(ノ；Д；)ノ ｀、、ヽ｀ヽ｀、ヽ｀｀、ヽ｀、ヽ｀ヽ｀｀、ヽ｀｀、、ヽ｀ヽ｀、、ヽ｀ヽ｀、｀、ヽ｀｀、ヽ｀、ヽ｀｀、、ヽ｀ヽヽ｀、ヽ｀｀、ヽ｀、ヽ｀ヽ｀、、ヽ｀ヽ",          labelKey: "chaotic_21"),
                FandomItem(label: "엉엉 꺼이꺼이",               output: "엉엉༼;´༎ຶ ۝ ༎ຶ༽༼;´༎ຶ ۝ ༎ຶ༽༼;´༎ຶ ۝ ༎ຶ༽( o̴̶̷̥᷅⌓o̴̶̷᷄ ) ( o̴̶̷̥᷅⌓o̴̶̷᷄ ) ( o̴̶̷̥᷅⌓o̴̶̷᷄ ) 허엉엉으엉엉엉 갸아앙ㅇ헝헝흐앙앙༼ ˃ɷ˂ഃ༽༼ ˃ɷ˂ഃ༽엉엉흐엉어허어엉ㅇ어ㅠㅓ허허허휴ㅠㅠㅠㅠㅎ어어유ㅠㅠㅠㅠ파하규ㅠㅠㅠ༼;´༎ຶ ۝ ༎ຶ༽༼;´༎ຶ ۝ ༎ຶ༽꺼이꺼이",               labelKey: "chaotic_22"),
                FandomItem(label: "오잉⍤⃝오잉⍤⃝",              output: "오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝오잉⍤⃝",              labelKey: "chaotic_23"),
                FandomItem(label: "죄송한 마음을 담아 ❤️",        output: "죄송한 마음을 담아 ❤️ 작곡 작사를 해 보았어요 💕 정말 죄송합니다 😉 예쁘게 들어 주세요 💖 쏘리 쏘리 암 쏘리 🎵 내가 미안해 🎙🎙 한번만 봐줘! 😘 이쁘게 봐줘잉~ 😍 돌아와줘! ❣️ 사랑해줘~~ 🎤🎶🎶🎵 죄송한 마음을 담아 ❤️ 작곡 작사를 해 보았어요 💕 정말 죄송합니다 😉 예쁘게 들어 주세요 💖 쏘리 쏘리 암 쏘리 🎵 내가 미안해 🎙🎙 한번만 봐줘! 😘 이쁘게 봐줘잉~ 😍 돌아와줘! ❣️ 사랑해줘~~ 🎤🎶🎶🎵 죄송한 마음을 담아 ❤️ 작곡 작사를 해 보았어요 💕 정말 죄송합니다 😉 예쁘게 들어 주세요 💖 쏘리 쏘리 암 쏘리 🎵 내가 미안해 🎙🎙 한번만 봐줘!",        labelKey: "chaotic_24"),
                FandomItem(label: "㉪㉻ 반복",                   output: "㉪㉻㉪㉻㉪㉻㉪㉻㉪㉻㉪㉻㉪㉻㉪㉻",                   labelKey: "chaotic_25"),
                FandomItem(label: "𐌅𐨛 𐌅𐨛",                   output: "𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛𐌅𐨛",                   labelKey: "chaotic_26"),
                FandomItem(label: "으이구 인간아",                output: " 으이구 인간아 ᕙ( ︡\'︡益\'︠)ง 으이구 인간아 ᕙ( ︡\'︡益\'︠)ง  으이구 인간아 ᕙ( ︡\'︡益\'︠)ง 으이구 인간아 ᕙ( ︡\'︡益\'︠)ง  으이구 인간아 ᕙ( ︡\'︡益\'︠)ง 으이구 인간아 ᕙ( ︡\'︡益\'︠)ง",                labelKey: "chaotic_27"),
                FandomItem(label: "수류탄이다!!!",                output: "수류탄이다!!! ( ˙ ∇˙)づ ⌒ (툭) 펑҉!҉ 펑҉퍼҉엉҉퍼҉어҉어҉퍼҉҉퍼҉엉҉퍼҉엉҉!҉!҉펑펑",                labelKey: "chaotic_28"),
                FandomItem(label: "🐌...잠시....만요",            output: "🐌...잠시....만요....🐌...지나가겠...🐌.......읍니다....🐌..정말...🐌죄송.......합니..🐌.....다....🐌...지나......가겠..🐌...읍니다...🐌....면목...🐌..........없읍이다...🐌......뚜뚜.....🐌..............🐌......빵빵......🐌......잠시..🐌......만요.........🐌... ...🐌...잠시....만요....🐌...지나가겠...🐌.......읍니다....🐌..정말...🐌죄송.......합니..🐌.....다....🐌...지나......가겠..🐌...읍니다...🐌.... ...🐌...잠시....만요....🐌...지나가겠...🐌.......읍니다....🐌..",            labelKey: "chaotic_29"),
                FandomItem(label: "도데체 어쩌라는거지",           output: "(c\" ತ,_ತ) 도데체 어쩌라는거지 (c\" ತ,_ತ) (c\" ತ,_ತ) 도데체 어쩌라는거지 (c\" ತ,_ತ) (c\" ತ,_ತ) 도데체 어쩌라는거지 (c\" ತ,_ತ) (c\" ತ,_ತ) 도데체 어쩌라는거지 (c\" ತ,_ತ) (c\" ತ,_ತ) 도데체 어쩌라는거지 (c\" ತ,_ತ) (c\" ತ,_ತ) 도데체 어쩌라는거지 (c\" ತ,_ತ) (c\" ತ,_ತ) 도데체 어쩌라는거지 (c\" ತ,_ತ) (c\" ತ,_ತ) 도데체 어쩌라는거지 (c\" ತ,_ತ) (c\" ತ,_ತ) 도데체 어쩌라는거지 (c\" ತ,_ತ) (c\" ತ,_ತ)",           labelKey: "chaotic_30"),
                FandomItem(label: "우리오파(于里烏播)",            output: "우리오파(于里烏播)개귀여어(凱歸蠡魚)개예부다(凱叡部多)하고풍거(河鼓風去) 삭다해라(削多海蘿) 신의미모(神義美貌) 세상간지(世上間地) 매일이론(每日理論) 덕후마음(德厚馬音)",            labelKey: "chaotic_31"),
                FandomItem(label: "하...당신...오타쿠",           output: "하...당신...지금 ''오타쿠''를 ''무시''하는 건가요?! 『오타쿠』는 원래 ''무언가에 열중하는 사람''이라는 뜻..이랄까..? 암튼 당신네들 「멸칭」이랑은 상관없다고!! 키사마 ..이것도 헌법위반에 명예훼손인 거 아려나 몰라? 아무튼 당신네들...이렇게 나온다면 나도 참는 건 절대로 「무리」..한 번만 더 그러면 정말로 부.숴.버.릴.거.야.",           labelKey: "chaotic_32"),
                FandomItem(label: "너무해!",                     output: "너무해! ᕙ(•̀‸•́‶)ᕗ 너무해! ᕙ(•̀‸•́‶)ᕗ 너무해! ᕙ(•̀‸•́‶)ᕗ 너무해! ᕙ(•̀‸•́‶)ᕗ 너무해! ᕙ(•̀‸•́‶)ᕗ 너무해! ᕙ(•̀‸•́‶)ᕗ 너무해! ᕙ(•̀‸•́‶)ᕗ 너무해! ᕙ(•̀‸•́‶)ᕗ 너무해! ᕙ(•̀‸•́‶)ᕗ 너무해! ᕙ(•̀‸•́‶)ᕗ",                     labelKey: "chaotic_33"),
                FandomItem(label: "👊주먹",                      output: "👊( 　'-' )==👊💥)`-') 👊( 　'-' )==👊💥)`-')👊( 　'-' )==👊💥)`-')👊( 　'-' )==👊💥)`-')👊( 　'-' )==👊💥)`-')👊( 　'-' )==👊💥)`-')👊( 　'-' )==👊💥)`-')👊( 　'-' )==👊💥)`-')👊( 　'-' )==👊💥)`-')👊( 　'-' )==👊💥)`-')",                      labelKey: "chaotic_34"),
            ]),
        ]),
    ]

    private var fandomCatIndex = 0
    private var fandomLangIsEN = true
    private var fandomItemOutputs: [Int: String] = [:]

    // MARK: - Dot Art Data

    private let dotArtCategories: [(String, [String])] = [
        ("도트아트", [
            // 0
            """
⠀⢀⠤⠤⣀ ⠀⡠ ⠉⠉⡀
⠀⡅⠀   ⠤⠉⢱⠤ ⠀ ⡄
⠀⠸⡀⠀⡠⠃⠈⠒⠤⠐
　　　　　　　      ⢀⠒⠒⠤
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀    ⢂  ⠀⠤⠜ ⠔⠈⠉ ⠢
　　　　   ⢀⣀⠀    ⠐⠄⡀⠤⠒⡊⠐     ⠌
⠀  ⠤⠤ ⠀⠔⠀    ⢃  ⠀⠀⠀⠀⠀⠀  ⠒⠤ ⠊
 ⠎ ⠀ ⠤⡎ ⠦ 　  ⡸
 ⠈⡄⠀⠀⡠⠀ ⠉
⠀⠀⠉⠉
""",
            // 1
            """
⠠⣶⣿⣿⣷⡶⠀⠀⠀⣀⡴⣖⡦⡀⢀⣤⢤⡤⣀⠀
⠀⠈⣿⣿⣿⠀⠀⠀⢰⢯⡽⣞⣵⡳⣟⢮⡗⣯⡽⡀
⠀⠀⣿⣿⣿⠀⠀⠀⠸⣏⣾⢳⡞⣽⢞⡯⣞⣳⣽⠁
⠀⢀⣿⣿⣿⠀⠀⠀⠀⠈⢺⡳⣏⣟⢾⣹⣳⡝⠂⠀
⠀⠻⠿⠿⠿⠗⠀⠀⠀⠀⠀⠈⠙⢮⠯⠃⠉⠀⠀⠀
⠀⠀⠀⢀⡄⣄⡀⢀⣀⣀⡜⠓⣄⠤⢤⣀⠀⠀⠀⠀
⠀⠀⠀⣾⠀⠀⠉⠉⠉⠩⣉⣀⣼⡒⠊⠁⡃⠀⠀⠀
⠀⠀⠀⡝⠀⠀⠀⠀⠀⠐⠍⠵⢫⣧⡰⡔⠀⠀⠀⠀
⠀⠀⣸⡃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠑⢁⣼⠤⠄⠀⠀
⠀⠀⠨⣧⠀⠘⠃⠀⠀⡤⠄⠀⠙⠁⠀⣚⠒⠀⠀⠀
⠀⠀⠠⠚⠹⢤⣀⣀⠀⠀⢀⣀⡤⠜⠉⠂⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠈⠁
""",
            // 2
            """
⠀⠀⠀⠀⣾⣿⣿⣷⣄
⠀⠀⠀⢸⣿⣿⣿⣿⣿⣧⣴⣶⣶⣶⣄
⠀⠀⠀⣀⣿⣿⡿⠻⣿⣿⣿⣿⣿⣿⣿⡄
⠀⠀⠀⢇⠠⣏⡖⠒⣿⣿⣿⣿⣿⣿⣿⣧⡀
⠀⠀⢀⣷⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷
⠀⠀⢸⣿⣿⡿⢋⠁⠀⠀⠀⠀⠉⡙⢿⣿⣿⡇
⠀⠀⠘⣿⣿⠀⣿⠇⠀⢀⠀⠀⠘⣿⠀⣿⡿⠁
⠀⠀⠀⠈⠙⠷⠤⣀⣀⣐⣂⣀⣠⠤⠾⠋⠁
""",
            // 3
            """
⣿⣿⣿⣿⠿⠿⠿⢿⡿⠿⠿⠿⢿⣿⣿⣿
⣿⣿⣿⡇ ⣤⣤⣤⡇⠀⣤⣤⣤⣿⣿⣿
⣿⣿⣿⣇ ⠉⠉⠉⡇⠀⠉⠉⠉⣿⣿⣿
⣿⣿⣿⠿⠿⠿⠿⠀ ⠿ ⠿⠿⠿⣿⣿⣿
⣿⣿⣿⣤⣤⣤⠤⠤⠤⠤⢤⣤⣤⣿⣿⣿
⣿⣿⣿⣿⠉⠀⣤⣤⣤⣤⡀⠈⢻⣿⣿⣿
⣿⣿⣿⣿⣄⡀⠉⠙⠛⠉⠁⣠⣾⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
""",
            // 4
            """
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢠⡾⠲⠶⣤⣀⣠⣤⣤⣤⡿⠛⠿⡴⠾⠛⢻⡆⠀⠀⠀
⠀⠀⠀⣼⠁⠀⠀⠀⠉⠁⠀⢀⣿⠐⡿⣿⠿⣶⣤⣤⣷⡀⠀⠀
⠀⠀⠀⢹⡶⠀⠀⠀⠀⠀⠀⠈⢯⣡⣿⣿⣀⣰⣿⣦⢂⡏⠀⠀
⠀⠀⢀⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠹⣍⣭⣾⠁⠀⠀
⠀⣀⣸⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣸⣧⣤⡀
⠈⠉⠹⣏⡁⠀⢸⣿⠀⠀⠀⢀⡀⠀⠀⠀⣿⠆⠀⢀⣸⣇⣀⠀
⠀⠐⠋⢻⣅⡄⢀⣀⣀⡀⠀⠯⠽⠂⢀⣀⣀⡀⠀⣤⣿⠀⠉⠀
⠀⠀⠴⠛⠙⣳⠋⠉⠉⠙⣆⠀⠀⢰⡟⠉⠈⠙⢷⠟⠈⠙⠂⠀
⠀⠀⠀⠀⠀⢻⣄⣠⣤⣴⠟⠛⠛⠛⢧⣤⣤⣀⡾⠀⠀⠀⠀⠀
""",
            // 5
            """
⠀⢀⠤⠤⢄⡀⠀⠀⠀⠀⠀⠀⢀⠤⠒⠒⢤⠀
⠀⠏⠀⠀⠀⠈⠳⡄⠀⠀⡠⠚⠁⠀⠀⠀⠘⡄
⢸⠀⠀⠀⠤⣤⣤⡆⠀⠈⣱⣤⣴⡄⠀⠀⠀⡇
⠘⡀⠀⠀⠀⠀⢈⣷⠤⠴⢺⣀⠀⠀⠀⠀⢀⡇
⠀⠡⣀⣀⣤⠶⠻⡏⠀⠀⢸⡟⠙⣶⡤⠤⠼⠀
⠀⠀⢠⡾⠉⠀⢠⡆⠀⠀⢸⠃⠀⠈⢻⣆⠀⠀
⠀⠀⣿⣠⢶⣄⠀⡇⠀⠀⠘⠃⣀⡤⢌⣈⡀⠀
⠀⠀⠀⠀⠀⠙⠼⠀⠀⠀⠀⠿⠋⠀⠀⠀⠀⠀
""",
            // 6
            """
⠀⢀⠤⣀⣀⣴⣶⣔⢂⠀⠀
⠀⠸⠀⠀⠀⠻⠿⢿⣿⡇⠀
⢀⣸⠀⡀⠀⠀⠀⢠⠀⣗⡂
⠀⢚⣄⡁⠀⠛⠀⢀⡰⢷⠀
⠀⢠⢎⣿⣿⣭⣽⣿⡄⠜⠀
⠀⠘⢺⣿⣿⣿⣿⣿⡇⠀⠀
⠀⠀⠐⠤⠤⠼⠤⠤⠄⠀⠀
""",
            // 7
            """
⢠⠋⠒⠙⡄⠀⣀⢴⠛⡦⣀⠀⠀⢠⠢⠔⡄
⠀⠑⣀⣊⠤⠯⣥⣄⣀⣠⣬⠵⣀⡈⠢⠔⠁
⣰⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠓⠦⣄
⣏⠀⢠⠟⠀⠛⠀⢠⣤⠀⠶⠀⠘⣇⠀⠀⣹
⠙⠒⣾⠀⠀⠀⠘⠚⠓⠚⠀⠀⠀⠙⡲⠚⠁
⠀⢀⡾⠀⣀⠔⠒⢞⣫⡷⠖⠢⡀⠀⢧⠀⠀
⠀⣼⠥⡀⢀⡀⣀⡜⠀⢣⣀⣀⠀⡴⠚⢦⠀
⢸⠁⠀⠙⡀⠀⠀⠙⠒⠋⠀⠀⠨⠀⠀⢸⠀
⠀⠳⣄⣠⠴⠤⠤⠤⠤⠤⠤⠤⠦⣤⡤⠋⠀
""",
            // 8
            """
⠀⣴⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢸⣏⡿⡇⠀⠀⢀⡀⢀⡤⣠⡀⠀⠀⠀⠀⠀⠀⠀
⠀⢻⣳⣇⢀⡤⠾⠙⠈⠀⠙⠦⣄⡀⠀⠀⠀⠀⠀
⠀⠀⢙⡿⠉⠀⠀⠀⠀⠀⠀⠀⠀⠙⣷⣦⡀⠀⠀
⠀⠀⣼⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣷⣽⣷⡄
⠀⠀⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⡏⠳⢷⣿
⠀⠀⠻⠀⠀⣠⡀⠀⠀⠀⠀⢀⣄⠀⠘⠃⠀⠀⠀
⠀⢠⡇⠀⠀⠛⠃⠀⠰⠶⠀⠚⠛⠀⠀⢷⠀⠀⠀
⠀⠀⠳⢤⣀⡀⣤⣄⡀⠀⣀⣤⣄⣀⡴⠋⠀⠀⠀
⠀⠀⠀⠀⠈⢹⣿⢏⣿⣿⢿⡽⡟⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠈⠛⠛⠉⠈⠙⠛⠃⠀⠀⠀⠀⠀⠀
""",
            // 9
            """
⠀⣠⠔⠛⠳⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢀⡍⠀⠀⠀⢹⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠈⣧⠀⠀⠀⠘⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠘⣆⠀⠀⠀⡸⠏⠑⢢⡴⠶⠦⢤⣄⣀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠘⠷⣄⠀⣸⡤⣤⠏⠀⠀⠀⠀⠀⠈⠛⡖⠊⠳⠀⠀⠀
⠀⠀⠀⠀⢈⡟⠁⢀⡀⠀⠀⠀⠀⠀⠀⠀⠘⠤⣀⡴⣏⠀⠀
⠀⠀⠀⠀⣾⠁⠀⠞⠙⠂⠀⠀⠀⠀⠀⢀⣄⡀⠁⣄⢹⡆⠀
⠀⠀⠀⠀⠘⣦⡀⠀⠀⠀⠻⠤⠤⣤⠀⠉⠀⠃⢀⣼⠀⢷⠀
⠀⠀⠀⠀⠀⠈⠙⠒⠶⢤⣤⣄⣀⣀⠀⠄⠀⢀⡡⠋⠀⠈⡇
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠉⠻⣏⠀⠀⠀⢠⡯
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠲⠾⠋⠀
""",
            // 10
            """
⠀⠀⠀⠀⠀⠀⠀⠀⢀⡤⠤⠤⠤⠤⢤⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢠⠞⠉⠉⠀⠀⠀⠀⠀⠀⠈⠓⠒⢄⠀⠀⠀⠀
⠀⠀⠀⢀⡞⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠣⣄⠀⠀
⢀⡄⠠⠼⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡇⠀
⠈⠢⠤⡖⠛⢀⡤⠴⠺⢤⣀⣀⣤⡀⠀⠀⠀⠀⠀⠀⠀⢱⡀
⠀⠀⠀⢳⠀⣿⢠⣀⡀⠀⠀⠀⠀⠉⠀⢖⠀⠀⢀⠐⢆⡾⠁
⠀⠀⠀⠈⢇⢸⡀⠉⠐⡷⠀⠀⠠⣤⡀⠸⡍⠀⠘⢆⡀⢉⡆
⠀⠀⠀⠀⢎⡝⠑⣤⣀⢯⠃⠀⠀⠀⠀⢠⠃⠀⣀⠜⠉⠉⠀
⠀⠀⠀⠀⠀⢳⣀⡔⠈⠑⠒⠒⠒⠒⠛⠉⠉⠉⠓⡤⣄⠀⠀
⠀⠀⠀⠀⠀⠀⠈⡇⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣠⠗⠋⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢱⠀⠀⠀⠀⠀⠀⠀⠀⢸⡼⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠈⢳⠦⣟⣲⣄⠀⠀⢀⠞⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠚⠃⠻⣭⡽⠁⠀⠀⠀⠀⠀⠀⠀
""",
            // 11
            """
⡤⠒⢤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡤⠒⢤
⢣⡀⠀⠉⠲⢤⣀⡀⠀⠀⠀⠀⠀⠀⢀⣀⡤⠖⠉⠀⢀⡜
⢸⡉⠒⠄⠀⠀⠀⢉⡙⢢⠀⠀⡔⢋⡉⠀⠀⠀⠠⠒⢉⡇
⠀⠉⢖⠒⠀⠀⠀⣇⠀⣸⠀⠀⣇⠀⣸⠀⠀⠀⠒⡲⠉⠀
⠀⠀⠀⠉⠙⠫⠤⠚⠉⠀⠀⠀⠀⠉⠓⠤⠝⠋⠉⠀⠀⠀
""",
            // 12
            """
⠀⠀⠀⠀⠀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢰⣿⡿⠗⠀⠠⠄⡀⠀⠀⠀⠀
⠀⠀⠀⠀⡜⠁⠀⠀⠀⠀⠀⠈⠑⢶⣶⡄
⢀⣶⣦⣸⠀⢼⣟⡇⠀⠀⢀⣀⠀⠘⡿⠃
⠀⢿⣿⣿⣄⠒⠀⠠⢶⡂⢫⣿⢇⢀⠃⠀
⠀⠈⠻⣿⣿⣿⣶⣤⣀⣀⣀⣂⡠⠊⠀⠀
⠀⠀⠀⠃⠀⠀⠉⠙⠛⠿⣿⣿⣧⠀⠀⠀
⠀⠀⠘⡀⠀⠀⠀⠀⠀⠀⠘⣿⣿⡇⠀⠀
⠀⠀⠀⣷⣄⡀⠀⠀⠀⢀⣴⡟⠿⠃⠀⠀
⠀⠀⠀⢻⣿⣿⠉⠉⢹⣿⣿⠁⠀⠀⠀⠀
⠀⠀⠀⠀⠉⠁⠀⠀⠀⠉⠁⠀⠀⠀⠀⠀
""",
            // 13
            """
⠀⠀⠀⠀⠀⠀⠀⢀⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢀⣀⠀⡞⠉⠉⢳⣤⠤⣤⠀⠀⠀
⠀⠀⢰⡏⠈⠹⣷⡄⠀⡞⠁⠀⠘⡇⠀⠀
⠀⠀⣘⣧⠀⠀⠘⢷⡀⠀⢀⣠⡾⢥⣄⠀
⠀⢸⡏⠁⠀⠀⠀⣸⣿⡞⠋⠀⠁⠀⣬⠃
⠀⠘⢿⣤⣶⡶⠛⠉⠘⣷⡀⠐⠁⣾⡅⠀
⠀⠀⠀⢰⣿⠀⠀⣹⡄⣺⣿⣷⡔⣼⡇⠀
⠀⢀⣠⡾⠛⠶⠾⠻⣿⣻⣿⠊⠉⠁⠀⠀
⠛⠋⠁⠀⠀⠀⠀⠀⠈⠉⠀⠀⠀⠀⠀⠀
""",
            // 14
            """
⠀⠀⣤⣲⣲⢤⠀⢀⡮⡯⡯⡦⠀⠀
⠀⢸⣳⡳⡯⣯⣀⡸⡽⡽⣽⣫⠀⠀
⠀⡸⠮⡯⡯⣗⣗⡯⣯⢯⣗⡯⡄⠀
⡞⢠⣖⢶⠒⡄⠀⣠⢶⡒⢠⠀⠈⢢
⢆⠘⠾⠽⠄⠃⠀⠙⠽⡥⡜⠁⠀⡞
⠈⠦⣀⡀⠀⠑⠒⠁⠀⠀⣀⣠⠜⠀
⠀⠀⠀⢴⣩⠉⠉⠉⠉⡭⠆⠀⠀⠀
⠀⠀⠀⠀⠸⡰⠚⠒⢆⠇⠀⠀⠀⠀
""",
            // 15
            """
⠀⠀⠀⣠⣀⠀⠀⣀⡀⠀⠀
⢀⣤⣾⣿⣿⡆⣾⣿⣿⣆⠀
⢿⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿
⣀⣬⣭⣿⣿⣿⣿⣿⣟⣛⠉
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦
⠉⢻⣿⣿⡟⡟⣿⣿⣿⠿⠋
⠀⠈⠙⠋⡼⠁⠙⠛⠁⠀⠀
⠀⠀⠀⠘⠁⠀⠀⠀⠀⠀⠀
""",
            // 16
            """
⠀⠀⠀⠀⠀⠀⣴⠶⢦⣤⠶⠶⣄⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣇⠀⠀⠁⠀⢀⣿⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠙⢧⣄⠀⣠⠞⠁⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣀⡀⠀⠉⠛⠃⣠⣄⡀⠀⠀⠀
⠀⠀⠀⠀⡞⠉⠙⢳⣄⢀⡾⠁⠈⣿⠀⠀⠀
⠀⠀⠀⠀⢻⡄⠀⠀⠙⢿⡇⠀⢰⠇⠀⠀⠀
⠀⠀⠀⠀⠀⠙⣦⡀⠀⠀⠹⣦⡟⠀⠀
⠀⠀⠀⠀⠀⠀⠈⢳⣄⠀⠀⠈⠻⣄⠀⠀⠀
⠀⠀⠀⠀⠀⠀⡞⠋⠛⢧⡀⠀⠀⠘⢷⡀⠀
⠀⠀⠀⢠⡴⠾⣧⡀⠀⠀⠹⣦⠀⠀⠈⢿⡄
⠀⠀⣀⣿⠀⠀⠈⠻⣄⠀⠀⠀⠀⠀⠀⠈⣷
⢠⡟⠉⠛⢷⣄⠀⠀⠈⠀⠀⠀⠀⠀⠀⣰⠏
⠀⢷⡀⠀⠀⠉⠃⠀⠀⠀⠀⠀⠀⠀⣴⠏⠀
⠀⠈⠻⣦⡀⠀⠀⠀⠀⠀⠀⢀⣠⠞⠁⠀⠀
⠀⠀⠀⠈⠙⠶⣤⣤⣤⡤⠶⠋⠁⠀⠀⠀⠀
""",
            // 17
            """
⠀⠀⣀⣴⡂⠠⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢀⣴⠾⠛⢉⡅⠀⢽⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠸⣷⣶⡶⠛⢀⣀⠸⠿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠘⠿⠒⠚⢿⣇⡀⠀⠛⠛⠶⣄⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣧⣿⣢⣀⠆⠀⠀⠀⠳⡀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠉⠉⣿⡇⠀⠀⣀⡴⠀⢱⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠸⣿⣀⣴⣿⣿⣇⠀⠈⣆⠀⠀⠠⡀
⠀⠀⠀⠀⠀⠀⢀⣘⣿⡟⣾⡟⠙⢷⣀⠀⠂⢀⣴⠎
⠀⠀⠀⠀⠀⠀⠛⠛⠿⠿⠿⠇⠀⠀⠉⠓⠲⠒⠉⠀
""",
            // 18
            """
⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣤⣤⣤⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣠⣾⠟⠁⠀⠀⢀⣄⣤⣤⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣠⣼⠟⠀⠀⣠⣴⠟⠟⠉⠉⠈⠉⠻⣷⣄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⣠⡿⠁⠀⢀⣾⠟⠁⠀⣠⣤⡶⣤⣤⣀⠈⢻⣦⠀⠀⠀⠀⠀
⠀⠀⢀⣿⠀⠀⢀⣾⠋⠀⠀⣾⠏⠀⣠⣄⠉⢻⣆⠈⣿⡄⠀⠀⠀⠀
⠀⠀⣸⡏⠀⠀⢸⡏⠀⠀⣸⡇⠀⢼⡏⠻⠂⢸⡯⠀⣸⡇⠀⠀⠀⠀
⠀⠀⢸⣇⠀⠀⢿⡇⠀⠀⠪⣷⠀⠈⠻⣷⡾⠟⠁⢠⡿⠁⠀⠀⠀⠀
⠀⠀⠀⢿⣆⠀⠈⣿⡄⠀⠀⠻⣷⣄⣀⣀⣀⣠⣴⠿⠁⠀⠀⠀⠀⠀
⠀⠀⠀⠈⢻⣧⠀⠘⠿⣶⣄⠀⠈⠈⠛⠛⠛⠋⠀⠀⣤⡾⠋⠀⠀⠀
⠀⠀⠀⠀⠀⠋⠀⠀⠀⠈⠹⠷⣦⣤⣤⣤⣤⡴⠾⠟⠋⠀⠀⠀⠀⠀
""",
            // 19
            #"""
😥    😫  😒😣😒
😒😒  😒 😒    😲
😩 😢 😲 😤    😠
😒  😒😒 😞    😤
😭    😖  😒😔😫
"""#,
            // 20
            #"""
  \😭/              💂
     |          🔫👈|\
     |                   |
    / \                / \
"""#,
            // 21
            #"""
  (҂·_·)
  .,︻╦╤─ ҉ - - 😂 - 😂-😂
  /﹋\"
"""#,
            // 23
            #"""
❤🔫🔫❤🔫🔫❤
🔫🔫🔫🔫🔫🔫🔫
🔫🔫🔫🔫🔫🔫🔫
❤🔫🔫🔫🔫🔫❤
❤❤🔫🔫🔫❤❤
❤❤❤🔫❤❤❤
"""#,
            // 24
            #"""
(¯`♥´¯)..♥
.`•.¸.•´(¯`♥´¯)..♥
******.`•.¸.•´(¯`♥´¯)..♥
************.`•.¸.•´(¯`♥´¯)..♥
******************.`•.¸.•´……♥ ♥
"""#,
            // 25
            #"""
*♥.•´¸.•*´✶´♡ ¸.•*´´♡🌼🍃🌼🍃*
*_🌈○💙_Good morning❤🌹*
*💚.•´¸.•*´✶´♡ ¸.•*´´♡⛅*
*° ☆ ° ˛*˛☆_Π____*。*˚☆*
*˚ ˛★˛•˚ */______/~＼。˚ ˚ ˛*
*˚ ˛•˛• ˚ ｜ 田田 ｜門｜ ˚*
*🌴╬═🌴╬╬🌴╬╬🌴═╬╬═🌴*
"""#,
            // 26
            #"""
┏━━━━━ ✨┓
┃✨BEST OF ┃
┃LUCK🍀 FOR ┃
┃  !!          ┃
┃😍 HAPPY 😚┃
┃*🆕* YEAR 🎉┃
┃& I ♥YOU✨┃
┗━━━━⋁━🎀
                  ლ(╹◡╹ლ)
"""#,
            // 27
            #"""
🎅 🎁 🎄　　  ❄ ⛄ 🎅
⛄　　   🎅　🎁　　  🎄
💚　　　　🎄　　　　🎁
❤　        Merry          ❄
　🎁     Christmas!  ⛄
　　❄　　　　　🎅
　　　🎄　　　💚
　　　　⛄　❤
　    　　　✨
"""#,
            // 28
            #"""
🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨
🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨
🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨
🟨⬛⬜🟨🟨🟨🟨🟨⬛⬜🟨
🟨⬛⬛🟨🟨🟨🟨🟨⬛⬛🟨
🟨⬛⬛🟨🟨⬛🟨🟨⬛⬛🟨
🟥🟨🟨🟨🟨🟨🟨🟨🟨🟨🟥
🟥🟥🟨🟨🟨⬛🟨🟨🟨🟥🟥
🟥🟥🟨🟨⬛🟨⬛🟨🟨🟥🟥
🟥🟨🟨🟨🟨🟨🟨🟨🟨🟨🟥
🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨
"""#,
            // 30
            #"""
⬜⬛⬛⬜⬜⬜⬜⬜⬛⬛⬜
⬛⬛⬛⬛⬜⬜⬜⬛⬛⬛⬛
⬛⬛⬛⬛⬜⬜⬜⬛⬛⬛⬛
⬜⬛⬛⬛🏼⬛🏼⬛⬛⬛⬜
⬜⬜⬛🏼🏼🏼🏼🏼⬛⬜⬜
⬜⬜⬛🏼⬛🏼⬛🏼⬛⬜⬜
⬜⬜🏼🏼⬛🏼⬛🏼🏼⬜⬜
⬜⬜🏼🏼🏼⬛🏼🏼🏼⬜⬜
⬜⬜⬜⬛🏼🏼🏼⬛⬜⬜⬜
⬜⬜⬛⬛⬛⬛⬛⬛⬛⬜⬜
⬜⬛⬛⬛⬛⬛⬛⬛⬛⬛⬜
⬜⬜⬜🟥⬜🟥⬜🟥⬜⬜⬜
⬜⬜⬜🟥🟥🟥🟥🟥⬜⬜⬜
"""#
        ])
    ]
    private var selectedDotArtCat = 0

    // MARK: - GIF State

    private lazy var gifCategories: [(String, String?)] = [
        (loc("gif_trending"), nil),
        (loc("gif_cat_funny"), "funny"),
        (loc("gif_cat_love"), "love"),
        (loc("gif_cat_sad"), "sad"),
        (loc("gif_cat_reaction"), "reaction"),
        (loc("gif_cat_angry"), "angry"),
    ]
    private var gifCategoryIndex = 0
    private var gifImages: [GiphyImage] = []
    private weak var gifGridStack: UIStackView?
    private weak var gifLoadingLabel: UILabel?
    private weak var gifScrollView: UIScrollView?
    private var gifOffset = 0
    private var isLoadingGifs = false
    private var gifSearchQuery: String?

    // MARK: - Translate State

    private let translateLangs: [(String, String)] = [
        ("🇰🇷 Korean", "Korean"), ("🇺🇸 English", "English"), ("🇯🇵 Japanese", "Japanese"),
        ("🇨🇳 Chinese", "Chinese"), ("🇪🇸 Spanish", "Spanish"), ("🇫🇷 French", "French"),
        ("🇩🇪 German", "German"), ("🇻🇳 Vietnamese", "Vietnamese"), ("🇹🇭 Thai", "Thai"),
        ("🇮🇩 Indonesian", "Indonesian"),
    ]
    private weak var translateKeyboardContainer: UIStackView?
    private weak var translateNumToggleButton: UIButton?
    /// Bottom bar (한/영 / !?123 / space / 번역 / 삽입) tracked separately
    /// because it lives as a sibling of `translateKeyboardContainer` inside
    /// the outer translate `stack`, NOT inside `kbArea`. Without this ref,
    /// `rebuildTranslateKeys` (which only tears down kbArea) leaves a
    /// stale bottom bar behind on layout switches — visible as a doubled
    /// row of 한/영/번역/삽입 buttons stacked under the cheonjiin row 4.
    /// On rebuild we drop the old bar via this ref and re-add only when
    /// the new layout calls for it.
    private weak var translateBottomBar: UIStackView?
    private weak var translateInputField: UITextView?
    private weak var translatePlaceholderLabel: UILabel?
    private weak var translateCloseButton: UIButton?
    private weak var translateCounterLabel: UILabel?
    private var translationFieldView: UIView?
    /// In-flight OpenAI request, kept so a fresh `translateTriggered` tap can
    /// cancel a still-pending one — protects against double-taps and avoids
    /// the older response winning a race against the newer one.
    private var translationTask: URLSessionDataTask?

    // Calculator state
    private var calcDisplay = "0"
    private var calcPrevValue: Double?
    private var calcPendingOp: String?
    private var calcJustEvaluated = false
    private var calcExpression = ""
    private weak var calcDisplayButton: UIButton?
    private weak var calcExpressionLabel: UILabel?
    private weak var calcACButton: UIButton?
    private var translationInput = ""
    private var lastTranslation = ""
    private var isTranslateDirectInput = true
    private var sourceLangIndex = 0   // 🇰🇷 Korean
    private var targetLangIndex = 1   // 🇺🇸 English
    private var isKoreanMode = true
    private var isTranslateShifted = false
    private var isTranslateCapsLock = false
    private var isTranslateNumberMode = false
    private var isTranslateSymbolPage2 = false
    private var lastShiftTime: Date?

    // ㅂㅈㄷㄱㅅ → ㅃㅉㄸㄲㅆ
    private let korShiftMap: [String: String] = ["ㅂ":"ㅃ", "ㅈ":"ㅉ", "ㄷ":"ㄸ", "ㄱ":"ㄲ", "ㅅ":"ㅆ"]

    // ── Korean Input Mode (settings) ────────────────────────────────────
    /// `"dubeolsik"` (default, 두벌식 / 2-set QWERTY) or `"cheonjiin"`
    /// (천지인 / 12-key cycle). Persisted in App Group UserDefaults so a
    /// change in the settings popup propagates instantly to the next
    /// `showMode` rebuild on both Aa and translate tabs.
    private var koreanInputMode: String {
        get {
            UserDefaults(suiteName: "group.com.yunajung.fonki")?
                .string(forKey: "korean_input_mode") ?? "dubeolsik"
        }
        set {
            UserDefaults(suiteName: "group.com.yunajung.fonki")?
                .set(newValue, forKey: "korean_input_mode")
        }
    }

    // ── Cheonjiin (천지인) Cycle State ────────────────────────────────────
    /// Currently-active cycle group identifier — either a consonant button
    /// label like `"ㄱㅋ"` or the synthetic `"VOWEL"` key for the chained
    /// vowel buffer (ㅣ/·/ㅡ taps that build compound jungs).
    private var cjjLastGroup: String?
    /// Position within the current consonant cycle (0-based). Wraps modulo
    /// the cycle's length on each consecutive tap of the same button.
    private var cjjConsonantIdx: Int = 0
    /// Accumulating vowel tap chain — concatenation of "ㅣ", "·", "ㅡ" in
    /// tap order. Looked up against `CJJ_VOWELS` to derive the 두벌식 jamo
    /// to feed into `handleHangulInput`.
    private var cjjVowelChain: String = ""
    /// Last jamo this engine actually emitted via `handleHangulInput`. On
    /// the next cycling tap we call `handleHangulDelete()` once to undo it
    /// before emitting the next jamo in the cycle. Empty string means the
    /// chain is mid-build (e.g. isolated `·` waiting to pair) so no delete
    /// is needed.
    private var cjjLastEmitted: String = ""
    /// Auto-commit timer. When the user pauses for `CJJ_TIMEOUT` seconds
    /// the cycle is finalized and the next tap starts a fresh group — even
    /// if it's the same button as before.
    private var cjjTimer: Timer?
    private let CJJ_TIMEOUT: TimeInterval = 0.7
    /// Position within the `.,?!` punctuation cycle (0=`.`, 1=`,`, 2=`?`,
    /// 3=`!`). Active only when `cjjLastGroup == "PUNCT"`; each consecutive
    /// tap on the punct key within `CJJ_TIMEOUT` advances the cycle and
    /// replaces the previously-emitted character via `deleteBackward` +
    /// `insertText`. Reset to 0 by `cjjReset()`.
    private var cjjPunctIdx: Int = 0

    /// Consonant cycle table — each multi-jamo button cycles through these
    /// in order on consecutive taps. Lengths vary (2 or 3) — `% .count`
    /// keeps the cycle wrapping on a 4th tap.
    private let CJJ_CONSONANTS: [String: [String]] = [
        "ㄱㅋ": ["ㄱ", "ㅋ", "ㄲ"],
        "ㄴㄹ": ["ㄴ", "ㄹ"],
        "ㄷㅌ": ["ㄷ", "ㅌ", "ㄸ"],
        "ㅂㅍ": ["ㅂ", "ㅍ", "ㅃ"],
        "ㅅㅎ": ["ㅅ", "ㅎ", "ㅆ"],
        "ㅈㅊ": ["ㅈ", "ㅊ", "ㅉ"],
        "ㅇㅁ": ["ㅇ", "ㅁ"],
    ]

    /// Vowel chain → 두벌식 jamo. Lookup key is the concatenated tap
    /// sequence of ㅣ/·/ㅡ.
    ///
    /// Single-tap basics (ㅣ/ㅡ alone) + 4 directional pairs (ㅏㅓㅗㅜ) +
    /// their yod variants (ㅑㅕㅛㅠ) + the four "stage-2" iotization
    /// compounds (ㅐ/ㅔ/ㅒ/ㅖ).
    ///
    /// The stage-2 entries were added to fix "· + ㅣ + ㅣ ≠ ㅔ" — the
    /// 두벌식 `CJ` compound-jung table (used downstream by
    /// `handleHangulInput`) only knows about ㅗ/ㅜ/ㅡ family compounds
    /// (ㅘ/ㅝ/ㅚ/ㅟ/ㅢ etc.); ㅓ+ㅣ=ㅔ and ㅏ+ㅣ=ㅐ aren't there because
    /// 두벌식 has ㅔ/ㅐ as direct keys. We have to recognize the longer
    /// 천지인 chains here so the engine can emit them via a single
    /// `handleHangulInput` call.
    ///
    /// Other 두벌식 compounds (ㅢ/ㅚ/ㅟ etc.) still work via the cycle
    /// engine's "chain doesn't extend → commit + start fresh with this
    /// tap" branch, because `handleHangulInput` runs the `CJ` table on
    /// each successive jamo emission. Compound jungs that need state
    /// across BOTH a consonant boundary AND multiple vowel taps (ㅘ/ㅝ)
    /// remain unsupported — they would require a richer state machine.
    private let CJJ_VOWELS: [String: String] = [
        "ㅣ":     "ㅣ",
        "ㅣ·":    "ㅏ",
        "ㅣ··":   "ㅑ",
        "·ㅣ":    "ㅓ",
        "··ㅣ":   "ㅕ",
        "ㅡ":     "ㅡ",
        "·ㅡ":    "ㅗ",
        "··ㅡ":   "ㅛ",
        "ㅡ·":    "ㅜ",
        "ㅡ··":   "ㅠ",
        // Stage-2 (ㅏ/ㅓ/ㅑ/ㅕ + ㅣ → ㅐ/ㅔ/ㅒ/ㅖ).
        "ㅣ·ㅣ":  "ㅐ",
        "·ㅣㅣ":  "ㅔ",
        "ㅣ··ㅣ": "ㅒ",
        "··ㅣㅣ": "ㅖ",
        // Stage-3 compound jungs (ㅗ/ㅜ + secondary vowel). Longer chains
        // are listed before their shorter counterparts for readability
        // only — dictionary lookup is hash-based and order-insensitive,
        // but the chain extender's prefix check (`hasPrefix(extended)`)
        // sees every key regardless of position, so adding these here is
        // sufficient to make the intermediate `"ㅡ··ㅣ"` / `"ㅣ·ㅡ"` /
        // `"ㅣ·ㅡ·"` states valid buffer points instead of resetting the
        // chain. Bug fixed: typing ㅡ··ㅣㅣ used to land at "유ㅣㅣ"
        // because `"ㅡ··ㅣ"` matched neither exact nor (pre-fix-add)
        // prefix → chain reset, emitting standalone ㅣ.
        "ㅡ··ㅣㅣ":   "ㅞ",   // ㅜ + ㅔ
        "ㅡ··ㅣ":     "ㅝ",   // ㅜ + ㅓ
        "ㅣ·ㅡ·ㅣㅣ": "ㅙ",   // ㅗ + ㅐ
        "ㅣ·ㅡ·ㅣ":   "ㅘ",   // ㅗ + ㅏ
    ]

    // ── Hangul Composition Engine ──────────────────────────────────────
    private var hgCho: Int = -1    // current chosung index (-1 = none)
    private var hgJung: Int = -1   // current jungsung index
    private var hgJong: Int = 0    // current jongsung index (0 = none)

    private let CHO: [String]  = ["ㄱ","ㄲ","ㄴ","ㄷ","ㄸ","ㄹ","ㅁ","ㅂ","ㅃ","ㅅ","ㅆ","ㅇ","ㅈ","ㅉ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"]
    private let JUNG: [String] = ["ㅏ","ㅐ","ㅑ","ㅒ","ㅓ","ㅔ","ㅕ","ㅖ","ㅗ","ㅘ","ㅙ","ㅚ","ㅛ","ㅜ","ㅝ","ㅞ","ㅟ","ㅠ","ㅡ","ㅢ","ㅣ"]
    private let JONG: [String] = ["","ㄱ","ㄲ","ㄳ","ㄴ","ㄵ","ㄶ","ㄷ","ㄹ","ㄺ","ㄻ","ㄼ","ㄽ","ㄾ","ㄿ","ㅀ","ㅁ","ㅂ","ㅄ","ㅅ","ㅆ","ㅇ","ㅈ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"]

    // compound vowel: (base jung, added jung) → result jung
    private let CJ: [String: Int] = [
        "8,0":9, "8,1":10, "8,20":11,   // ㅗ+ㅏ=ㅘ, ㅗ+ㅐ=ㅙ, ㅗ+ㅣ=ㅚ
        "13,4":14, "13,5":15, "13,20":16, // ㅜ+ㅓ=ㅝ, ㅜ+ㅔ=ㅞ, ㅜ+ㅣ=ㅟ
        "18,20":19,                        // ㅡ+ㅣ=ㅢ
    ]
    // compound jongsung: (base jong, added key) → result jong
    private let CK: [String: Int] = [
        "1,ㅅ":3, "4,ㅈ":5, "4,ㅎ":6,
        "8,ㄱ":9, "8,ㅁ":10, "8,ㅂ":11, "8,ㅅ":12, "8,ㅌ":13, "8,ㅍ":14, "8,ㅎ":15,
        "17,ㅅ":18,
    ]
    // simple jongsung → chosung index
    private let J2C: [Int: Int] = [
        1:0, 2:1, 4:2, 7:3, 8:5, 16:6, 17:7, 19:9, 20:10, 21:11, 22:12, 23:14, 24:15, 25:16, 26:17, 27:18
    ]
    // compound jongsung → (remaining jong, new chosung index).
    //
    // Each entry maps the compound jongsung's JONG-table index to the result
    // of splitting it on a following vowel: the first element stays behind
    // as a simple jongsung, the second element becomes the new syllable's
    // chosung. Example: ㄾ (jong 13 = ㄹ+ㅌ) splits to ㄹ jong (8) + ㅌ cho
    // (16), so 됱 + ㅔ → 될 + 테.
    //
    // Off-by-one bug fix: previously `13:(8,15)` and `14:(8,16)` mapped to
    // ㅋ (15) and ㅌ (16) on the cho side — one position low because the
    // CHO list has ㅃ (index 8) interrupting the consonant order. That made
    // ㄾ split to ㄹ+ㅋ (so 됱+ㅔ rendered as 될케 instead of 될테), and
    // ㄿ split to ㄹ+ㅌ instead of ㄹ+ㅍ. Now they point to the correct cho
    // indices: ㅌ (16) and ㅍ (17).
    private let JSP: [Int: (Int, Int)] = [
        3:(1,9), 5:(4,12), 6:(4,18),
        9:(8,0), 10:(8,6), 11:(8,7), 12:(8,9), 13:(8,16), 14:(8,17), 15:(8,18),
        18:(17,9),
    ]

    // MARK: - Lifecycle

    private var isPremiumUser = false
    private var userTier = "free" // "free" | "premium" | "lifetime"
    private var canTranslateUnlimited = false
    private var premiumRefreshTimer: Timer?
    // TODO: REMOVE - 배포 전 false 유지
    static var debugForceFree: Bool = false // TODO: REMOVE
/// Throttle gate for the `textDidChange` subscription re-check. `viewWillAppear`
    /// can be skipped when iOS caches/reuses this VC across text fields, but
    /// `textDidChange` always fires on (re)connection — so we re-verify there
    /// too, at most once per 30s to avoid a per-keystroke UserDefaults read.
    private var lastPremiumCheck = Date.distantPast

    /// True while the host field is a URL/email/search-style input, for which
    /// we force the fonts tab to Normal. The user's prior style selection is
    /// stashed here and restored when they return to a normal text field —
    /// without this, browsing to Safari's address bar with `Bold` selected
    /// would silently send `𝐡𝐭𝐭𝐩𝐬://…` and break URL parsing.
    private var isPlainTextField = false
    private var savedFontCatIndex: Int?
    private var savedFontStyleIndex: Int?

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds

        if currentTheme == .vintageGray {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                for btn in self.vintageGrayKeys {
                    guard btn.superview != nil else { continue }
                    btn.layoutIfNeeded()
                    btn.layer.sublayers?
                        .filter { ["vtTop","vtLeft","vtBottom","vtRight"].contains($0.name ?? "") }
                        .forEach { $0.removeFromSuperlayer() }
                    btn.layer.cornerRadius = 6
                    btn.layer.masksToBounds = false
                    btn.contentEdgeInsets = .zero
                    // Top border — white highlight
                    let top = CALayer()
                    top.name = "vtTop"
                    top.frame = CGRect(x: 0, y: 0, width: btn.bounds.width, height: 1.5)
                    top.backgroundColor = UIColor.white.cgColor
                    btn.layer.insertSublayer(top, at: 0)
                    // Left border — white highlight
                    let left = CALayer()
                    left.name = "vtLeft"
                    left.frame = CGRect(x: 0, y: 0, width: 1.5, height: btn.bounds.height)
                    left.backgroundColor = UIColor.white.cgColor
                    btn.layer.insertSublayer(left, at: 0)
                    // Bottom border — slightly lighter dark to reduce double-line effect
                    let bottom = CALayer()
                    bottom.name = "vtBottom"
                    bottom.frame = CGRect(x: 0, y: btn.bounds.height - 1.5,
                                          width: btn.bounds.width, height: 1.5)
                    bottom.backgroundColor = UIColor(white: 0.55, alpha: 1).cgColor
                    btn.layer.insertSublayer(bottom, at: 0)
                    // Right border
                    let right = CALayer()
                    right.name = "vtRight"
                    right.frame = CGRect(x: btn.bounds.width - 1.5, y: 0,
                                         width: 1.5, height: btn.bounds.height)
                    right.backgroundColor = UIColor(white: 0.55, alpha: 1).cgColor
                    btn.layer.insertSublayer(right, at: 0)
                    // Drop shadow — softened to avoid harsh line between rows
                    btn.layer.shadowColor   = UIColor(white: 0.10, alpha: 1.0).cgColor
                    btn.layer.shadowOffset  = CGSize(width: 0, height: 3)
                    btn.layer.shadowOpacity = 0.5
                    btn.layer.shadowRadius  = 1
                    btn.layer.shadowPath    = UIBezierPath(
                        roundedRect: CGRect(x: 0, y: 0,
                                            width: btn.bounds.width,
                                            height: btn.bounds.height),
                        cornerRadius: 6).cgPath
                }
            }
        }

        if currentTheme == .bubbleMint {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                for btn in self.bubbleMintKeys {
                    guard btn.superview != nil, btn.bounds.width > 0, btn.bounds.height > 0 else { continue }

                    // 기존 그라데이션/테두리 레이어 전부 제거
                    btn.layer.sublayers?.filter { $0 is CAGradientLayer || $0 is CAShapeLayer }
                        .forEach { $0.removeFromSuperlayer() }
                    btn.layer.mask = nil
                    btn.layer.cornerRadius = 0
                    btn.layer.masksToBounds = false

                    let r = btn.bounds.height / 2
                    let path = UIBezierPath(roundedRect: btn.bounds, cornerRadius: r)

                    // 1. 그라데이션 — 자체 CAShapeLayer 마스크로 타원 클리핑
                    let gradient = CAGradientLayer()
                    gradient.frame = btn.bounds
                    gradient.colors = [
                        UIColor.white.cgColor,
                        UIColor(red: 0.75, green: 0.95, blue: 0.80, alpha: 1).cgColor,
                    ]
                    gradient.locations = [0, 1]
                    gradient.startPoint = CGPoint(x: 0.5, y: 0)
                    gradient.endPoint   = CGPoint(x: 0.5, y: 1)
                    let gradMask = CAShapeLayer()
                    gradMask.path = path.cgPath
                    gradient.mask = gradMask
                    btn.layer.insertSublayer(gradient, at: 0)

                    // 2. 테두리 — 별도 CAShapeLayer
                    let border = CAShapeLayer()
                    border.path = path.cgPath
                    border.fillColor = UIColor.clear.cgColor
                    border.strokeColor = UIColor(red: 0.55, green: 0.80, blue: 0.62, alpha: 1).cgColor
                    border.lineWidth = 1.5
                    btn.layer.addSublayer(border)

                    // 3. btn.layer.mask 없음 — 그라데이션에만 마스크 적용
                    btn.backgroundColor = .clear
                }
            }
        }

        if currentTheme == .bubbleMint && currentMode == .translate {
            print("🫧[DIAG-VDL] viewDidLayoutSubviews → applyGradient, view.frame=\(view.frame), window=\(view.window != nil)")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.applyBubbleMintGradientToTranslateLetterKeys()
            }
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("🔥 [KeyboardVC] extensionContext: \(String(describing: extensionContext))")
        print("🔥 [KeyboardVC] hasFullAccess: \(hasFullAccess)")

        // Apply gradient first so it sits at layer index 0 before any
        // subviews are added; viewDidLayoutSubviews() corrects the frame.
        applyGradientBackground()
        view.backgroundColor = keyboardBg

        // 프리미엄 체크 (App Group UserDefaults 통해 메인 앱에서 동기화)
        checkPremiumStatus()
        premiumRefreshTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            self?.checkPremiumStatus()
        }

        // Clean up stale translation-count keys from older versions (free tier
        // no longer uses per-day counting — subscription-gated instead).
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "translation_count")
        defaults.removeObject(forKey: "translation_date")
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("translation_count_") {
            defaults.removeObject(forKey: key)
        }

        setupLayout()
        showMode(.fonts)

        let kbHeight: CGFloat = (view.window?.windowScene?.screen ?? UIScreen.main).bounds.height < 700 ? 248 :
                                (view.window?.windowScene?.screen ?? UIScreen.main).bounds.height < 850 ? 295 : 308
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: kbHeight)
        heightConstraint.priority = UILayoutPriority(999)
        heightConstraint.isActive = true

        // The default tab (.fonts) is shown via showMode above, not modeTapped,
        // so its first-entry tip would never fire. Trigger it here once the
        // layout has settled. Re-show is already guarded by the per-tab
        // UserDefaults flag, so this can't double up with the modeTapped path.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            self.showTipIfNeeded(for: self.currentMode)
        }
    }

    /// `viewDidLoad` runs only once per VC instance, but iOS keeps the
    /// keyboard-extension process (and this VC) alive across show/hide
    /// cycles. Without re-checking here, a subscription that expired while
    /// the process stayed warm would never be picked up — the keyboard
    /// would stay unlocked on its stale cached `isPremiumUser`. Re-reading
    /// the App Group on every appearance closes that gap.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkPremiumStatus()
        applyPlainTextFieldGate()
    }

    /// Detect whether the connected host field is URL/email/search-style and,
    /// when entering or leaving one, snap the fonts tab to Normal (or restore
    /// the user's prior selection). The translate tab is exempted — its
    /// styling flow operates on its own UITextView, and force-resetting
    /// indices mid-translation would be unexpected. The fonts tab is the only
    /// surface that pipes styled output to the host text field, so re-rendering
    /// is gated to that mode.
    private func applyPlainTextFieldGate() {
        if currentMode == .translate { return }

        let kbType = textDocumentProxy.keyboardType
        let returnType = textDocumentProxy.returnKeyType
        let shouldForce =
            kbType == .URL ||
            kbType == .webSearch ||
            kbType == .emailAddress ||
            kbType == .numberPad ||
            returnType == .search ||
            returnType == .go ||
            returnType == .send ||
            // Belt-and-suspenders: some host apps don't set keyboardType
            // honestly but DO emit a leading zero-width space we previously
            // inserted as a marker. Treat that as a plain-text context too.
            textDocumentProxy.documentContextBeforeInput?
                .contains("\u{200B}") == true

        if shouldForce && !isPlainTextField {
            savedFontCatIndex = fontCatIndex
            savedFontStyleIndex = fontStyleIndex
            fontCatIndex = 0
            fontStyleIndex = 0
            isPlainTextField = true
            if currentMode == .fonts { showMode(.fonts) }
        } else if !shouldForce && isPlainTextField {
            if let cat = savedFontCatIndex { fontCatIndex = cat }
            if let style = savedFontStyleIndex { fontStyleIndex = style }
            savedFontCatIndex = nil
            savedFontStyleIndex = nil
            isPlainTextField = false
            if currentMode == .fonts { showMode(.fonts) }
        }
    }

    /// Persist the translate-tab state (langs / input / result) so closing
    /// and reopening the keyboard — or the extension process being recycled —
    /// doesn't lose the user's in-progress translation.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveTranslateState()
        premiumRefreshTimer?.invalidate()
        premiumRefreshTimer = nil
    }

    /// Host-app text changes — including external clears we didn't cause.
    /// When the document drops to empty (e.g. Flutter chat's send button
    /// fires `_input.clear()` after a tap), reset both Hangul and cheonjiin
    /// engines so the next jamo doesn't compose against ghost state from
    /// the just-sent syllable. This is cheap (no-op when buffers are
    /// already empty) and runs on every text change.
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        let current = textDocumentProxy.documentContextBeforeInput ?? ""
        if current.isEmpty {
            hgFlush()
            cjjReset()
        }
        // Throttled subscription re-check — covers the case where iOS reused
        // this cached VC for a new text field and skipped `viewWillAppear`.
        // 30s gate keeps this off the per-keystroke hot path.
        if Date().timeIntervalSince(lastPremiumCheck) > 30 {
            lastPremiumCheck = Date()
            checkPremiumStatus()
        }
        // Catch field-type changes when iOS reuses this VC across text fields
        // and skips `viewWillAppear`. The gate is cheap when state matches.
        applyPlainTextFieldGate()
    }

    /// Device-branched keyboard height — single source of truth used by
    /// viewDidLoad (view.heightAnchor) and by each build method (container height).
    private var kbHeight: CGFloat {
        (view.window?.windowScene?.screen ?? UIScreen.main).bounds.height < 700 ? 248 :
        (view.window?.windowScene?.screen ?? UIScreen.main).bounds.height < 850 ? 295 : 308
    }

    /// contentView height available to each tab builder — keyboard height minus
    /// view insets(4+3), modeBar(36), and mainStack spacing(4) = 47pt chrome.
    private var tabContainerHeight: CGFloat { kbHeight - 47 }

    // MARK: - Layout

    private func setupLayout() {
        // Mode bar
        modeBar.axis = .horizontal
        modeBar.distribution = .fillEqually
        modeBar.spacing = 4
        let modeOrder: [Mode] = [
            .fonts, .translate, .textTemplate, .emoticon, .special, .gif, .dotArt, .favorites, .palette,
            // 비활성화 탭 (순서 복구 시 위 배열로 이동):
            .calculator,
        ]
        for mode in modeOrder {
            // MARK: - 계산기 탭 비활성화 (복구 시 주석 해제)
            if mode == .calculator { continue }
            let btn = makeModeButton(mode)
            modeBar.addArrangedSubview(btn)
        }

        // Main stack
        mainStack = UIStackView(arrangedSubviews: [modeBar, contentView])
        mainStack.axis = .vertical
        mainStack.spacing = 4
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 3),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -3),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -3),
            modeBar.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    // MARK: - Mode Switching

    private func showMode(_ mode: Mode) {
        // Leaving the Aa tab while the Korean composer has buffered jamos
        // would strand that state — the next time the user comes back, the
        // first tap would unexpectedly extend the old syllable. Flush at the
        // tab boundary; intra-fonts rebuilds (style tap, shift tap, lang
        // toggle) hit `mode == .fonts` and skip this.
        // Any genuine tab change flushes the Hangul / cheonjiin buffers.
        // Previously this was gated on `currentMode == .fonts && isFontsKorean`,
        // which missed the translate→other-tab path (translate Korean mode
        // also writes to hgCho/hgJung/hgJong via the same engine). In-tab
        // rebuilds — style pill tap, shift tap, language toggle — all call
        // `showMode(currentMode)` so `currentMode != mode` skips them.
        // Genuine entry INTO the translate tab from another tab (or fresh
        // keyboard open). Captured before `currentMode` is overwritten below.
        // Restore must be gated on this — running it on every
        // `buildTranslateMode` (including intra-tab rebuilds triggered by the
        // language dropdown / swap / direct-input toggle) would clobber the
        // user's just-made selection with the stale App Group snapshot.
        let enteringTranslate = (currentMode != mode && mode == .translate)

        if currentMode != mode {
            hgFlush()
            cjjReset()
            // Leaving the translate tab — persist its state now so a later
            // return (this session or next keyboard open) restores the most
            // recent input/result, not a stale snapshot.
            if currentMode == .translate {
                saveTranslateState()
            }
        }
        currentMode = mode
        updateModeBar()
        clearContent()

        // Restore persisted translate state ONLY on a genuine tab entry, and
        // before `buildTranslateMode` builds the language buttons (which read
        // `sourceLangIndex`/`targetLangIndex`).
        if enteringTranslate {
            restoreTranslateState()
        }

        // Subscriber gate: any non-translate tab renders the in-keyboard lock
        // view for free-tier users. Translate has its own toast at modeTapped
        // (it distinguishes lifetime from free with a more specific message),
        // Both premium and premium_lifetime have `isPremiumUser == true` and pass through.
        // Exception: textTemplate at My List category (index 0) is free for all users.
        print("🔥 [showMode] mode=\(mode) isPremiumUser=\(isPremiumUser)")
        if mode != .translate && !isPremiumUser {
            let isTextTemplate = (mode == .textTemplate)  // per-item gating inside the list
            let isFontsMode = (mode == .fonts)            // per-font gating in styleTapped/fontPanelStyleTapped
            let isGifMode = (mode == .gif)                // per-tap 5/day free quota in gifCellTapped
            let isPartialFree = (mode == .emoticon || mode == .special || mode == .dotArt)  // first N items free per category
            let isFavorites = (mode == .favorites)        // fully free
            let isPalette = (mode == .palette)            // settings popup — fully free
            if !isTextTemplate && !isFontsMode && !isGifMode && !isPartialFree && !isFavorites && !isPalette {
                showLockedOverlay()
                return
            }
        }

        switch mode {
        case .fonts:     buildFontsMode()
        case .emoticon:  buildGridMode(categories: emoticonCategories,
                                       selected: selectedEmoticonCat,
                                       cols: 4, fontSize: 14,
                                       onCatChange: { [weak self] i in
                                           self?.selectedEmoticonCat = i
                                           self?.showMode(.emoticon)
                                       },
                                       scrollTag: 100,
                                       fullBottomBar: true,
                                       freeCount: isPremiumUser ? 4 : 0)
        case .special:   buildGridMode(categories: specialCategories,
                                       selected: selectedSpecialCat,
                                       cols: 4, fontSize: 22,
                                       onCatChange: { [weak self] i in
                                           self?.selectedSpecialCat = i
                                           self?.showMode(.special)
                                       },
                                       scrollTag: 200,
                                       freeCount: isPremiumUser ? 6 : 0)
        case .dotArt:    buildDotArtMode()
        case .gif:       buildGifMode()
        case .translate: buildTranslateMode()
        case .favorites: buildFavoritesMode()
        case .textTemplate: buildTextTemplateMode()
        case .calculator: buildCalculatorMode()
        case .palette:    break  // popup-based; modeTapped redirects
        }
    }

    private func clearContent() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        letterKeys.removeAll()
        vintageGrayKeys.removeAll()
        bubbleMintKeys.removeAll()
        translationFieldView?.removeFromSuperview()
        translationFieldView = nil
    }

    /// Full-bleed lock view shown in place of the requested tab when a
    /// non-subscriber lands on a gated mode. Tapping the CTA bounces to the
    private static let translateSettingsBtnTag = 9902

    @objc private func showLockedOverlay() {
        view.subviews.filter { $0.tag == 9999 }.forEach { $0.removeFromSuperview() }

        let overlay = UIView(frame: view.bounds)
        overlay.tag = 9999
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlay.isUserInteractionEnabled = true
        view.addSubview(overlay)

        let dimTap = UITapGestureRecognizer(target: self, action: #selector(dismissLockedOverlay))
        dimTap.cancelsTouchesInView = false
        overlay.addGestureRecognizer(dimTap)

        // ── 카드 크기 계산 ──────────────────────────────────────────────────
        let cardWidth = view.bounds.width * 0.72
        let hPad: CGFloat = 24
        let textWidth = cardWidth - hPad * 2

        // Title text omits its own 👑 — the standalone crown icon above
        // already covers that, so an inline one would just double up.
        let isKo = Locale.current.languageCode == "ko"
        let titleText = isKo
            ? "프리미엄 전용 기능이에요"
            : "This is a Premium-only feature"
        let guidanceText = isKo
            ? "앱에서 일주일 무료 체험을 시작해보세요!"
            : "Start your 1-week free trial in the app!"

        let titleFont = UIFont.boldSystemFont(ofSize: 16)
        let guidanceFont = UIFont.systemFont(ofSize: 14, weight: .medium)

        func textHeight(_ text: String, font: UIFont) -> CGFloat {
            ceil((text as NSString).boundingRect(
                with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            ).height)
        }
        let titleH = textHeight(titleText, font: titleFont)
        let guidanceH = textHeight(guidanceText, font: guidanceFont)

        let crownY: CGFloat = 16
        let crownH: CGFloat = 52
        let titleY    = crownY + crownH + 10
        let guidanceY = titleY + titleH + 8
        let cardH     = guidanceY + guidanceH + 20

        let cardX = (overlay.bounds.width  - cardWidth) / 2
        let cardY = (overlay.bounds.height - cardH) / 2

        // ── 카드 ────────────────────────────────────────────────────────────
        let card = UIView(frame: CGRect(x: cardX, y: cardY, width: cardWidth, height: cardH))
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.layer.masksToBounds = false
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.12
        card.layer.shadowRadius = 12
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.isUserInteractionEnabled = true
        overlay.addSubview(card)

        // 카드 탭 제스처 (이벤트 소비용 — dimTap이 card 영역에서 닫히지 않도록)
        let cardTap = UITapGestureRecognizer(target: nil, action: nil)
        cardTap.cancelsTouchesInView = false
        card.addGestureRecognizer(cardTap)

        // ── 닫기 버튼 ────────────────────────────────────────────────────────
        let closeBtn = UIButton(type: .system)
        closeBtn.frame = CGRect(x: cardWidth - 40, y: 8, width: 32, height: 32)
        closeBtn.setTitle("✕", for: .normal)
        closeBtn.titleLabel?.font = .systemFont(ofSize: 18)
        closeBtn.setTitleColor(UIColor(white: 0.5, alpha: 1), for: .normal)
        closeBtn.addTarget(self, action: #selector(dismissLockedOverlay), for: .touchUpInside)
        card.addSubview(closeBtn)

        // ── 왕관 ─────────────────────────────────────────────────────────────
        let crownLabel = UILabel(frame: CGRect(x: hPad, y: crownY, width: textWidth, height: crownH))
        crownLabel.text = "👑"
        crownLabel.font = .systemFont(ofSize: 32)
        crownLabel.textAlignment = .center
        card.addSubview(crownLabel)

        // ── 제목 ─────────────────────────────────────────────────────────────
        let titleLabel = UILabel(frame: CGRect(x: hPad, y: titleY, width: textWidth, height: titleH))
        titleLabel.text = titleText
        titleLabel.font = titleFont
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        card.addSubview(titleLabel)

        // ── 안내 ─────────────────────────────────────────────────────────────
        let guidanceLabel = UILabel(frame: CGRect(x: hPad, y: guidanceY, width: textWidth, height: guidanceH))
        guidanceLabel.text = guidanceText
        guidanceLabel.font = guidanceFont
        guidanceLabel.textAlignment = .center
        guidanceLabel.numberOfLines = 0
        guidanceLabel.textColor = UIColor(white: 0.35, alpha: 1)
        card.addSubview(guidanceLabel)
    }

    @objc private func dismissLockedOverlay() {
        view.subviews.filter { $0.tag == 9999 }.forEach { $0.removeFromSuperview() }
        showMode(currentMode)
    }

    @objc func openPaywallApp() {
        print("🔥 [Keyboard] openPaywallApp() called")
        // Persist flag so the host app can navigate on next resume — same
        // App Group pattern as `myListAddTapped`'s `open_my_list` write.
        // This is the safety net: `checkPendingAppGroupFlags()` in
        // AppDelegate picks it up on `applicationDidBecomeActive`, so the
        // moment the user opens Fonkii themselves, the paywall shows —
        // independent of whether the ctx.open() below succeeds.
        let defaults = UserDefaults(suiteName: Self.favAppGroup)
        defaults?.set(true, forKey: "open_paywall")
        defaults?.synchronize()

        guard let url = URL(string: "fonkii://paywall") else { return }
        let isKo = Locale.current.language.languageCode?.identifier == "ko"

        // extensionContext.open() — public API, requires Full Access. Still
        // worth trying (works on some devices/iOS versions), but keyboard
        // extensions can't reliably auto-launch the host app, so a failure
        // just falls through to the toast telling the user to open it
        // themselves — the App Group flag above takes it from there.
        if let ctx = extensionContext {
            ctx.open(url) { [weak self] success in
                print("🔥 [Keyboard] extensionContext.open result: \(success)")
                if !success {
                    DispatchQueue.main.async {
                        self?.showToast(isKo ? "Fonkii 앱을 열면 구독할 수 있어요" : "Open the Fonkii app to subscribe")
                    }
                }
            }
        } else {
            showToast(isKo ? "Fonkii 앱을 열면 구독할 수 있어요" : "Open the Fonkii app to subscribe")
        }
    }

    // MARK: - Mode Bar

    private func makeModeButton(_ mode: Mode) -> UIButton {
        let btn = UIButton(type: .system)
        if mode == .calculator {
            let config = UIImage.SymbolConfiguration(pointSize: mode.fontSize, weight: .semibold)
            let img = UIImage(systemName: "plusminus.circle", withConfiguration: config)
                   ?? UIImage(systemName: "multiply.square", withConfiguration: config)
            btn.setImage(img, for: .normal)
        } else if mode == .palette {
            // Palette tab now hosts a generic settings popup (Korean input
            // mode + accent color), so it shows a gear icon instead of the
            // old paintpalette glyph. The mode enum stays `.palette` to
            // avoid renaming all call sites; only the user-visible icon
            // changed.
            let config = UIImage.SymbolConfiguration(pointSize: mode.fontSize, weight: .semibold)
            btn.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: config), for: .normal)
        } else {
            btn.setTitle(mode.title, for: .normal)
        }
        btn.titleLabel?.font = .systemFont(ofSize: mode.fontSize, weight: .semibold)
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.titleLabel?.minimumScaleFactor = 0.6
        btn.tag = mode.rawValue
        btn.layer.cornerRadius = 8
        btn.addTarget(self, action: #selector(modeTapped(_:)), for: .touchUpInside)
        return btn
    }

    private func updateModeBar() {
        let unselectedColor: UIColor = currentTheme == .hotPink ? .white : .darkGray
        for case let btn as UIButton in modeBar.arrangedSubviews {
            let sel = btn.tag == currentMode.rawValue
            btn.backgroundColor = sel ? accentColor : .clear
            btn.setTitleColor(sel ? selectedCatTextColor : unselectedColor, for: .normal)
            if btn.tag == Mode.calculator.rawValue || btn.tag == Mode.palette.rawValue {
                btn.tintColor = sel ? .white : unselectedColor
            }
        }
    }

    @objc private func modeTapped(_ s: UIButton) {
        let mode = Mode(rawValue: s.tag) ?? .fonts

        // Refresh subscription state on every tab switch — not just the
        // translate/palette taps below. Previously fonts/emoticon/special/
        // gif/favorites/etc. relied purely on the cached `isPremiumUser`
        // from viewDidLoad, so an expired subscription wouldn't re-lock
        // those tabs until the process was killed. The translate/palette
        // branches keep their own `checkPremiumStatus()` calls (harmless
        // redundancy — already-fresh values).
        checkPremiumStatus()

        // Translate keeps its own messaging (distinguishes lifetime from free).
        // Trial users have isPremiumUser=true but canTranslateUnlimited=false
        // — they must reach `translateTriggered` so the 30/day counter applies,
        // so we gate on tier/membership here, not on the unlimited flag.
        // Hard paywall gating for the free tier lives in `translateTriggered`
        // (the action), NOT here — a tab-entry guard that calls
        // showLockedOverlay() gets re-triggered every time
        // dismissLockedOverlay() rebuilds the tab via showMode(currentMode),
        // recreating the overlay forever (the bug fixed in My List/favorites).
        if mode == .translate {
            checkPremiumStatus()
            if userTier == "lifetime" {
                showToast(loc("toast_translate_monthly"))
                return
            }
            showMode(mode)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showTipIfNeeded(for: .translate)
            }
            return
        }

        if mode == .palette {
            checkPremiumStatus()
            showPalettePicker()
            return
        }

        // MARK: - 계산기 탭 비활성화 (복구 시 주석 해제)
        // if mode == .calculator { return }

        showMode(mode)
        // Defer so showMode finishes building before the tip overlays it —
        // otherwise the first entry into a tab can swallow the popup. Tip is
        // a no-op for non-fonts/gif modes and once the per-tab flag is set,
        // so calling it unconditionally here is safe.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showTipIfNeeded(for: mode)
        }
    }

    // MARK: - Accent Color Palette

    private static let paletteColors: [UIColor] = [
        UIColor(red: 1.0,  green: 0.42, blue: 0.62, alpha: 1.0), // 핑크 (기본)
        UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0), // 블랙
        UIColor(red: 1.0,  green: 0.18, blue: 0.18, alpha: 1.0), // 레드
        UIColor(red: 0.0,  green: 0.60, blue: 1.0,  alpha: 1.0), // 블루
        UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0), // 그린
        UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1.0), // 퍼플
    ]

    /// RGB-component equality check (UIColor identity is unstable across
    /// archive/unarchive so direct == doesn't help).
    private func colorsEqual(_ a: UIColor, _ b: UIColor) -> Bool {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let tol: CGFloat = 0.015
        return abs(ar - br) < tol && abs(ag - bg) < tol && abs(ab - bb) < tol
    }

    @objc private func showPalettePicker() {
        // Refresh premium status so 👑 badges reflect the latest subscription state.
        checkPremiumStatus()
        // Custom (non-`makePopupStack`) popup so we can make it wider than the
        // default 220pt and lay out two columns side-by-side. Goal: fit
        // everything on one screen within the keypad area — no scrolling.
        //
        //   ┌───────────────────────────────────────┐
        //   │ 한글 입력 방식                          │
        //   │ [두벌식]    [천지인]                    │
        //   ├──────────┬────────────────────────────┤
        //   │ 포인트   │ ● ● ● ● ● ●                │
        //   │  컬러    │ R [────────]               │
        //   │          │ G [────────]               │
        //   │          │ B [────────]               │
        //   └──────────┴────────────────────────────┘
        let overlay = makeOverlay()

        let popup = UIView()
        popup.backgroundColor = .white
        popup.layer.cornerRadius = 14
        popup.layer.shadowColor = UIColor.black.cgColor
        popup.layer.shadowOpacity = 0.2
        popup.layer.shadowRadius = 10
        popup.layer.masksToBounds = false
        popup.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(popup)
        // 70% of the device screen height; overlay constraints cap it further
        // to keyboard view bounds when the keyboard is shorter.
        let maxPopupH = (view.window?.bounds.height ?? UIScreen.main.bounds.height) * 0.70
        NSLayoutConstraint.activate([
            popup.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            popup.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            popup.widthAnchor.constraint(equalToConstant: 340),
            popup.heightAnchor.constraint(lessThanOrEqualToConstant: maxPopupH),
            popup.topAnchor.constraint(greaterThanOrEqualTo: overlay.topAnchor, constant: 8),
            popup.bottomAnchor.constraint(lessThanOrEqualTo: overlay.bottomAnchor, constant: -8),
        ])

        // ScrollView fills the popup; cornerRadius clips scrolled content.
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.layer.cornerRadius = 14
        scrollView.layer.masksToBounds = true
        popup.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: popup.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: popup.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: popup.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: popup.bottomAnchor),
        ])

        let outer = UIStackView()
        outer.axis = .vertical
        outer.spacing = 8
        outer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(outer)
        // Soft: popup grows to fit content. Yields to the required lessThanOrEqual /
        // greaterThanOrEqual overlay constraints when content exceeds keyboard height.
        let fitHeight = popup.heightAnchor.constraint(equalTo: outer.heightAnchor, constant: 24)
        fitHeight.priority = UILayoutPriority(749)
        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            outer.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 14),
            outer.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -14),
            outer.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -12),
            // Prevents horizontal scroll — outer fills the scroll view's visible width.
            outer.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -28),
            fitHeight,
        ])

        // ── Top: 한글 입력 방식 (full width) ────────────────────────────
        let inputHeader = UILabel()
        inputHeader.text = loc("settings_korean_input")
        inputHeader.font = .systemFont(ofSize: 13, weight: .semibold)
        inputHeader.textColor = .darkGray
        inputHeader.heightAnchor.constraint(equalToConstant: 18).isActive = true
        outer.addArrangedSubview(inputHeader)

        let inputRow = UIStackView()
        inputRow.axis = .horizontal
        inputRow.spacing = 10
        inputRow.distribution = .fillEqually
        inputRow.heightAnchor.constraint(equalToConstant: 32).isActive = true
        let modes: [(label: String, value: String)] = [
            (loc("keyboard_standard"), "dubeolsik"),
            (loc("keyboard_cheonjiin"), "cheonjiin"),
        ]
        for (label, value) in modes {
            let btn = UIButton(type: .system)
            btn.setTitle(label, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            btn.layer.cornerRadius = 12
            btn.layer.borderWidth = 1
            let isSel = koreanInputMode == value
            btn.backgroundColor = isSel ? accentColor : UIColor(white: 0.96, alpha: 1)
            btn.setTitleColor(isSel ? selectedCatTextColor : .darkGray, for: .normal)
            btn.layer.borderColor = (isSel ? accentColor : UIColor(white: 0.85, alpha: 1)).cgColor
            btn.addAction(UIAction { [weak self, weak overlay] _ in
                guard let self = self else { return }
                if self.koreanInputMode == value { return }
                self.koreanInputMode = value
                self.hgFlush()
                self.cjjReset()
                overlay?.removeFromSuperview()
                self.showMode(self.currentMode)
                self.showPalettePicker()
            }, for: .touchUpInside)
            inputRow.addArrangedSubview(btn)
        }
        outer.addArrangedSubview(inputRow)

        let divider1 = UIView()
        divider1.backgroundColor = UIColor(white: 0.9, alpha: 1)
        divider1.heightAnchor.constraint(equalToConstant: 1).isActive = true
        outer.addArrangedSubview(divider1)

        // ── Theme picker (2×2 grid) ─────────────────────────────────────
        let themeHeader = UILabel()
        themeHeader.text = loc("settings_theme")
        themeHeader.font = .systemFont(ofSize: 13, weight: .semibold)
        themeHeader.textColor = .darkGray
        themeHeader.heightAnchor.constraint(equalToConstant: 18).isActive = true
        outer.addArrangedSubview(themeHeader)

        let themes: [(label: String, theme: KeyboardTheme)] = [
            (loc("theme_default"),        .default),
            (loc("theme_cotton_candy"),   .cottonCandy),
            (loc("theme_lavender"),       .lavender),
            (loc("theme_pastel_rainbow"), .pastelRainbow),
            (loc("theme_soft"),           .soft),
            (loc("theme_bubble_mint"),    .bubbleMint),
            (loc("theme_retro_cream"),    .retroCream),
            (loc("theme_vintage_gray"),   .vintageGray),
            (loc("theme_hot_pink"),       .hotPink),
        ]
        let freeThemes: Set<KeyboardTheme> = [.default, .cottonCandy]
        func makeThemeButton(_ label: String, _ theme: KeyboardTheme) -> UIButton {
            let isPremiumTheme = !freeThemes.contains(theme)
            let btn = UIButton(type: .system)
            btn.setTitle(isPremiumTheme && !isPremiumUser ? "\(label) 👑" : label, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
            btn.titleLabel?.adjustsFontSizeToFitWidth = true
            btn.titleLabel?.minimumScaleFactor = 0.7
            btn.layer.cornerRadius = 12
            btn.layer.borderWidth = 1
            let isSel = currentTheme == theme
            btn.backgroundColor = isSel ? accentColor : UIColor(white: 0.96, alpha: 1)
            btn.setTitleColor(isSel ? selectedCatTextColor : .darkGray, for: .normal)
            btn.layer.borderColor = (isSel ? accentColor : UIColor(white: 0.85, alpha: 1)).cgColor
            btn.addAction(UIAction { [weak self, weak overlay] _ in
                guard let self = self else { return }
                if isPremiumTheme && !self.isPremiumUser {
                    overlay?.removeFromSuperview()
                    self.showLockedOverlay()
                    return
                }
                if self.currentTheme == theme { return }
                self.currentTheme = theme
                overlay?.removeFromSuperview()
                self.showPalettePicker()
            }, for: .touchUpInside)
            return btn
        }
        let themeGrid = UIStackView()
        themeGrid.axis = .vertical
        themeGrid.spacing = 6
        for row in stride(from: 0, to: themes.count, by: 2) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            rowStack.distribution = .fillEqually
            rowStack.heightAnchor.constraint(equalToConstant: 32).isActive = true
            for i in row..<min(row + 2, themes.count) {
                rowStack.addArrangedSubview(makeThemeButton(themes[i].label, themes[i].theme))
            }
            themeGrid.addArrangedSubview(rowStack)
        }
        outer.addArrangedSubview(themeGrid)

        let divider = UIView()
        divider.backgroundColor = UIColor(white: 0.9, alpha: 1)
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        outer.addArrangedSubview(divider)

        // ── Bottom: 2-col split ─────────────────────────────────────────
        // Left = "포인트 컬러" label (narrow), right = swatches + sliders.
        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = 10
        bottom.alignment = .center

        let leftLabel = UILabel()
        leftLabel.text = loc("settings_point_color")
        leftLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        leftLabel.textColor = .darkGray
        leftLabel.textAlignment = .center
        leftLabel.numberOfLines = 2
        leftLabel.widthAnchor.constraint(equalToConstant: 70).isActive = true
        bottom.addArrangedSubview(leftLabel)

        let rightCol = UIStackView()
        rightCol.axis = .vertical
        rightCol.spacing = 6

        // Preset swatches — single row of 6 (was 3×2) to keep the popup short.
        let swatchRow = UIStackView()
        swatchRow.axis = .horizontal
        swatchRow.spacing = 6
        swatchRow.distribution = .fillEqually
        swatchRow.heightAnchor.constraint(equalToConstant: 30).isActive = true
        for color in Self.paletteColors {
            let isSel = colorsEqual(color, accentColor)
            let btn = UIButton(type: .system)
            btn.backgroundColor = color
            btn.layer.cornerRadius = 15
            btn.layer.masksToBounds = true
            if isSel {
                let cfg = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
                btn.setImage(UIImage(systemName: "checkmark", withConfiguration: cfg), for: .normal)
                btn.tintColor = .white
            }
            btn.addAction(UIAction { [weak self, weak overlay] _ in
                self?.accentColor = color
                overlay?.removeFromSuperview()
            }, for: .touchUpInside)
            swatchRow.addArrangedSubview(btn)
        }
        rightCol.addArrangedSubview(swatchRow)

        // RGB sliders — compact (28pt rows). Live preview piggybacks the
        // selected preset's check-image: we update the leftLabel's textColor
        // to the staged color so the user gets visual feedback without an
        // extra preview circle (saves vertical space).
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        accentColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        let rSlider = UISlider(); rSlider.minimumValue = 0; rSlider.maximumValue = 255
        rSlider.value = Float(r * 255); rSlider.minimumTrackTintColor = .systemRed
        let gSlider = UISlider(); gSlider.minimumValue = 0; gSlider.maximumValue = 255
        gSlider.value = Float(g * 255); gSlider.minimumTrackTintColor = .systemGreen
        let bSlider = UISlider(); bSlider.minimumValue = 0; bSlider.maximumValue = 255
        bSlider.value = Float(b * 255); bSlider.minimumTrackTintColor = .systemBlue

        // Live preview — repaint the left-column "포인트 컬러" text in the
        // staged color so the user sees the slider drag effect without
        // needing an extra preview circle. Commit (accentColor setter →
        // showMode rebuild) only happens on popup dismiss, so dragging
        // sliders stays cheap.
        let valueChanged = UIAction { [weak rSlider, weak gSlider, weak bSlider, weak leftLabel] _ in
            guard let rs = rSlider, let gs = gSlider, let bs = bSlider, let lbl = leftLabel else { return }
            lbl.textColor = UIColor(
                red: CGFloat(rs.value) / 255,
                green: CGFloat(gs.value) / 255,
                blue: CGFloat(bs.value) / 255,
                alpha: 1)
        }
        rSlider.addAction(valueChanged, for: .valueChanged)
        gSlider.addAction(valueChanged, for: .valueChanged)
        bSlider.addAction(valueChanged, for: .valueChanged)

        rightCol.addArrangedSubview(makePaletteSliderRow("R", slider: rSlider))
        rightCol.addArrangedSubview(makePaletteSliderRow("G", slider: gSlider))
        rightCol.addArrangedSubview(makePaletteSliderRow("B", slider: bSlider))

        bottom.addArrangedSubview(rightCol)
        outer.addArrangedSubview(bottom)

        // Replace overlay's default tap-dismiss with one that commits the
        // staged RGB color to accentColor BEFORE removing the overlay —
        // single showMode rebuild per popup session.
        overlay.gestureRecognizers?.forEach { overlay.removeGestureRecognizer($0) }
        let dismissTap = UITapGestureRecognizer(target: nil, action: nil)
        dismissTap.addTarget(self, action: #selector(paletteOverlayTapped(_:)))
        overlay.addGestureRecognizer(dismissTap)

        pendingPaletteOverlay = overlay
        pendingRSlider = rSlider
        pendingGSlider = gSlider
        pendingBSlider = bSlider
    }

    private weak var pendingPaletteOverlay: UIView?
    private weak var pendingRSlider: UISlider?
    private weak var pendingGSlider: UISlider?
    private weak var pendingBSlider: UISlider?

    @objc private func paletteOverlayTapped(_ g: UITapGestureRecognizer) {
        // If user adjusted any RGB slider, commit that staged color now.
        if let rs = pendingRSlider, let gs = pendingGSlider, let bs = pendingBSlider {
            var cr: CGFloat = 0, cg: CGFloat = 0, cb: CGFloat = 0, ca: CGFloat = 0
            accentColor.getRed(&cr, green: &cg, blue: &cb, alpha: &ca)
            let stagedR = CGFloat(rs.value) / 255
            let stagedG = CGFloat(gs.value) / 255
            let stagedB = CGFloat(bs.value) / 255
            let tol: CGFloat = 0.005
            if abs(stagedR - cr) > tol || abs(stagedG - cg) > tol || abs(stagedB - cb) > tol {
                accentColor = UIColor(red: stagedR, green: stagedG, blue: stagedB, alpha: 1)
            }
        }
        pendingPaletteOverlay?.removeFromSuperview()
        pendingPaletteOverlay = nil
        pendingRSlider = nil
        pendingGSlider = nil
        pendingBSlider = nil
    }

    private func makePaletteSliderRow(_ label: String, slider: UISlider) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 32).isActive = true
        let lab = UILabel()
        lab.text = label
        lab.font = .systemFont(ofSize: 12, weight: .semibold)
        lab.textColor = .darkGray
        lab.widthAnchor.constraint(equalToConstant: 16).isActive = true
        row.addArrangedSubview(lab)
        row.addArrangedSubview(slider)
        return row
    }

    // MARK: - Fonts Mode (QWERTY + Style Picker)

    private let numberRowsPage1: [[String]] = [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["-","/",":",";","(",")","₩","&","@","\""],
        [".",",","?","!","'"]  // row 3: 5 char keys flanked by #+=/⌫ added at runtime
    ]
    private let numberRowsPage2: [[String]] = [
        ["[","]","{","}","#","%","^","*","+","="],
        ["_","\\","|","~","<",">","$","£","¥","•"],
        [".",",","?","!","'"]  // row 3: 5 char keys flanked by 123/⌫ added at runtime
    ]

    private func buildFontsMode() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        contentView.heightAnchor.constraint(equalToConstant: tabContainerHeight).isActive = true
        // Drop the previous build's bottom-bar HC ref so a stale (dead-view)
        // constraint doesn't get re-used in the next picker-toggle resize.
        fontsBottomBarHeightConstraint = nil

        let stack = UIStackView()
        stack.axis = .vertical
        // spacing 4→3: absorbs the +4pt net growth from the row-height
        // redistribution below (letter rows 52→56, bottom bar 52→44 → +12-8
        // = +4pt). The 4 visible inter-row gaps × 1pt = -4pt brings the
        // total back to the original kbHeight budget. Number-mode and
        // cheonjiin paths share this stack, so they lose ~4pt / 1pt of gap
        // respectively — visually negligible and well within the
        // 999-priority view height envelope.
        stack.spacing = 3
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        pinToEdges(stack, in: contentView)

        // ── Font picker: single-row collapsed / expanded (+ toggle) ──
        let visibleCats = visibleFontCategories()
        let safeCatIndex = min(fontCatIndex, max(visibleCats.count - 1, 0))

        // Style row (always visible) + toggle button on the right
        let pickerRow = UIStackView()
        pickerRow.axis = .horizontal
        pickerRow.spacing = 4
        pickerRow.alignment = .center
        pickerRow.translatesAutoresizingMaskIntoConstraints = false
        pickerRow.heightAnchor.constraint(equalToConstant: 36).isActive = true

        let styleScroll = FontScrollView()
        styleScroll.showsHorizontalScrollIndicator = false
        styleScroll.delaysContentTouches = false
        styleScroll.canCancelContentTouches = true
        styleScroll.delegate = self
        fontStyleScrollView = styleScroll
        let styleRow = UIStackView()
        styleRow.axis = .horizontal; styleRow.spacing = 8
        styleRow.translatesAutoresizingMaskIntoConstraints = false
        styleScroll.addSubview(styleRow)
        NSLayoutConstraint.activate([
            styleRow.topAnchor.constraint(equalTo: styleScroll.topAnchor),
            styleRow.leadingAnchor.constraint(equalTo: styleScroll.leadingAnchor, constant: 6),
            styleRow.trailingAnchor.constraint(equalTo: styleScroll.trailingAnchor, constant: -6),
            styleRow.bottomAnchor.constraint(equalTo: styleScroll.bottomAnchor),
            styleRow.heightAnchor.constraint(equalTo: styleScroll.heightAnchor),
        ])
        let styles = visibleCats.isEmpty ? [] : visibleCats[safeCatIndex].1
        for (i, style) in styles.enumerated() {
            let isLocked = !isPremiumUser && !effectiveFreeFontNames.contains(style.name)
            let btn = UIButton(type: .system)
            btn.setTitle(displayFontName(style) + (isLocked ? " 👑" : ""), for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            btn.titleLabel?.adjustsFontSizeToFitWidth = true
            btn.titleLabel?.minimumScaleFactor = 0.6
            btn.tag = i
            btn.layer.cornerRadius = 16
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            let sel = selectedFontStyleName.map { $0 == style.name } ?? false
            btn.backgroundColor = sel ? accentColor : UIColor(white: 0.92, alpha: 1)
            let styleTextColor: UIColor = sel ? selectedCatTextColor
                : (isLocked ? UIColor(white: 0.75, alpha: 1) : .darkGray)
            btn.setTitleColor(styleTextColor, for: .normal)
            btn.tintColor = styleTextColor
            if isFavoriteFont(style.name) {
                btn.layer.borderWidth = 1.5
                btn.layer.borderColor = accentColor.cgColor
            }
            btn.isExclusiveTouch = false
            btn.addTarget(self, action: #selector(styleTapped(_:)), for: .touchUpInside)
            let lp = UILongPressGestureRecognizer(
                target: self, action: #selector(fontStyleLongPressed(_:)))
            lp.minimumPressDuration = 0.5
            btn.addGestureRecognizer(lp)
            styleRow.addArrangedSubview(btn)
        }

        let toggleBtn = UIButton(type: .system)
        toggleBtn.setTitle(fontPickerExpanded ? "▲" : "▼", for: .normal)
        toggleBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        toggleBtn.setTitleColor(.darkGray, for: .normal)
        toggleBtn.backgroundColor = UIColor(white: 0.94, alpha: 1)
        toggleBtn.layer.cornerRadius = 14
        toggleBtn.widthAnchor.constraint(equalToConstant: 36).isActive = true
        toggleBtn.heightAnchor.constraint(equalToConstant: 28).isActive = true
        toggleBtn.addTarget(self, action: #selector(fontPickerToggleTapped), for: .touchUpInside)
        fontToggleButton = toggleBtn

        pickerRow.addArrangedSubview(styleScroll)
        pickerRow.addArrangedSubview(toggleBtn)
        stack.addArrangedSubview(pickerRow)
        fontPickerRowView = pickerRow

        // Restore scroll offset after layout
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let sv = self.fontStyleScrollView else { return }
            sv.setContentOffset(self.savedFontScrollOffset, animated: false)
        }

        if isNumberMode {
            // Number/symbol rows — row 3 has [page toggle] + [5 char keys] + [⌫]
            // mirroring the iOS native symbols keyboard layout.
            //
            // Rows live in a `numberWrapper` structurally identical to the
            // QWERTY/dubeolsik `lettersWrapper`: `.fillEqually`, 174pt tall,
            // so the 3 rows evenly split to 56pt each and completely fill the
            // wrapper — no leftover gap above the bottom bar. The shared
            // bottom bar below stays the SAME height across all fonts-tab
            // modes because every wrapper is 174pt.
            let numberWrapper = UIStackView()
            numberWrapper.axis = .vertical
            numberWrapper.distribution = .fillEqually
            numberWrapper.spacing = 3
            let numberWrapperH = numberWrapper.heightAnchor.constraint(equalToConstant: 3 * 56 + 2 * 3)
            numberWrapperH.priority = UILayoutPriority(999)
            numberWrapperH.isActive = true

            let pageRows = isSymbolPage2 ? numberRowsPage2 : numberRowsPage1
            for (ri, row) in pageRows.enumerated() {
                let rowStack = UIStackView()
                rowStack.axis = .horizontal
                rowStack.distribution = .fillEqually
                rowStack.spacing = 4
                // No per-row heightAnchor — numberWrapper's .fillEqually
                // divides its 174pt height evenly across the 3 rows.

                if ri == 2 {
                    let pageToggle = makeSpecialKey(isSymbolPage2 ? "123" : "#+=")
                    pageToggle.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
                    pageToggle.addTarget(self, action: #selector(toggleSymbolPage), for: .touchUpInside)
                    rowStack.addArrangedSubview(pageToggle)
                }

                for key in row {
                    let btn = makeLetterKey(key)
                    btn.addTarget(self, action: #selector(letterTapped(_:)), for: .touchDown)
                    rowStack.addArrangedSubview(btn)
                    letterKeys.append(btn)
                }

                if ri == 2 {
                    let del = makeSpecialKey("⌫")
                    del.addTarget(self, action: #selector(backspaceTapped), for: .touchDown)
                    attachBackspaceLongPress(to: del)
                    rowStack.addArrangedSubview(del)
                }

                numberWrapper.addArrangedSubview(rowStack)
            }
            stack.addArrangedSubview(numberWrapper)
        } else if isFontsKorean && koreanInputMode == "cheonjiin" {
            // 천지인 12-key layout — see `buildCheonjiinKeypadRows` /
            // `handleCheonjiinTap`. Each tap synthesizes a 두벌식 jamo and
            // forwards to `handleHangulInput` so the existing syllable
            // composer still does its job.
            buildCheonjiinKeypadRows(into: stack)
        } else if isFontsKorean {
            // 한글 두벌식 layout — same row structure as QWERTY (3 rows, ⇧/⌫
            // on row 3) so SHIFT and BACKSPACE behavior carries over for free.
            // Jamo taps route through `letterTapped`, which on this branch
            // diverts into the same Hangul composition engine the translate
            // tab uses (`handleHangulInput`/`handleHangulDelete`/`hgFlush`)
            // so taps build syllables (ㅇ + ㅏ + ㄴ → 안). The composer
            // appends/replaces directly via `textDocumentProxy`; font
            // conversion isn't applied to composed syllables (Hangul is
            // outside the math alphanumeric blocks most styles target, so
            // the visible result matches what the old per-jamo path produced
            // — minus the no-composition defect).
            let korN: [[String]] = [
                ["ㅂ","ㅈ","ㄷ","ㄱ","ㅅ","ㅛ","ㅕ","ㅑ","ㅐ","ㅔ"],
                ["ㅁ","ㄴ","ㅇ","ㄹ","ㅎ","ㅗ","ㅓ","ㅏ","ㅣ"],
                ["ㅋ","ㅌ","ㅊ","ㅍ","ㅠ","ㅜ","ㅡ"]
            ]
            // Shift swaps the basic consonants for their tense counterparts
            // and ㅐ/ㅔ for ㅒ/ㅖ — bottom row stays the same (no shifted
            // form for those jamos in 두벌식).
            let korS: [[String]] = [
                ["ㅃ","ㅉ","ㄸ","ㄲ","ㅆ","ㅛ","ㅕ","ㅑ","ㅒ","ㅖ"],
                ["ㅁ","ㄴ","ㅇ","ㄹ","ㅎ","ㅗ","ㅓ","ㅏ","ㅣ"],
                ["ㅋ","ㅌ","ㅊ","ㅍ","ㅠ","ㅜ","ㅡ"]
            ]
            let shifted = isShifted || isCapsLock
            let rows = shifted ? korS : korN
            // Wrap rows 1-3 in a `.fillEqually` vertical stack — guarantees
            // uniform row heights regardless of any slack/overflow at the
            // outer stack level (a previous build relied on per-row
            // heightAnchors which UIKit would arbitrarily break under
            // budget pressure, producing the "only row 3 grew" symptom).
            let lettersWrapper = UIStackView()
            lettersWrapper.axis = .vertical
            lettersWrapper.distribution = .fillEqually
            lettersWrapper.spacing = 3
            let lettersWrapperH = lettersWrapper.heightAnchor.constraint(equalToConstant: 3 * 56 + 2 * 3)
            lettersWrapperH.priority = UILayoutPriority(999)
            lettersWrapperH.isActive = true
            for (ri, row) in rows.enumerated() {
                let rowStack = UIStackView()
                rowStack.axis = .horizontal
                rowStack.distribution = .fillEqually
                rowStack.spacing = 4
                // No per-row heightAnchor — lettersWrapper's .fillEqually
                // divides its height across the 3 rows evenly.

                if ri == 2 {
                    let shift = makeSpecialKey("⇧")
                    shift.addTarget(self, action: #selector(shiftTapped), for: .touchDown)
                    if isCapsLock {
                        shift.backgroundColor = accentColor
                        shift.setTitle("", for: .normal)
                        let capsConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
                        shift.setImage(UIImage(systemName: "capslock.fill", withConfiguration: capsConfig), for: .normal)
                        shift.tintColor = .white
                    } else if isShifted {
                        shift.backgroundColor = accentColor
                        shift.setTitleColor(.white, for: .normal)
                    }
                    rowStack.addArrangedSubview(shift)
                }

                for key in row {
                    // Hangul jamos pass through `letterTapped`'s `.uppercased()`
                    // path harmlessly — uppercasing a non-cased Unicode scalar
                    // is a no-op, so the original "ㅂ"/"ㅃ" reaches the font
                    // converter as-is.
                    let btn = makeLetterKey(key)
                    btn.titleLabel?.font = .systemFont(ofSize: 22)
                    btn.addTarget(self, action: #selector(letterTapped(_:)), for: .touchDown)
                    rowStack.addArrangedSubview(btn)
                    letterKeys.append(btn)
                }

                if ri == 2 {
                    let del = makeSpecialKey("⌫")
                    del.addTarget(self, action: #selector(backspaceTapped), for: .touchDown)
                    attachBackspaceLongPress(to: del)
                    rowStack.addArrangedSubview(del)
                }

                lettersWrapper.addArrangedSubview(rowStack)
            }
            stack.addArrangedSubview(lettersWrapper)
        } else {
            // QWERTY rows — wrapped in `.fillEqually` vertical lettersWrapper
            // for guaranteed-uniform row heights (same fix as the 두벌식
            // branch above).
            let lettersWrapper = UIStackView()
            lettersWrapper.axis = .vertical
            lettersWrapper.distribution = .fillEqually
            lettersWrapper.spacing = 3
            let lettersWrapperH = lettersWrapper.heightAnchor.constraint(equalToConstant: 3 * 56 + 2 * 3)
            lettersWrapperH.priority = UILayoutPriority(999)
            lettersWrapperH.isActive = true
            for (ri, row) in qwertyRows.enumerated() {
                let rowStack = UIStackView()
                rowStack.axis = .horizontal
                rowStack.distribution = .fillEqually
                rowStack.spacing = 4
                // No per-row heightAnchor — lettersWrapper.fillEqually
                // divides the wrapper height evenly across rows.

                if ri == 2 {
                    let shift = makeSpecialKey("⇧")
                    shift.addTarget(self, action: #selector(shiftTapped), for: .touchDown)
                    if isCapsLock {
                        shift.backgroundColor = accentColor
                        shift.setTitle("", for: .normal)
                        let capsConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
                        shift.setImage(UIImage(systemName: "capslock.fill", withConfiguration: capsConfig), for: .normal)
                        shift.tintColor = .white
                    } else if isShifted {
                        shift.backgroundColor = accentColor
                        shift.setTitleColor(.white, for: .normal)
                    }
                    rowStack.addArrangedSubview(shift)
                }

                for key in row {
                    let label = isShifted ? key.uppercased() : key
                    let btn = makeLetterKey(label)
                    btn.addTarget(self, action: #selector(letterTapped(_:)), for: .touchDown)
                    rowStack.addArrangedSubview(btn)
                    letterKeys.append(btn)
                }

                if ri == 2 {
                    let del = makeSpecialKey("⌫")
                    del.addTarget(self, action: #selector(backspaceTapped), for: .touchDown)
                    attachBackspaceLongPress(to: del)
                    rowStack.addArrangedSubview(del)
                }
                lettersWrapper.addArrangedSubview(rowStack)
            }
            stack.addArrangedSubview(lettersWrapper)
        }

        // Bottom row: 한/영 + 123/ABC + space + 완료.
        // 천지인 ships its own bottom row (!#1 / 한/영 / ㅇㅁ / space / , )
        // inside `buildCheonjiinKeypadRows`, so we skip this standard bar
        // when that layout is active — otherwise the user would see two
        // 한/영 toggles stacked.
        if isFontsKorean && koreanInputMode == "cheonjiin" && !isNumberMode {
            return
        }

        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = 4
        // Dynamic height — shrinks when the font category bar is expanded
        // so the picker's catScroll (+36pt) can fit without overflowing the
        // kbHeight budget. Priority 750 (< required 1000) lets UIKit further
        // compress this bar under tight conditions before reaching for the
        // letter rows above (which are wrapped in `.fillEqually` and stay
        // uniform). The constraint is stashed in `fontsBottomBarHeightConstraint`
        // so `fontPickerToggleTapped` can update its constant in-place.
        let bottomHC = bottom.heightAnchor.constraint(equalToConstant: computedFontsBottomBarHeight())
        bottomHC.priority = UILayoutPriority(750)
        bottomHC.isActive = true
        fontsBottomBarHeightConstraint = bottomHC

        let langToggle = makeSpecialKey(isFontsKorean ? "En" : "Ko")
        langToggle.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        // In number mode the 한/영 key serves a different role: it exits the
        // number/symbol page back to the previous letter layout (preserving
        // language) since the dedicated `ABC` toggle is removed from the
        // number-mode bottom bar. In letter mode it keeps its normal
        // language-toggle semantics.
        let langSelector: Selector = isNumberMode
            ? #selector(exitNumberModeBackToLetters)
            : #selector(fontLangToggleTapped)
        langToggle.addTarget(self, action: langSelector, for: .touchUpInside)
        langToggle.setWidth(50)
        // Mark the active language with the accent fill so the user can tell
        // at a glance which layout the keypad above is rendering.
        langToggle.backgroundColor = accentColor
        langToggle.setTitleColor(.white, for: .normal)
        if currentTheme == .cottonCandy {
            langToggle.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 1)
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .lavender {
            langToggle.backgroundColor = UIColor(red: 0.80, green: 0.70, blue: 0.95, alpha: 1)
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .pastelRainbow {
            langToggle.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .hotPink {
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .soft {
            langToggle.backgroundColor = UIColor(red: 0.97, green: 0.90, blue: 0.93, alpha: 1)
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .bubbleMint {
            langToggle.backgroundColor = UIColor(red: 0.95, green: 0.85, blue: 0.90, alpha: 1)
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .retroCream {
            langToggle.setTitleColor(.black, for: .normal)
            if isFontsKorean {
                langToggle.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
            }
        }
        if currentTheme == .vintageGray {
            langToggle.backgroundColor = specialKeyBG
            langToggle.setTitleColor(.black, for: .normal)
        }
        bottom.addArrangedSubview(langToggle)

        // 123/ABC toggle — only shown when in letter mode (to enter the
        // number page). In number mode the user exits via the 한/영 key
        // above, so the toggle is omitted entirely from the bottom bar.
        if !isNumberMode {
            let toggleKey = makeSpecialKey("123")
            toggleKey.addTarget(self, action: #selector(toggleNumberMode), for: .touchUpInside)
            toggleKey.setWidth(44)
            bottom.addArrangedSubview(toggleKey)
        }

        let space = makeLetterKey("space")
        space.titleLabel?.font = .systemFont(ofSize: 14)
        space.addTarget(self, action: #selector(spaceTapped), for: .touchDown)
        bottom.addArrangedSubview(space)

        let done = makeSpecialKey("")
        done.setTitle("", for: .normal)
        let returnImage = UIImage(systemName: "return", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
        done.setImage(returnImage, for: .normal)
        done.backgroundColor = currentTheme == .retroCream
            ? UIColor(red: 0.98, green: 0.75, blue: 0.80, alpha: 1)
            : specialKeyBG
        done.tintColor = .black
        done.setTitleColor(.black, for: .normal)
        done.addTarget(self, action: #selector(returnTapped), for: .touchDown)
        done.setWidth(50)
        bottom.addArrangedSubview(done)

        stack.addArrangedSubview(bottom)
    }

    /// Aa-tab 한/영 toggle. Forces `isNumberMode = false` so the user lands
    /// on the new layout's letter rows instead of a stale digit page.
    /// `isShifted`/`isCapsLock` carry over so an active SHIFT keeps modifying
    /// the new layout (Korean ⇧ shows tense consonants instead of caps).
    @objc private func fontLangToggleTapped() {
        // Commit any in-flight Hangul syllable before swapping layouts —
        // otherwise the buffered cho/jung would silently combine with the
        // next non-Korean tap (or get bulldozed by an English keystroke).
        // Also reset the cheonjiin cycle so a stale buffer doesn't leak
        // into the next 한글 entry session.
        hgFlush()
        cjjReset()
        isFontsKorean.toggle()
        isNumberMode = false
        isSymbolPage2 = false
        showMode(.fonts)
    }

    // MARK: - Grid Mode (Emoticon / Special)

    private func buildGridMode(categories: [(String, [String])],
                               selected: Int, cols: Int, fontSize: CGFloat,
                               onCatChange: @escaping (Int) -> Void,
                               scrollTag: Int = 0,
                               fullBottomBar: Bool = false,
                               freeCount: Int = Int.max) {
        contentView.subviews.forEach { $0.removeFromSuperview() }

        // Use manual layout instead of outer stack to avoid scrollView collapsing
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        pinToEdges(container, in: contentView)
        container.heightAnchor.constraint(equalToConstant: tabContainerHeight).isActive = true

        // Category tabs (horizontal scroll)
        let catScroll = UIScrollView()
        catScroll.showsHorizontalScrollIndicator = false
        catScroll.translatesAutoresizingMaskIntoConstraints = false
        catScroll.tag = scrollTag
        catScroll.delegate = self
        container.addSubview(catScroll)

        // Store reference
        if scrollTag == 100 { emoticonCatScrollView = catScroll }
        else if scrollTag == 200 { specialCatScrollView = catScroll }

        let catRow = UIStackView()
        catRow.axis = .horizontal
        catRow.spacing = 6
        catRow.translatesAutoresizingMaskIntoConstraints = false
        catScroll.addSubview(catRow)
        NSLayoutConstraint.activate([
            catRow.topAnchor.constraint(equalTo: catScroll.topAnchor),
            catRow.leadingAnchor.constraint(equalTo: catScroll.leadingAnchor, constant: 4),
            catRow.trailingAnchor.constraint(equalTo: catScroll.trailingAnchor, constant: -4),
            catRow.bottomAnchor.constraint(equalTo: catScroll.bottomAnchor),
            catRow.heightAnchor.constraint(equalTo: catScroll.heightAnchor),
        ])

        for (i, cat) in categories.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(cat.0, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            btn.layer.cornerRadius = 14
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)
            let sel = i == selected
            btn.backgroundColor = sel ? accentColor : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? selectedCatTextColor : .darkGray, for: .normal)
            btn.tag = i
            btn.addAction(UIAction { _ in onCatChange(i) }, for: .touchUpInside)
            catRow.addArrangedSubview(btn)
        }

        // Restore category scroll offset after layout
        DispatchQueue.main.async {
            if scrollTag == 100 {
                catScroll.setContentOffset(self.savedEmoticonCatOffset, animated: false)
            } else if scrollTag == 200 {
                catScroll.setContentOffset(self.savedSpecialCatOffset, animated: false)
            }
        }

        // Bottom delete bar removed per spec — emoticon/kaomoji/special tabs
        // no longer carry a ⌫ bar. The grid scroll view extends straight to
        // the container bottom.

        // Grid scroll view — pinned between catScroll and the container bottom
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            catScroll.topAnchor.constraint(equalTo: container.topAnchor),
            catScroll.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            catScroll.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            catScroll.heightAnchor.constraint(equalToConstant: 32),

            scrollView.topAnchor.constraint(equalTo: catScroll.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 6
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(gridStack)
        NSLayoutConstraint.activate([
            gridStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 4),
            gridStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            gridStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            gridStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -4),
            gridStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        // Detect special categories: "도트아트" (1-col, tall fixed), "큰 이모티콘" (1-col, auto-height)
        let categoryName = categories[selected].0
        let isDotArt = categoryName == "도트아트"
        let isBigEmoticon = categoryName == "큰 이모티콘"
        let actualCols = (isDotArt || isBigEmoticon) ? 1 : cols
        let cellHeight: CGFloat = isDotArt ? 130 : 44
        gridStack.spacing = isBigEmoticon ? 8 : 6

        let items = categories[selected].1
        let chunked = stride(from: 0, to: items.count, by: actualCols).map {
            Array(items[$0..<min($0 + actualCols, items.count)])
        }

        for (rowIdx, row) in chunked.enumerated() {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 5
            if isBigEmoticon {
                rowStack.isLayoutMarginsRelativeArrangement = true
                rowStack.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            }
            for (colIdx, item) in row.enumerated() {
                let itemIdx = rowIdx * actualCols + colIdx
                let isLocked = !isPremiumUser && itemIdx >= freeCount
                let btn = UIButton(type: .system)
                btn.setTitle(item, for: .normal)
                btn.tag = itemIdx
                if isDotArt {
                    btn.titleLabel?.font = .monospacedSystemFont(ofSize: 9, weight: .regular)
                    btn.titleLabel?.numberOfLines = 0
                    btn.titleLabel?.textAlignment = .center
                    btn.titleLabel?.lineBreakMode = .byWordWrapping
                    btn.titleLabel?.adjustsFontSizeToFitWidth = true
                    btn.titleLabel?.minimumScaleFactor = 0.5
                } else if isBigEmoticon {
                    btn.titleLabel?.font = .systemFont(ofSize: fontSize)
                    btn.titleLabel?.numberOfLines = 0
                    btn.titleLabel?.textAlignment = .center
                    btn.titleLabel?.lineBreakMode = .byWordWrapping
                    btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
                } else {
                    btn.titleLabel?.font = .systemFont(ofSize: fontSize)
                    btn.titleLabel?.adjustsFontSizeToFitWidth = true
                    btn.titleLabel?.minimumScaleFactor = 0.4
                }
                btn.backgroundColor = .white
                btn.layer.cornerRadius = 8
                btn.layer.borderWidth = 0.5
                btn.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
                btn.setTitleColor(isLocked ? UIColor.systemGray3 : .darkGray, for: .normal)
                btn.alpha = isLocked ? 0.45 : 1.0
                if !isBigEmoticon {
                    btn.setHeight(cellHeight)
                }
                btn.addTarget(self, action: #selector(gridItemTapped(_:)), for: .touchUpInside)
                let longPress = UILongPressGestureRecognizer(target: self, action: #selector(gridItemLongPressed(_:)))
                longPress.minimumPressDuration = 0.5
                btn.addGestureRecognizer(longPress)
                rowStack.addArrangedSubview(btn)
            }
            // Fill empty cells
            for _ in 0..<(actualCols - row.count) { rowStack.addArrangedSubview(UIView()) }
            gridStack.addArrangedSubview(rowStack)
        }
    }

    // MARK: - Dot Art Mode (가로 스크롤)

    private func buildDotArtMode() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        pinToEdges(container, in: contentView)

        // Bottom delete bar removed per spec — the scroll view extends
        // straight to the container bottom.

        // Vertical scroll view filling the whole tab.
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        // 3-column grid inside scroll view — square cards via 1:1 aspect ratio.
        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 4
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(gridStack)
        NSLayoutConstraint.activate([
            gridStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 4),
            gridStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 4),
            gridStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -4),
            gridStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -4),
            gridStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -8),
        ])

        let items = dotArtCategories.first?.1 ?? []
        let cols = 3
        let chunked = stride(from: 0, to: items.count, by: cols).map {
            Array(items[$0..<min($0 + cols, items.count)])
        }
        for (rowIdx, row) in chunked.enumerated() {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 4
            for (colIdx, text) in row.enumerated() {
                let globalIdx = rowIdx * cols + colIdx
                let isLocked = !isPremiumUser && globalIdx >= (isPremiumUser ? 5 : 0)
                let btn = UIButton(type: .custom)
                btn.tag = globalIdx
                btn.backgroundColor = .white
                btn.layer.cornerRadius = 8
                btn.layer.borderWidth = 0.8
                btn.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.4).cgColor
                btn.clipsToBounds = true
                btn.heightAnchor.constraint(equalTo: btn.widthAnchor).isActive = true
                btn.addTarget(self, action: #selector(dotArtTapped(_:)), for: .touchUpInside)
                let lp = UILongPressGestureRecognizer(target: self, action: #selector(dotArtLongPressed(_:)))
                lp.minimumPressDuration = 0.5
                btn.addGestureRecognizer(lp)

                // Dot art content (always shown — locked items are dimmed but visible)
                let cardPadding: CGFloat = 8
                let labelFont = UIFont(name: "Menlo", size: 4) ?? UIFont.monospacedSystemFont(ofSize: 4, weight: .regular)
                let label = UILabel()
                label.text = text
                label.font = labelFont
                label.textColor = isLocked ? .systemGray3 : .black
                label.numberOfLines = 0
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.5
                label.lineBreakMode = .byClipping
                label.contentMode = .scaleAspectFit
                label.textAlignment = .center
                label.isUserInteractionEnabled = false
                label.translatesAutoresizingMaskIntoConstraints = false
                btn.addSubview(label)
                NSLayoutConstraint.activate([
                    label.topAnchor.constraint(equalTo: btn.topAnchor, constant: cardPadding),
                    label.leadingAnchor.constraint(equalTo: btn.leadingAnchor, constant: cardPadding),
                    label.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -cardPadding),
                    label.bottomAnchor.constraint(equalTo: btn.bottomAnchor, constant: -cardPadding),
                ])

                if isLocked {
                    let crownLabel = UILabel()
                    crownLabel.text = "👑"
                    crownLabel.font = .systemFont(ofSize: 14)
                    crownLabel.textAlignment = .center
                    crownLabel.isUserInteractionEnabled = false
                    crownLabel.translatesAutoresizingMaskIntoConstraints = false
                    btn.addSubview(crownLabel)
                    NSLayoutConstraint.activate([
                        crownLabel.topAnchor.constraint(equalTo: btn.topAnchor, constant: 4),
                        crownLabel.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -4),
                    ])
                }

                rowStack.addArrangedSubview(btn)
            }
            // Pad the last partial row with invisible spacers so remaining cells
            // still respect fillEqually widths.
            for _ in 0..<(cols - row.count) {
                rowStack.addArrangedSubview(UIView())
            }
            gridStack.addArrangedSubview(rowStack)
        }
    }

    // MARK: - Text Template Mode

    private func buildTextTemplateMode() {
        fandomItemOutputs.removeAll()
        let safeCat = min(fandomCatIndex, max(fandomCategories.count - 1, 0))
        let extBundle = Bundle(for: type(of: self))

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        pinToEdges(container, in: contentView)

        // ── Category tab bar ──
        let catScroll = UIScrollView()
        catScroll.showsHorizontalScrollIndicator = false
        catScroll.translatesAutoresizingMaskIntoConstraints = false
        catScroll.delegate = self
        fandomCatScrollView = catScroll
        container.addSubview(catScroll)

        let catRow = UIStackView()
        catRow.axis = .horizontal
        catRow.spacing = 8
        catRow.translatesAutoresizingMaskIntoConstraints = false
        catScroll.addSubview(catRow)
        NSLayoutConstraint.activate([
            catRow.topAnchor.constraint(equalTo: catScroll.topAnchor),
            catRow.leadingAnchor.constraint(equalTo: catScroll.leadingAnchor, constant: 8),
            catRow.trailingAnchor.constraint(equalTo: catScroll.trailingAnchor, constant: -8),
            catRow.bottomAnchor.constraint(equalTo: catScroll.bottomAnchor),
            catRow.heightAnchor.constraint(equalTo: catScroll.heightAnchor),
        ])
        for (i, cat) in fandomCategories.enumerated() {
            let btn = UIButton(type: .system)
            let catTitleKey = "text_replace_\(cat.title.lowercased())"
            let catTitle = NSLocalizedString(catTitleKey, bundle: extBundle, comment: "")
            btn.setTitle(catTitle, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            btn.tag = i
            btn.layer.cornerRadius = 14
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)
            let sel = i == safeCat
            btn.backgroundColor = sel ? accentColor : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? selectedCatTextColor : .darkGray, for: .normal)
            btn.addTarget(self, action: #selector(fandomCatTapped(_:)), for: .touchUpInside)
            catRow.addArrangedSubview(btn)
        }

        NSLayoutConstraint.activate([
            catScroll.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            catScroll.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            catScroll.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            catScroll.heightAnchor.constraint(equalToConstant: 34),
        ])

        // Restore scroll position after layout so the selected tab stays visible.
        DispatchQueue.main.async {
            catScroll.setContentOffset(self.savedFandomCatOffset, animated: false)
        }

        let selectedCat = fandomCategories[safeCat]

        // ── My List branch ──────────────────────────────────────────────────
        if selectedCat.sections.isEmpty {
            // Hard paywall: My List is premium-only, but gated per-item (tap
            // → showLockedOverlay) rather than at tab entry — a full-tab
            // guard here would call showLockedOverlay() from inside
            // buildTextTemplateMode(), which dismissLockedOverlay() re-enters
            // via `showMode(currentMode)`, recreating the same overlay forever.
            let addBtn = UIButton(type: .system)
            addBtn.setTitle(NSLocalizedString("text_replace_add", bundle: extBundle, comment: "") + (isPremiumUser ? "" : " 👑"), for: .normal)
            addBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            addBtn.backgroundColor = accentColor
            addBtn.setTitleColor(.white, for: .normal)
            addBtn.layer.cornerRadius = 10
            addBtn.translatesAutoresizingMaskIntoConstraints = false
            addBtn.isUserInteractionEnabled = true
            container.addSubview(addBtn)
            addBtn.addTarget(self, action: #selector(myListAddTapped), for: .touchUpInside)

            let listScroll = UIScrollView()
            listScroll.alwaysBounceVertical = true
            listScroll.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(listScroll)

            NSLayoutConstraint.activate([
                addBtn.topAnchor.constraint(equalTo: catScroll.bottomAnchor, constant: 6),
                addBtn.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
                addBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
                addBtn.heightAnchor.constraint(equalToConstant: 36),

                listScroll.topAnchor.constraint(equalTo: addBtn.bottomAnchor, constant: 6),
                listScroll.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                listScroll.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                listScroll.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])

            let vStack = UIStackView()
            vStack.axis = .vertical
            vStack.spacing = 5
            vStack.translatesAutoresizingMaskIntoConstraints = false
            listScroll.addSubview(vStack)
            NSLayoutConstraint.activate([
                vStack.topAnchor.constraint(equalTo: listScroll.contentLayoutGuide.topAnchor, constant: 4),
                vStack.leadingAnchor.constraint(equalTo: listScroll.contentLayoutGuide.leadingAnchor, constant: 8),
                vStack.trailingAnchor.constraint(equalTo: listScroll.contentLayoutGuide.trailingAnchor, constant: -8),
                vStack.bottomAnchor.constraint(equalTo: listScroll.contentLayoutGuide.bottomAnchor, constant: -4),
                vStack.widthAnchor.constraint(equalTo: listScroll.frameLayoutGuide.widthAnchor, constant: -16),
            ])

            let phrases = loadFavList(Self.myPhrasesKey)
            for (idx, phrase) in phrases.enumerated() {
                let isLocked = !isPremiumUser
                let btn = UIButton(type: .system)
                btn.tag = idx
                btn.setTitle(phrase + (isLocked ? " 👑" : ""), for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 14)
                btn.titleLabel?.lineBreakMode = .byTruncatingTail
                btn.contentHorizontalAlignment = .left
                btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
                btn.backgroundColor = .white
                btn.setTitleColor(isLocked ? UIColor.systemGray3 : .darkGray, for: .normal)
                btn.alpha = isLocked ? 0.6 : 1.0
                btn.layer.cornerRadius = 8
                btn.layer.borderWidth = 0.5
                btn.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
                btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
                btn.addTarget(self, action: #selector(myListItemTapped(_:)), for: .touchUpInside)
                let lp = UILongPressGestureRecognizer(target: self, action: #selector(myListItemLongPressed(_:)))
                lp.minimumPressDuration = 0.5
                btn.addGestureRecognizer(lp)
                vStack.addArrangedSubview(btn)
            }
            return
        }

        // ── EN | KO toggle (hidden for single-section categories) ───────────
        let hasToggle = selectedCat.sections.count > 1
        let toggleRow = UIStackView()
        toggleRow.axis = .horizontal
        toggleRow.spacing = 6
        toggleRow.distribution = .fillEqually
        let sectionTitleKey = !hasToggle ? selectedCat.sections.first?.titleKey : nil
        toggleRow.isHidden = !hasToggle && sectionTitleKey == nil
        toggleRow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(toggleRow)

        if hasToggle {
            for (i, langKey) in ["text_replace_en", "text_replace_ko"].enumerated() {
                let btn = UIButton(type: .system)
                btn.setTitle(NSLocalizedString(langKey, bundle: extBundle, comment: ""), for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
                btn.tag = i  // 0=EN, 1=KO
                btn.layer.cornerRadius = 12
                let sel = (i == 0) == fandomLangIsEN
                btn.backgroundColor = sel ? accentColor : UIColor(white: 0.92, alpha: 1)
                btn.setTitleColor(sel ? selectedCatTextColor : .darkGray, for: .normal)
                btn.addTarget(self, action: #selector(fandomLangToggled(_:)), for: .touchUpInside)
                toggleRow.addArrangedSubview(btn)
            }
        } else if let key = sectionTitleKey {
            // Single-section category with a display title — show as non-interactive label
            let label = UILabel()
            label.text = NSLocalizedString(key, bundle: extBundle, comment: "")
            label.font = .systemFont(ofSize: 13, weight: .semibold)
            label.textColor = .darkGray
            label.textAlignment = .center
            label.backgroundColor = UIColor(white: 0.92, alpha: 1)
            label.layer.cornerRadius = 12
            label.clipsToBounds = true
            toggleRow.addArrangedSubview(label)
        }

        // ── Item list scroll ──
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)

        let toggleHeight: CGFloat = (hasToggle || sectionTitleKey != nil) ? 30 : 0
        let toggleSpacing: CGFloat = (hasToggle || sectionTitleKey != nil) ? 6 : 0
        NSLayoutConstraint.activate([
            toggleRow.topAnchor.constraint(equalTo: catScroll.bottomAnchor, constant: toggleSpacing),
            toggleRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            toggleRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            toggleRow.heightAnchor.constraint(equalToConstant: toggleHeight),

            scrollView.topAnchor.constraint(equalTo: toggleRow.bottomAnchor, constant: toggleSpacing),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 5
        vStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
            vStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 8),
            vStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -8),
            vStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -4),
            vStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -16),
        ])

        let cat = fandomCategories[safeCat]
        let sectionIndex = fandomLangIsEN ? 0 : 1
        let safeSection = min(sectionIndex, cat.sections.count - 1)
        let items = safeSection >= 0 ? cat.sections[safeSection].items : []

        for (idx, item) in items.enumerated() {
            let isLocked = !isPremiumUser && idx >= (isPremiumUser ? 3 : 0)
            let btn = UIButton(type: .system)
            btn.tag = idx
            fandomItemOutputs[idx] = item.output
            let displayText: String
            if let key = item.labelKey {
                displayText = NSLocalizedString(key, bundle: extBundle, comment: "")
            } else {
                displayText = item.output
            }
            btn.setTitle(displayText + (isLocked ? " 👑" : ""), for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 14)
            btn.titleLabel?.lineBreakMode = .byTruncatingTail
            btn.contentHorizontalAlignment = .left
            btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            btn.backgroundColor = .white
            btn.setTitleColor(isLocked ? UIColor.systemGray3 : .darkGray, for: .normal)
            btn.alpha = isLocked ? 0.6 : 1.0
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth = 0.5
            btn.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
            btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
            btn.addTarget(self, action: #selector(fandomItemTapped(_:)), for: .touchUpInside)
            let lp = UILongPressGestureRecognizer(target: self, action: #selector(fandomItemLongPressed(_:)))
            lp.minimumPressDuration = 0.5
            btn.addGestureRecognizer(lp)
            vStack.addArrangedSubview(btn)
        }
    }

    @objc private func fandomCatTapped(_ s: UIButton) {
        fandomCatIndex = s.tag
        showMode(.textTemplate)
    }

    @objc private func fandomLangToggled(_ s: UIButton) {
        fandomLangIsEN = (s.tag == 0)
        showMode(.textTemplate)
    }

    @objc private func fandomItemTapped(_ s: UIButton) {
        print("🔥 [fandomItemTapped] tag=\(s.tag) isPremiumUser=\(isPremiumUser)")
        if !isPremiumUser && s.tag >= (isPremiumUser ? 3 : 0) {
            showLockedOverlay()
            return
        }
        guard let output = fandomItemOutputs[s.tag] else { return }
        textDocumentProxy.insertText(output)
        UIView.animate(withDuration: 0.06, animations: {
            s.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            s.backgroundColor = self.accentColor.withAlphaComponent(0.15)
        }) { _ in
            UIView.animate(withDuration: 0.06) {
                s.transform = .identity
                s.backgroundColor = .white
            }
        }
    }

    @objc private func myListAddTapped() {
        guard isPremiumUser else {
            showLockedOverlay()
            return
        }
        let isKo = Locale.current.language.languageCode?.identifier == "ko"

        // Path 1: host app has a text selection — save it directly, no need
        // to ever leave the extension. Reuses the same App Group storage
        // (`myPhrasesKey`) and list-refresh (`showMode(.textTemplate)`) as
        // every other My List write.
        if let selected = textDocumentProxy.selectedText, !selected.isEmpty {
            let trimmed = selected.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            guard trimmed.count <= 200 else {
                showToast(isKo ? "선택한 텍스트가 너무 길어요 (200자 이하)" : "Selected text is too long (max 200 characters)")
                return
            }
            var list = loadFavList(Self.myPhrasesKey)
            if list.contains(trimmed) {
                showToast(isKo ? "이미 목록에 있어요" : "Already in your list")
                return
            }
            list.insert(trimmed, at: 0)
            saveFavList(Self.myPhrasesKey, list)
            showToast(isKo ? "내 목록에 저장했어요!" : "Saved to My List!")
            showMode(.textTemplate)
            return
        }

        // Path 2: nothing selected — fall back to opening the app. Persist
        // flag so the host app can navigate on next resume — the safety
        // net: `checkPendingAppGroupFlags()` in AppDelegate picks it up on
        // `applicationDidBecomeActive`, so the moment the user opens Fonkii
        // themselves, AddPhraseScreen shows — independent of whether the
        // ctx.open() below succeeds.
        let defaults = UserDefaults(suiteName: Self.favAppGroup)
        defaults?.set(true, forKey: "open_my_list")
        defaults?.synchronize()

        // extensionContext.open() — public API, requires Full Access. Still
        // worth trying (works on some devices/iOS versions), but keyboard
        // extensions can't reliably auto-launch the host app, so a failure
        // just falls through to the toast telling the user to select text
        // or open the app themselves — the App Group flag above takes it
        // from there.
        if let ctx = extensionContext, let url = URL(string: "fonkii://myList") {
            ctx.open(url) { [weak self] success in
                print("🔗 [myList] ctx exists: \(self?.extensionContext != nil), open success: \(success)")
                if !success {
                    DispatchQueue.main.async {
                        self?.showToast(isKo ? "텍스트를 선택하거나, Fonkii 앱에서 추가해보세요" : "Select text, or add phrases in the Fonkii app")
                    }
                }
            }
        } else {
            showToast(isKo ? "텍스트를 선택하거나, Fonkii 앱에서 추가해보세요" : "Select text, or add phrases in the Fonkii app")
        }
    }

    @objc private func myListItemTapped(_ s: UIButton) {
        guard isPremiumUser else {
            showLockedOverlay()
            return
        }
        let phrases = loadFavList(Self.myPhrasesKey)
        guard s.tag < phrases.count else { return }
        textDocumentProxy.insertText(phrases[s.tag])
    }

    @objc private func myListItemLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard let btn = gesture.view as? UIButton else { return }
        let phrases = loadFavList(Self.myPhrasesKey)
        guard btn.tag < phrases.count else { return }
        let text = phrases[btn.tag]
        let overlay = makeOverlay()
        let stack = makePopupStack(in: overlay)

        // Favorite toggle — shares `favKeyTextReplace` with the preset
        // category's `fandomItemLongPressed`/`showAddPopup`, so a My List
        // phrase favorited here shows up in the same ❤️ tab section
        // alongside preset favorites. `addFavorite` already guards against
        // duplicates (`toast_fav_exists`), so the "add" side reuses it as-is.
        // The "remove" side can't reuse `removeFavorite` directly — it always
        // ends with `showMode(.favorites)`, which would yank the user out of
        // 💬 over to the ❤️ tab just for un-favoriting a My List phrase. So
        // this mirrors its list-mutation logic but rebuilds `.textTemplate`
        // instead, keeping the user on the tab they were already on.
        let isFav = loadFavList(Self.favKeyTextReplace).contains(text)
        stack.addArrangedSubview(makePopupButton(
            title: loc(isFav ? "fav_delete" : "fav_add"),
            color: UIColor(red: 0.90, green: 0.20, blue: 0.40, alpha: 1)) {
            overlay.removeFromSuperview()
            if isFav {
                var favs = self.loadFavList(Self.favKeyTextReplace)
                favs.removeAll { $0 == text }
                self.saveFavList(Self.favKeyTextReplace, favs)
                self.showToast(self.loc("favorite_removed"))
                self.showMode(.textTemplate)
            } else {
                self.addFavorite(text, key: Self.favKeyTextReplace)
            }
        })

        stack.addArrangedSubview(makePopupButton(
            title: loc("text_replace_delete_yes"), color: .systemRed) {
            overlay.removeFromSuperview()
            var list = self.loadFavList(Self.myPhrasesKey)
            list.removeAll { $0 == text }
            self.saveFavList(Self.myPhrasesKey, list)
            self.showToast(self.loc("favorite_removed"))
            self.showMode(.textTemplate)
        })
        stack.addArrangedSubview(makePopupButton(
            title: loc("cancel_button"), color: .darkGray) {
            overlay.removeFromSuperview()
        })
    }

    @objc private func fandomItemLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard let btn = gesture.view as? UIButton else { return }
        guard let output = fandomItemOutputs[btn.tag] else { return }
        showAddPopup(text: output, favKey: Self.favKeyTextReplace)
    }

    @objc private func favTextReplaceTapped(_ s: UIButton) {
        guard isPremiumUser else {
            showLockedOverlay()
            return
        }
        let items = loadFavList(Self.favKeyTextReplace)
        guard s.tag < items.count else { return }
        textDocumentProxy.insertText(items[s.tag])
    }

    @objc private func favTextReplaceLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard let btn = gesture.view as? UIButton else { return }
        let items = loadFavList(Self.favKeyTextReplace)
        guard btn.tag < items.count else { return }
        showRemovePopup(text: items[btn.tag], favKey: Self.favKeyTextReplace)
    }

    @objc private func textTemplateTapped(_ s: UIButton) {
        // Legacy handler — kept for compatibility; no longer called.
    }

    // MARK: - Calculator Mode

    private enum CalcKind { case digit, op, function, empty }

    /// Calculator button with auto-rounding corner radius (= bounds.height / 2),
    /// producing a pill/circle shape matching the native iOS calculator.
    private final class CalcButton: UIButton {
        /// Snapshot of the button's intended background color, set once in
        /// makeCalcButton. We restore to this value when the highlight ends.
        var currentBgColor: UIColor = .clear

        override func layoutSubviews() {
            super.layoutSubviews()
            layer.cornerRadius = bounds.height / 2
        }

        override var isHighlighted: Bool {
            didSet {
                UIView.animate(withDuration: 0.08) {
                    self.backgroundColor = self.isHighlighted
                        ? self.currentBgColor.withAlphaComponent(0.6)
                        : self.currentBgColor
                }
            }
        }
    }

    private func buildCalculatorMode() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        pinToEdges(container, in: contentView)

        // Expression label (small, above display)
        let exprLabel = UILabel()
        exprLabel.text = calcExpression
        exprLabel.font = .systemFont(ofSize: 13, weight: .regular)
        exprLabel.textColor = UIColor(white: 0.4, alpha: 1)
        exprLabel.textAlignment = .right
        exprLabel.adjustsFontSizeToFitWidth = true
        exprLabel.minimumScaleFactor = 0.5
        exprLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(exprLabel)
        calcExpressionLabel = exprLabel

        // Display (tap → insertText)
        // `.custom` (not `.system`) — `.system` cross-dissolves the title on
        // every `setTitle(...)` call, which shows up as a flicker each time
        // calcKeyTapped updates the digit display.
        let displayBtn = UIButton(type: .custom)
        displayBtn.setTitle(calcDisplay, for: .normal)
        displayBtn.titleLabel?.font = .systemFont(ofSize: 30, weight: .light)
        displayBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        displayBtn.titleLabel?.minimumScaleFactor = 0.4
        displayBtn.setTitleColor(.darkText, for: .normal)
        displayBtn.contentHorizontalAlignment = .right
        displayBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 14)
        displayBtn.backgroundColor = UIColor(white: 0.95, alpha: 1)
        displayBtn.layer.cornerRadius = 8
        displayBtn.translatesAutoresizingMaskIntoConstraints = false
        displayBtn.addTarget(self, action: #selector(calcDisplayTapped), for: .touchUpInside)
        container.addSubview(displayBtn)
        calcDisplayButton = displayBtn

        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 4
        gridStack.distribution = .fillEqually
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(gridStack)

        let topRows: [[(String, CalcKind)]] = [
            [("⌫", .function), ("AC", .function),  ("%", .function), ("÷", .op)],
            [("7", .digit),    ("8", .digit),      ("9", .digit),    ("×", .op)],
            [("4", .digit),    ("5", .digit),      ("6", .digit),    ("−", .op)],
            [("1", .digit),    ("2", .digit),      ("3", .digit),    ("+", .op)],
        ]

        for row in topRows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 4
            rowStack.distribution = .fillEqually
            for (title, kind) in row {
                let btn = makeCalcButton(title: title, kind: kind)
                if title == "AC" { calcACButton = btn }
                rowStack.addArrangedSubview(btn)
            }
            gridStack.addArrangedSubview(rowStack)
        }

        // Row 5: +/- + 0 + . + =  (all single-width, matches the 4-col grid)
        let row5 = UIStackView()
        row5.axis = .horizontal
        row5.spacing = 4
        row5.distribution = .fillEqually
        row5.addArrangedSubview(makeCalcButton(title: "000", kind: .function))
        row5.addArrangedSubview(makeCalcButton(title: "0", kind: .digit))
        row5.addArrangedSubview(makeCalcButton(title: ".", kind: .digit))
        row5.addArrangedSubview(makeCalcButton(title: "=", kind: .op))
        gridStack.addArrangedSubview(row5)

        NSLayoutConstraint.activate([
            exprLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            exprLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            exprLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            exprLabel.heightAnchor.constraint(equalToConstant: 18),

            displayBtn.topAnchor.constraint(equalTo: exprLabel.bottomAnchor, constant: 2),
            displayBtn.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            displayBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            displayBtn.heightAnchor.constraint(equalToConstant: 42),

            gridStack.topAnchor.constraint(equalTo: displayBtn.bottomAnchor, constant: 6),
            gridStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            gridStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            gridStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
        ])
    }

    private func makeCalcButton(title: String, kind: CalcKind) -> UIButton {
        // .custom (not .system) avoids the fade-in/fade-out title-tint animation
        // that UIKit applies on tap, which looked like a flicker on our colored
        // calculator buttons.
        let btn = CalcButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 22, weight: .medium)
        btn.setTitleColor(.white, for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.showsTouchWhenHighlighted = false
        let bg: UIColor
        switch kind {
        case .digit:
            bg = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)      // #333333
            btn.addTarget(self, action: #selector(calcKeyTapped(_:)), for: .touchUpInside)
        case .op:
            bg = UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1)    // #FF9500
            btn.addTarget(self, action: #selector(calcKeyTapped(_:)), for: .touchUpInside)
        case .function:
            bg = UIColor(red: 0.647, green: 0.647, blue: 0.647, alpha: 1) // #A5A5A5
            btn.addTarget(self, action: #selector(calcKeyTapped(_:)), for: .touchUpInside)
        case .empty:
            bg = .clear
            btn.isEnabled = false
        }
        btn.backgroundColor = bg
        btn.currentBgColor = bg
        return btn
    }

    @objc private func calcKeyTapped(_ sender: UIButton) {
        guard let key = sender.title(for: .normal) else { return }
        switch key {
        case "0","1","2","3","4","5","6","7","8","9":
            if calcJustEvaluated {
                calcDisplay = "0"
                calcJustEvaluated = false
                // Fresh input after "=" → clear expression
                if calcPrevValue == nil { calcExpression = "" }
            }
            if calcDisplay == "0" { calcDisplay = key } else { calcDisplay += key }
        case ".":
            if calcJustEvaluated {
                calcDisplay = "0"
                calcJustEvaluated = false
                if calcPrevValue == nil { calcExpression = "" }
            }
            if !calcDisplay.contains(".") { calcDisplay += "." }
        case "AC":
            calcDisplay = "0"
            calcPrevValue = nil
            calcPendingOp = nil
            calcJustEvaluated = false
            calcExpression = ""
        case "C":
            calcDisplay = "0"
            calcJustEvaluated = false
        case "⌫":
            // Delete the last digit; show "0" once the display is empty.
            if calcJustEvaluated {
                // After "=" the display is the result — backspace clears it.
                calcDisplay = "0"
                calcJustEvaluated = false
                if calcPrevValue == nil { calcExpression = "" }
            } else if calcDisplay.count > 1 {
                calcDisplay.removeLast()
            } else {
                calcDisplay = "0"
            }
        case "000":
            // Mirror the digit-key path: clear-on-eval, then append. Special-
            // case the "0" display so tapping 000 on a fresh display doesn't
            // produce "0000" — stays as "0" like real-world calculators.
            if calcJustEvaluated {
                calcDisplay = "0"
                calcJustEvaluated = false
                if calcPrevValue == nil { calcExpression = "" }
            }
            if calcDisplay != "0" { calcDisplay += "000" }
        case "%":
            if let d = Double(calcDisplay) { calcDisplay = formatCalcValue(d / 100) }
        case "+","−","×","÷":
            if let d = Double(calcDisplay) {
                // Fresh op after "=" → reset expression to continue with result
                if calcPrevValue == nil && calcPendingOp == nil {
                    calcExpression = ""
                }
                // Append current number + operator to expression
                calcExpression += "\(calcDisplay) \(key) "
                if let prev = calcPrevValue, let op = calcPendingOp, !calcJustEvaluated {
                    let result = performCalc(prev, d, op)
                    calcPrevValue = result
                    calcDisplay = formatCalcValue(result)
                } else {
                    calcPrevValue = d
                }
                calcPendingOp = key
                calcJustEvaluated = true
            }
        case "=":
            if let d = Double(calcDisplay), let prev = calcPrevValue, let op = calcPendingOp {
                calcExpression += "\(calcDisplay) ="
                let result = performCalc(prev, d, op)
                calcDisplay = formatCalcValue(result)
                calcPrevValue = nil
                calcPendingOp = nil
                calcJustEvaluated = true
            }
        default: break
        }
        calcDisplayButton?.setTitle(calcDisplay, for: .normal)
        calcExpressionLabel?.text = calcExpression
        let showAC = (calcDisplay == "0" && calcPrevValue == nil && calcPendingOp == nil && calcExpression.isEmpty)
        calcACButton?.setTitle(showAC ? "AC" : "C", for: .normal)
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
    }

    @objc private func calcBackspaceLongPressed(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began else { return }
        // Same as AC — full reset
        calcDisplay = "0"
        calcPrevValue = nil
        calcPendingOp = nil
        calcJustEvaluated = false
        calcExpression = ""
        calcDisplayButton?.setTitle(calcDisplay, for: .normal)
        calcExpressionLabel?.text = calcExpression
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
    }

    private func performCalc(_ a: Double, _ b: Double, _ op: String) -> Double {
        switch op {
        case "+": return a + b
        case "−": return a - b
        case "×": return a * b
        case "÷": return b == 0 ? 0 : a / b
        default:  return b
        }
    }

    private func formatCalcValue(_ v: Double) -> String {
        if v.isNaN || v.isInfinite { return "Error" }
        if v == v.rounded() && abs(v) < 1e15 {
            return String(Int64(v))
        }
        // Strip trailing zeros
        var s = String(format: "%.10f", v)
        while s.contains(".") && (s.hasSuffix("0") || s.hasSuffix(".")) {
            s.removeLast()
        }
        return s
    }

    @objc private func calcDisplayTapped() {
        textDocumentProxy.insertText(calcDisplay)
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
    }

    // MARK: - GIF Mode

    private func buildGifMode() {
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        pinToEdges(container, in: contentView)
        container.heightAnchor.constraint(equalToConstant: tabContainerHeight).isActive = true

        // Category tabs
        let catScroll = UIScrollView()
        catScroll.showsHorizontalScrollIndicator = false
        catScroll.translatesAutoresizingMaskIntoConstraints = false
        catScroll.delegate = self
        gifCatScrollView = catScroll
        container.addSubview(catScroll)

        let catRow = UIStackView()
        catRow.axis = .horizontal
        catRow.spacing = 6
        catRow.translatesAutoresizingMaskIntoConstraints = false
        catScroll.addSubview(catRow)
        NSLayoutConstraint.activate([
            catRow.topAnchor.constraint(equalTo: catScroll.topAnchor),
            catRow.leadingAnchor.constraint(equalTo: catScroll.leadingAnchor, constant: 4),
            catRow.trailingAnchor.constraint(equalTo: catScroll.trailingAnchor, constant: -4),
            catRow.bottomAnchor.constraint(equalTo: catScroll.bottomAnchor),
            catRow.heightAnchor.constraint(equalTo: catScroll.heightAnchor),
        ])
        for (i, cat) in gifCategories.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(cat.0, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            btn.layer.cornerRadius = 14
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)
            let sel = i == gifCategoryIndex
            btn.backgroundColor = sel ? accentColor : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? selectedCatTextColor : .darkGray, for: .normal)
            btn.tag = i
            btn.addTarget(self, action: #selector(gifCategoryTapped(_:)), for: .touchUpInside)
            catRow.addArrangedSubview(btn)
        }

        DispatchQueue.main.async {
            catScroll.setContentOffset(self.savedGifCatOffset, animated: false)
        }

        // Bottom delete bar removed per spec — the grid scroll view extends
        // straight to the container bottom.

        // Grid scroll view
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.tag = 300
        container.addSubview(scrollView)
        gifScrollView = scrollView

        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 5
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(gridStack)
        gifGridStack = gridStack

        // Loading label
        let loadingLabel = UILabel()
        loadingLabel.text = "불러오는 중..."
        loadingLabel.font = .systemFont(ofSize: 13)
        loadingLabel.textColor = .lightGray
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(loadingLabel)
        gifLoadingLabel = loadingLabel

        NSLayoutConstraint.activate([
            catScroll.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            catScroll.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            catScroll.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            catScroll.heightAnchor.constraint(equalToConstant: 32),

            scrollView.topAnchor.constraint(equalTo: catScroll.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            gridStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 5),
            gridStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 5),
            gridStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -5),
            gridStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -5),
            gridStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10),

            loadingLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            loadingLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 40),
        ])

        loadGifs()
    }

    // MARK: - GIPHY Network

    private func loadGifs() {
        let category = gifCategories[gifCategoryIndex]
        gifImages = []
        gifOffset = 0
        gifSearchQuery = category.1
        fetchGiphy(append: false)
    }

    private func loadMoreGifs() {
        guard !isLoadingGifs else { return }
        gifOffset += 50
        fetchGiphy(append: true)
    }

    private func fetchGiphy(append: Bool) {
        // A keyboard extension can't reach the network without Full Access, so
        // the request would fail and surface the generic "API Key" error,
        // misdiagnosing the cause. Detect it up front and guide the user.
        if !hasFullAccess {
            if !append { showGifFullAccessNotice() }
            return
        }
        isLoadingGifs = true
        if !append {
            gifLoadingLabel?.text = "불러오는 중..."
            gifLoadingLabel?.isHidden = false
        }

        let urlString: String
        if let q = gifSearchQuery?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString = "https://api.giphy.com/v1/gifs/search?api_key=\(giphyApiKey)&q=\(q)&limit=50&offset=\(gifOffset)&lang=ko"
        } else {
            urlString = "https://api.giphy.com/v1/gifs/trending?api_key=\(giphyApiKey)&limit=50&offset=\(gifOffset)&lang=ko"
        }
        guard let url = URL(string: urlString) else { isLoadingGifs = false; return }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["data"] as? [[String: Any]]
            else {
                DispatchQueue.main.async {
                    self.isLoadingGifs = false
                    if !append {
                        self.gifImages = []
                        self.gifLoadingLabel?.text = "GIF 불러오기 실패\nAPI Key를 확인해주세요"
                        self.gifLoadingLabel?.numberOfLines = 0
                        self.renderGifGrid()
                    }
                }
                return
            }

            let gifs: [GiphyImage] = items.compactMap { item in
                guard let id = item["id"] as? String,
                      let images = item["images"] as? [String: Any],
                      let preview = images["fixed_width_small_still"] as? [String: Any],
                      let previewStr = preview["url"] as? String,
                      let previewURL = URL(string: previewStr),
                      let original = images["original"] as? [String: Any],
                      let originalStr = original["url"] as? String,
                      let originalURL = URL(string: originalStr)
                else { return nil }
                return GiphyImage(id: id, previewURL: previewURL, originalURL: originalURL)
            }

            DispatchQueue.main.async {
                self.isLoadingGifs = false
                if append {
                    let startIndex = self.gifImages.count
                    self.gifImages.append(contentsOf: gifs)
                    self.appendGifRows(from: startIndex)
                } else {
                    self.gifImages = gifs
                    self.gifLoadingLabel?.isHidden = !gifs.isEmpty
                    if gifs.isEmpty { self.gifLoadingLabel?.text = self.loc("gif_search_empty") }
                    self.renderGifGrid()
                }
            }
        }.resume()
    }

    /// Shown when GIF can't load because Full Access is off (the extension
    /// has no network otherwise). Replaces the misleading API-key error with
    /// an explanation and a jump to the iOS Keyboard settings.
    private func showGifFullAccessNotice() {
        isLoadingGifs = false
        gifImages = []
        gifGridStack?.arrangedSubviews.forEach { $0.removeFromSuperview() }
        gifLoadingLabel?.isHidden = true

        guard let scrollView = gifScrollView else { return }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 30),
            stack.widthAnchor.constraint(equalToConstant: 280),
        ])

        let label = UILabel()
        label.text = loc("gif_no_access")
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        stack.addArrangedSubview(label)

    }

    /// Walk the responder chain to find the host `UIApplication` and open the
    /// iOS Keyboard settings — the same trick `openPaywallApp()` uses, since
    /// `UIApplication.shared` is off-limits in extensions.
    @objc private func openKeyboardSettings() {
        guard let url = URL(string: "app-settings:root=General&path=Keyboard"),
              let ctx = extensionContext else { return }
        ctx.open(url, completionHandler: nil)
    }

    private func renderGifGrid() {
        guard let gridStack = gifGridStack else { return }
        gridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let cols = 3
        let chunked = stride(from: 0, to: gifImages.count, by: cols).map {
            Array(gifImages[$0..<min($0 + cols, gifImages.count)])
        }

        for row in chunked {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 5

            for gif in row {
                let btn = UIButton(type: .custom)
                btn.backgroundColor = UIColor(white: 0.94, alpha: 1)
                btn.layer.cornerRadius = 8
                btn.clipsToBounds = true
                btn.heightAnchor.constraint(equalToConstant: 72).isActive = true
                btn.accessibilityIdentifier = gif.id
                btn.addTarget(self, action: #selector(gifCellTapped(_:)), for: .touchUpInside)
                let gifLongPress = UILongPressGestureRecognizer(target: self, action: #selector(gifLongPressed(_:)))
                gifLongPress.minimumPressDuration = 0.5
                btn.addGestureRecognizer(gifLongPress)

                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.isUserInteractionEnabled = false
                imageView.translatesAutoresizingMaskIntoConstraints = false
                btn.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.topAnchor.constraint(equalTo: btn.topAnchor),
                    imageView.leadingAnchor.constraint(equalTo: btn.leadingAnchor),
                    imageView.trailingAnchor.constraint(equalTo: btn.trailingAnchor),
                    imageView.bottomAnchor.constraint(equalTo: btn.bottomAnchor),
                ])

                loadGifPreview(url: gif.previewURL, into: imageView, gifID: gif.id, button: btn)
                rowStack.addArrangedSubview(btn)
            }
            for _ in 0..<(cols - row.count) { rowStack.addArrangedSubview(UIView()) }
            gridStack.addArrangedSubview(rowStack)
        }
    }

    private func loadGifPreview(url: URL, into imageView: UIImageView, gifID: String, button: UIButton) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                if button.accessibilityIdentifier == gifID {
                    imageView.image = image
                }
            }
        }.resume()
    }

    private func appendGifRows(from startIndex: Int) {
        guard let gridStack = gifGridStack else { return }
        let cols = 3
        let newItems = Array(gifImages[startIndex...])
        let chunked = stride(from: 0, to: newItems.count, by: cols).map {
            Array(newItems[$0..<min($0 + cols, newItems.count)])
        }
        for row in chunked {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 5
            for gif in row {
                let btn = UIButton(type: .custom)
                btn.backgroundColor = UIColor(white: 0.94, alpha: 1)
                btn.layer.cornerRadius = 8
                btn.clipsToBounds = true
                btn.heightAnchor.constraint(equalToConstant: 72).isActive = true
                btn.accessibilityIdentifier = gif.id
                btn.addTarget(self, action: #selector(gifCellTapped(_:)), for: .touchUpInside)
                let lp = UILongPressGestureRecognizer(target: self, action: #selector(gifLongPressed(_:)))
                lp.minimumPressDuration = 0.5
                btn.addGestureRecognizer(lp)

                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.isUserInteractionEnabled = false
                imageView.translatesAutoresizingMaskIntoConstraints = false
                btn.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.topAnchor.constraint(equalTo: btn.topAnchor),
                    imageView.leadingAnchor.constraint(equalTo: btn.leadingAnchor),
                    imageView.trailingAnchor.constraint(equalTo: btn.trailingAnchor),
                    imageView.bottomAnchor.constraint(equalTo: btn.bottomAnchor),
                ])
                loadGifPreview(url: gif.previewURL, into: imageView, gifID: gif.id, button: btn)
                rowStack.addArrangedSubview(btn)
            }
            for _ in 0..<(cols - row.count) { rowStack.addArrangedSubview(UIView()) }
            gridStack.addArrangedSubview(rowStack)
        }
    }

    @objc private func gifCategoryTapped(_ sender: UIButton) {
        gifCategoryIndex = sender.tag
        showMode(.gif)
    }

    @objc private func gifCellTapped(_ sender: UIButton) {
        guard let gifID = sender.accessibilityIdentifier,
              let gif = gifImages.first(where: { $0.id == gifID })
        else { return }

        if !isPremiumUser {
            let defaults = UserDefaults(suiteName: Self.favAppGroup)
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone.current
            let today = df.string(from: Date())
            let storedDate = defaults?.string(forKey: "free_gif_date")
            var count = (storedDate == today) ? (defaults?.integer(forKey: "free_gif_count") ?? 0) : 0
            if count >= (isPremiumUser ? 5 : 0) {
                showLockedOverlay()
                return
            }
            count += 1
            defaults?.set(count, forKey: "free_gif_count")
            defaults?.set(today, forKey: "free_gif_date")
        }

        showToast(loc("toast_gif_downloading"))
        URLSession.shared.dataTask(with: gif.originalURL) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                guard let data = data else {
                    self?.showToast(self?.loc("toast_gif_failed") ?? "")
                    return
                }
                UIPasteboard.general.setData(data, forPasteboardType: "com.compuserve.gif")
                // Stash the URL in the App Group so the host Flutter app
                // can pick it up via its paste button.
                let defaults = UserDefaults(suiteName: "group.com.yunajung.fonki")
                defaults?.set(gif.originalURL.absoluteString, forKey: "lastCopiedGifUrl")
                self?.showToast(self?.loc("toast_gif_copied") ?? "")
            }
        }.resume()
    }

    // MARK: - Translate Mode

    private func buildTranslateMode() {
        // NOTE: `restoreTranslateState()` is intentionally NOT called here —
        // `buildTranslateMode` also runs on intra-tab rebuilds (language
        // dropdown / swap / direct-input toggle), and restoring then would
        // overwrite the user's just-made change with the stale App Group
        // snapshot. `showMode` calls `restoreTranslateState()` instead, gated
        // on a genuine tab entry. This builder just reads whatever
        // `sourceLangIndex`/`translationInput`/`lastTranslation` currently
        // hold.

        // ── Translation field view (modeBar 위에 표시) ──
        let fieldView = UIStackView()
        fieldView.axis = .vertical; fieldView.spacing = 2
        fieldView.translatesAutoresizingMaskIntoConstraints = false

        // ── Top bar: 원본언어 → 번역언어 + 🔄 + 🗑 ──
        let topBar = UIStackView()
        topBar.axis = .horizontal; topBar.spacing = 2; topBar.setHeight(26)

        let srcBtn = UIButton(type: .system)
        srcBtn.setTitle(translateLangs[sourceLangIndex].0 + " ▼", for: .normal)
        srcBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        srcBtn.setTitleColor(currentTheme == .hotPink ? .white : .darkGray, for: .normal)
        srcBtn.addTarget(self, action: #selector(translateSourceDropdown), for: .touchUpInside)
        topBar.addArrangedSubview(srcBtn)

        let arrowLabel = UILabel()
        arrowLabel.text = "→"
        arrowLabel.font = .systemFont(ofSize: 14, weight: .bold)
        arrowLabel.textColor = currentTheme == .hotPink ? .white : translateAccentColor
        arrowLabel.textAlignment = .center
        arrowLabel.setWidth(20)
        topBar.addArrangedSubview(arrowLabel)

        let tgtBtn = UIButton(type: .system)
        tgtBtn.setTitle(translateLangs[targetLangIndex].0 + " ▼", for: .normal)
        tgtBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        tgtBtn.setTitleColor(currentTheme == .hotPink ? .white : translateAccentColor, for: .normal)
        tgtBtn.addTarget(self, action: #selector(translateTargetDropdown), for: .touchUpInside)
        topBar.addArrangedSubview(tgtBtn)

        topBar.addArrangedSubview(UIView()) // spacer

        let swapBtn = UIButton(type: .system)
        swapBtn.setTitle("🔄", for: .normal)
        swapBtn.titleLabel?.font = .systemFont(ofSize: 14)
        swapBtn.addTarget(self, action: #selector(translateSwapLangs), for: .touchUpInside)
        swapBtn.setWidth(28)
        topBar.addArrangedSubview(swapBtn)

        let clearBtn = UIButton(type: .system)
        clearBtn.setTitle("🗑", for: .normal)
        clearBtn.titleLabel?.font = .systemFont(ofSize: 14)
        clearBtn.addTarget(self, action: #selector(translateClearTapped), for: .touchUpInside)
        clearBtn.setWidth(28)
        topBar.addArrangedSubview(clearBtn)

        fieldView.addArrangedSubview(topBar)

        // ── Input box ──
        let inputBox = UIView()
        inputBox.backgroundColor = .white
        inputBox.layer.cornerRadius = 8; inputBox.layer.borderWidth = 0.5
        inputBox.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor

        let inputField = UITextView()
        inputField.font = .systemFont(ofSize: 15)
        inputField.textColor = .darkText
        inputField.backgroundColor = .clear
        inputField.tintColor = accentColor
        inputField.returnKeyType = .done
        inputField.autocorrectionType = .no
        inputField.spellCheckingType = .no
        inputField.smartDashesType = .no
        inputField.smartQuotesType = .no
        inputField.smartInsertDeleteType = .no
        inputField.isScrollEnabled = true
        inputField.isEditable = true
        inputField.textContainer.lineBreakMode = .byWordWrapping
        inputField.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        inputField.textContainer.lineFragmentPadding = 0
        inputField.delegate = self
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputBox.addSubview(inputField)
        translateInputField = inputField

        let placeholderLabel = UILabel()
        placeholderLabel.text = loc("translate_placeholder")
        placeholderLabel.textColor = .lightGray
        placeholderLabel.font = .systemFont(ofSize: 15)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.isUserInteractionEnabled = false
        inputBox.addSubview(placeholderLabel)
        translatePlaceholderLabel = placeholderLabel

        let counterLabel = UILabel()
        counterLabel.font = .systemFont(ofSize: 10)
        counterLabel.textColor = .lightGray
        counterLabel.text = "0 / 200"
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        inputBox.addSubview(counterLabel)
        translateCounterLabel = counterLabel

        let closeBtn = UIButton(type: .system)
        let closeConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        closeBtn.setImage(UIImage(systemName: "checkmark.circle.fill", withConfiguration: closeConfig), for: .normal)
        closeBtn.tintColor = accentColor
        closeBtn.alpha = 0
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addTarget(self, action: #selector(dismissTranslateKeyboard), for: .touchUpInside)
        inputBox.addSubview(closeBtn)
        translateCloseButton = closeBtn

        NSLayoutConstraint.activate([
            inputField.topAnchor.constraint(equalTo: inputBox.topAnchor, constant: 4),
            inputField.leadingAnchor.constraint(equalTo: inputBox.leadingAnchor, constant: 6),
            inputField.trailingAnchor.constraint(equalTo: closeBtn.leadingAnchor, constant: -4),
            inputField.bottomAnchor.constraint(equalTo: counterLabel.topAnchor, constant: -2),
            placeholderLabel.topAnchor.constraint(equalTo: inputField.topAnchor, constant: 8),
            placeholderLabel.leadingAnchor.constraint(equalTo: inputField.leadingAnchor, constant: 0),
            placeholderLabel.trailingAnchor.constraint(equalTo: inputField.trailingAnchor, constant: 0),
            counterLabel.trailingAnchor.constraint(equalTo: inputBox.trailingAnchor, constant: -6),
            counterLabel.bottomAnchor.constraint(equalTo: inputBox.bottomAnchor, constant: -2),
            closeBtn.trailingAnchor.constraint(equalTo: inputBox.trailingAnchor, constant: -4),
            closeBtn.topAnchor.constraint(equalTo: inputField.topAnchor, constant: 4),
            closeBtn.widthAnchor.constraint(equalToConstant: 24),
            closeBtn.heightAnchor.constraint(equalToConstant: 24),
        ])

        // Text areas row — input field only, full width.
        let textRow = UIStackView()
        textRow.axis = .horizontal; textRow.spacing = 3
        textRow.addArrangedSubview(inputBox)
        textRow.translatesAutoresizingMaskIntoConstraints = false
        textRow.heightAnchor.constraint(equalToConstant: 70).isActive = true
        fieldView.addArrangedSubview(textRow)

        // Insert fieldView above modeBar in mainStack (translation tab only)
        mainStack.insertArrangedSubview(fieldView, at: 0)
        translationFieldView = fieldView
        fieldView.heightAnchor.constraint(equalToConstant: 100).isActive = true

        // ── Keyboard area (inside contentView) ──
        let stack = UIStackView()
        stack.axis = .vertical; stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        pinToEdges(stack, in: contentView)

        // ── Keyboard rows (in dedicated container for partial rebuild) ──
        let kbArea = UIStackView()
        kbArea.axis = .vertical
        kbArea.spacing = 4
        kbArea.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(kbArea)
        translateKeyboardContainer = kbArea
        buildTranslateKeyboardRows(into: kbArea)

        // 표준 bottom bar 조건부 추가. 천지인 Korean 모드는 row 4
        // 자체에 한/영/ㅇㅁ/번역/삽입이 있어 bottom bar 중복 회피.
        // isBuildingTranslateLayout = true so vintageGray keys in the
        // bottom bar get the same light translate background as key rows.
        isBuildingTranslateLayout = true
        addTranslateBottomBarIfNeeded(to: stack)
        isBuildingTranslateLayout = false
        updateTranslateInputDisplay()

        // 🫧[DIAG-BTM] ─────────────────────────────────────────────────────
        print("🫧[DIAG-BTM] START: theme=\(currentTheme), window=\(view.window != nil), view.frame=\(view.frame)")
        stack.layoutIfNeeded()
        print("🫧[DIAG-BTM] after stack.layoutIfNeeded: stack.frame=\(stack.frame), kbArea.frame=\(kbArea.frame)")
        mainStack.layoutIfNeeded()
        print("🫧[DIAG-BTM] after mainStack.layoutIfNeeded: mainStack.frame=\(mainStack.frame)")
        print("🫧[DIAG-BTM] applyGradient done (called from buildTranslateMode)")
        // ─────────────────────────────────────────────────────────────────

    }

    /// Build the translate-mode bottom bar (한/영 / !?123 / space / 번역 /
    /// 삽입) and append it to `container`. Skipped when the current state
    /// is cheonjiin Korean (the cheonjiin keypad has its own row-4 with
    /// equivalent controls — adding this bar would double the 한/영 /
    /// 번역 / 삽입 buttons). Stashes the new bar in `translateBottomBar`
    /// so `rebuildTranslateKeys` can find and tear it down on layout
    /// switches.
    private func addTranslateBottomBarIfNeeded(to container: UIStackView) {
        if isKoreanMode && koreanInputMode == "cheonjiin" && !isTranslateNumberMode {
            return
        }

        let bottom = UIStackView()
        bottom.axis = .horizontal; bottom.spacing = 4
        bottom.translatesAutoresizingMaskIntoConstraints = false
        bottom.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let langToggle = makeSpecialKey(isKoreanMode ? "En" : "Ko")
        if currentTheme == .vintageGray {
            langToggle.backgroundColor = specialKeyBG
        } else {
            langToggle.backgroundColor = (isKoreanMode && currentTheme != .default) ? UIColor.systemBlue.withAlphaComponent(0.15) : accentColor
        }
        langToggle.setTitleColor(currentTheme == .default ? .white : .black, for: .normal)
        if currentTheme == .cottonCandy {
            langToggle.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 1)
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .lavender {
            langToggle.backgroundColor = UIColor(red: 0.80, green: 0.70, blue: 0.95, alpha: 1)
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .pastelRainbow {
            langToggle.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .hotPink {
            langToggle.backgroundColor = accentColor
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .soft {
            langToggle.backgroundColor = UIColor(red: 0.97, green: 0.90, blue: 0.93, alpha: 1)
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .bubbleMint {
            langToggle.backgroundColor = UIColor(red: 0.95, green: 0.85, blue: 0.90, alpha: 1)
            langToggle.setTitleColor(.black, for: .normal)
        }
        langToggle.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        langToggle.setWidth(48)
        langToggle.addTarget(self, action: #selector(translateToggleKorEng), for: .touchUpInside)
        bottom.addArrangedSubview(langToggle)

        let numToggle = makeSpecialKey(isTranslateNumberMode ? "ABC" : "123")
        numToggle.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        if currentTheme == .vintageGray {
            numToggle.backgroundColor = UIColor(white: 0.82, alpha: 1)
        }
        numToggle.setWidth(50)
        numToggle.addTarget(self, action: #selector(translateToggleNumberMode), for: .touchUpInside)
        translateNumToggleButton = numToggle
        bottom.addArrangedSubview(numToggle)

        let space = makeLetterKey("space")
        space.titleLabel?.font = .systemFont(ofSize: 14)
        space.addTarget(self, action: #selector(translateSpaceTapped), for: .touchUpInside)
        bottom.addArrangedSubview(space)

        let trBtn = makeSpecialKey(loc("translate_button"))
        trBtn.backgroundColor = UIColor(white: 0.82, alpha: 1)
        trBtn.setTitleColor(.black, for: .normal)
        if currentTheme == .cottonCandy {
            trBtn.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 1)
            trBtn.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .lavender {
            trBtn.backgroundColor = UIColor(red: 0.80, green: 0.70, blue: 0.95, alpha: 1)
            trBtn.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .pastelRainbow {
            trBtn.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
            trBtn.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .hotPink {
            trBtn.backgroundColor = accentColor
            trBtn.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .soft {
            trBtn.backgroundColor = UIColor(red: 0.97, green: 0.90, blue: 0.93, alpha: 1)
            trBtn.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .retroCream {
            trBtn.backgroundColor = accentColor
        }
        if currentTheme == .default {
            trBtn.backgroundColor = specialKeyBG
        }
        if currentTheme == .bubbleMint {
            trBtn.backgroundColor = specialKeyBG
        }
        trBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        trBtn.setWidth(48)
        trBtn.addTarget(self, action: #selector(translateTriggered), for: .touchUpInside)
        bottom.addArrangedSubview(trBtn)

        // Return/newline key — same visual style as the Aa-tab one, but
        // wired to `translateReturnTapped` (below) so it A/B-routes: host
        // app when unfocused (defers to the unmodified `returnTapped`), or
        // the translate input box itself when that field is focused.
        let returnBtn = makeSpecialKey("")
        returnBtn.setTitle("", for: .normal)
        let returnImage = UIImage(systemName: "return", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
        returnBtn.setImage(returnImage, for: .normal)
        returnBtn.backgroundColor = currentTheme == .retroCream
            ? UIColor(red: 0.98, green: 0.75, blue: 0.80, alpha: 1)
            : specialKeyBG
        returnBtn.tintColor = .black
        returnBtn.setTitleColor(.black, for: .normal)
        returnBtn.addTarget(self, action: #selector(translateReturnTapped), for: .touchDown)
        returnBtn.setWidth(50)
        bottom.addArrangedSubview(returnBtn)

        container.addArrangedSubview(bottom)
        translateBottomBar = bottom
    }

    private func buildTranslateKeyboardRows(into stack: UIStackView) {
        isBuildingTranslateLayout = true
        defer { isBuildingTranslateLayout = false }
        let rowHeight: CGFloat = 52  // iOS 기본 키보드 수준

        func makeRowStack() -> UIStackView {
            let rs = UIStackView()
            rs.axis = .horizontal
            rs.distribution = .fillEqually
            rs.spacing = 4
            rs.translatesAutoresizingMaskIntoConstraints = false
            rs.heightAnchor.constraint(equalToConstant: rowHeight).isActive = true
            return rs
        }

        if isTranslateNumberMode {
            let page1Rows: [[String]] = [
                ["1","2","3","4","5","6","7","8","9","0"],
                ["-","/",":",";","(",")","₩","&","@","\""],
                [".",",","?","!","'"]
            ]
            let page2Rows: [[String]] = [
                ["[","]","{","}","#","%","^","*","+","="],
                ["_","\\","|","~","<",">","$","£","¥","•"],
                [".",",","?","!","'"]
            ]
            let numRows = isTranslateSymbolPage2 ? page2Rows : page1Rows
            for (ri, row) in numRows.enumerated() {
                let rowStack = makeRowStack()
                if ri == 2 {
                    let pageToggle = makeSpecialKey(isTranslateSymbolPage2 ? "123" : "#+=")
                    pageToggle.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
                    pageToggle.addTarget(self, action: #selector(translateToggleSymbolPage), for: .touchUpInside)
                    rowStack.addArrangedSubview(pageToggle)
                }
                for key in row {
                    let btn = makeLetterKey(key)
                    btn.titleLabel?.font = .systemFont(ofSize: 22)
                    btn.addTarget(self, action: #selector(translateKeyTapped(_:)), for: .touchDown)
                    rowStack.addArrangedSubview(btn)
                }
                if ri == 2 {
                    let del = makeSpecialKey("⌫")
                    del.addTarget(self, action: #selector(translateDeleteTapped), for: .touchUpInside)
                    attachBackspaceLongPress(to: del, translateMode: true)
                    rowStack.addArrangedSubview(del)
                }
                stack.addArrangedSubview(rowStack)
            }
        } else if isKoreanMode && koreanInputMode == "cheonjiin" {
            // Translate tab + Korean + 천지인: dedicated 4-row layout where
            // row 4 carries ㅇㅁ / space / 번역 / 삽입 (instead of the fonts-
            // tab's !#1 / 한/영 / ㅇㅁ / space / ,). `buildTranslateMode`
            // detects this combo and skips the standard bottom bar so the
            // translate-tab cheonjiin keypad stays a clean 3-row jamo grid
            // + 1-row action row.
            buildCheonjiinKeypadRows(into: stack, host: .translateTab)
        } else {
            let shifted = isTranslateShifted || isTranslateCapsLock
            let korN: [[String]] = [
                ["ㅂ","ㅈ","ㄷ","ㄱ","ㅅ","ㅛ","ㅕ","ㅑ","ㅐ","ㅔ"],
                ["ㅁ","ㄴ","ㅇ","ㄹ","ㅎ","ㅗ","ㅓ","ㅏ","ㅣ"],
                ["ㅋ","ㅌ","ㅊ","ㅍ","ㅠ","ㅜ","ㅡ"]
            ]
            let korS: [[String]] = [
                ["ㅃ","ㅉ","ㄸ","ㄲ","ㅆ","ㅛ","ㅕ","ㅑ","ㅒ","ㅖ"],
                ["ㅁ","ㄴ","ㅇ","ㄹ","ㅎ","ㅗ","ㅓ","ㅏ","ㅣ"],
                ["ㅋ","ㅌ","ㅊ","ㅍ","ㅠ","ㅜ","ㅡ"]
            ]
            let eng: [[String]] = [
                ["q","w","e","r","t","y","u","i","o","p"],
                ["a","s","d","f","g","h","j","k","l"],
                ["z","x","c","v","b","n","m"]
            ]
            let rows = isKoreanMode ? (shifted ? korS : korN) : eng

            for (ri, row) in rows.enumerated() {
                let rowStack = makeRowStack()
                if ri == 2 {
                    let shift = makeSpecialKey("⇧")
                    shift.addTarget(self, action: #selector(translateShiftTapped), for: .touchUpInside)
                    if currentTheme == .vintageGray {
                        shift.backgroundColor = UIColor(white: 0.82, alpha: 1)
                    }
                    if shifted { shift.backgroundColor = accentColor; shift.setTitleColor(.white, for: .normal) }
                    rowStack.addArrangedSubview(shift)
                }
                for key in row {
                    let label = (!isKoreanMode && shifted) ? key.uppercased() : key
                    let btn = makeLetterKey(label)
                    btn.titleLabel?.font = .systemFont(ofSize: isKoreanMode ? 22 : 24)
                    btn.addTarget(self, action: #selector(translateKeyTapped(_:)), for: .touchDown)
                    rowStack.addArrangedSubview(btn)
                }
                if ri == 2 {
                    let del = makeSpecialKey("⌫")
                    if currentTheme == .vintageGray {
                        del.backgroundColor = UIColor(white: 0.82, alpha: 1)
                    }
                    del.addTarget(self, action: #selector(translateDeleteTapped), for: .touchUpInside)
        attachBackspaceLongPress(to: del, translateMode: true)
                    rowStack.addArrangedSubview(del)
                }
                stack.addArrangedSubview(rowStack)
            }
        }
    }

    private func _DELETED_buildTranslatePasteMode() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        pinToEdges(container, in: contentView)

        // Language + mode toggle row
        let topRow = UIStackView()
        topRow.axis = .horizontal; topRow.spacing = 4
        topRow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(topRow)

        let langScroll = UIScrollView()
        langScroll.showsHorizontalScrollIndicator = false
        let langRow = UIStackView()
        langRow.axis = .horizontal; langRow.spacing = 6
        langRow.translatesAutoresizingMaskIntoConstraints = false
        langScroll.addSubview(langRow)
        NSLayoutConstraint.activate([
            langRow.topAnchor.constraint(equalTo: langScroll.topAnchor),
            langRow.leadingAnchor.constraint(equalTo: langScroll.leadingAnchor, constant: 4),
            langRow.trailingAnchor.constraint(equalTo: langScroll.trailingAnchor, constant: -4),
            langRow.bottomAnchor.constraint(equalTo: langScroll.bottomAnchor),
            langRow.heightAnchor.constraint(equalTo: langScroll.heightAnchor),
        ])
        for (i, lang) in translateLangs.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(lang.0, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
            btn.tag = i; btn.layer.cornerRadius = 12
            btn.contentEdgeInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
            let sel = i == targetLangIndex
            btn.backgroundColor = sel ? accentColor : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? selectedCatTextColor : .darkGray, for: .normal)
            btn.addTarget(self, action: #selector(translateLangTapped(_:)), for: .touchUpInside)
            langRow.addArrangedSubview(btn)
        }
        topRow.addArrangedSubview(langScroll)

        // Input box
        let inputBox = UIView()
        inputBox.backgroundColor = .white
        inputBox.layer.cornerRadius = 10; inputBox.layer.borderWidth = 0.5
        inputBox.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        inputBox.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(inputBox)

        let inputField = UITextView()
        inputField.font = .systemFont(ofSize: 13)
        inputField.textColor = .darkText
        inputField.backgroundColor = .clear
        inputField.tintColor = accentColor
        inputField.returnKeyType = .done
        inputField.delegate = self
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputBox.addSubview(inputField)
        translateInputField = inputField

        // Action buttons row
        let actionRow = UIStackView()
        actionRow.axis = .horizontal; actionRow.spacing = 4
        actionRow.translatesAutoresizingMaskIntoConstraints = false
        inputBox.addSubview(actionRow)

        let pasteBtn = UIButton(type: .system)
        pasteBtn.setTitle("📋 붙여넣기", for: .normal)
        pasteBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        pasteBtn.setTitleColor(accentColor, for: .normal)
        pasteBtn.addTarget(self, action: #selector(translatePasteTapped), for: .touchUpInside)
        actionRow.addArrangedSubview(pasteBtn)

        let directBtn = UIButton(type: .system)
        directBtn.setTitle("✏️ 직접입력", for: .normal)
        directBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        directBtn.setTitleColor(.systemBlue, for: .normal)
        // NB: target binding intentionally not added — `translateToggleDirectInput`
        // is legacy and could cause spurious `showMode(.translate)` rebuilds if
        // it ever fires. This whole block sits inside the orphaned
        // `_DELETED_buildTranslatePasteMode` function so the button is never
        // actually rendered, but the binding is removed defensively in case
        // someone resurrects this function later.
        actionRow.addArrangedSubview(directBtn)

        let clearBtn = UIButton(type: .system)
        clearBtn.setTitle("지우기", for: .normal)
        clearBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        clearBtn.setTitleColor(.darkGray, for: .normal)
        clearBtn.addTarget(self, action: #selector(translateClearTapped), for: .touchUpInside)
        actionRow.addArrangedSubview(clearBtn)

        NSLayoutConstraint.activate([
            actionRow.topAnchor.constraint(equalTo: inputBox.topAnchor, constant: 5),
            actionRow.leadingAnchor.constraint(equalTo: inputBox.leadingAnchor, constant: 6),
            actionRow.trailingAnchor.constraint(equalTo: inputBox.trailingAnchor, constant: -6),
            inputField.topAnchor.constraint(equalTo: actionRow.bottomAnchor, constant: 2),
            inputField.leadingAnchor.constraint(equalTo: inputBox.leadingAnchor, constant: 10),
            inputField.trailingAnchor.constraint(equalTo: inputBox.trailingAnchor, constant: -10),
            inputField.bottomAnchor.constraint(equalTo: inputBox.bottomAnchor, constant: -6),
        ])

        // Bottom bar
        let bottomBar = UIStackView()
        bottomBar.axis = .horizontal; bottomBar.spacing = 6
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomBar)

        let translateBtn = makeSpecialKey(loc("translate_button"))
        translateBtn.backgroundColor = UIColor(white: 0.82, alpha: 1)
        translateBtn.setTitleColor(.black, for: .normal)
        if currentTheme == .cottonCandy {
            translateBtn.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 1)
            translateBtn.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .lavender {
            translateBtn.backgroundColor = UIColor(red: 0.80, green: 0.70, blue: 0.95, alpha: 1)
            translateBtn.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .pastelRainbow {
            translateBtn.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
            translateBtn.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .hotPink {
            translateBtn.backgroundColor = accentColor
            translateBtn.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .soft {
            translateBtn.backgroundColor = UIColor(red: 0.97, green: 0.90, blue: 0.93, alpha: 1)
            translateBtn.setTitleColor(.black, for: .normal)
        }
        translateBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        translateBtn.addTarget(self, action: #selector(translateTriggered), for: .touchUpInside)
        bottomBar.addArrangedSubview(translateBtn)

        let del = makeSpecialKey("⌫")
        del.setWidth(44)
        del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
        attachBackspaceLongPress(to: del)
        bottomBar.addArrangedSubview(del)

        NSLayoutConstraint.activate([
            topRow.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            topRow.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            topRow.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            topRow.heightAnchor.constraint(equalToConstant: 28),

            inputBox.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 4),
            inputBox.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            inputBox.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            inputBox.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -4),

            bottomBar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            bottomBar.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            bottomBar.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            bottomBar.heightAnchor.constraint(equalToConstant: 36),
        ])

        updateTranslateInputDisplay()
    }

    // ── Direct Input Mode (QWERTY / Hangul) ────────────────────────────
    private func buildTranslateDirectMode() {
        isBuildingTranslateLayout = true
        defer { isBuildingTranslateLayout = false }
        let stack = UIStackView()
        stack.axis = .vertical; stack.spacing = 3
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        pinToEdges(stack, in: contentView)

        // Language row
        let langScroll = UIScrollView()
        langScroll.showsHorizontalScrollIndicator = false
        langScroll.setHeight(26)
        let langRow = UIStackView()
        langRow.axis = .horizontal; langRow.spacing = 6
        langRow.translatesAutoresizingMaskIntoConstraints = false
        langScroll.addSubview(langRow)
        NSLayoutConstraint.activate([
            langRow.topAnchor.constraint(equalTo: langScroll.topAnchor),
            langRow.leadingAnchor.constraint(equalTo: langScroll.leadingAnchor, constant: 4),
            langRow.trailingAnchor.constraint(equalTo: langScroll.trailingAnchor, constant: -4),
            langRow.bottomAnchor.constraint(equalTo: langScroll.bottomAnchor),
            langRow.heightAnchor.constraint(equalTo: langScroll.heightAnchor),
        ])
        for (i, lang) in translateLangs.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(lang.0, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 10, weight: .semibold)
            btn.tag = i; btn.layer.cornerRadius = 11
            btn.contentEdgeInsets = UIEdgeInsets(top: 2, left: 7, bottom: 2, right: 7)
            let sel = i == targetLangIndex
            btn.backgroundColor = sel ? accentColor : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? selectedCatTextColor : .darkGray, for: .normal)
            btn.addTarget(self, action: #selector(translateLangTapped(_:)), for: .touchUpInside)
            langRow.addArrangedSubview(btn)
        }
        stack.addArrangedSubview(langScroll)

        // Clipboard action buttons
        let actionRow = UIStackView()
        actionRow.axis = .horizontal; actionRow.spacing = 8
        let pasteBtn = UIButton(type: .system)
        pasteBtn.setTitle("📋 붙여넣기", for: .normal)
        pasteBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        pasteBtn.setTitleColor(accentColor, for: .normal)
        pasteBtn.addTarget(self, action: #selector(translatePasteAndTranslate), for: .touchUpInside)
        actionRow.addArrangedSubview(pasteBtn)
        let clearBtn = UIButton(type: .system)
        clearBtn.setTitle("🗑 지우기", for: .normal)
        clearBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        clearBtn.setTitleColor(.darkGray, for: .normal)
        clearBtn.addTarget(self, action: #selector(translateClearTapped), for: .touchUpInside)
        actionRow.addArrangedSubview(clearBtn)
        actionRow.addArrangedSubview(UIView()) // spacer
        stack.addArrangedSubview(actionRow)

        // Input + Result side by side
        let displayRow = UIStackView()
        displayRow.axis = .horizontal; displayRow.spacing = 4; displayRow.distribution = .fillEqually

        let inputField = UITextView()
        inputField.font = .systemFont(ofSize: 11)
        inputField.textColor = .darkText
        inputField.backgroundColor = .white
        inputField.tintColor = accentColor
        inputField.returnKeyType = .done
        inputField.delegate = self
        inputField.layer.cornerRadius = 6; inputField.layer.masksToBounds = true
        translateInputField = inputField

        displayRow.addArrangedSubview(inputField)
        stack.addArrangedSubview(displayRow)

        // Keyboard rows
        if isTranslateNumberMode {
            // Number/Symbol keyboard
            let numRows: [[String]] = [
                ["1","2","3","4","5","6","7","8","9","0"],
                ["-","/",":",";","(",")","₩","&","@","\""],
                [".",",","?","!","'"]
            ]
            for (ri, row) in numRows.enumerated() {
                let rowStack = UIStackView()
                rowStack.axis = .horizontal; rowStack.distribution = .fillEqually; rowStack.spacing = 3
                for key in row {
                    let btn = makeLetterKey(key)
                    btn.titleLabel?.font = .systemFont(ofSize: 16)
                    btn.addTarget(self, action: #selector(translateKeyTapped(_:)), for: .touchUpInside)
                    rowStack.addArrangedSubview(btn)
                }
                if ri == 2 {
                    let del = makeSpecialKey("⌫")
                    del.addTarget(self, action: #selector(translateDeleteTapped), for: .touchUpInside)
        attachBackspaceLongPress(to: del, translateMode: true)
                    rowStack.addArrangedSubview(del)
                }
                stack.addArrangedSubview(rowStack)
            }
        } else {
            // Korean or English keyboard
            let shifted = isTranslateShifted || isTranslateCapsLock
            let korRowsNormal: [[String]] = [
                ["ㅂ","ㅈ","ㄷ","ㄱ","ㅅ","ㅛ","ㅕ","ㅑ","ㅐ","ㅔ"],
                ["ㅁ","ㄴ","ㅇ","ㄹ","ㅎ","ㅗ","ㅓ","ㅏ","ㅣ"],
                ["ㅋ","ㅌ","ㅊ","ㅍ","ㅠ","ㅜ","ㅡ"]
            ]
            let korRowsShifted: [[String]] = [
                ["ㅃ","ㅉ","ㄸ","ㄲ","ㅆ","ㅛ","ㅕ","ㅑ","ㅐ","ㅔ"],
                ["ㅁ","ㄴ","ㅇ","ㄹ","ㅎ","ㅗ","ㅓ","ㅏ","ㅣ"],
                ["ㅋ","ㅌ","ㅊ","ㅍ","ㅠ","ㅜ","ㅡ"]
            ]
            let engRows: [[String]] = [
                ["q","w","e","r","t","y","u","i","o","p"],
                ["a","s","d","f","g","h","j","k","l"],
                ["z","x","c","v","b","n","m"]
            ]
            let rows: [[String]]
            if isKoreanMode {
                rows = shifted ? korRowsShifted : korRowsNormal
            } else {
                rows = engRows
            }

            for (ri, row) in rows.enumerated() {
                let rowStack = UIStackView()
                rowStack.axis = .horizontal; rowStack.distribution = .fillEqually; rowStack.spacing = 3

                if ri == 2 {
                    let shift = makeSpecialKey("⇧")
                    shift.addTarget(self, action: #selector(translateShiftTapped), for: .touchUpInside)
                    if shifted {
                        shift.backgroundColor = accentColor
                        shift.setTitleColor(.white, for: .normal)
                    }
                    rowStack.addArrangedSubview(shift)
                }

                for key in row {
                    let label = (!isKoreanMode && shifted) ? key.uppercased() : key
                    let btn = makeLetterKey(label)
                    btn.titleLabel?.font = .systemFont(ofSize: isKoreanMode ? 16 : 18)
                    btn.addTarget(self, action: #selector(translateKeyTapped(_:)), for: .touchUpInside)
                    rowStack.addArrangedSubview(btn)
                }
                if ri == 2 {
                    let del = makeSpecialKey("⌫")
                    del.addTarget(self, action: #selector(translateDeleteTapped), for: .touchUpInside)
        attachBackspaceLongPress(to: del, translateMode: true)
                    rowStack.addArrangedSubview(del)
                }
                stack.addArrangedSubview(rowStack)
            }
        }

        // Bottom: 한/영 + !?123/ABC + space + 번역 + 삽입
        let bottom = UIStackView()
        bottom.axis = .horizontal; bottom.spacing = 3

        let langToggle = makeSpecialKey(isKoreanMode ? "En" : "Ko")
        if currentTheme == .vintageGray {
            langToggle.backgroundColor = specialKeyBG
        } else {
            langToggle.backgroundColor = (isKoreanMode && currentTheme != .default) ? UIColor.systemBlue.withAlphaComponent(0.15) : accentColor
        }
        langToggle.setTitleColor(currentTheme == .default ? .white : .black, for: .normal)
        if currentTheme == .cottonCandy {
            langToggle.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 1)
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .lavender {
            langToggle.backgroundColor = UIColor(red: 0.80, green: 0.70, blue: 0.95, alpha: 1)
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .pastelRainbow {
            langToggle.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .hotPink {
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .soft {
            langToggle.backgroundColor = UIColor(red: 0.97, green: 0.90, blue: 0.93, alpha: 1)
            langToggle.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .bubbleMint {
            langToggle.backgroundColor = UIColor(red: 0.95, green: 0.85, blue: 0.90, alpha: 1)
            langToggle.setTitleColor(.black, for: .normal)
        }
        langToggle.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        langToggle.setWidth(40)
        langToggle.addTarget(self, action: #selector(translateToggleKorEng), for: .touchUpInside)
        bottom.addArrangedSubview(langToggle)

        let numToggle = makeSpecialKey(isTranslateNumberMode ? "ABC" : "123")
        numToggle.titleLabel?.font = .systemFont(ofSize: 10, weight: .semibold)
        numToggle.setWidth(42)
        numToggle.addTarget(self, action: #selector(translateToggleNumberMode), for: .touchUpInside)
        bottom.addArrangedSubview(numToggle)

        let space = makeLetterKey("space")
        space.titleLabel?.font = .systemFont(ofSize: 12)
        space.addTarget(self, action: #selector(translateSpaceTapped), for: .touchUpInside)
        bottom.addArrangedSubview(space)

        let trBtn = makeSpecialKey(loc("translate_button"))
        trBtn.backgroundColor = UIColor(white: 0.82, alpha: 1)
        trBtn.setTitleColor(.black, for: .normal)
        if currentTheme == .cottonCandy {
            trBtn.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 1)
            trBtn.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .lavender {
            trBtn.backgroundColor = UIColor(red: 0.80, green: 0.70, blue: 0.95, alpha: 1)
            trBtn.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .pastelRainbow {
            trBtn.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
            trBtn.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .hotPink {
            trBtn.backgroundColor = accentColor
            trBtn.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .soft {
            trBtn.backgroundColor = UIColor(red: 0.97, green: 0.90, blue: 0.93, alpha: 1)
            trBtn.setTitleColor(.black, for: .normal)
        }
        if currentTheme == .retroCream {
            trBtn.backgroundColor = accentColor
        }
        if currentTheme == .default {
            trBtn.backgroundColor = specialKeyBG
        }
        trBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        trBtn.setWidth(40)
        trBtn.addTarget(self, action: #selector(translateTriggered), for: .touchUpInside)
        bottom.addArrangedSubview(trBtn)

        stack.addArrangedSubview(bottom)
        updateTranslateInputDisplay()
    }

    private func updateTranslateInputDisplay() {
        if translationInput.count > 200 { translationInput = String(translationInput.prefix(200)) }
        if translateInputField?.text != translationInput {
            translateInputField?.text = translationInput
        }
        translateInputField?.textColor = .darkText
        let cnt = translationInput.count
        translateCounterLabel?.text = "\(cnt) / 200"
        translateCounterLabel?.textColor = cnt >= 180 ? .systemRed : .lightGray
        translatePlaceholderLabel?.isHidden = !translationInput.isEmpty
    }

    @objc private func translateSourceDropdown() {
        let overlay = makeOverlay()
        let stack = makePopupStack(in: overlay)
        for (i, lang) in translateLangs.enumerated() {
            let btn = makePopupButton(title: lang.0, color: i == sourceLangIndex ? accentColor : .darkGray) {
                overlay.removeFromSuperview()
                self.sourceLangIndex = i
                self.showMode(.translate)
            }
            stack.addArrangedSubview(btn)
        }
    }

    @objc private func translateTargetDropdown() {
        let overlay = makeOverlay()
        let stack = makePopupStack(in: overlay)
        for (i, lang) in translateLangs.enumerated() {
            let btn = makePopupButton(title: lang.0, color: i == targetLangIndex ? accentColor : .darkGray) {
                overlay.removeFromSuperview()
                self.targetLangIndex = i
                self.showMode(.translate)
            }
            stack.addArrangedSubview(btn)
        }
    }

    @objc private func translateSwapLangs() {
        let tmp = sourceLangIndex
        sourceLangIndex = targetLangIndex
        targetLangIndex = tmp
        showMode(.translate)
    }

    // MARK: - Translate Actions

    @objc private func translateLangTapped(_ s: UIButton) {
        // unused legacy — kept for compatibility
    }

    @objc private func translateToggleDirectInput() {
        isTranslateDirectInput.toggle()
        showMode(.translate)
    }

    @objc private func translatePasteTapped() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else {
            showToast(loc("toast_clipboard_empty"))
            return
        }
        translationInput = text
        updateTranslateInputDisplay()
        showToast(loc("toast_paste_done"))
    }

    @objc private func translatePasteAndTranslate() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else {
            showToast(loc("toast_clipboard_empty"))
            return
        }
        hgFlush()
        translationInput = text
        updateTranslateInputDisplay()
        translateTriggered()
    }

    @objc private func translateClearTapped() {
        translationInput = ""
        lastTranslation = ""
        updateTranslateInputDisplay()
        // Also drop the persisted copy so a reopen doesn't resurrect the
        // just-cleared text. Lang selection is intentionally left as-is.
        clearSavedTranslateState()
    }

    @objc private func dismissTranslateKeyboard() {
        translateInputField?.resignFirstResponder()
        hgFlush()
    }

    // MARK: - Translate state persistence (App Group)
    // Survives keyboard close/reopen and extension process recycling. Uses the
    // same App Group suite as the subscription sync. Independent of the
    // `translateDailyCount` quota keys — those are untouched.

    private static let translateStateKeys = (
        src:    "translate_source_lang_index",
        tgt:    "translate_target_lang_index",
        input:  "translate_input_text",
        result: "translate_result_text"
    )

    /// Write the current translate-tab state to the App Group.
    private func saveTranslateState() {
        guard let d = UserDefaults(suiteName: "group.com.yunajung.fonki") else { return }
        let k = Self.translateStateKeys
        d.set(sourceLangIndex, forKey: k.src)
        d.set(targetLangIndex, forKey: k.tgt)
        d.set(translationInput, forKey: k.input)
        d.set(lastTranslation, forKey: k.result)
    }

    /// Restore translate-tab state from the App Group. Missing keys leave the
    /// in-memory defaults intact (한국어→영어, empty text). Lang indices are
    /// bounds-checked against `translateLangs` in case the list ever shrinks.
    private func restoreTranslateState() {
        guard let d = UserDefaults(suiteName: "group.com.yunajung.fonki") else { return }
        let k = Self.translateStateKeys
        if d.object(forKey: k.src) != nil {
            let i = d.integer(forKey: k.src)
            if i >= 0 && i < translateLangs.count { sourceLangIndex = i }
        }
        if d.object(forKey: k.tgt) != nil {
            let i = d.integer(forKey: k.tgt)
            if i >= 0 && i < translateLangs.count { targetLangIndex = i }
        }
        translationInput = d.string(forKey: k.input) ?? translationInput
        lastTranslation = d.string(forKey: k.result) ?? lastTranslation
    }

    /// Wipe the saved input + result text — invoked from the 🗑 button so a
    /// clear also empties the persisted copy. The src/tgt language keys are
    /// left intact: the 🗑 button doesn't reset the user's language choice,
    /// so neither should this.
    private func clearSavedTranslateState() {
        guard let d = UserDefaults(suiteName: "group.com.yunajung.fonki") else { return }
        let k = Self.translateStateKeys
        d.removeObject(forKey: k.input)
        d.removeObject(forKey: k.result)
    }

    /// Rebuild the keyboard rows AND the bottom bar.
    /// Falls back to a full `showMode` if the container is gone.
    ///
    /// The bottom bar lives as a sibling of `kbArea` inside the outer
    /// translate `stack`, so we must tear it down explicitly here —
    /// otherwise the layout swap (e.g. QWERTY → cheonjiin via 한/영
    /// toggle) leaves the stale bar visible alongside the cheonjiin
    /// row 4, producing a doubled-controls row.
    private func rebuildTranslateKeys() {
        guard let container = translateKeyboardContainer,
              let outerStack = container.superview as? UIStackView else {
            showMode(.translate)
            return
        }

        UIView.performWithoutAnimation {
            // Tear down + rebuild kbArea contents (rowStacks or cheonjiin
            // container). fieldView is in mainStack and is NOT touched here.
            // Every translate keypad — 천지인 / QWERTY / 두벌식 / 숫자 — is
            // built to the same total height (218pt, see
            // `buildCheonjiinKeypadRows` + `buildTranslateKeyboardRows`), so
            // swapping keypads no longer shifts mainStack's layout and the
            // fieldView height stays constant without any capture/re-pin hack.
            print("🫧[DIAG] rebuildTranslateKeys: container rows BEFORE clear=\(container.arrangedSubviews.count)")
            container.arrangedSubviews.forEach { $0.removeFromSuperview() }
            print("🫧[DIAG] rebuildTranslateKeys: container rows AFTER clear=\(container.arrangedSubviews.count)")
            vintageGrayKeys.removeAll()
            letterKeys.removeAll()
            bubbleMintKeys.removeAll()
            buildTranslateKeyboardRows(into: container)
            print("🫧[DIAG] rebuildTranslateKeys: container rows AFTER build=\(container.arrangedSubviews.count)")
            // Bottom bar lives as a sibling of kbArea inside outerStack —
            // drop and re-add it via the same helper buildTranslateMode uses,
            // so cheonjiin mode (which skips the bar) and the other modes
            // (QWERTY / dubeolsik / number) stay symmetric.
            translateBottomBar?.removeFromSuperview()
            translateBottomBar = nil
            isBuildingTranslateLayout = true
            addTranslateBottomBarIfNeeded(to: outerStack)
            isBuildingTranslateLayout = false

            // fieldView guard — if anything has knocked it out of mainStack
            // index 0 (e.g. an implicit layout pass during the cheonjiin
            // container's `heightAnchor` activation pushed it through a
            // reparenting cycle in iOS's stackview internals), put it back.
            // The visible symptom of this drift was fieldView floating up
            // past modeBar's top edge and the host app's Paste affordance
            // bleeding through the gap.
            if let fv = translationFieldView,
               fv.superview === mainStack,
               mainStack.arrangedSubviews.firstIndex(of: fv) != 0 {
                mainStack.removeArrangedSubview(fv)
                mainStack.insertArrangedSubview(fv, at: 0)
            }

            // Force layout to settle inside this no-animation transaction so
            // the user doesn't see a transitional frame where kbArea and the
            // bottom bar are mid-resize. Without this, UIKit defers layout
            // until the next runloop tick and the intermediate state is
            // visible as a flash / jump.
            outerStack.layoutIfNeeded()
            mainStack.layoutIfNeeded()
            applyBubbleMintGradientToTranslateLetterKeys()
        }
    }

    private func applyBubbleMintGradientToTranslateLetterKeys() {
        // 🫧[DIAG-APPLY] guard 실패 로그
        guard currentTheme == .bubbleMint else {
            print("🫧[DIAG-APPLY] SKIP: theme=\(currentTheme)")
            return
        }
        guard let container = translateKeyboardContainer else {
            print("🫧[DIAG-APPLY] SKIP: translateKeyboardContainer is nil")
            return
        }
        guard !(isKoreanMode && koreanInputMode == "cheonjiin" && !isTranslateNumberMode) else {
            print("🫧[DIAG-APPLY] SKIP: cheonjiin mode")
            return
        }
        // 🫧[DIAG-APPLY] ───────────────────────────────────────────────────
        print("🫧[DIAG-APPLY] ENTER: container rows=\(container.arrangedSubviews.count), container.frame=\(container.frame)")
        for (ri, rv) in container.arrangedSubviews.enumerated() {
            if let rs = rv as? UIStackView {
                let titles = rs.arrangedSubviews.map { v -> String in
                    if let b = v as? HitExpandButton {
                        let ok = b.bounds.width > 0 && b.bounds.height > 0
                        return "HEB(\(b.title(for:.normal) ?? "?"):\(b.bounds.size)\(ok ? "✓" : "✗SKIP"))"
                    }
                    return "UIB(\(type(of:v)))"
                }
                print("🫧[DIAG-APPLY]   row[\(ri)]: \(titles)")
            } else {
                print("🫧[DIAG-APPLY]   row[\(ri)]: NOT UIStackView — \(type(of:rv))")
            }
        }
        // ──────────────────────────────────────────────────────────────────
        for rowView in container.arrangedSubviews {
            guard let rowStack = rowView as? UIStackView else { continue }
            for subview in rowStack.arrangedSubviews {
                guard let btn = subview as? HitExpandButton else { continue }
                guard btn.bounds.width > 0, btn.bounds.height > 0 else { continue }

                btn.layer.sublayers?.filter { $0 is CAGradientLayer || $0 is CAShapeLayer }
                    .forEach { $0.removeFromSuperlayer() }
                btn.layer.mask = nil
                btn.layer.cornerRadius = 0
                btn.layer.masksToBounds = false

                let r = btn.bounds.height / 2
                let path = UIBezierPath(roundedRect: btn.bounds, cornerRadius: r)

                let gradient = CAGradientLayer()
                gradient.frame = btn.bounds
                gradient.colors = [
                    UIColor.white.cgColor,
                    UIColor(red: 0.75, green: 0.95, blue: 0.80, alpha: 1).cgColor,
                ]
                gradient.locations = [0, 1]
                gradient.startPoint = CGPoint(x: 0.5, y: 0)
                gradient.endPoint   = CGPoint(x: 0.5, y: 1)
                let gradMask = CAShapeLayer()
                gradMask.path = path.cgPath
                gradient.mask = gradMask
                btn.layer.insertSublayer(gradient, at: 0)

                let border = CAShapeLayer()
                border.path = path.cgPath
                border.fillColor = UIColor.clear.cgColor
                border.strokeColor = UIColor(red: 0.55, green: 0.80, blue: 0.62, alpha: 1).cgColor
                border.lineWidth = 1.5
                btn.layer.addSublayer(border)

                btn.backgroundColor = .clear
            }
        }
    }

    @objc private func translateToggleKorEng() {
        // Flush BOTH composers — without `cjjReset()` the cheonjiin
        // cycle state (cjjLastGroup / cjjVowelChain / cjjPunctIdx) could
        // survive across a 한/영 toggle and merge into the next session,
        // causing the layout to appear to flicker between cheonjiin /
        // QWERTY on subsequent taps.
        hgFlush()
        cjjReset()
        isKoreanMode.toggle()
        isTranslateNumberMode = false
        isTranslateShifted = false
        isTranslateCapsLock = false
        rebuildTranslateKeys()
    }

    @objc private func translateToggleNumberMode() {
        hgFlush()
        isTranslateNumberMode.toggle()
        if !isTranslateNumberMode { isTranslateSymbolPage2 = false }
        translateNumToggleButton?.setTitle(
            isTranslateNumberMode ? "ABC" : "123", for: .normal)
        rebuildTranslateKeys()
    }

    @objc private func translateToggleSymbolPage() {
        isTranslateSymbolPage2.toggle()
        rebuildTranslateKeys()
    }

    @objc private func translateShiftTapped() {
        let now = Date()
        if let last = lastShiftTime, now.timeIntervalSince(last) < 0.4 {
            // Double tap → caps lock
            isTranslateCapsLock = true
            isTranslateShifted = true
        } else if isTranslateCapsLock {
            // Was caps lock → turn off
            isTranslateCapsLock = false
            isTranslateShifted = false
        } else {
            // Single tap → toggle shift
            isTranslateShifted.toggle()
        }
        lastShiftTime = now
        rebuildTranslateKeys()
    }

    @objc private func translateKeyTapped(_ s: UIButton) {
        guard let key = s.title(for: .normal) else { return }
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
        if isKoreanMode && !isTranslateNumberMode {
            handleHangulInput(key)
            // Auto-release one-shot shift. SYNC rebuild (no
            // `DispatchQueue.main.async`) — the async dispatch was the
            // root cause of "키 누를 때마다 키패드가 전환됨" symptom:
            // it deferred `rebuildTranslateKeys` to the next runloop tick,
            // so subsequent rapid taps landed on the OLD button refs
            // about to be torn down, producing visible flicker. The
            // identical fix was applied to fonts-tab `letterTapped`
            // earlier; this brings translate-tab `translateKeyTapped` in
            // line. Sync rebuild completes inside the current event tick
            // so the next touch hits freshly-built buttons cleanly.
            if isTranslateShifted && !isTranslateCapsLock {
                isTranslateShifted = false
                rebuildTranslateKeys()
            }
        } else {
            hgFlush()
            translateTargetAppend(key)
            if isTranslateShifted && !isTranslateCapsLock {
                isTranslateShifted = false
                rebuildTranslateKeys()
            }
        }
    }

    @objc private func translateSpaceTapped() {
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
        // Cheonjiin "smart space" — mirrors fonts-tab `spaceTapped`'s
        // jongsung-commit behavior but gated on translate-tab state
        // (`isKoreanMode` instead of `isFontsKorean`). When a syllable
        // with a 받침 is currently being composed in 천지인 mode, space
        // commits the syllable boundary WITHOUT inserting a literal space
        // — fixes "안 + ㄴ → 알 cycling" by letting users tap space to
        // start a new syllable cleanly. A literal space is still possible
        // by tapping space again after the smart-commit (buffer empty,
        // falls through to the normal branch).
        if isKoreanMode && koreanInputMode == "cheonjiin" && hgJong > 0 {
            hgFlush()
            cjjReset()
            return
        }
        hgFlush()
        translateTargetAppend(" ")
    }

    @objc private func translateDeleteTapped() {
        // Selected text in the host app → one `deleteBackward()` clears the
        // whole selection. Only fires when the host app holds the selection;
        // when the in-keyboard `translateInputField` is focused its own
        // selection isn't reported here, so this falls through to the
        // existing path (UITextView.deleteBackward handles its selection
        // natively).
        if let selected = textDocumentProxy.selectedText, !selected.isEmpty {
            textDocumentProxy.deleteBackward()
            hgFlush()
            cjjReset()
            DispatchQueue.global(qos: .userInteractive).async {
                AudioServicesPlaySystemSound(1104)
            }
            return
        }
        // A 타겟(translateInputField)일 때만 빈칸 가드 — A.text는 신뢰 가능.
        // B 타겟(host app)일 때는 documentContextBeforeInput 신뢰 불가 앱이
        // 있으므로 가드 생략; deleteBackward는 빈 곳에서 no-op이라 안전.
        if !translateTargetsHostApp {
            guard !(translateInputField?.text?.isEmpty ?? true) else { return }
        }
        performTranslateDelete()
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
    }

    /// Delete one unit without audio feedback — used by long-press repeat
    /// so the click sound doesn't fire on every tick.
    private func performTranslateDelete() {
        if isKoreanMode {
            handleHangulDelete()
        } else {
            translateTargetRemoveLast()
        }
    }

    // MARK: - Hangul Composition Engine

    private func hgCompose() -> String {
        if hgCho >= 0 && hgJung >= 0 {
            return String(UnicodeScalar(0xAC00 + hgCho * 21 * 28 + hgJung * 28 + hgJong)!)
        } else if hgCho >= 0 {
            return CHO[hgCho]
        }
        return ""
    }

    private func hgFlush() { hgCho = -1; hgJung = -1; hgJong = 0 }

    // MARK: - Cheonjiin (천지인) Engine
    //
    // The user spec asked us to keep this simple: 천지인 buttons map to the
    // same 두벌식 jamos that `handleHangulInput` already understands, so we
    // *just* feed jamos in and let the existing Hangul state machine do its
    // syllable assembly. The only state we own here is:
    //
    //   1) Consonant cycle position — consecutive taps on the same multi-
    //      jamo button (ㄱㅋ, ㄴㄹ, …) cycle through `CJJ_CONSONANTS[k]`.
    //      Each cycle step undoes the previous emission via
    //      `handleHangulDelete()` and emits the next jamo via
    //      `handleHangulInput()`.
    //
    //   2) Vowel chain — taps on ㅣ/·/ㅡ accumulate into `cjjVowelChain`.
    //      Each successful chain extension undoes the previous vowel and
    //      emits the new one. An isolated `·` (chain == "·") emits nothing
    //      and waits for ㅣ or ㅡ to pair.
    //
    // Boundaries that flush state: timeout (`CJJ_TIMEOUT`), pressing a key
    // outside the current cycle group, space, return, language toggle,
    // backspace (single tap), or leaving the .fonts/.translate mode. Edge
    // cases not covered by this minimum-viable engine: compound jungs
    // (ㅘ/ㅝ/ㅢ — those need state across consonant boundaries), cycle-
    // step backspace (we always commit + delete one jamo), and long-press.

    /// Reset all 천지인 state — drop any cycle position, kill the timer,
    /// clear the vowel chain. Does *not* call `handleHangulDelete` — by
    /// design, the most-recently-emitted jamo stays in the host editor as
    /// the committed character.
    private func cjjReset() {
        cjjLastGroup = nil
        cjjConsonantIdx = 0
        cjjVowelChain = ""
        cjjLastEmitted = ""
        cjjPunctIdx = 0
        cjjTimer?.invalidate()
        cjjTimer = nil
    }

    /// (Re)start the auto-commit timer. Fires once after `CJJ_TIMEOUT`s of
    /// inactivity and finalizes whatever cycle is in flight.
    private func cjjArmTimer() {
        cjjTimer?.invalidate()
        cjjTimer = Timer.scheduledTimer(
            withTimeInterval: CJJ_TIMEOUT, repeats: false
        ) { [weak self] _ in self?.cjjReset() }
    }

    /// Emit a single jamo via the existing Hangul engine, undoing any prior
    /// in-cycle emission first. Returns the emitted jamo so callers can
    /// stash it as `cjjLastEmitted`.
    private func cjjEmit(_ jamo: String) {
        if !cjjLastEmitted.isEmpty {
            handleHangulDelete()
        }
        if !jamo.isEmpty {
            handleHangulInput(jamo)
        }
        cjjLastEmitted = jamo
    }

    /// Handle a tap on a 천지인 keypad button.
    ///
    /// The button's title is the cycle group identifier itself (e.g. the
    /// raw key labels `"ㄱㅋ"`, `"ㅣ"`, `"·"`) — we look the label up in
    /// `CJJ_CONSONANTS` for consonant rows or treat ㅣ/·/ㅡ as vowel-chain
    /// extenders. Anything else is a no-op (separator/spacer keys).
    private func handleCheonjiinTap(_ label: String) {
        // Vowel chain branch: ㅣ / · / ㅡ.
        if label == "ㅣ" || label == "·" || label == "ㅡ" {
            // Different group active → commit it and start fresh.
            if cjjLastGroup != "VOWEL" {
                cjjReset()
                cjjLastGroup = "VOWEL"
            }
            // Try extending the chain. If the new chain isn't in the table
            // and isn't a fresh single tap that *could* extend, commit and
            // start a new chain with this tap.
            let extended = cjjVowelChain + label
            if let jamo = CJJ_VOWELS[extended] {
                // Exact match — extend chain and emit the mapped jamo.
                cjjVowelChain = extended
                cjjEmit(jamo)
            } else if CJJ_VOWELS.keys.contains(where: { $0.hasPrefix(extended) }) {
                // Valid prefix of some longer key (e.g. `·` is a prefix of
                // `·ㅡ`/`·ㅣ`; `··` is a prefix of `··ㅣ`/`··ㅡ`). Extend the
                // chain WITHOUT emit — wait for the next tap to complete a
                // table entry. This is what makes ㅛ via `·· + ㅡ` and ㅕ via
                // `·· + ㅣ` reachable; without it, the second `·` would reset
                // chain to `"·"` and the following ㅡ/ㅣ would emit ㅗ/ㅓ.
                cjjVowelChain = extended
            } else if extended.count >= 2 {
                // Chain doesn't extend and isn't a valid prefix — commit
                // current, start anew with this single new tap. The committed
                // jamo stays in the editor.
                cjjLastEmitted = ""
                cjjVowelChain = label
                if let jamo = CJJ_VOWELS[label] {
                    handleHangulInput(jamo)
                    cjjLastEmitted = jamo
                }
                // For `·` alone, no jamo to emit yet — wait for next tap.
            } else {
                // First tap of the chain.
                cjjVowelChain = label
                if let jamo = CJJ_VOWELS[label] {
                    handleHangulInput(jamo)
                    cjjLastEmitted = jamo
                }
                // Isolated `·` lands here too — emit nothing.
            }
            cjjArmTimer()
            return
        }

        // Consonant branch — only multi-jamo cycle keys are recognized.
        guard let cycle = CJJ_CONSONANTS[label] else { return }
        if cjjLastGroup == label {
            // Same button tapped again within timeout — advance the cycle.
            cjjConsonantIdx = (cjjConsonantIdx + 1) % cycle.count
            cjjEmit(cycle[cjjConsonantIdx])
        } else {
            // Different group → commit current, start fresh.
            cjjReset()
            cjjLastGroup = label
            cjjConsonantIdx = 0
            handleHangulInput(cycle[0])
            cjjLastEmitted = cycle[0]
        }
        cjjArmTimer()
    }

    /// Where the 천지인 keypad is being rendered — drives the row-4 variant.
    /// Rows 1-3 are identical across hosts (jamo cycle + ⌫/🔍/.,?!); only
    /// row 4 changes: the Aa tab needs system controls (mode toggle, lang
    /// toggle, comma) while the translate tab needs translate-specific
    /// actions (번역 / 삽입) inline with the cheonjiin row so it can replace
    /// the standard translate bottom bar entirely.
    private enum CheonjiinHost {
        case fontsTab
        case translateTab
    }

    /// Build the 천지인 keypad rows into the given vertical stack. Used by
    /// both the Aa tab and the translate tab. Includes its own row 4 so
    /// callers should skip the standard bottom bar when this layout is
    /// active.
    ///
    /// Row 4 layout (host-dependent):
    ///   • `.fontsTab`     → !#1 / 한/영 / ㅇㅁ⁰ / space / ,
    ///   • `.translateTab` → ㅇㅁ⁰ / space(2×) / 번역 / 삽입
    ///
    /// Rows 1-3 (common):
    ///   ┌──────┬──────┬──────┬──────┐
    ///   │ ㅣ¹  │ ·²   │ ㅡ³  │  ⌫   │
    ///   ├──────┼──────┼──────┼──────┤
    ///   │ㄱㅋ⁴ │ㄴㄹ⁵ │ㄷㅌ⁶ │ 🔍   │
    ///   ├──────┼──────┼──────┼──────┤
    ///   │ㅂㅍ⁷ │ㅅㅎ⁸ │ㅈㅊ⁹ │ .,?! │
    ///   └──────┴──────┴──────┴──────┘
    private func buildCheonjiinKeypadRows(into stack: UIStackView,
                                          host: CheonjiinHost = .fontsTab) {
        // Helper: build a jamo cycle key with the small digit badge in the
        // top-right corner. `digit == nil` skips the badge (used for the
        // ㅇㅁ key in row 4 where we want the digit too — it gets "0").
        func makeJamoKey(_ label: String, digit: String) -> UIButton {
            let btn = makeLetterKey(label)
            btn.titleLabel?.font = .systemFont(ofSize: 17)
            if !(currentTheme == .bubbleMint && isBuildingTranslateLayout) && currentTheme != .vintageGray {
                btn.backgroundColor = (currentTheme == .pastelRainbow || currentTheme == .retroCream || currentTheme == .lavender || currentTheme == .hotPink) ? keyBG : .white
            }
            if currentTheme == .bubbleMint && isBuildingTranslateLayout {
                btn.layer.borderWidth = 0
                btn.backgroundColor = .clear
                btn.layer.cornerRadius = 0
                btn.layer.masksToBounds = false
                btn.clipsToBounds = false
                bubbleMintKeys.append(btn)
            }
            btn.addTarget(self, action: #selector(cheonjiinKeyTapped(_:)), for: .touchDown)
            // Top-right digit badge — `userInteractionEnabled = false` so
            // the badge doesn't intercept taps.
            let badge = UILabel()
            badge.text = digit
            badge.font = .systemFont(ofSize: 11, weight: .medium)
            badge.textColor = UIColor(white: 0.55, alpha: 1)
            badge.isUserInteractionEnabled = false
            badge.translatesAutoresizingMaskIntoConstraints = false
            btn.addSubview(badge)
            NSLayoutConstraint.activate([
                badge.topAnchor.constraint(equalTo: btn.topAnchor, constant: 4),
                badge.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -6),
            ])
            letterKeys.append(btn)
            return btn
        }

        // Helper: build a gray "function" key — bg #D1D3D9-ish for visual
        // contrast against the white jamo keys.
        func makeFnKey(title: String) -> UIButton {
            let btn = makeSpecialKey(title)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            if currentTheme != .bubbleMint && currentTheme != .vintageGray && currentTheme != .soft && currentTheme != .retroCream && currentTheme != .default && currentTheme != .hotPink {
                btn.backgroundColor = currentTheme == .pastelRainbow ? UIColor(white: 1.0, alpha: 0.5) : UIColor(white: 0.82, alpha: 1)
            }
            if currentTheme == .bubbleMint && isBuildingTranslateLayout {
                btn.backgroundColor = specialKeyBG
                btn.layer.borderWidth = 0
            }
            btn.setTitleColor(.darkText, for: .normal)
            return btn
        }

        // Row metrics — host-dependent.
        //
        // `.fontsTab`: kept tight (51/1 → 4×51 + 3×1 = 207pt) to absorb the
        // fonts-tab chrome and avoid the small-device overflow.
        //
        // `.translateTab`: 53/2 → 4×53 + 3×2 = 218pt. This MATCHES the
        // 두벌식/숫자 translate keypad total (kbArea 3×52 + 2×4 = 164, +
        // stack.spacing 2, + bottomBar 52 = 218). Equalizing every translate
        // keypad to 218pt is the root-cause fix for the fieldView height
        // jumping on 한/영 keypad switches: with all keypads the same height,
        // mainStack's layout never shifts when kbArea is rebuilt — no
        // capture/re-pin hack needed.
        let rowHeight: CGFloat
        let rowSpacing: CGFloat
        switch host {
        case .fontsTab:
            rowHeight = 51
            rowSpacing = 1
        case .translateTab:
            rowHeight = 53
            rowSpacing = 2
        }

        // All 4 rows live inside a single `cheonjiinContainer` vertical
        // stack with `distribution = .fillEqually`. That guarantees the
        // rows share height evenly regardless of internal constraints — in
        // particular row 4's mixed `.fill` distribution with proportional
        // width multipliers was previously rendering at a different visual
        // height than rows 1-3 even though each row carried an explicit
        // `heightAnchor = 52`. Letting the container divide its total height
        // evenly is the layout-engine-blessed way to keep them in sync.
        let cheonjiinContainer = UIStackView()
        cheonjiinContainer.axis = .vertical
        cheonjiinContainer.distribution = .fillEqually
        cheonjiinContainer.spacing = rowSpacing
        cheonjiinContainer.translatesAutoresizingMaskIntoConstraints = false
        // Total = 4 rows × rowHeight + 3 inter-row gaps × rowSpacing.
        cheonjiinContainer.heightAnchor.constraint(
            equalToConstant: 4 * rowHeight + 3 * rowSpacing
        ).isActive = true

        // ── Row 1: ㅣ¹ ·² ㅡ³ ⌫ ────────────────────────────────────
        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.distribution = .fillEqually
        row1.spacing = 4
        row1.addArrangedSubview(makeJamoKey("ㅣ", digit: "1"))
        row1.addArrangedSubview(makeJamoKey("·", digit: "2"))
        row1.addArrangedSubview(makeJamoKey("ㅡ", digit: "3"))
        let del = makeFnKey(title: "")
        let delImg = UIImage(systemName: "delete.left",
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular))
        del.setImage(delImg, for: .normal)
        del.tintColor = .darkText
        if currentTheme == .retroCream {
            del.backgroundColor = UIColor(red: 1.0, green: 0.90, blue: 0.50, alpha: 1)
        }
        if currentTheme == .vintageGray && host == .translateTab {
            del.backgroundColor = specialKeyBG
        }
        if currentTheme == .cottonCandy {
            del.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.96, alpha: 1)
        }
        if currentTheme == .lavender {
            del.backgroundColor = keyBG
        }
        del.addTarget(self, action: #selector(cheonjiinBackspaceTapped), for: .touchDown)
        attachBackspaceLongPress(to: del)
        row1.addArrangedSubview(del)
        cheonjiinContainer.addArrangedSubview(row1)

        // ── Row 2: ㄱㅋ⁴ ㄴㄹ⁵ ㄷㅌ⁶ + [col 4] ─────────────────────────
        // Col 4 is host-dependent: fonts tab keeps ← (cursor-left); translate
        // tab swaps in `.,?!` here (moved up from row 3) so row 3 can carry
        // the new newline key instead. Jamo columns 1-3 are untouched and
        // identical for both hosts.
        let row2 = UIStackView()
        row2.axis = .horizontal
        row2.distribution = .fillEqually
        row2.spacing = 4
        row2.addArrangedSubview(makeJamoKey("ㄱㅋ", digit: "4"))
        row2.addArrangedSubview(makeJamoKey("ㄴㄹ", digit: "5"))
        row2.addArrangedSubview(makeJamoKey("ㄷㅌ", digit: "6"))
        switch host {
        case .fontsTab:
            // ← cursor-left — unchanged from before this edit. The shared
            // `cheonjiinCursorLeftTapped` handler flushes Hangul / cheonjiin
            // engine state before moving the cursor, so the next jamo tap
            // doesn't merge into the syllable the cursor just departed.
            let arrowLeft = makeFnKey(title: "")
            let leftImg = UIImage(systemName: "chevron.left",
                                  withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium))
            arrowLeft.setImage(leftImg, for: .normal)
            arrowLeft.tintColor = .darkText
            if currentTheme == .retroCream && host == .fontsTab {
                arrowLeft.backgroundColor = UIColor(red: 0.98, green: 0.75, blue: 0.80, alpha: 1)
            }
            if currentTheme == .cottonCandy {
                arrowLeft.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.96, alpha: 1)
            }
            if currentTheme == .lavender {
                arrowLeft.backgroundColor = keyBG
            }
            arrowLeft.addTarget(self, action: #selector(cheonjiinCursorLeftTapped), for: .touchDown)
            row2.addArrangedSubview(arrowLeft)
        case .translateTab:
            // `.,?!` moved up here from row 3 to make room for the newline
            // key below. Same punctuation-cycle handler as before, just
            // relocated.
            let punctUp = makeFnKey(title: ".,?!")
            punctUp.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            if currentTheme == .vintageGray {
                punctUp.backgroundColor = specialKeyBG
            }
            if currentTheme == .cottonCandy {
                punctUp.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.96, alpha: 1)
            }
            if currentTheme == .lavender {
                punctUp.backgroundColor = keyBG
            }
            punctUp.addTarget(self, action: #selector(cheonjiinPunctTapped), for: .touchDown)
            row2.addArrangedSubview(punctUp)
        }
        cheonjiinContainer.addArrangedSubview(row2)

        // ── Row 3: ㅂㅍ⁷ ㅅㅎ⁸ ㅈㅊ⁹ + [col 4] ─────────────────────────
        // Col 4 is host-dependent: fonts tab keeps `.,?!` (unchanged);
        // translate tab gets a newline key here instead, routed through the
        // same `translateReturnTapped` the 두벌식 bottom bar's enter key
        // already uses (A/B-routes: input box when focused, host app
        // otherwise — reused as-is, not duplicated).
        let row3 = UIStackView()
        row3.axis = .horizontal
        row3.distribution = .fillEqually
        row3.spacing = 4
        row3.addArrangedSubview(makeJamoKey("ㅂㅍ", digit: "7"))
        row3.addArrangedSubview(makeJamoKey("ㅅㅎ", digit: "8"))
        row3.addArrangedSubview(makeJamoKey("ㅈㅊ", digit: "9"))
        switch host {
        case .fontsTab:
            let punct = makeFnKey(title: ".,?!")
            punct.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            if currentTheme == .retroCream && host == .fontsTab {
                punct.backgroundColor = UIColor(red: 0.98, green: 0.75, blue: 0.80, alpha: 1)
            }
            if currentTheme == .cottonCandy {
                punct.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.96, alpha: 1)
            }
            if currentTheme == .lavender {
                punct.backgroundColor = keyBG
            }
            punct.addTarget(self, action: #selector(cheonjiinPunctTapped), for: .touchDown)
            row3.addArrangedSubview(punct)
        case .translateTab:
            let returnBtn = makeFnKey(title: "")
            let returnImg = UIImage(systemName: "return",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium))
            returnBtn.setImage(returnImg, for: .normal)
            returnBtn.tintColor = .darkText
            if currentTheme == .vintageGray {
                returnBtn.backgroundColor = specialKeyBG
            }
            if currentTheme == .cottonCandy {
                returnBtn.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.96, alpha: 1)
            }
            if currentTheme == .lavender {
                returnBtn.backgroundColor = keyBG
            }
            returnBtn.addTarget(self, action: #selector(translateReturnTapped), for: .touchDown)
            row3.addArrangedSubview(returnBtn)
        }
        cheonjiinContainer.addArrangedSubview(row3)

        // ── Row 4: host-dependent ───────────────────────────────────────
        // `.fontsTab`:     [한/영 | 123]  ㅇㅁ⁰  ⎵  ↵     (4 column slots,
        //                  slot 1 is a nested HStack with 2 sub-keys so the
        //                  remaining 3 single-key slots align under columns
        //                  2-4 of rows 1-3, i.e. ㅇㅁ sits below ㄴㄹ/ㅅㅎ,
        //                  ⎵ below ㄷㅌ/ㅈㅊ, ↵ below ⌫/🔍/.,?!.)
        // `.translateTab`: 한/영 / ㅇㅁ⁰ / 번역 / 삽입    (4 equal cells)
        //
        // Both variants use `.fillEqually` at the outer level so the four
        // column slots split the row width evenly — same widths as the
        // four cells of rows 1-3. Height comes from the surrounding
        // `cheonjiinContainer.fillEqually`, so row 4 has no own heightAnchor.
        let row4 = UIStackView()
        row4.axis = .horizontal
        row4.distribution = .fillEqually
        row4.spacing = 4

        switch host {
        case .fontsTab:
            // Slot 1: [한/영 | 123] nested HStack. Two keys split the
            // column-1 width evenly, so each is ~½ the width of a single
            // jamo cell in rows 1-3. This keeps both controls reachable on
            // a single tap while letting the remaining 3 slots line up
            // perfectly with the columns above.
            let slot1 = UIStackView()
            slot1.axis = .horizontal
            slot1.distribution = .fillEqually
            slot1.spacing = 4

            // 한/영 — toggles `isFontsKorean` (cheonjiin ↔ QWERTY English).
            // Accent highlight when Korean is active.
            let langToggle = makeFnKey(title: isFontsKorean ? "En" : "Ko")
            langToggle.addTarget(self, action: #selector(fontLangToggleTapped), for: .touchDown)
            langToggle.backgroundColor = accentColor
            langToggle.setTitleColor(.white, for: .normal)
            if currentTheme == .cottonCandy {
                langToggle.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 1)
                langToggle.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .lavender {
                langToggle.backgroundColor = UIColor(red: 0.80, green: 0.70, blue: 0.95, alpha: 1)
                langToggle.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .pastelRainbow {
                langToggle.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
                langToggle.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .hotPink {
                langToggle.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .soft {
                langToggle.backgroundColor = UIColor(red: 0.97, green: 0.90, blue: 0.93, alpha: 1)
                langToggle.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .bubbleMint {
                langToggle.backgroundColor = UIColor(red: 0.95, green: 0.85, blue: 0.90, alpha: 1)
                langToggle.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .retroCream {
                langToggle.setTitleColor(.black, for: .normal)
                if isFontsKorean {
                    langToggle.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
                }
            }
            if currentTheme == .vintageGray {
                langToggle.backgroundColor = specialKeyBG
                langToggle.setTitleColor(.black, for: .normal)
            }
            slot1.addArrangedSubview(langToggle)

            // 123 — switches to the number/symbol page (toggleNumberMode).
            // From the number page, the bottom bar's 한/영 key returns
            // back to cheonjiin (handled in `buildFontsMode`).
            let numToggle = makeFnKey(title: "123")
            numToggle.backgroundColor = keyBG
            if currentTheme == .retroCream {
                numToggle.backgroundColor = UIColor(red: 0.98, green: 0.75, blue: 0.80, alpha: 1)
            }
            if currentTheme == .vintageGray {
                numToggle.backgroundColor = specialKeyBG
            }
            if currentTheme == .cottonCandy {
                numToggle.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.96, alpha: 1)
            }
            if currentTheme == .lavender {
                numToggle.backgroundColor = keyBG
            }
            if currentTheme == .soft {
                numToggle.backgroundColor = UIColor(red: 0.97, green: 0.90, blue: 0.93, alpha: 1)
            }
            if currentTheme == .hotPink {
                numToggle.backgroundColor = specialKeyBG
            }
            if currentTheme == .bubbleMint {
                numToggle.backgroundColor = specialKeyBG
            }
            numToggle.addTarget(self, action: #selector(toggleNumberMode), for: .touchDown)
            slot1.addArrangedSubview(numToggle)

            row4.addArrangedSubview(slot1)

            // Slot 2 (column 2 — below ㄴㄹ/ㅅㅎ): ㅇㅁ⁰ jamo.
            let omKey = makeJamoKey("ㅇㅁ", digit: "0")
            row4.addArrangedSubview(omKey)

            // Slot 3 (column 3 — below ㄷㅌ/ㅈㅊ): space. White background
            // with ⎵ glyph (U+23B5), matches the translate-tab cheonjiin
            // row-2 space key.
            let space = makeLetterKey("⎵")
            space.titleLabel?.font = .systemFont(ofSize: 22)
            space.backgroundColor = currentTheme == .pastelRainbow ? UIColor(white: 1.0, alpha: 0.5) : (currentTheme == .retroCream || currentTheme == .vintageGray || currentTheme == .hotPink || currentTheme == .lavender ? keyBG : .white)
            if currentTheme == .bubbleMint {
                space.layer.borderWidth = 0
                space.backgroundColor = .clear
                space.layer.cornerRadius = 0
                space.layer.masksToBounds = false
                space.clipsToBounds = false
                bubbleMintKeys.append(space)
            }
            space.addTarget(self, action: #selector(spaceTapped), for: .touchDown)
            row4.addArrangedSubview(space)

            // Slot 4 (column 4 — below ⌫/🔍/.,?!): return. Gray "function"
            // background with SF Symbol arrow.
            let returnBtn = makeFnKey(title: "")
            let returnImg = UIImage(systemName: "return",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium))
            returnBtn.setImage(returnImg, for: .normal)
            returnBtn.backgroundColor = currentTheme == .retroCream
                ? accentColor
                : specialKeyBG
            if currentTheme == .hotPink {
                returnBtn.backgroundColor = accentColor
            }
            if currentTheme == .bubbleMint {
                returnBtn.backgroundColor = specialKeyBG
            }
            returnBtn.tintColor = .black
            returnBtn.setTitleColor(.black, for: .normal)
            returnBtn.addTarget(self, action: #selector(returnTapped), for: .touchDown)
            row4.addArrangedSubview(returnBtn)

        case .translateTab:
            // 번역 탭 row 4: [한/영 | 123]  ㅇㅁ⁰  ⎵  [번역 | 삽입].
            // 4-slot grid where slot 1 and slot 4 each hold two nested
            // keys (.fillEqually) — col-1 width is split between 한/영
            // and 123, col-4 width is split between 번역 and 삽입. The
            // standard translate bottom bar is skipped by `buildTranslate
            // Mode` in cheonjiin Korean, so this row is the only entry
            // point for those actions.

            // Slot 1: [한/영 | 123] nested HStack
            let slot1 = UIStackView()
            slot1.axis = .horizontal
            slot1.distribution = .fillEqually
            slot1.spacing = 4

            // "En" because translate cheonjiin only appears in Korean mode
            let langToggle = makeFnKey(title: "En")
            langToggle.backgroundColor = accentColor
            langToggle.setTitleColor(.white, for: .normal)
            if currentTheme == .cottonCandy {
                langToggle.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 1)
                langToggle.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .lavender {
                langToggle.backgroundColor = UIColor(red: 0.80, green: 0.70, blue: 0.95, alpha: 1)
                langToggle.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .pastelRainbow {
                langToggle.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
                langToggle.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .hotPink {
                langToggle.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .soft {
                langToggle.backgroundColor = UIColor(red: 0.97, green: 0.90, blue: 0.93, alpha: 1)
                langToggle.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .bubbleMint {
                langToggle.backgroundColor = UIColor(red: 0.95, green: 0.85, blue: 0.90, alpha: 1)
                langToggle.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .retroCream {
                langToggle.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
                langToggle.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .vintageGray {
                langToggle.backgroundColor = specialKeyBG
                langToggle.setTitleColor(.black, for: .normal)
            }
            langToggle.addTarget(self, action: #selector(translateToggleKorEng), for: .touchUpInside)
            slot1.addArrangedSubview(langToggle)

            let numToggle = makeFnKey(title: "123")
            if currentTheme == .vintageGray {
                numToggle.backgroundColor = specialKeyBG
            }
            if currentTheme == .cottonCandy {
                numToggle.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.96, alpha: 1)
            }
            if currentTheme == .lavender {
                numToggle.backgroundColor = keyBG
            }
            if currentTheme == .soft {
                numToggle.backgroundColor = UIColor(red: 0.97, green: 0.90, blue: 0.93, alpha: 1)
            }
            numToggle.addTarget(self, action: #selector(translateToggleNumberMode), for: .touchUpInside)
            slot1.addArrangedSubview(numToggle)

            row4.addArrangedSubview(slot1)

            // Slot 2: ㅇㅁ⁰ jamo (column 2 — below ㄴㄹ/ㅅㅎ).
            let omKey = makeJamoKey("ㅇㅁ", digit: "0")
            row4.addArrangedSubview(omKey)

            // Slot 3: ⎵ space (column 3 — below ㄷㅌ/ㅈㅊ). Routes through
            // `translateSpaceTapped` which (a) writes to translateInput
            // Field when focused / host app otherwise, and (b) honors the
            // cheonjiin jongsung smart-commit (받침 후 space → 음절 확정).
            let space = makeLetterKey("⎵")
            space.titleLabel?.font = .systemFont(ofSize: 22)
            space.backgroundColor = currentTheme == .pastelRainbow ? UIColor(white: 1.0, alpha: 0.5) : (currentTheme == .retroCream || currentTheme == .vintageGray || currentTheme == .hotPink || currentTheme == .lavender ? keyBG : .white)
            if currentTheme == .bubbleMint {
                space.layer.borderWidth = 0
                space.backgroundColor = .clear
                space.layer.cornerRadius = 0
                space.layer.masksToBounds = false
                space.clipsToBounds = false
                bubbleMintKeys.append(space)
            }
            space.addTarget(self, action: #selector(translateSpaceTapped), for: .touchUpInside)
            row4.addArrangedSubview(space)

            // Slot 4: [번역 | 삽입] nested HStack (column 4 — below ←/.,?!).
            // Same nested 2-split pattern as slot 1 for visual symmetry.
            let slot4 = UIStackView()
            slot4.axis = .horizontal
            slot4.distribution = .fillEqually
            slot4.spacing = 4

            let trBtn = makeFnKey(title: loc("translate_button"))
            trBtn.backgroundColor = UIColor(white: 0.82, alpha: 1)
            trBtn.setTitleColor(.black, for: .normal)
            if currentTheme == .cottonCandy {
                trBtn.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 1)
                trBtn.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .lavender {
                trBtn.backgroundColor = UIColor(red: 0.80, green: 0.70, blue: 0.95, alpha: 1)
                trBtn.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .pastelRainbow {
                trBtn.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
                trBtn.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .hotPink {
                trBtn.backgroundColor = accentColor
                trBtn.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .soft {
                trBtn.backgroundColor = UIColor(red: 0.97, green: 0.90, blue: 0.93, alpha: 1)
                trBtn.setTitleColor(.black, for: .normal)
            }
            if currentTheme == .bubbleMint {
                trBtn.backgroundColor = specialKeyBG
                trBtn.layer.borderWidth = 0
            }
            if currentTheme == .retroCream {
                trBtn.backgroundColor = accentColor
            }
            if currentTheme == .default {
                trBtn.backgroundColor = specialKeyBG
            }
            trBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            trBtn.addTarget(self, action: #selector(translateTriggered), for: .touchUpInside)
            slot4.addArrangedSubview(trBtn)

            row4.addArrangedSubview(slot4)
        }

        cheonjiinContainer.addArrangedSubview(row4)
        stack.addArrangedSubview(cheonjiinContainer)
    }

    @objc private func cheonjiinKeyTapped(_ s: UIButton) {
        guard let label = s.title(for: .normal) else { return }
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
        // Visual tap feedback (92% shrink + accent tint pulse) — without
        // this, isolated `·` taps look completely dead because `·` alone
        // doesn't emit a jamo (it's buffered until the next vowel pairs
        // with it). Matching `letterTapped`'s tapFeedback call so every
        // 천지인 key gives the same visual confirmation as 두벌식 keys.
        tapFeedback(s)
        handleCheonjiinTap(label)
    }

    @objc private func cheonjiinBackspaceTapped() {
        // Selected text in the host app → one `deleteBackward()` clears the
        // whole selection. Composer/cheonjiin paths below only peel a single
        // jamo and ignore the selection, so intercept here and reset both
        // buffers.
        if let selected = textDocumentProxy.selectedText, !selected.isEmpty {
            textDocumentProxy.deleteBackward()
            hgFlush()
            cjjReset()
            DispatchQueue.global(qos: .userInteractive).async {
                AudioServicesPlaySystemSound(1104)
            }
            return
        }
        // Empty-target guard — suppress click sound on no-op delete. The
        // cheonjiin keypad is shared between fonts and translate tabs, so
        // pick the right target via `translateTargetsHostApp` (true when no
        // in-keyboard field is focused, i.e. fonts tab or translate-host
        // mode).
        if translateTargetsHostApp {
            let before = textDocumentProxy.documentContextBeforeInput ?? ""
            guard !before.isEmpty else { return }
        } else {
            guard !(translateInputField?.text?.isEmpty ?? true) else { return }
        }
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
        // 천지인 backspace = drop the most recently emitted jamo and reset
        // the cycle. Mid-cycle "step back" isn't supported (would require
        // reverse cycle state); deleting feels close enough for an MVP.
        cjjReset()
        handleHangulDelete()
    }

    @objc private func cheonjiinPunctTapped() {
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
        // `.,?!` cycle button — consecutive taps within `CJJ_TIMEOUT`
        // advance through the four-glyph cycle, with each step replacing
        // the previously-emitted glyph (`deleteBackward` + `insertText`).
        // A different-group tap, a timer expiry, or an explicit boundary
        // (space/return/etc.) resets the cycle and the next punct tap
        // starts fresh from `.`.
        let cycle = [".", ",", "?", "!"]
        if cjjLastGroup == "PUNCT" {
            cjjPunctIdx = (cjjPunctIdx + 1) % cycle.count
            translateTargetRemoveLast()
            translateTargetAppend(cycle[cjjPunctIdx])
        } else {
            // Fresh start — commit any in-flight Hangul / cheonjiin state
            // so the punctuation lands cleanly after the current syllable.
            hgFlush()
            cjjReset()
            cjjLastGroup = "PUNCT"
            cjjPunctIdx = 0
            translateTargetAppend(cycle[0])
        }
        cjjArmTimer()
    }

    @objc private func cheonjiinCommaTapped() {
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
        hgFlush()
        cjjReset()
        textDocumentProxy.insertText(",")
    }

    /// Move the host's caret one character to the left. Flushes the Hangul
    /// / cheonjiin engine state first — leaving in-flight cho/jung/jong
    /// state attached to a syllable the cursor has just moved away from
    /// would cause the next jamo tap to merge into the WRONG syllable.
    @objc private func cheonjiinCursorLeftTapped() {
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
        hgFlush()
        cjjReset()
        textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
    }

    /// Exit the number/symbol page back to the previous letter layout
    /// without flipping `isFontsKorean`. Used by the standard fonts-mode
    /// bottom bar's 한/영 button when `isNumberMode == true` — the user
    /// removed the dedicated `ABC` toggle from the number-page bottom bar,
    /// so the 한/영 key doubles as the "back to letters" exit while
    /// preserving the current language (Korean stays Korean, English stays
    /// English).
    @objc private func exitNumberModeBackToLetters() {
        hgFlush()
        cjjReset()
        isNumberMode = false
        isSymbolPage2 = false
        showMode(.fonts)
    }

    // MARK: - Translate Target Routing

    /// true: custom keypad input goes to host app (textDocumentProxy)
    /// false: input goes to translationInput (translate input field is focused)
    private var translateTargetsHostApp: Bool {
        return translateInputField?.isFirstResponder != true
    }

    private func translateTargetAppend(_ s: String) {
        if translateTargetsHostApp {
            textDocumentProxy.insertText(s)
        } else {
            translateInputField?.insertText(s)
            translationInput = translateInputField?.text ?? ""
        }
    }

    private func translateTargetRemoveLast() {
        if translateTargetsHostApp {
            textDocumentProxy.deleteBackward()
        } else {
            translateInputField?.deleteBackward()
            translationInput = translateInputField?.text ?? ""
        }
    }

    /// Return/newline for the translate tab — routes through the same
    /// `translateTargetsHostApp` flag `translateTargetAppend`/
    /// `translateTargetRemoveLast` already use, so it's consistent with
    /// every other A/B decision in this tab.
    ///
    /// Host-app target: just defers to the existing `returnTapped()`
    /// (unchanged, reused as-is).
    ///
    /// Input-box target: deliberately does NOT call
    /// `translateTargetAppend("\n")` — `UITextView.insertText(_:)` goes
    /// through `UITextViewDelegate.textView(_:shouldChangeTextIn:...)`,
    /// which explicitly rejects "\n" (treats it as "dismiss focus", see
    /// that delegate method). Mutating `.text` directly bypasses that
    /// delegate entirely, so this instead appends "\n" to the text itself
    /// and replicates the same bookkeeping `textViewDidChange` does
    /// (character cap, counter label, placeholder visibility) since a
    /// direct `.text` assignment doesn't trigger that callback either.
    @objc private func translateReturnTapped() {
        guard !translateTargetsHostApp else {
            returnTapped()
            return
        }
        // Finalize any in-progress Hangul/cheonjiin composition before
        // mutating `.text` directly below. `hgFlush()`/`cjjReset()` only
        // reset the composer's own index state (hgCho/hgJung/hgJong,
        // cjjLastGroup, etc.) — they never touch `field.text` or
        // `textDocumentProxy`, so they're safe for either A or B target,
        // same as `returnTapped()` already relies on. Without this, the
        // composer keeps believing it's still mid-syllable (e.g. "요")
        // after the newline is appended, so the next keystroke's
        // `hgReplaceLast` deletes the just-inserted "\n" instead of the
        // syllable it thinks is still last — producing duplicated/garbled
        // characters.
        hgFlush()
        cjjReset()
        guard let field = translateInputField else { return }
        var newText = (field.text ?? "") + "\n"
        if newText.count > 200 { newText = String(newText.prefix(200)) }
        field.text = newText
        translationInput = newText
        let cnt = newText.count
        translateCounterLabel?.text = "\(cnt) / 200"
        translateCounterLabel?.textColor = cnt >= 180 ? .systemRed : .lightGray
        translatePlaceholderLabel?.isHidden = !newText.isEmpty
    }

    private func hgReplaceLast(_ s: String) {
        translateTargetRemoveLast()
        translateTargetAppend(s)
    }

    private func handleHangulInput(_ key: String) {
        // `·` is a cheonjiin chain marker, never a Hangul jamo. Guard at the
        // engine boundary so any accidental feed (future code path, mistaken
        // CJJ_VOWELS entry) can't leak `·` into the editor via the State-0
        // `translateTargetAppend(key)` else-if branch below.
        if key == "·" { return }
        let ci = CHO.firstIndex(of: key)   // chosung index or nil
        let ji = JUNG.firstIndex(of: key)  // jungsung index or nil
        let isCon = ci != nil
        let isVow = ji != nil

        // STATE 0: Empty buffer
        if hgCho < 0 {
            if isCon {
                hgCho = ci!
                translateTargetAppend(hgCompose())
            } else if isVow {
                hgFlush()
                translateTargetAppend(key)
            }
            return
        }

        // STATE 1: Chosung only (no jungsung yet)
        if hgJung < 0 {
            if isVow {
                hgJung = ji!
                hgReplaceLast(hgCompose())
            } else if isCon {
                hgFlush()
                hgCho = ci!
                translateTargetAppend(hgCompose())
            }
            return
        }

        // STATE 2: Cho + Jung (no jongsung)
        if hgJong == 0 {
            if isVow {
                // Try compound vowel
                if let cj = CJ["\(hgJung),\(ji!)"] {
                    hgJung = cj
                    hgReplaceLast(hgCompose())
                    return
                }
                // Can't compound → flush, output standalone vowel
                hgFlush()
                translateTargetAppend(key)
            } else if isCon {
                // Try as jongsung
                let jIdx = JONG.firstIndex(of: key)
                if let jIdx = jIdx, jIdx > 0 {
                    hgJong = jIdx
                    hgReplaceLast(hgCompose())
                } else {
                    // Not valid jong → flush, new cho
                    hgFlush()
                    hgCho = ci!
                    translateTargetAppend(hgCompose())
                }
            }
            return
        }

        // STATE 3: Cho + Jung + Jong
        if isVow {
            // Vowel after jong → split jong off as new cho
            if let split = JSP[hgJong] {
                // Compound jong: split into (remaining jong, new cho)
                hgJong = split.0
                hgReplaceLast(hgCompose())
                hgFlush()
                hgCho = split.1
                hgJung = ji!
                translateTargetAppend(hgCompose())
            } else if let newCho = J2C[hgJong] {
                // Simple jong → becomes new cho
                hgJong = 0
                hgReplaceLast(hgCompose())
                hgFlush()
                hgCho = newCho
                hgJung = ji!
                translateTargetAppend(hgCompose())
            } else {
                hgFlush()
                translateTargetAppend(key)
            }
        } else if isCon {
            // Try compound jongsung
            if let ck = CK["\(hgJong),\(key)"] {
                hgJong = ck
                hgReplaceLast(hgCompose())
                return
            }
            // Can't compound → flush, new cho
            hgFlush()
            hgCho = ci!
            translateTargetAppend(hgCompose())
        }
    }

    private func handleHangulDelete() {
        if hgCho < 0 {
            // No composition — just remove last char
            translateTargetRemoveLast()
            return
        }
        if hgJong > 0 {
            // Remove jongsung (check compound first)
            if let split = JSP[hgJong] {
                hgJong = split.0
            } else {
                hgJong = 0
            }
            hgReplaceLast(hgCompose())
        } else if hgJung >= 0 {
            // Remove jungsung (check compound first)
            var found = false
            for (k, v) in CJ where v == hgJung {
                let parts = k.split(separator: ",")
                hgJung = Int(parts[0])!
                found = true
                break
            }
            if !found { hgJung = -1 }
            hgReplaceLast(hgCompose())
            if hgJung < 0 && hgCho >= 0 {
                // Only cho left — show as jamo
                hgReplaceLast(hgCompose())
            }
        } else {
            // Remove chosung
            translateTargetRemoveLast()
            hgFlush()
        }
    }

    @objc private func translateTriggered() {
        // Hard paywall: free tier can view/type in the translate tab (see
        // modeTapped) but can't actually run a translation. Gated here (the
        // action), not in buildTranslateMode (the screen) — see the comment
        // at modeTapped's `.translate` branch for why that distinction matters.
        guard isPremiumUser else {
            showLockedOverlay()
            return
        }
        // ORIGINAL: guard !translationInput.isEmpty else { return }
        // Try reading the active text field's content via textDocumentProxy first.
        // ORIGINAL: guard !translationInput.isEmpty else { return }
        let effectiveInput = translationInput
        guard !effectiveInput.isEmpty else { return }
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }

        // ── 입력 언어 = 타겟 언어 → 번역 없이 바로 삽입 ────────────────
        let tgtLang = translateLangs[targetLangIndex].1
        let containsKorean = effectiveInput.unicodeScalars.contains { $0.value >= 0xAC00 && $0.value <= 0xD7A3 }
        let containsLatin = effectiveInput.unicodeScalars.contains { ($0.value >= 0x41 && $0.value <= 0x5A) || ($0.value >= 0x61 && $0.value <= 0x7A) }
        if tgtLang == "Korean" && containsKorean {
            textDocumentProxy.insertText(effectiveInput)
            translateInputField?.resignFirstResponder()
            return
        }
        if tgtLang == "English" && containsLatin && !containsKorean {
            textDocumentProxy.insertText(effectiveInput)
            translateInputField?.resignFirstResponder()
            return
        }

        // ── DB 1차 조회 ─────────────────────────────────────────────────
        // Check the local TranslationDB (200×9 phrase pairs, exact match)
        // BEFORE running any of the API-side gates. A hit returns instantly,
        // costs nothing from the daily quota, and works even when Full Access
        // is off / the user is on the lifetime tier / the daily cap is
        // exhausted — because none of those constraints apply to a purely
        // local table lookup. On miss we fall through to the existing API
        // path unchanged.

        if let cached = TranslationDB.lookup(
            text: effectiveInput,
            from: translateLangs[sourceLangIndex].1,
            to: translateLangs[targetLangIndex].1
        ) {
            lastTranslation = sanitizeTranslationOutput(cached)
            textDocumentProxy.insertText(lastTranslation)
            translateInputField?.resignFirstResponder()
            return
        }

        // ── Knowledge Base 2차 조회 (밈/슬랭) ───────────────────────────
        // TranslationDB was a miss — check the meme/slang Knowledge Base for
        // reference material (meaning + guideline + candidate wording) that
        // steers GPT away from literal mistranslations of figurative
        // expressions. `nil` on no match, and fail-safe to `nil` if the
        // bundled JSON is missing/malformed — either way the request below
        // proceeds exactly as it did before the KB existed.
        let kbReference = TranslationKnowledgeBase.shared.buildReference(
            for: effectiveInput,
            targetLanguage: tgtLang
        )

        // Full Access check — keyboard extensions cannot make network
        // requests without Full Access in Settings.
        if !hasFullAccess {
            showTranslateFullAccessError()
            return
        }

        // Refresh tier from App Group (main app may have updated it)
        checkPremiumStatus()

        // Lifetime: translation not included in lifetime plan
        if userTier == "lifetime" {
            showTranslateError("번역은 주/연간 구독에서만 가능합니다")
            return
        }

        // Daily translation limit. Both tiers are now capped:
        //   • free                    → 5/day
        //   • premium (weekly/yearly) → 300/day
        // (Lifetime is blocked outright above; trial users land on the
        // free quota since `canTranslateUnlimited == false` for them.)
        // `canTranslateUnlimited` is the premium-tier gate flag — kept
        // under its old name to avoid touching its other call sites; it
        // now selects which quota to apply, not "unlimited vs limited".
        // Counter resets at local midnight and is keyed by
        // `translateDailyDate` in App Group UserDefaults so it survives
        // extension lifecycle + syncs with the host app.
        let appGroupID = "group.com.yunajung.fonki"
        let defaults = UserDefaults(suiteName: appGroupID)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        let today = dateFormatter.string(from: Date())

        let storedDate = defaults?.string(forKey: "translateDailyDate")
        var count = (storedDate == today)
            ? (defaults?.integer(forKey: "translateDailyCount") ?? 0)
            : 0

        // 3-tier quota: full (non-trial) premium subscribers are unlimited-ish
        // at 300/day; `can_translate_unlimited` is specifically false for
        // trial subscribers (see subscription_service.dart _isInFreeTrial),
        // so `isPremiumUser` (true for both trial and full premium) is what
        // separates trial (30/day) from the free tier (0/day).
        let maxCount = canTranslateUnlimited ? 300 : (isPremiumUser ? 30 : 0)
        if count >= maxCount {
            if canTranslateUnlimited {
                showToast("오늘 번역 한도를 모두 사용했어요.")
            } else {
                showLockedOverlay()
            }
            return
        }

        count += 1
        defaults?.set(count, forKey: "translateDailyCount")
        defaults?.set(today, forKey: "translateDailyDate")

        let srcLang = translateLangs[sourceLangIndex].1
        let systemPrompt = """
        You are a professional chat translation assistant for messaging apps, social media, and K-pop fan communities.

        Translate the user's message from \(srcLang) to \(tgtLang).

        Follow this priority order:
        1. Preserve the original meaning and intended message.
        2. Preserve the original tone, emotion, politeness, and communication style.
        3. Preserve the user's formatting and expressive cues.
        4. Make the translation sound natural to native speakers.
        5. Rewrite the wording or sentence structure only when necessary for naturalness.

        CORE TRANSLATION RULES
        - Translate the intended meaning, not individual words or the source-language sentence structure.
        - Write the translation as something a native speaker would naturally send in a real chat, comment, or social media post.
        - Do not produce wording that sounds robotic, awkward, overly literal, or unnecessarily formal.
        - Do not omit meaningful information from the source.
        - Do not add information, implications, emotions, humor, or reactions that are not present in the source.
        - Do not make the message cuter, funnier, friendlier, ruder, more affectionate, or more dramatic than the source.
        - Keep the emotional intensity at the same level as the source.
        - When the relationship or situation is unclear, use the most neutral and commonly used natural chat expression. Do not invent intimacy or formality.

        STYLE AND FORMAT PRESERVATION
        - Never add laughter such as ㅋㅋ, ㅎㅎ, haha, hehe, lol, lmao, or similar expressions unless laughter is present in the source.
        - Never remove laughter that is present in the source. Translate it into the natural equivalent in the target language while preserving its intensity as closely as possible.
        - Never add, remove, or replace emojis unless necessary to place the same emoji naturally in the translated sentence.
        - Preserve repeated letters and exaggerated spelling when they express emotion, such as "HELPPPP", "noooo", or "제발ㄹㄹ".
        - Preserve the original line-break structure.
        - Preserve question marks, exclamation marks, ellipses, and other meaningful punctuation as closely as natural usage allows.
        - Do not add a period when the source has no ending punctuation unless the target language absolutely requires it.
        - If the text is already in the target language and requires no translation, return it unchanged.
        - If the input contains only symbols, numbers, emojis, or a URL and has no translatable meaning, return it unchanged.

        SLANG, MEMES, AND IDIOMS
        - Before translating, determine whether an expression is literal, idiomatic, slang, a meme, or a culturally specific expression.
        - If an expression is idiomatic, slang, or a meme, translate its intended conversational meaning rather than its individual words.
        - Do not explain the expression or add notes.
        - Do not preserve a meme literally when the literal wording would confuse native speakers of the target language.
        - When possible, use a natural equivalent expression used by native speakers.
        - If no direct equivalent exists, communicate the intended meaning naturally without inventing extra humor or emotion.
        - Expressions ending in "challenge" may be playful social-media comments rather than official challenge names. Infer the intended teasing or joking meaning from the full sentence instead of translating each word separately.

        K-POP AND FANDOM LANGUAGE
        - This translator is frequently used by K-pop fans on Instagram, TikTok, X, YouTube, Weverse, Bubble, Discord, and similar platforms.
        - Interpret fandom terms according to how fans actually use them, not according to dictionary definitions.
        - Examples include bias, bias wrecker, comeback, stan, maknae, oppa, unnie, visual, era, ending fairy, fan meeting, debut, fancam, and similar terms.
        - Preserve the warmth, excitement, admiration, teasing, and emotional tone of fan culture without exaggerating them.
        - Do not automatically translate fandom slang literally when it has a recognized figurative meaning.

        DIRECT ADDRESS AND PERSON NAMES
        - When a person's name appears, first determine whether the person is being directly addressed or merely mentioned as a third party.
        - Prioritize conversational intent over literal word order or punctuation.
        - Treat the person as being directly addressed when the message speaks to them through a request, command, greeting, question, compliment, thanks, encouragement, confession, affectionate statement, or emotional reaction.
        - A name may be a direct address even when it appears at the end of an informal sentence or has no comma.
        - Requests such as "say hi to me", "notice me", "look at me", "wave at me", "smile", "marry me", "come to my country", and similar expressions are normally directed to the named person in fan comments.
        - Do not incorrectly reinterpret the named person as the recipient of an indirect command such as "tell that person to do something" unless the sentence clearly expresses that meaning.
        - When translating a direct address into Korean, use the person's name naturally as Korean fans would.
        - Add -아 or -야 only when it sounds natural for that specific name and context.
        - Nicknames, stage names, and full names may naturally remain without -아 or -야 when adding it would sound awkward.
        - When the person is only being mentioned as a third party, do not use a vocative form.

        POLITENESS
        - If the target language has multiple politeness levels, infer the most natural level from the original wording and context.
        - Do not automatically use formal language.
        - Do not automatically use casual language.
        - Preserve explicit politeness, affection, distance, or respect expressed in the source.
        - When the context is unclear, choose a neutral everyday chat style rather than an unusually formal or intimate style.
        - Do not mix casual and polite speech levels within a single sentence or connected clause — keep one consistent formality level across the whole sentence, based on the overall casualness/formality of the source.

        OUTPUT
        - Output only the translated text.
        - Do not include explanations, quotation marks, labels, alternatives, language names, or introductory text.
        """
        // Fixed system-prompt + few-shot prefix is built as its own array so
        // it stays byte-identical across every request regardless of the KB
        // — that identical prefix is what OpenAI's prompt caching keys off
        // of. The KB reference (if any) and the real input are appended
        // AFTER it, never interleaved into it.
        var messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            // 1-3: 자연스러운 의역 / 팬덤 슬랭
            ["role": "user", "content": "This lives rent free in my head"],
            ["role": "assistant", "content": "계속 머릿속에서 맴돌아"],
            ["role": "user", "content": "She ate and left no crumbs"],
            ["role": "assistant", "content": "진짜 제대로 해냈어"],
            ["role": "user", "content": "He's so babygirl"],
            ["role": "assistant", "content": "완전 사랑스러워"],
            // 4-5: SNS challenge 표현
            ["role": "user", "content": "Stop being so perfect challenge"],
            ["role": "assistant", "content": "완벽한 거 좀 그만해봐"],
            ["role": "user", "content": "Try not to laugh challenge"],
            ["role": "assistant", "content": "안 웃기 챌린지"],
            // 6-8: 이름이 문장 끝에 있어도 직접 호명으로 판단
            ["role": "user", "content": "say hi to me, jhope please"],
            ["role": "assistant", "content": "제이홉 제발 나한테 인사해줘"],
            ["role": "user", "content": "i love you so much jimin"],
            ["role": "assistant", "content": "지민아 진짜 너무 사랑해"],
            ["role": "user", "content": "please notice my comment mark"],
            ["role": "assistant", "content": "마크야 제발 내 댓글 좀 봐줘"],
            // 9-10: 이름이 제3자로 언급되는 경우
            ["role": "user", "content": "I watched Jungkook's live"],
            ["role": "assistant", "content": "정국이 라이브 봤어"],
            ["role": "user", "content": "Felix made me laugh"],
            ["role": "assistant", "content": "필릭스 때문에 웃었어"],
            // 11-12: 제3자에게 전달/질문 요청 — 호격 아님, 화자는 "전해줘/물어봐줘"의
            // 대상이지 이름의 주인이 아님 (예: "tell taehyung ~"은 태형이한테
            // 직접 말 거는 게 아니라, 상대방에게 태형이한테 전해달라는 부탁)
            ["role": "user", "content": "tell taehyung I said good luck tonight"],
            ["role": "assistant", "content": "태형이한테 오늘 잘 되길 바란다고 전해줘"],
            ["role": "user", "content": "ask namjoon if he's eating well"],
            ["role": "assistant", "content": "남준이한테 잘 먹고 있는지 물어봐줘"],
            // 13-16: 원문에 없는 웃음 표현 추가 금지
            ["role": "user", "content": "I love you"],
            ["role": "assistant", "content": "사랑해"],
            ["role": "user", "content": "I love you lol"],
            ["role": "assistant", "content": "사랑해ㅋㅋ"],
            ["role": "user", "content": "Really?"],
            ["role": "assistant", "content": "진짜?"],
            ["role": "user", "content": "Really?? 😭"],
            ["role": "assistant", "content": "진짜?? 😭"],
            // 17-18: 반대 방향 번역 스타일
            ["role": "user", "content": "나 지금 가는 중"],
            ["role": "assistant", "content": "I'm on my way"],
            ["role": "user", "content": "너무 웃겨ㅋㅋ"],
            ["role": "assistant", "content": "You're so funny lol"],
            // 19: 부정문에서도 문장 전체의 반말/존댓말 톤을 일관되게 유지
            // (앞은 반말인데 뒤에서 갑자기 존댓말로 바뀌는 톤 혼합 방지)
            ["role": "user", "content": "this is NOT giving villain energy, don't even try it"],
            ["role": "assistant", "content": "이건 절대 악당 느낌 아니야, 그런 시도도 하지 마"],
        ]
        if let kbReference {
            messages.append(["role": "system", "content": kbReference])
        }
        messages.append(["role": "user", "content": effectiveInput])

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0.1,
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body),
              let url = URL(string: "https://api.openai.com/v1/chat/completions")
        else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // Cancel any still-pending request before kicking off a new one so a
        // double-tap on the translate button (or fast retap) can't race two
        // responses.
        translationTask?.cancel()
        translationTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let bodyText = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""

                // 1) Network transport error (offline, timeout, DNS 등)
                if let error = error {
                    let ns = error as NSError
                    if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorNotConnectedToInternet {
                        self.showTranslateError("인터넷 연결 없음\n키보드 '전체 접근 허용'을 확인하세요")
                    } else {
                        self.showTranslateError("네트워크 오류 (code \(ns.code))\n\(ns.localizedDescription)")
                    }
                    return
                }

                // 2) HTTP status check
                guard let data = data else {
                    self.showTranslateError("응답 없음 (HTTP \(statusCode))")
                    return
                }

                // Parse response
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]

                if !(200...299).contains(statusCode) {
                    // 3) OpenAI 에러 응답 — 전체 본문 표시
                    var msg = "HTTP \(statusCode)"
                    if let err = json?["error"] as? [String: Any] {
                        if let m = err["message"] as? String { msg += "\nmessage: \(m)" }
                        if let c = err["code"] as? String { msg += "\ncode: \(c)" }
                        if let t = err["type"] as? String { msg += "\ntype: \(t)" }
                    } else if !bodyText.isEmpty {
                        msg += "\n\(bodyText.prefix(300))"
                    }
                    switch statusCode {
                    case 401: self.showTranslateError("인증 실패 (API Key 확인)\n\(msg)")
                    case 429: self.showTranslateError("사용량 초과 또는 rate limit\n\(msg)")
                    case 500...599: self.showTranslateError("OpenAI 서버 오류\n\(msg)")
                    default: self.showTranslateError(msg)
                    }
                    return
                }

                // 4) Success
                guard let choices = json?["choices"] as? [[String: Any]],
                      let message = choices.first?["message"] as? [String: Any],
                      let translated = message["content"] as? String
                else {
                    self.showTranslateError("응답 파싱 실패\n\(bodyText.prefix(300))")
                    return
                }
                #if DEBUG
                // Prompt-caching visibility: don't assume the fixed system
                // prompt + few-shot prefix is actually being cached — read
                // it back from the API instead. `cached_tokens` is only
                // present once OpenAI has cached that prefix from a prior
                // request; 0/absent doesn't mean caching is broken, just
                // that this particular request didn't hit it.
                if let usage = json?["usage"] as? [String: Any] {
                    let promptTokens = usage["prompt_tokens"] as? Int ?? -1
                    let completionTokens = usage["completion_tokens"] as? Int ?? -1
                    let cachedTokens = (usage["prompt_tokens_details"] as? [String: Any])?["cached_tokens"] as? Int ?? 0
                    print("🔥 [translateTriggered] usage: prompt=\(promptTokens) completion=\(completionTokens) cached=\(cachedTokens)")
                }
                #endif
                self.lastTranslation = self.sanitizeTranslationOutput(translated)
                self.textDocumentProxy.insertText(self.lastTranslation)
                self.translateInputField?.resignFirstResponder()
            }
        }
        translationTask?.resume()
    }

    private func showTranslateError(_ message: String) {
        showToast(message)
    }

    private func showTranslateFullAccessError() {
        showTranslateError(loc("translate_no_access"))
    }

    /// Strip a leading language-label prefix the model sometimes prepends
    /// despite the "output only the translated text" rule (e.g.
    /// "English: You have a big head."). We cover the 10 supported target
    /// languages in both their English names and common Korean labels. The
    /// match is anchored at start-of-string and case-insensitive, with
    /// optional whitespace after the colon. Only one pass is needed since
    /// the model never doubles the prefix.
    private func sanitizeTranslationOutput(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixes = [
            // English names of the 10 languages in `translateLangs`
            "English:", "Korean:", "Japanese:", "Chinese:",
            "Spanish:", "French:", "German:",
            "Vietnamese:", "Thai:", "Indonesian:",
            // Korean labels that occasionally appear
            "영어:", "한국어:", "일본어:", "중국어:",
            "스페인어:", "프랑스어:", "독일어:",
            "베트남어:", "태국어:", "인니어:", "인도네시아어:",
            // Generic fallbacks
            "Translation:", "번역:",
        ]
        for p in prefixes {
            if s.lowercased().hasPrefix(p.lowercased()) {
                s = String(s.dropFirst(p.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        s = s.trimmingCharacters(in: .whitespaces)
        if s.hasSuffix(".") && !s.hasSuffix("..") {
            s = String(s.dropLast())
        }
        return s
    }

    private func todayString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    // MARK: - Favorites Mode (♥)

    private func buildFavoritesMode() {
        // Hard paywall: favorites is premium-only, but gated per-item (tap →
        // showLockedOverlay) rather than at tab entry — see the My List
        // branch comment in buildTextTemplateMode for why a full-tab guard
        // here breaks the overlay's ✕ button (dismissLockedOverlay() calls
        // showMode(currentMode), which would re-enter this same guard).
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let emoFavs    = loadFavList(Self.favKeyEmoticon)
        let dotArtFavs = loadFavList(Self.favKeyDotArt)
        let gifFavs    = loadFavList(Self.favKeyGif)
        let textFavs   = loadFavList(Self.favKeyTextReplace)
        // Font favorites surface in the Aa tab now — this tab no longer
        // duplicates them, so we don't fetch / render the font list here.
        let allEmpty   = emoFavs.isEmpty && dotArtFavs.isEmpty && gifFavs.isEmpty && textFavs.isEmpty

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        pinToEdges(container, in: contentView)
        container.heightAnchor.constraint(equalToConstant: tabContainerHeight).isActive = true

        // Category tabs
        let catScroll = UIScrollView()
        catScroll.showsHorizontalScrollIndicator = false
        catScroll.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(catScroll)

        let catRow = UIStackView()
        catRow.axis = .horizontal
        catRow.spacing = 6
        catRow.translatesAutoresizingMaskIntoConstraints = false
        catScroll.addSubview(catRow)
        NSLayoutConstraint.activate([
            catRow.topAnchor.constraint(equalTo: catScroll.topAnchor),
            catRow.leadingAnchor.constraint(equalTo: catScroll.leadingAnchor, constant: 4),
            catRow.trailingAnchor.constraint(equalTo: catScroll.trailingAnchor, constant: -4),
            catRow.bottomAnchor.constraint(equalTo: catScroll.bottomAnchor),
            catRow.heightAnchor.constraint(equalTo: catScroll.heightAnchor),
        ])
        for (i, name) in favCategoryNames.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(name, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
            btn.layer.cornerRadius = 14
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
            let sel = i == favCategoryIndex
            btn.backgroundColor = sel ? accentColor : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? selectedCatTextColor : .darkGray, for: .normal)
            btn.tag = i
            btn.addTarget(self, action: #selector(favCategoryTapped(_:)), for: .touchUpInside)
            catRow.addArrangedSubview(btn)
        }

        // Bottom bar removed entirely — the favorites tab's only bottom-bar
        // control was the ⌫ button, removed per spec. The scroll view now
        // extends straight to the container bottom (see constraints below).

        // Scroll view for content
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            catScroll.topAnchor.constraint(equalTo: container.topAnchor),
            catScroll.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            catScroll.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            catScroll.heightAnchor.constraint(equalToConstant: 32),

            scrollView.topAnchor.constraint(equalTo: catScroll.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 5
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(gridStack)
        NSLayoutConstraint.activate([
            gridStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 5),
            gridStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 5),
            gridStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -5),
            gridStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -5),
            gridStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10),
        ])

        // Determine what to show. Categories: 0=전체, 1=Text, 2=이모티콘, 3=기호, 4=GIF.
        // (도트아트 카테고리 비활성화 — 전체에서만 표시)
        let showEmo    = favCategoryIndex == 0 || favCategoryIndex == 2 || favCategoryIndex == 3
        let showDotArt = favCategoryIndex == 0
        let showGif    = favCategoryIndex == 0 || favCategoryIndex == 4
        let showText   = favCategoryIndex == 0 || favCategoryIndex == 1
        let filteredEmo  = showEmo    ? emoFavs    : []
        let filteredDA   = showDotArt ? dotArtFavs : []
        let filteredGif  = showGif    ? gifFavs    : []
        let filteredText = showText   ? textFavs   : []

        let totalEmpty = filteredEmo.isEmpty && filteredDA.isEmpty && filteredGif.isEmpty && filteredText.isEmpty

        if totalEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = allEmpty
                ? loc("favorite_empty_sub")
                : loc("favorite_empty")
            emptyLabel.numberOfLines = 0
            emptyLabel.textColor = .lightGray
            emptyLabel.textAlignment = .center
            emptyLabel.font = .systemFont(ofSize: 14)
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(emptyLabel)
            NSLayoutConstraint.activate([
                emptyLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
                emptyLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 40),
            ])
            return
        }

        // Emoticon/Special rows (4 cols)
        if !filteredEmo.isEmpty {
            let cols = 4
            let chunked = stride(from: 0, to: filteredEmo.count, by: cols).map {
                Array(filteredEmo[$0..<min($0 + cols, filteredEmo.count)])
            }
            for row in chunked {
                let rowStack = UIStackView()
                rowStack.axis = .horizontal
                rowStack.distribution = .fillEqually
                rowStack.spacing = 5
                for item in row {
                    let btn = UIButton(type: .system)
                    btn.setTitle(item, for: .normal)
                    btn.titleLabel?.font = .systemFont(ofSize: 14)
                    btn.titleLabel?.adjustsFontSizeToFitWidth = true
                    btn.titleLabel?.minimumScaleFactor = 0.4
                    btn.backgroundColor = .white
                    btn.layer.cornerRadius = 8
                    btn.layer.borderWidth = 0.5
                    btn.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
                    btn.setTitleColor(.darkGray, for: .normal)
                    btn.setHeight(44)
                    btn.addTarget(self, action: #selector(favoriteTapped(_:)), for: .touchUpInside)
                    let lp = UILongPressGestureRecognizer(target: self, action: #selector(favoriteLongPressed(_:)))
                    lp.minimumPressDuration = 0.5
                    btn.addGestureRecognizer(lp)
                    rowStack.addArrangedSubview(btn)
                }
                for _ in 0..<(cols - row.count) { rowStack.addArrangedSubview(UIView()) }
                gridStack.addArrangedSubview(rowStack)
            }
        }

        // Dot art rows (image, 1 col, 100pt tall)
        for (i, text) in filteredDA.enumerated() {
            let btn = UIButton(type: .custom)
            btn.tag = i
            btn.backgroundColor = .white
            btn.layer.cornerRadius = 10
            btn.layer.borderWidth = 0.5
            btn.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
            btn.clipsToBounds = true
            btn.setHeight(100)
            btn.addTarget(self, action: #selector(favDotArtTapped(_:)), for: .touchUpInside)
            let lp = UILongPressGestureRecognizer(target: self, action: #selector(favDotArtLongPressed(_:)))
            lp.minimumPressDuration = 0.5
            btn.addGestureRecognizer(lp)

            let tv = UITextView()
            tv.text = text
            tv.font = UIFont(name: "Menlo", size: 4) ?? .monospacedSystemFont(ofSize: 4, weight: .regular)
            tv.textColor = .black
            tv.backgroundColor = .white
            tv.isEditable = false
            tv.isScrollEnabled = false
            tv.isUserInteractionEnabled = false
            tv.textContainerInset = .zero
            tv.textContainer.lineFragmentPadding = 0
            tv.textAlignment = .center
            tv.translatesAutoresizingMaskIntoConstraints = false
            btn.addSubview(tv)
            NSLayoutConstraint.activate([
                tv.topAnchor.constraint(equalTo: btn.topAnchor, constant: 2),
                tv.leadingAnchor.constraint(equalTo: btn.leadingAnchor, constant: 2),
                tv.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -2),
                tv.bottomAnchor.constraint(equalTo: btn.bottomAnchor, constant: -2),
            ])
            gridStack.addArrangedSubview(btn)
        }

        // GIF rows (thumbnail, 3 cols, 72pt)
        if !filteredGif.isEmpty {
            let cols = 3
            let chunked = stride(from: 0, to: filteredGif.count, by: cols).map {
                Array(filteredGif[$0..<min($0 + cols, filteredGif.count)])
            }
            for (rowIdx, row) in chunked.enumerated() {
                let rowStack = UIStackView()
                rowStack.axis = .horizontal
                rowStack.distribution = .fillEqually
                rowStack.spacing = 5
                for (colIdx, urlStr) in row.enumerated() {
                    let globalIdx = rowIdx * cols + colIdx
                    let btn = UIButton(type: .custom)
                    btn.tag = globalIdx
                    btn.backgroundColor = UIColor(white: 0.94, alpha: 1)
                    btn.layer.cornerRadius = 8
                    btn.clipsToBounds = true
                    btn.setHeight(72)
                    btn.addTarget(self, action: #selector(favGifTapped(_:)), for: .touchUpInside)
                    let lp = UILongPressGestureRecognizer(target: self, action: #selector(favGifLongPressed(_:)))
                    lp.minimumPressDuration = 0.5
                    btn.addGestureRecognizer(lp)

                    // Load thumbnail (use still image from URL by modifying path)
                    if let url = URL(string: urlStr) {
                        let iv = UIImageView()
                        iv.contentMode = .scaleAspectFill
                        iv.clipsToBounds = true
                        iv.isUserInteractionEnabled = false
                        iv.translatesAutoresizingMaskIntoConstraints = false
                        btn.addSubview(iv)
                        NSLayoutConstraint.activate([
                            iv.topAnchor.constraint(equalTo: btn.topAnchor),
                            iv.leadingAnchor.constraint(equalTo: btn.leadingAnchor),
                            iv.trailingAnchor.constraint(equalTo: btn.trailingAnchor),
                            iv.bottomAnchor.constraint(equalTo: btn.bottomAnchor),
                        ])
                        URLSession.shared.dataTask(with: url) { data, _, _ in
                            guard let data = data, let image = UIImage(data: data) else { return }
                            DispatchQueue.main.async { iv.image = image }
                        }.resume()
                    }
                    rowStack.addArrangedSubview(btn)
                }
                for _ in 0..<(cols - row.count) { rowStack.addArrangedSubview(UIView()) }
                gridStack.addArrangedSubview(rowStack)
            }
        }

        // Text replace rows (full-width, 1 col)
        for (i, text) in filteredText.enumerated() {
            let btn = UIButton(type: .system)
            btn.tag = i
            btn.setTitle(text, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 14)
            btn.titleLabel?.lineBreakMode = .byTruncatingTail
            btn.contentHorizontalAlignment = .left
            btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            btn.backgroundColor = .white
            btn.setTitleColor(.darkGray, for: .normal)
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth = 0.5
            btn.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
            btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
            btn.addTarget(self, action: #selector(favTextReplaceTapped(_:)), for: .touchUpInside)
            let lp = UILongPressGestureRecognizer(target: self, action: #selector(favTextReplaceLongPressed(_:)))
            lp.minimumPressDuration = 0.5
            btn.addGestureRecognizer(lp)
            gridStack.addArrangedSubview(btn)
        }

    }

    // MARK: - Key Actions

    @objc private func letterTapped(_ s: UIButton) {
        guard var ch = s.title(for: .normal) else { return }
        // Korean keypad on the Aa tab: divert raw jamos into the same Hangul
        // composition engine the translate tab uses, so taps build syllables
        // (ㅇ + ㅏ + ㄴ → 안) instead of dropping standalone jamos. The engine
        // routes its inserts/replaces through `translateTargetAppend`, which
        // falls back to `textDocumentProxy` when no `translateInputField` is
        // first responder — that's always the case in fonts mode, so output
        // lands in the host app correctly.
        //
        // NB: font conversion (`style.convert`) is not applied to composed
        // syllables; Hangul codepoints aren't in the math alphanumeric blocks
        // that most styles target, so the user-visible result is the same as
        // streaming jamos through `style.convert` would have been — minus the
        // jamo-vs-syllable defect we're fixing here.
        if isFontsKorean && !isNumberMode {
            handleHangulInput(ch)
            DispatchQueue.global(qos: .userInteractive).async {
                AudioServicesPlaySystemSound(1104)
            }
            tapFeedback(s)
            // One-shot shift auto-release for Korean dubeolsik. Any letter
            // input (ㅃㅉㄸㄲㅆ tense consonants, ㅒ/ㅖ shifted vowels, OR
            // plain non-shifted jamos when `isShifted` happens to still be
            // on) releases shift and rebuilds the keypad into the unshifted
            // layout. Caps lock (`isCapsLock`) is honored — it stays sticky.
            //
            // SYNC rebuild (no `DispatchQueue.main.async`): the previous
            // async dispatch was the root cause of "모음 연타 시 유실" —
            // it deferred `showMode` to the next runloop iteration, so
            // rapid follow-up taps landed on the OLD buttons that were
            // about to be torn down. Calling `showMode(.fonts)` directly
            // completes the rebuild inside the current event-handling tick,
            // so the next `touchesBegan` hits the freshly-built unshifted
            // buttons cleanly.
            if isShifted && !isCapsLock {
                isShifted = false
                showMode(.fonts)
            }
            return
        }
        if isShifted { ch = ch.uppercased() }
        let cats = visibleFontCategories()
        guard !cats.isEmpty else { return }
        let fontStyle: FontStyleDef
        if let name = selectedFontStyleName,
           let found = cats.flatMap({ $0.1 }).first(where: { $0.name == name }) {
            fontStyle = found
        } else {
            let safeCat = min(fontCatIndex, max(cats.count - 1, 0))
            let styles = cats[safeCat].1
            guard !styles.isEmpty else { return }
            fontStyle = styles[0]
        }
        // Plain-text fields (URL/email/search etc.) bypass styling entirely.
        let converted = isPlainTextField ? ch : fontStyle.convert(ch)
        textDocumentProxy.insertText(converted)
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
        tapFeedback(s)
        if isShifted && !isCapsLock {
            isShifted = false
            DispatchQueue.main.async { [weak self] in
                self?.showMode(.fonts)
            }
        }
    }

    @objc private func spaceTapped() {
        // Cheonjiin "smart space" — when a syllable with a jongsung
        // (받침) is currently being composed in 천지인 mode, space acts
        // as a syllable boundary commit rather than a literal space:
        // it flushes the engine state and returns without inserting " ".
        // Without this, the user's only way to start a new syllable
        // after a 받침-ending one was to type a space (which left an
        // unwanted gap), because the next consonant tap would otherwise
        // cycle the existing 받침 (e.g. 안 + ㄴ → 알). Now "안" + space
        // + "ㄴㅕㅇ" → "안녕" (no gap). A literal space can still be
        // inserted by tapping space again after the smart-commit (the
        // buffer is empty by then, so the fallback branch below fires).
        if isFontsKorean && koreanInputMode == "cheonjiin" && hgJong > 0 {
            hgFlush()
            cjjReset()
            DispatchQueue.global(qos: .userInteractive).async {
                AudioServicesPlaySystemSound(1104)
            }
            return
        }

        // Default: unconditionally finalize the Hangul / cheonjiin
        // buffers and insert a space. Previously the flush was gated on
        // `isFontsKorean`, which missed (a) Korean typing in the
        // translate tab (`isFontsKorean` is an Aa-tab-only flag) and
        // (b) state set in one tab persisting after a host-app external
        // clear (e.g. Flutter chat's send button). Calling hgFlush()
        // with an already-empty buffer is a no-op.
        hgFlush()
        cjjReset()
        textDocumentProxy.insertText(" ")
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
    }

    @objc private func backspaceTapped() {
        // Selected text in the host app → a single `deleteBackward()` clears
        // the whole selection. The composer-aware path below peels just one
        // jamo and ignores the selection, so we must intercept here. Reset
        // both Hangul and cheonjiin buffers since the syllable they were
        // tracking is gone with the selection.
        if let selected = textDocumentProxy.selectedText, !selected.isEmpty {
            textDocumentProxy.deleteBackward()
            hgFlush()
            cjjReset()
            DispatchQueue.global(qos: .userInteractive).async {
                AudioServicesPlaySystemSound(1104)
            }
            return
        }
        // No text before cursor → bail early so the click sound doesn't fire
        // on a no-op delete. In Korean fonts mode the composing syllable is
        // already inserted into the host editor (handleHangulInput writes via
        // translateTargetAppend), so its presence shows up in
        // `documentContextBeforeInput` and we still proceed correctly.
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        guard !before.isEmpty else { return }
        // In Korean fonts mode, route through the composer's delete so a
        // jong/jung is peeled off the active syllable instead of nuking the
        // whole composed character (e.g. 안 → 아, 아 → ㅇ, ㅇ → empty).
        // `handleHangulDelete` falls back to `translateTargetRemoveLast` →
        // `textDocumentProxy.deleteBackward()` when nothing is buffered.
        if isFontsKorean && !isNumberMode {
            handleHangulDelete()
        } else {
            textDocumentProxy.deleteBackward()
        }
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
    }

    // MARK: - Backspace long-press (repeat delete)

    private var deleteTimer: Timer?
    private var deleteTickCount = 0
    private var deleteTranslateMode = false
    /// Snapshot at long-press `.began` — true when the press started on the
    /// Aa-tab Korean keypad. Keeps every repeat tick routing through the
    /// Hangul composer (peeling jong/jung/cho before hitting the host editor)
    /// instead of the first tick going through the composer and the rest
    /// silently switching to a raw `deleteBackward`.
    private var deleteFontsKoreanMode = false
    /// Attach long-press to a delete button so holding triggers repeat delete.
    /// `translateMode = true` uses translate-specific backspace (hangul + translationInput).
    private func attachBackspaceLongPress(to btn: UIButton, translateMode: Bool = false) {
        let lp = UILongPressGestureRecognizer(
            target: self, action: #selector(backspaceLongPressed(_:)))
        lp.minimumPressDuration = 0.4
        btn.addGestureRecognizer(lp)
        // Store mode as associated tag on the gesture via its view is cleaner,
        // but we use one instance var since only one long-press runs at a time.
        // The mode is set at gesture .began based on currentMode.
        _ = translateMode // param kept for call-site clarity
    }

    @objc private func backspaceLongPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            deleteTickCount = 0
            deleteTranslateMode = (currentMode == .translate)
            deleteFontsKoreanMode =
                (currentMode == .fonts && isFontsKorean && !isNumberMode)
            performBackspaceForCurrentMode()
            let soundHasText: Bool = {
                if currentMode == .translate && !translateTargetsHostApp {
                    return !(translateInputField?.text?.isEmpty ?? true)
                } else if currentMode == .translate && translateTargetsHostApp {
                    return true  // B 타겟: hasText 신뢰 불가 앱 대응
                } else {
                    return textDocumentProxy.hasText
                }
            }()
            if soundHasText {
                DispatchQueue.global(qos: .userInteractive).async {
                    AudioServicesPlaySystemSound(1104)
                }
            }
            deleteTimer?.invalidate()
            deleteTimer = Timer.scheduledTimer(
                withTimeInterval: 0.08, repeats: true
            ) { [weak self] _ in
                guard let self = self else { return }
                let isBTargeted = self.currentMode == .translate && self.translateTargetsHostApp
                let soundHasText: Bool = {
                    if self.currentMode == .translate && !self.translateTargetsHostApp {
                        return !(self.translateInputField?.text?.isEmpty ?? true)
                    } else if self.currentMode == .translate && self.translateTargetsHostApp {
                        return true  // B 타겟: hasText 신뢰 불가 앱 대응
                    } else {
                        return self.textDocumentProxy.hasText
                    }
                }()
                // B 타겟: hasText 신뢰 불가 앱 대응 — 최대 100틱까지 타이머 유지.
                // A/폰트탭: 기존대로 빈 텍스트 기준으로 정지.
                let shouldStop: Bool = isBTargeted
                    ? self.deleteTickCount >= 100
                    : !soundHasText
                guard !shouldStop else {
                    self.deleteTimer?.invalidate()
                    self.deleteTimer = nil
                    return
                }
                self.performBackspaceForCurrentMode()
                if soundHasText {
                    DispatchQueue.global(qos: .userInteractive).async {
                        AudioServicesPlaySystemSound(1104)
                    }
                }
                self.deleteTickCount += 1
                if self.deleteTickCount == 5 {
                    self.deleteTimer?.invalidate()
                    self.deleteTimer = Timer.scheduledTimer(
                        withTimeInterval: 0.06, repeats: true
                    ) { [weak self] _ in
                        guard let self = self else { return }
                        let isBTargeted = self.currentMode == .translate && self.translateTargetsHostApp
                        let soundHasText: Bool = {
                            if self.currentMode == .translate && !self.translateTargetsHostApp {
                                return !(self.translateInputField?.text?.isEmpty ?? true)
                            } else if self.currentMode == .translate && self.translateTargetsHostApp {
                                return true  // B 타겟: hasText 신뢰 불가 앱 대응
                            } else {
                                return self.textDocumentProxy.hasText
                            }
                        }()
                        let shouldStop: Bool = isBTargeted
                            ? self.deleteTickCount >= 100
                            : !soundHasText
                        guard !shouldStop else {
                            self.deleteTimer?.invalidate()
                            self.deleteTimer = nil
                            return
                        }
                        self.performBackspaceForCurrentMode()
                        if soundHasText {
                            DispatchQueue.global(qos: .userInteractive).async {
                                AudioServicesPlaySystemSound(1104)
                            }
                        }
                    }
                }
            }
        case .ended, .cancelled, .failed:
            deleteTimer?.invalidate()
            deleteTimer = nil
        default:
            break
        }
    }

    private func performBackspaceForCurrentMode() {
        if deleteTranslateMode {
            performTranslateDelete()
        } else if deleteFontsKoreanMode {
            handleHangulDelete()
        } else {
            textDocumentProxy.deleteBackward()
        }
    }

    @objc private func shiftTapped() {
        let now = Date()
        if let last = lastFontShiftTime, now.timeIntervalSince(last) < 0.4 {
            // Double tap → caps lock
            isCapsLock = true
            isShifted = true
        } else if isCapsLock {
            // Was caps lock → turn off
            isCapsLock = false
            isShifted = false
        } else {
            // Single tap → toggle shift
            isShifted.toggle()
        }
        lastFontShiftTime = now
        showMode(.fonts)
    }

    @objc private func returnTapped() {
        // Unconditionally finalize both Hangul and cheonjiin buffers — same
        // rationale as `spaceTapped`. Most importantly this catches the
        // "send via host app" flow: user types 한글, taps return to send
        // (which may trigger a host-side text clear), then types again.
        // Without an unconditional flush, hgCho/hgJung/hgJong retained the
        // previous syllable's state, so the first jamo of the new message
        // composed against ghost state — visible as "last character lingers
        // and merges with new input."
        hgFlush()
        cjjReset()
        textDocumentProxy.insertText("\n")
    }

    /// Convert math-alphanumeric / fullwidth Unicode codepoints back to their
    /// plain ASCII counterparts so a follow-up `convert()` can re-style them.
    /// Anything outside the recognised ranges passes through unchanged.
    private func normalizeToASCII(_ text: String) -> String {
        // BMP fallbacks Apple chose for the "reserved" math-alphanumeric slots
        // (e.g. italic ℎ, script ℬ/ℰ/ℱ/ℋ/…, fraktur ℭ/ℌ/…, double-struck ℂ/ℕ/…).
        let bmpExceptions: [UInt32: UInt32] = [
            0x210E: 0x68,                              // h (italic)
            0x212C: 0x42, 0x2130: 0x45, 0x2131: 0x46, // B / E / F (script upper)
            0x210B: 0x48, 0x2110: 0x49, 0x2112: 0x4C, // H / I / L
            0x2133: 0x4D, 0x211B: 0x52,                // M / R
            0x212F: 0x65, 0x210A: 0x67, 0x2134: 0x6F, // e / g / o (script lower)
            0x212D: 0x43, 0x210C: 0x48, 0x2111: 0x49, // C / H / I (fraktur)
            0x211C: 0x52, 0x2128: 0x5A,                // R / Z
            0x2102: 0x43, 0x210D: 0x48, 0x2115: 0x4E, // C / H / N (double-struck)
            0x2119: 0x50, 0x211A: 0x51, 0x211D: 0x52, // P / Q / R
            0x2124: 0x5A,                              // Z
        ]
        // Each Latin-alphabet block in U+1D400..U+1D6A3 is exactly 26 chars,
        // alternating uppercase / lowercase. List the start of each.
        let upperBlocks: [UInt32] = [
            0x1D400, 0x1D434, 0x1D468, 0x1D49C, 0x1D4D0, 0x1D504, 0x1D538,
            0x1D56C, 0x1D5A0, 0x1D5D4, 0x1D608, 0x1D63C, 0x1D670,
        ]
        let lowerBlocks: [UInt32] = [
            0x1D41A, 0x1D44E, 0x1D482, 0x1D4B6, 0x1D4EA, 0x1D51E, 0x1D552,
            0x1D586, 0x1D5BA, 0x1D5EE, 0x1D622, 0x1D656, 0x1D68A,
        ]
        // Digit blocks in U+1D7CE..U+1D7FF — each 10 chars.
        let digitBlocks: [UInt32] = [0x1D7CE, 0x1D7D8, 0x1D7E2, 0x1D7EC, 0x1D7F6]

        func mapScalar(_ v: UInt32) -> UInt32 {
            if let m = bmpExceptions[v] { return m }
            for base in upperBlocks where v >= base && v < base + 26 {
                return 0x41 + (v - base)
            }
            for base in lowerBlocks where v >= base && v < base + 26 {
                return 0x61 + (v - base)
            }
            for base in digitBlocks where v >= base && v < base + 10 {
                return 0x30 + (v - base)
            }
            // Fullwidth Latin / digits (used by the "Wide" style).
            if v >= 0xFF21 && v <= 0xFF3A { return 0x41 + (v - 0xFF21) }
            if v >= 0xFF41 && v <= 0xFF5A { return 0x61 + (v - 0xFF41) }
            if v >= 0xFF10 && v <= 0xFF19 { return 0x30 + (v - 0xFF10) }
            // Bubble: Ⓐ-Ⓩ (U+24B6-24CF) / ⓐ-ⓩ (U+24D0-24E9).
            if v >= 0x24B6 && v <= 0x24CF { return 0x41 + (v - 0x24B6) }
            if v >= 0x24D0 && v <= 0x24E9 { return 0x61 + (v - 0x24D0) }
            // Square / Chunky / Block — three uppercase-only enclosed blocks.
            if v >= 0x1F130 && v <= 0x1F149 { return 0x41 + (v - 0x1F130) }
            if v >= 0x1F150 && v <= 0x1F169 { return 0x41 + (v - 0x1F150) }
            if v >= 0x1F170 && v <= 0x1F189 { return 0x41 + (v - 0x1F170) }
            // _cm-style maps (Comic / Cursive / Small Caps / Super / Sub) —
            // their styled glyphs sit outside the math-alphanumeric blocks,
            // so we go through the inverted lookup table.
            if let m = _cmReverseMap[v] { return m }
            // Flip (_udMap) — undo the per-char substitution. We do NOT reverse
            // the string afterwards: most of `_udMap` is bidirectional (b↔q,
            // d↔p, n↔u, m↔w, M↔W, 6↔9, …), so plain ASCII input would falsely
            // trigger a reverse and scramble unrelated styles like Bold.
            // Trade-off: re-converting Flip-styled text loses the original
            // word order, which beats wrecking every other style.
            //
            // Gate the lookup on `v > 0x7F`: even for one-way lookups, the
            // ASCII halves of the bidirectional pairs (n→u, q→b, p→d, …) are
            // valid keys in the inverted table, so unstyled text would still
            // be rewritten without this guard.
            if v > 0x7F, let m = _udReverseMap[v] { return m }
            return v
        }

        var out = ""
        out.reserveCapacity(text.unicodeScalars.count)
        for scalar in text.unicodeScalars {
            let v = scalar.value
            // Drop combining marks left over from previous styles like Sad
            // (`\u{0308}`), Clouds (`\u{0353}\u{033D}`), Chaos (`\u{0489}`),
            // Arrows (`\u{20D7}`), etc. — otherwise the next conversion stacks
            // its own decoration on top of these.
            let isCombining =
                (v >= 0x0300 && v <= 0x036F) ||  // basic combining diacritics
                (v >= 0x1AB0 && v <= 0x1AFF) ||  // combining diacritics extended
                (v >= 0x1DC0 && v <= 0x1DFF) ||  // combining diacritics supplement
                (v >= 0x20D0 && v <= 0x20FF) ||  // combining symbols
                (v >= 0xFE20 && v <= 0xFE2F) ||  // combining half marks
                (v >= 0xA670 && v <= 0xA67F) ||  // combining Cyrillic (꙰ U+A670)
                (v >= 0x1CD0 && v <= 0x1CFF) ||  // Vedic extensions (combining)
                (v >= 0x0600 && v <= 0x0605) || // Arabic combining/format marks
                v == 0x0489                      // Cyrillic millions sign
            if isCombining { continue }

            // Wrapping glyphs left over from Cloudy (`☁X`), Candy (`♡X♡`) and
            // Box (`[X]`). Strip them so the inner letter survives for the
            // next conversion.
            let isWrapping =
                v == 0x2601 ||  // ☁
                v == 0x2661 ||  // ♡
                v == 0x005B ||  // [
                v == 0x005D     // ]
            if isWrapping { continue }

            if let mapped = UnicodeScalar(mapScalar(v)) {
                out.unicodeScalars.append(mapped)
            } else {
                out.unicodeScalars.append(scalar)
            }
        }
        return out
    }

    @objc private func styleTapped(_ s: UIButton) {
        let cats = visibleFontCategories()
        let safeCat = min(fontCatIndex, max(cats.count - 1, 0))
        let styles = cats.isEmpty ? [] : cats[safeCat].1
        print("🔥 [styleTapped] tag=\(s.tag) isPremiumUser=\(isPremiumUser) styleName=\(s.tag < styles.count ? styles[s.tag].name : "oob")")
        if !isPremiumUser {
            if s.tag < styles.count && !effectiveFreeFontNames.contains(styles[s.tag].name) {
                showLockedOverlay()
                return
            }
        }

        fontStyleIndex = s.tag
        if s.tag < styles.count { selectedFontStyleName = styles[s.tag].name }
        applyCurrentFontConversion()
    }

    /// Refresh the fonts-tab UI after a style selection, preserving panel state:
    /// if the panel is open keep it open (showFontPanel), otherwise do a full rebuild.
    private func refreshFontsUI() {
        if fontPickerExpanded {
            showFontPanel()
        } else {
            showMode(.fonts)
        }
    }

    private func applyCurrentFontConversion() {
        let cats = visibleFontCategories()
        guard !cats.isEmpty else { showMode(.fonts); return }
        let convert: (String) -> String
        if let name = selectedFontStyleName,
           let found = cats.flatMap({ $0.1 }).first(where: { $0.name == name }) {
            convert = found.convert
        } else {
            let safeCat = min(fontCatIndex, max(cats.count - 1, 0))
            let styles = cats[safeCat].1
            guard !styles.isEmpty else { showMode(.fonts); return }
            convert = styles[0].convert
        }

        // Translate tab: when our own UITextView is focused, the host
        // textDocumentProxy isn't pointing at it, so selectedText would be
        // nil. Operate on the UITextView directly using NSRange.
        if let tv = translateInputField, tv.isFirstResponder {
            let fullText = tv.text ?? ""
            let nsText = fullText as NSString
            let range = tv.selectedRange
            if range.length > 0 {
                // Replace the selected slice in place; move cursor to the end
                // of the converted segment (selection collapses).
                let portion = nsText.substring(with: range)
                let converted = convert(normalizeToASCII(portion))
                tv.text = nsText.replacingCharacters(in: range, with: converted)
                let cursor = range.location + (converted as NSString).length
                tv.selectedRange = NSRange(location: cursor, length: 0)
            } else {
                // No selection → convert the whole field; cursor lands at end.
                let converted = convert(normalizeToASCII(fullText))
                tv.text = converted
                tv.selectedRange = NSRange(
                    location: (converted as NSString).length, length: 0)
            }
            // Keep the translation input model in sync.
            translationInput = tv.text ?? ""
            DispatchQueue.global(qos: .userInteractive).async {
                AudioServicesPlaySystemSound(1104)
            }
            refreshFontsUI()
            return
        }

        // If the host app reports a non-empty selection, convert it.
        //
        // Hosts disagree on what `deleteBackward()` does to a selection:
        //  • Selection-aware (UITextField/UITextView in Notes, KakaoTalk, …)
        //    wipe the entire selected range on the first call. Looping would
        //    over-delete past the original selection.
        //  • Selection-unaware (Flutter `FlutterTextInputView` and similar
        //    UITextInput shims) only delete one grapheme before the cursor,
        //    leaving the rest of the selection intact.
        //
        // Probe at runtime: fire one `deleteBackward()`, wait long enough for
        // the platform-channel round-trip Flutter needs, then re-read
        // `selectedText`. If it's gone the host handled the whole selection;
        // otherwise we finish the job by deleting the remaining `count - 1`
        // scalars. Sound, cursor-bounce and `refreshFontsUI()` all run after
        // the probe so the picker UI doesn't update before the host caught up.
        if let selected = textDocumentProxy.selectedText, !selected.isEmpty {
            let converted = convert(normalizeToASCII(selected))
            let scalarCount = selected.unicodeScalars.count

            textDocumentProxy.deleteBackward()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self = self else { return }

                if let stillSelected = self.textDocumentProxy.selectedText,
                   !stillSelected.isEmpty {
                    // Selection-unaware host (Flutter, …) — finish the delete
                    // ourselves. We already fired one deleteBackward, so loop
                    // `scalarCount - 1` more times.
                    for _ in 0..<max(scalarCount - 1, 0) {
                        self.textDocumentProxy.deleteBackward()
                    }
                }
                self.textDocumentProxy.insertText(converted)

                let len = converted.utf16.count
                self.textDocumentProxy.adjustTextPosition(byCharacterOffset: -len)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.textDocumentProxy.adjustTextPosition(byCharacterOffset: len)
                }
                DispatchQueue.global(qos: .userInteractive).async {
                    AudioServicesPlaySystemSound(1104)
                }
                self.refreshFontsUI()
            }
            return
        }

        refreshFontsUI()
    }

    @objc private func fontStyleLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let btn = gesture.view as? UIButton else { return }
        let cats = visibleFontCategories()
        let safeCat = min(fontCatIndex, max(cats.count - 1, 0))
        guard !cats.isEmpty else { return }
        let styles = cats[safeCat].1
        guard btn.tag < styles.count else { return }
        let styleName = styles[btn.tag].name

        // Block favorites for locked fonts
        if !isPremiumUser && !effectiveFreeFontNames.contains(styleName) {
            showLockedOverlay()
            return
        }

        // Remember current selection by NAME so we preserve position after rebuild.
        let currentCatName = cats[safeCat].0
        let currentStyleName = styleName // same as the one just long-pressed

        // Toggle favorite
        var favs = loadFavoriteFontNames()
        if favs.contains(styleName) {
            favs.removeAll { $0 == styleName }
            saveFavoriteFontNames(favs)
            showToast(loc("favorite_removed"))
        } else {
            favs.append(styleName)
            saveFavoriteFontNames(favs)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showToast(loc("favorite_added"))
        }

        // Re-map indices to same category/style name in new layout
        let newCats = visibleFontCategories()
        if let newCat = newCats.firstIndex(where: { $0.0 == currentCatName }) {
            fontCatIndex = newCat
            if let newStyle = newCats[newCat].1.firstIndex(where: { $0.name == currentStyleName }) {
                fontStyleIndex = newStyle
            }
        }
        refreshFontsUI()
    }

    @objc private func fontCatTapped(_ s: UIButton) {
        fontCatIndex = s.tag
        savedFontScrollOffset = .zero
        showMode(.fonts)
    }

    @objc private func fontPickerToggleTapped() {
        if fontPickerExpanded {
            fontPickerExpanded = false
            fontPanel = nil  // buildFontsMode clears contentView subviews
            savedFontScrollOffset = .zero
            showMode(.fonts)  // full rebuild with current fontCatIndex/fontStyleIndex
            DispatchQueue.main.async { [weak self] in self?.scrollFontStyleToSelected() }
        } else {
            fontPickerExpanded = true
            fontToggleButton?.setTitle("▲", for: .normal)
            showFontPanel()
        }
    }

    private func scrollFontStyleToSelected() {
        guard let sv = fontStyleScrollView else { return }
        guard let stack = sv.subviews.compactMap({ $0 as? UIStackView }).first else { return }
        let buttons = stack.arrangedSubviews.compactMap { $0 as? UIButton }
        guard fontStyleIndex < buttons.count else { return }
        sv.scrollRectToVisible(buttons[fontStyleIndex].frame, animated: false)
    }

    private func showFontPanel() {
        fontPanel?.removeFromSuperview()

        // Hide the style-picker row while the panel is open.
        fontPickerRowView?.isHidden = true

        let panel = UIView()
        panel.backgroundColor = .white
        panel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(panel)
        pinToEdges(panel, in: contentView)
        fontPanel = panel

        let visibleCats = visibleFontCategories()
        let safeCatIndex = min(fontCatIndex, max(visibleCats.count - 1, 0))

        // ── Top row: category scroll + toggle button ──
        let topRow = UIView()
        topRow.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(topRow)

        let catScroll = UIScrollView()
        catScroll.showsHorizontalScrollIndicator = false
        catScroll.translatesAutoresizingMaskIntoConstraints = false
        topRow.addSubview(catScroll)

        let catRow = UIStackView()
        catRow.axis = .horizontal
        catRow.spacing = 8
        catRow.translatesAutoresizingMaskIntoConstraints = false
        catScroll.addSubview(catRow)
        NSLayoutConstraint.activate([
            catRow.topAnchor.constraint(equalTo: catScroll.topAnchor),
            catRow.leadingAnchor.constraint(equalTo: catScroll.leadingAnchor, constant: 6),
            catRow.trailingAnchor.constraint(equalTo: catScroll.trailingAnchor, constant: -6),
            catRow.bottomAnchor.constraint(equalTo: catScroll.bottomAnchor),
            catRow.heightAnchor.constraint(equalTo: catScroll.heightAnchor),
        ])
        for (i, cat) in visibleCats.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(cat.0, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            btn.tag = i
            btn.layer.cornerRadius = 14
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
            let sel = i == safeCatIndex
            btn.backgroundColor = sel ? accentColor : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? selectedCatTextColor : .darkGray, for: .normal)
            btn.addTarget(self, action: #selector(fontPanelCatTapped(_:)), for: .touchUpInside)
            catRow.addArrangedSubview(btn)
        }

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("▲", for: .normal)
        closeBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        closeBtn.setTitleColor(.darkGray, for: .normal)
        closeBtn.backgroundColor = UIColor(white: 0.94, alpha: 1)
        closeBtn.layer.cornerRadius = 14
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addTarget(self, action: #selector(fontPickerToggleTapped), for: .touchUpInside)
        topRow.addSubview(closeBtn)

        NSLayoutConstraint.activate([
            catScroll.topAnchor.constraint(equalTo: topRow.topAnchor),
            catScroll.leadingAnchor.constraint(equalTo: topRow.leadingAnchor),
            catScroll.bottomAnchor.constraint(equalTo: topRow.bottomAnchor),
            catScroll.trailingAnchor.constraint(equalTo: closeBtn.leadingAnchor, constant: -4),

            closeBtn.centerYAnchor.constraint(equalTo: topRow.centerYAnchor),
            closeBtn.trailingAnchor.constraint(equalTo: topRow.trailingAnchor, constant: -6),
            closeBtn.widthAnchor.constraint(equalToConstant: 36),
            closeBtn.heightAnchor.constraint(equalToConstant: 28),
        ])

        // ── Font grid scroll ──
        let gridScroll = UIScrollView()
        gridScroll.backgroundColor = .white
        gridScroll.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(gridScroll)
        fontPanelGridScroll = gridScroll

        NSLayoutConstraint.activate([
            topRow.topAnchor.constraint(equalTo: panel.topAnchor, constant: 4),
            topRow.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            topRow.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            topRow.heightAnchor.constraint(equalToConstant: 36),

            gridScroll.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 4),
            gridScroll.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            gridScroll.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            gridScroll.bottomAnchor.constraint(equalTo: panel.bottomAnchor),
        ])

        let styles = visibleCats.isEmpty ? [] : visibleCats[safeCatIndex].1
        buildFontPanelGrid(in: gridScroll, styles: styles)
    }

    private func buildFontPanelGrid(in scrollView: UIScrollView, styles: [FontStyleDef]) {
        scrollView.subviews.forEach { $0.removeFromSuperview() }

        let cols = 2
        let hPad: CGFloat = 8
        let spacing: CGFloat = 6

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = spacing
        grid.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 6),
            grid.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: hPad),
            grid.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -hPad),
            grid.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -6),
            grid.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -hPad * 2),
        ])

        let chunks = stride(from: 0, to: styles.count, by: cols).map {
            Array(styles[$0..<min($0 + cols, styles.count)])
        }
        for (rowIdx, rowStyles) in chunks.enumerated() {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = spacing
            let startIdx = rowIdx * cols
            for (colIdx, style) in rowStyles.enumerated() {
                let styleIdx = startIdx + colIdx
                let isLocked = !isPremiumUser && !effectiveFreeFontNames.contains(style.name)
                let btn = UIButton(type: .system)
                btn.setTitle(displayFontName(style) + (isLocked ? " 👑" : ""), for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
                btn.titleLabel?.adjustsFontSizeToFitWidth = true
                btn.titleLabel?.minimumScaleFactor = 0.6
                btn.tag = styleIdx
                btn.layer.cornerRadius = 10
                btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
                btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
                let sel = selectedFontStyleName.map { $0 == style.name } ?? false
                btn.backgroundColor = sel ? accentColor : UIColor(white: 0.92, alpha: 1)
                btn.setTitleColor(sel ? selectedCatTextColor : (isLocked ? UIColor.systemGray3 : .darkGray), for: .normal)
                if isFavoriteFont(style.name) {
                    btn.layer.borderWidth = 1.5
                    btn.layer.borderColor = accentColor.cgColor
                }
                btn.addTarget(self, action: #selector(fontPanelStyleTapped(_:)), for: .touchUpInside)
                let lp = UILongPressGestureRecognizer(target: self, action: #selector(fontStyleLongPressed(_:)))
                lp.minimumPressDuration = 0.5
                btn.addGestureRecognizer(lp)
                rowStack.addArrangedSubview(btn)
            }
            if rowStyles.count < cols {
                for _ in rowStyles.count..<cols { rowStack.addArrangedSubview(UIView()) }
            }
            grid.addArrangedSubview(rowStack)
        }
    }

    @objc private func fontPanelCatTapped(_ s: UIButton) {
        fontCatIndex = s.tag
        showFontPanel()
    }

    @objc private func fontPanelStyleTapped(_ s: UIButton) {
        let cats = visibleFontCategories()
        let safeCat = min(fontCatIndex, max(cats.count - 1, 0))
        let styles = cats.isEmpty ? [] : cats[safeCat].1
        if !isPremiumUser {
            if s.tag < styles.count && !effectiveFreeFontNames.contains(styles[s.tag].name) {
                fontPickerExpanded = false
                showLockedOverlay()
                return
            }
        }

        fontStyleIndex = s.tag
        if s.tag < styles.count { selectedFontStyleName = styles[s.tag].name }
        applyCurrentFontConversion()
    }

    /// Compute the ideal bottom-bar height for the current fonts-tab state:
    /// budget − picker − letter wrapper − (catScroll if expanded) − inter-
    /// item gaps. Mode-aware because number-mode keeps individual 52pt rows
    /// directly in `stack` while QWERTY/dubeolsik use a single 174pt
    /// `lettersWrapper`. Cheonjiin-without-number returns early before the
    /// bottom bar is built so this is only reached for the bar-bearing
    /// layouts. Clamps to 24pt minimum so the touch target stays usable
    /// even when budget is exhausted (small devices, picker expanded).
    private func computedFontsBottomBarHeight() -> CGFloat {
        let budget = tabContainerHeight
        let pickerH: CGFloat = 36
        let lettersH: CGFloat = 3 * 56 + 2 * 3
        let gaps: CGFloat = 2 * 3  // stack.spacing = 3, 2 gaps: [picker, letters, bottom]
        return max(24, budget - pickerH - lettersH - gaps)
    }

    @objc private func toggleNumberMode() {
        // Leaving a Korean letter row for the digit page (or coming back from
        // it): commit the active syllable so the buffer doesn't stick stale
        // jamo state across the layout switch.
        if isFontsKorean { hgFlush(); cjjReset() }
        isNumberMode.toggle()
        if !isNumberMode { isSymbolPage2 = false }
        showMode(.fonts)
    }

    @objc private func toggleSymbolPage() {
        isSymbolPage2.toggle()
        showMode(.fonts)
    }

    @objc private func gridItemTapped(_ s: UIButton) {
        print("🔥 [gridItemTapped] tag=\(s.tag) isPremiumUser=\(isPremiumUser) mode=\(currentMode)")
        if !isPremiumUser {
            let limit: Int
            if currentMode == .emoticon { limit = isPremiumUser ? 4 : 0 }
            else if currentMode == .special { limit = isPremiumUser ? 6 : 0 }
            else { limit = Int.max }
            if s.tag >= limit {
                showLockedOverlay()
                return
            }
        }
        guard let text = s.title(for: .normal) else { return }
        textDocumentProxy.insertText(text)
        DispatchQueue.global(qos: .userInteractive).async {
            AudioServicesPlaySystemSound(1104)
        }
        tapFeedback(s)
    }

    @objc private func dotArtTapped(_ s: UIButton) {
        if !isPremiumUser && s.tag >= (isPremiumUser ? 5 : 0) {
            showLockedOverlay()
            return
        }
        let items = dotArtCategories.first?.1 ?? []
        guard s.tag < items.count else { return }
        textDocumentProxy.insertText(items[s.tag])
        tapFeedback(s)
    }

    // MARK: - Favorites Storage

    private static let favKeyEmoticon    = "favorites"
    private static let favKeyDotArt     = "favorites_dotart"
    private static let favKeyGif        = "favorites_gif"
    private static let favKeyTextReplace = "favorite_text_replace"
    private static let myPhrasesKey     = "user_custom_phrases"
    private static let favAppGroup    = "group.com.yunajung.fonki"
    private static let maxFav         = 100

    private var favCategoryIndex = 0
    // MARK: - 도트아트 즐겨찾기 카테고리 비활성화 (복구 시 주석 해제)
    // private lazy var favCategoryNames = [loc("fav_cat_all"), loc("fav_cat_emoticon"), loc("fav_cat_special"), loc("fav_cat_dotart"), "GIF"]
    private lazy var favCategoryNames = [loc("fav_cat_all"), loc("fav_cat_text"), loc("fav_cat_emoticon"), loc("fav_cat_special"), "GIF"]

    private func favDefaults() -> UserDefaults {
        UserDefaults(suiteName: Self.favAppGroup) ?? .standard
    }

    private func loadFavList(_ key: String) -> [String] {
        let d = favDefaults()
        d.synchronize()
        return d.stringArray(forKey: key) ?? []
    }

    private func saveFavList(_ key: String, _ items: [String]) {
        favDefaults().set(items, forKey: key)
    }

    private func loadFavorites() -> [String] { loadFavList(Self.favKeyEmoticon) }

    private func addFavorite(_ text: String, key: String = favKeyEmoticon) {
        var items = loadFavList(key)
        guard !items.contains(text) else {
            showToast(loc("toast_fav_exists"))
            return
        }
        if items.count >= Self.maxFav { items.removeLast() }
        items.insert(text, at: 0)
        saveFavList(key, items)
        showToast(loc("favorite_added"))
    }

    private func removeFavorite(_ text: String, key: String) {
        var items = loadFavList(key)
        items.removeAll { $0 == text }
        saveFavList(key, items)
        showToast(loc("favorite_removed"))
        showMode(.favorites)
    }

    // MARK: - Long Press Handlers

    @objc private func gridItemLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let btn = gesture.view as? UIButton,
              let text = btn.title(for: .normal)
        else { return }
        // Determine key based on current mode
        let key = currentMode == .special ? Self.favKeyEmoticon : Self.favKeyEmoticon
        showAddPopup(text: text, favKey: key)
    }

    @objc private func dotArtLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let btn = gesture.view as? UIButton
        else { return }
        let items = dotArtCategories.first?.1 ?? []
        guard btn.tag < items.count else { return }
        let text = items[btn.tag]
        showAddPopup(text: text, favKey: Self.favKeyDotArt, isDotArt: true)
    }

    @objc private func gifLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let btn = gesture.view as? UIButton,
              let gifID = btn.accessibilityIdentifier,
              let gif = gifImages.first(where: { $0.id == gifID })
        else { return }
        showAddPopup(text: gif.originalURL.absoluteString, favKey: Self.favKeyGif, isGif: true)
    }

    @objc private func favoriteTapped(_ s: UIButton) {
        guard isPremiumUser else {
            showLockedOverlay()
            return
        }
        guard let text = s.title(for: .normal) else { return }
        textDocumentProxy.insertText(text)
        tapFeedback(s)
    }

    @objc private func favDotArtTapped(_ s: UIButton) {
        guard isPremiumUser else {
            showLockedOverlay()
            return
        }
        let dotArtFavs = loadFavList(Self.favKeyDotArt)
        guard s.tag < dotArtFavs.count else { return }
        textDocumentProxy.insertText(dotArtFavs[s.tag])
        tapFeedback(s)
    }

    @objc private func favGifTapped(_ s: UIButton) {
        guard isPremiumUser else {
            showLockedOverlay()
            return
        }
        let gifFavs = loadFavList(Self.favKeyGif)
        guard s.tag < gifFavs.count, let url = URL(string: gifFavs[s.tag]) else { return }
        showToast(loc("toast_gif_downloading"))
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                guard let data = data else { self?.showToast(self?.loc("toast_gif_failed") ?? ""); return }
                UIPasteboard.general.setData(data, forPasteboardType: "com.compuserve.gif")
                let defaults = UserDefaults(suiteName: "group.com.yunajung.fonki")
                defaults?.set(url.absoluteString, forKey: "lastCopiedGifUrl")
                self?.showToast(self?.loc("toast_gif_copied") ?? "")
            }
        }.resume()
    }

    @objc private func favoriteLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let btn = gesture.view as? UIButton,
              let text = btn.title(for: .normal)
        else { return }
        showRemovePopup(text: text, favKey: Self.favKeyEmoticon)
    }

    @objc private func favDotArtLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let btn = gesture.view as? UIButton
        else { return }
        let dotArtFavs = loadFavList(Self.favKeyDotArt)
        guard btn.tag < dotArtFavs.count else { return }
        showRemovePopup(text: dotArtFavs[btn.tag], favKey: Self.favKeyDotArt)
    }

    @objc private func favGifLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let btn = gesture.view as? UIButton
        else { return }
        let gifFavs = loadFavList(Self.favKeyGif)
        guard btn.tag < gifFavs.count else { return }
        showRemovePopup(text: gifFavs[btn.tag], favKey: Self.favKeyGif)
    }

    @objc private func favCategoryTapped(_ sender: UIButton) {
        favCategoryIndex = sender.tag
        showMode(.favorites)
    }

    // MARK: - Popup

    private func showAddPopup(text: String, favKey: String, isDotArt: Bool = false, isGif: Bool = false) {
        let overlay = makeOverlay()

        let stack = makePopupStack(in: overlay)

        let favBtn = makePopupButton(title: loc("fav_add"), color: UIColor(red: 0.90, green: 0.20, blue: 0.40, alpha: 1)) {
            overlay.removeFromSuperview()
            self.addFavorite(text, key: favKey)
        }
        stack.addArrangedSubview(favBtn)

        if !isDotArt && !isGif {
            let copyBtn = makePopupButton(title: loc("fav_copy"), color: .darkGray) {
                overlay.removeFromSuperview()
                UIPasteboard.general.string = text
                self.showToast(self.loc("toast_copied"))
            }
            stack.addArrangedSubview(copyBtn)
        }

        stack.addArrangedSubview(makePopupButton(title: loc("cancel_button"), color: .darkGray) {
            overlay.removeFromSuperview()
        })
    }

    private func showRemovePopup(text: String, favKey: String) {
        let overlay = makeOverlay()
        let stack = makePopupStack(in: overlay)

        stack.addArrangedSubview(makePopupButton(title: loc("fav_delete"), color: .systemRed) {
            overlay.removeFromSuperview()
            self.removeFavorite(text, key: favKey)
        })
        stack.addArrangedSubview(makePopupButton(title: loc("cancel_button"), color: .darkGray) {
            overlay.removeFromSuperview()
        })
    }

    private func makeOverlay() -> UIView {
        let overlay = UIView()
        overlay.backgroundColor = UIColor(white: 0, alpha: 0.3)
        overlay.frame = view.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)
        overlay.addGestureRecognizer(UITapGestureRecognizer(target: overlay, action: #selector(UIView.removeFromSuperview)))
        return overlay
    }

    // MARK: - First-entry usage tips

    /// Live tip popup state. Tracked so the "닫기"/"다시 안 보기" buttons and
    /// a background tap all route through `dismissTip(persist:)` — which
    /// only persists the per-tab flag (so the tip never reappears) when
    /// "다시 안 보기" was tapped. "닫기" and a background tap both dismiss
    /// without persisting, so the tip shows again next time that tab opens.
    private var tipOverlay: UIView?
    private var tipCard: UIView?
    private var tipFlagKey: String?

    /// Shows the one-time usage tip for fonts / translate / gif the first
    /// time the user opens that tab. No-op for every other mode and once the
    /// per-tab flag is set. The flag lives in the extension's own
    /// `UserDefaults.standard` (not the App Group) so deleting the app clears
    /// it — a reinstall shows the tips again.
    private func showTipIfNeeded(for mode: Mode) {
        let tip: (emoji: String, title: String, body: String, key: String)?
        switch mode {
        case .fonts:
            tip = ("✨", loc("tip_fonts_title"), loc("tip_fonts_body"), "tip_shown_fonts")
        case .translate:
            tip = ("🌐", loc("tip_translate_title"), loc("tip_translate_body"), "tip_shown_translate")
        case .gif:
            tip = ("🎬", loc("tip_gif_title"), loc("tip_gif_body"), "tip_shown_gif")
        case .textTemplate:
            tip = ("💬", loc("tip_textTemplate_title"), loc("tip_textTemplate_body"), "tip_shown_textTemplate")
        default:
            tip = nil
        }
        guard let tip = tip else { return }
        // Fonts/translate/GIF are usable by free users too (usage-limited,
        // not tab-locked — see the free-tier exemptions in `showMode`), so
        // their tips show for every user, same as My List. Per-tab
        // `tip_shown_*` flags below are still what prevents repeat showings.
        if UserDefaults.standard.bool(forKey: tip.key) { return }

        showTip(emoji: tip.emoji, title: tip.title, body: tip.body, flagKey: tip.key)
    }

    private func showTip(emoji: String, title: String, body: String, flagKey: String) {
        // Tear down any tip already on screen first. Without this, a second
        // `showTip` call (e.g. from a queued 0.5s-delayed `showTipIfNeeded`
        // while the user flips through tabs) would stack a new overlay on
        // top of the old one — the old one's buttons would still fire, but
        // `dismissTip`/`tipBackgroundTapped` only ever act on the single
        // shared `tipOverlay`/`tipCard`, so the orphaned one below could
        // never be removed by tapping it. This is a redraw, not a user
        // dismissal, so it must NOT persist the "don't show again" flag —
        // that's why this doesn't go through `dismissTip(persist:)`.
        tipOverlay?.removeFromSuperview()
        tipOverlay = nil
        tipCard = nil

        // Dedicated overlay (alpha 0.5, vs makeOverlay's 0.3) so the tip reads
        // as a modal rather than the lighter popup-picker dimming.
        let overlay = UIView()
        overlay.backgroundColor = UIColor(white: 0, alpha: 0.5)
        overlay.frame = view.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)
        overlay.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tipBackgroundTapped(_:))))

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(card)
        NSLayoutConstraint.activate([
            card.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            card.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -24),
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        let titleLabel = UILabel()
        titleLabel.text = "\(emoji) \(title)"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        stack.addArrangedSubview(titleLabel)

        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = .gray
        bodyLabel.textAlignment = .center
        bodyLabel.numberOfLines = 0
        stack.addArrangedSubview(bodyLabel)

        // Two buttons side by side: "다시 안 보기" (persists the per-tab
        // flag) and "닫기" (dismisses without persisting, same as a
        // background tap — the tip shows again next time this tab opens).
        let buttonRow = UIStackView()
        buttonRow.axis = .horizontal
        buttonRow.spacing = 8
        buttonRow.distribution = .fillEqually

        let dontShowBtn = UIButton(type: .system)
        dontShowBtn.setTitle(loc("tip_dont_show_again"), for: .normal)
        dontShowBtn.setTitleColor(.darkGray, for: .normal)
        dontShowBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        dontShowBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        dontShowBtn.backgroundColor = UIColor(white: 0.92, alpha: 1)
        dontShowBtn.layer.cornerRadius = 12
        dontShowBtn.setHeight(44)
        dontShowBtn.addAction(UIAction { [weak self] _ in
            self?.dismissTip(persist: true)
        }, for: .touchUpInside)
        buttonRow.addArrangedSubview(dontShowBtn)

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle(loc("close_button"), for: .normal)
        closeBtn.setTitleColor(.white, for: .normal)
        closeBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        closeBtn.backgroundColor = UIColor(red: 0x7F / 255, green: 0xC7 / 255, blue: 0xFF / 255, alpha: 1)
        closeBtn.layer.cornerRadius = 12
        closeBtn.setHeight(44)
        closeBtn.addAction(UIAction { [weak self] _ in
            self?.dismissTip(persist: false)
        }, for: .touchUpInside)
        buttonRow.addArrangedSubview(closeBtn)

        stack.addArrangedSubview(buttonRow)

        tipOverlay = overlay
        tipCard = card
        tipFlagKey = flagKey
    }

    @objc private func tipBackgroundTapped(_ g: UITapGestureRecognizer) {
        // Taps that land on the card itself shouldn't dismiss — only the
        // surrounding dimmed background should.
        guard let overlay = tipOverlay, let card = tipCard else { return }
        if card.frame.contains(g.location(in: overlay)) { return }
        // Dismissing via background tap is the same as tapping "확인" without
        // checking the box — the tip should show again next time.
        dismissTip(persist: false)
    }

    private func dismissTip(persist: Bool) {
        if persist, let key = tipFlagKey {
            UserDefaults.standard.set(true, forKey: key)
        }
        tipOverlay?.removeFromSuperview()
        tipOverlay = nil
        tipCard = nil
        tipFlagKey = nil
    }

    private func makePopupStack(in overlay: UIView) -> UIStackView {
        let popup = UIView()
        popup.backgroundColor = .white
        popup.layer.cornerRadius = 14
        popup.layer.shadowColor = UIColor.black.cgColor
        popup.layer.shadowOpacity = 0.2
        popup.layer.shadowRadius = 10
        popup.layer.masksToBounds = false
        popup.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(popup)

        NSLayoutConstraint.activate([
            popup.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            popup.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            popup.widthAnchor.constraint(equalToConstant: 220),
            popup.topAnchor.constraint(greaterThanOrEqualTo: overlay.topAnchor, constant: 8),
            popup.bottomAnchor.constraint(lessThanOrEqualTo: overlay.bottomAnchor, constant: -8),
        ])

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = false
        scrollView.layer.cornerRadius = 14
        scrollView.layer.masksToBounds = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: popup.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: popup.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: popup.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: popup.bottomAnchor),
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -8),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -16),
        ])

        // Drive popup height from scrollView's content (so popup auto-sizes to its buttons),
        // bounded by the popup.bottomAnchor <= overlay.bottom constraint above.
        let popupHeight = popup.heightAnchor.constraint(
            equalTo: scrollView.contentLayoutGuide.heightAnchor)
        popupHeight.priority = .defaultHigh
        popupHeight.isActive = true

        return stack
    }

    private func makePopupButton(title: String, color: UIColor, action: @escaping () -> Void) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(color, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        btn.backgroundColor = UIColor(white: 0.96, alpha: 1)
        btn.layer.cornerRadius = 10
        btn.setHeight(42)
        btn.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return btn
    }

    // MARK: - Premium Check (via App Group UserDefaults synced from main app)

    private func checkPremiumStatus() {
        let appGroupID = "group.com.yunajung.fonki"
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            isPremiumUser = false
            userTier = "free"
            canTranslateUnlimited = false
            print("🔥 [checkPremiumStatus] AppGroup unavailable → isPremiumUser=false")
            return
        }
        isPremiumUser = defaults.bool(forKey: "is_premium")
        userTier = defaults.string(forKey: "tier") ?? "free"
        canTranslateUnlimited = defaults.bool(forKey: "can_translate_unlimited")
        print("🔥 [checkPremiumStatus] AppGroup raw: is_premium=\(defaults.bool(forKey: "is_premium")) tier=\(userTier)")
        #if DEBUG
        if Self.debugForceFree {
            isPremiumUser = false
            userTier = "free"
            canTranslateUnlimited = false
        }
        #endif
        // If subscription lapsed, reset any premium theme back to Default.
        if !isPremiumUser {
            let premiumThemes: Set<KeyboardTheme> = [.lavender, .pastelRainbow, .soft, .bubbleMint, .retroCream, .vintageGray, .hotPink]
            if premiumThemes.contains(currentTheme) {
                currentTheme = .default
            }
        }
        print("🔥 [checkPremiumStatus] final: isPremiumUser=\(isPremiumUser) debugForceFree=\(Self.debugForceFree)")
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === fontStyleScrollView {
            savedFontScrollOffset = scrollView.contentOffset
        } else if scrollView === emoticonCatScrollView {
            savedEmoticonCatOffset = scrollView.contentOffset
        } else if scrollView === specialCatScrollView {
            savedSpecialCatOffset = scrollView.contentOffset
        } else if scrollView === fandomCatScrollView {
            savedFandomCatOffset = scrollView.contentOffset
        } else if scrollView === gifCatScrollView {
            savedGifCatOffset = scrollView.contentOffset
        } else if scrollView === gifScrollView {
            // Infinite scroll: load more when near bottom
            let offsetY = scrollView.contentOffset.y
            let contentH = scrollView.contentSize.height
            let frameH = scrollView.frame.height
            if contentH > 0, offsetY > contentH - frameH - 100 {
                loadMoreGifs()
            }
        }
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let toast = UIView()
        toast.backgroundColor = UIColor(white: 0, alpha: 0.75)
        toast.layer.cornerRadius = 14
        toast.layer.masksToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        toast.alpha = 0
        toast.addSubview(label)
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: toast.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: toast.bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -16),

            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            toast.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -32),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
        ])

        UIView.animate(withDuration: 0.2, animations: {
            toast.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.25, delay: 1.2, options: [], animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }

    // MARK: - Helpers

    private func updateKeyLabels() {
        for btn in letterKeys {
            guard let t = btn.title(for: .normal) else { continue }
            btn.setTitle(isShifted ? t.uppercased() : t.lowercased(), for: .normal)
        }
    }

    private func tapFeedback(_ btn: UIButton) {
        let originalBG = btn.backgroundColor
        UIView.animate(withDuration: 0.05, delay: 0,
                       options: [.allowUserInteraction, .curveEaseInOut],
                       animations: {
            btn.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            btn.backgroundColor = self.accentColor.withAlphaComponent(0.15)
        }) { _ in
            UIView.animate(withDuration: 0.05, delay: 0,
                           options: [.allowUserInteraction, .curveEaseInOut]) {
                btn.transform = .identity
                btn.backgroundColor = originalBG
            }
        }
    }

    private func makeLetterKey(_ title: String) -> UIButton {
        if currentTheme == .bubbleMint {
            let btn = HitExpandButton()
            btn.hitInset = 4
            btn.setTitle(title, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 22, weight: .regular)
            btn.setTitleColor(.black, for: .normal)
            btn.tintColor = .black
            btn.adjustsImageWhenHighlighted = false
            btn.showsTouchWhenHighlighted = false

            let isSpaceKey = (title == "space" || title == "⎵")
            let mintBorderColor = UIColor(red: 0.55, green: 0.80, blue: 0.62, alpha: 1).cgColor

            if isSpaceKey {
                // space: 단순 cornerRadius pill + 테두리, 그라데이션 없음
                btn.backgroundColor = UIColor(red: 0.88, green: 0.97, blue: 0.90, alpha: 1)
                btn.layer.cornerRadius = 28
                btn.layer.masksToBounds = true
                btn.clipsToBounds = true
                btn.layer.borderWidth = 1.5
                btn.layer.borderColor = mintBorderColor
            } else if isBuildingTranslateLayout {
                // 번역탭 키: 그라데이션은 applyBubbleMintGradientToTranslateLetterKeys()에서 동기 적용
                btn.backgroundColor = .clear
                btn.layer.cornerRadius = 0
                btn.layer.masksToBounds = false
                btn.clipsToBounds = false
                btn.layer.borderWidth = 0
            } else {
                // 일반 letter 키: viewDidLayoutSubviews에서 그라데이션+타원 마스크 적용
                btn.backgroundColor = .clear
                btn.layer.cornerRadius = 0
                btn.layer.masksToBounds = false
                btn.clipsToBounds = false
                bubbleMintKeys.append(btn)
            }
            return btn
        }
        // Use `HitExpandButton` (custom-type subclass) so we can override
        // `point(inside:with:)` to expand the touch target ~4pt past the
        // button's visual frame. `UIButton(type: .system)` would not
        // instantiate the subclass — Apple's factory returns a private
        // UIButton variant — so we use `.custom` and apply all visual
        // styling manually (which the rest of this builder already does).
        // The 4pt halo helps "모음 연타" stop dropping inputs when the
        // user's finger lands slightly off the narrow ~33pt vowel keys.
        let btn = HitExpandButton()
        btn.hitInset = 4
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 22, weight: .regular)
        btn.backgroundColor = keyBG
        if currentTheme == .default { btn.backgroundColor = .white }
        btn.setTitleColor(.black, for: .normal)
        btn.tintColor = .black
        if currentTheme == .soft {
            btn.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)
            btn.layer.cornerRadius = 8
            btn.layer.shadowColor = UIColor(white: 0.55, alpha: 1).cgColor
            btn.layer.shadowOffset = CGSize(width: 0, height: 4)
            btn.layer.shadowOpacity = 0.5
            btn.layer.shadowRadius = 3
            btn.layer.masksToBounds = false
            btn.layer.borderWidth = 0.5
            btn.layer.borderColor = UIColor(white: 0.88, alpha: 1).cgColor
        } else if currentTheme == .retroCream {
            btn.titleLabel?.font = .systemFont(ofSize: 24, weight: .regular)
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth = 1.2
            btn.layer.borderColor = UIColor.black.cgColor
            btn.layer.masksToBounds = true
        } else if currentTheme == .vintageGray {
            btn.setTitleColor(.black, for: .normal)
            btn.layer.cornerRadius = 6
            btn.layer.borderWidth = 0
            btn.layer.masksToBounds = false
            vintageGrayKeys.append(btn)
        } else if currentTheme == .hotPink {
            btn.setTitleColor(.black, for: .normal)
            btn.tintColor = .black
            btn.layer.cornerRadius = 5
            btn.layer.borderWidth = 0
        } else {
            btn.layer.cornerRadius = 5
            btn.layer.borderWidth = 1.0
            btn.layer.borderColor = currentTheme == .pastelRainbow
                ? UIColor(white: 1.0, alpha: 0.4).cgColor
                : accentColor.withAlphaComponent(0.5).cgColor
        }
        btn.adjustsImageWhenHighlighted = false
        btn.showsTouchWhenHighlighted = false
        return btn
    }

    private func makeSpecialKey(_ title: String) -> UIButton {
        if currentTheme == .bubbleMint {
            let btn = UIButton(type: .custom)
            btn.setTitle(title, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            btn.setTitleColor(.black, for: .normal)
            btn.layer.cornerRadius = 20
            btn.layer.masksToBounds = true
            btn.clipsToBounds = true
            if isBuildingTranslateLayout {
                btn.backgroundColor = specialKeyBG
                btn.layer.borderWidth = 0
            } else {
                btn.backgroundColor = specialKeyBG
            }
            btn.adjustsImageWhenHighlighted = false
            btn.showsTouchWhenHighlighted = false
            return btn
        }
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        btn.backgroundColor = specialKeyBG
        btn.setTitleColor(.black, for: .normal)
        if currentTheme == .soft {
            btn.layer.cornerRadius = 8
            btn.layer.shadowColor = UIColor(white: 0.55, alpha: 1).cgColor
            btn.layer.shadowOffset = CGSize(width: 0, height: 4)
            btn.layer.shadowOpacity = 0.5
            btn.layer.shadowRadius = 3
            btn.layer.masksToBounds = false
            btn.layer.borderWidth = 0.5
            btn.layer.borderColor = UIColor(white: 0.88, alpha: 1).cgColor
        } else if currentTheme == .retroCream {
            btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth = 1.2
            btn.layer.borderColor = UIColor.black.cgColor
            btn.layer.masksToBounds = true
            btn.tintColor = .black
            if title == "⇧" || title == "⌫" {
                btn.backgroundColor = UIColor(red: 1.0, green: 0.90, blue: 0.50, alpha: 1) // 노랑
            } else {
                btn.backgroundColor = UIColor(red: 0.98, green: 0.75, blue: 0.80, alpha: 1) // 핑크
            }
        } else if currentTheme == .vintageGray {
            btn.setTitleColor(.black, for: .normal)
            btn.tintColor = .black
            btn.layer.cornerRadius = 6
            btn.layer.borderWidth = 0
            btn.layer.masksToBounds = false
            if isBuildingTranslateLayout {
                btn.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)
            }
            vintageGrayKeys.append(btn)
        } else if currentTheme == .hotPink {
            btn.setTitleColor(.black, for: .normal)
            btn.tintColor = .black
            btn.layer.cornerRadius = 5
            btn.layer.borderWidth = 0
        } else {
            btn.layer.cornerRadius = 5
            btn.layer.borderWidth = 1.0
            btn.layer.borderColor = currentTheme == .pastelRainbow
                ? UIColor(white: 1.0, alpha: 0.4).cgColor
                : accentColor.withAlphaComponent(0.5).cgColor
        }
        btn.adjustsImageWhenHighlighted = false
        btn.showsTouchWhenHighlighted = false
        return btn
    }

    private func pinToEdges(_ child: UIView, in parent: UIView) {
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: parent.topAnchor),
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
        ])
    }
}

// MARK: - UIView Size Helpers

private extension UIView {
    func setHeight(_ h: CGFloat) {
        heightAnchor.constraint(equalToConstant: h).isActive = true
    }
    func setWidth(_ w: CGFloat) {
        widthAnchor.constraint(equalToConstant: w).isActive = true
    }
}

// MARK: - FontScrollView
// Horizontal scroll view for the font picker bar. Overrides
// `touchesShouldCancel(in:)` so that starting a drag on top of a UIButton
// cancels the button's touch tracking — otherwise buttons swallow drags and
// the scroll view never pans.
final class FontScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view is UIButton { return true }
        return super.touchesShouldCancel(in: view)
    }
}

/// UIButton subclass that reports touches as "inside" the button up to a
/// configurable `hitInset` past the visual frame. Used by `makeLetterKey`
/// to give every letter key a small touch halo — important for the narrow
/// Korean QWERTY (10-column top row → ~33pt buttons on a 4.7" iPhone)
/// where rapid-tap vowel inputs were dropping when the user's finger
/// landed slightly off-center between adjacent keys.
class HitExpandButton: UIButton {
    /// Number of points to extend the hit area outward on all four sides.
    /// 0 disables the override (falls back to default frame-bounded hit).
    var hitInset: CGFloat = 0
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard hitInset > 0 else { return super.point(inside: point, with: event) }
        return bounds.insetBy(dx: -hitInset, dy: -hitInset).contains(point)
    }
}



extension KeyboardViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Return key dismisses focus (matches the previous textFieldShouldReturn behavior).
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        let current = textView.text ?? ""
        guard let r = Range(range, in: current) else { return true }
        let newText = current.replacingCharacters(in: r, with: text)
        return newText.count <= 200
    }

    func textViewDidChange(_ textView: UITextView) {
        var t = textView.text ?? ""
        if t.count > 200 { t = String(t.prefix(200)); textView.text = t }
        translationInput = t
        let cnt = t.count
        translateCounterLabel?.text = "\(cnt) / 200"
        translateCounterLabel?.textColor = cnt >= 180 ? .systemRed : .lightGray
        translatePlaceholderLabel?.isHidden = !t.isEmpty
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        translateCloseButton?.alpha = 1
        hgFlush()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        translateCloseButton?.alpha = 0
        hgFlush()
    }
}

// MARK: - Debug helpers (remove before release)
private class DebugCard: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        print("🔥 [HitTest-Card] point:\(point) result:\(String(describing: result))")
        return result
    }
}

extension KeyboardViewController {
    func printViewHierarchy(_ v: UIView, indent: String = "") {
        let gestures = v.gestureRecognizers?.map { type(of: $0) } ?? []
        print("🔥 \(indent)\(type(of: v)) frame:\(v.frame) ui:\(v.isUserInteractionEnabled) alpha:\(v.alpha) hidden:\(v.isHidden) gestures:\(gestures)")
        for sub in v.subviews {
            printViewHierarchy(sub, indent: indent + "  ")
        }
    }
}

