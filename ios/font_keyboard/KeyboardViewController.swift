import UIKit

// MARK: - Constants

private let mainPink = UIColor(red: 1, green: 0.42, blue: 0.62, alpha: 1)
private let keyBG = UIColor.white
private let specialKeyBG = UIColor(white: 0.78, alpha: 1)

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
    "a":"ᗩ","b":"ᗷ","c":"ᑕ","d":"ᗪ","e":"ᗴ","f":"ᖴ","g":"ᘜ","h":"ᕼ","i":"ᓮ","j":"ᒍ",
    "k":"ᛕ","l":"ᒪ","m":"ᗰ","n":"ᑎ","o":"ᗝ","p":"ᑭ","q":"ᑫ","r":"ᖇ","s":"ᔕ","t":"ᖶ",
    "u":"ᑌ","v":"ᐯ","w":"ᗯ","x":"᙭","y":"Ƴ","z":"ᘔ",
    "A":"ᗩ","B":"ᗷ","C":"ᑕ","D":"ᗪ","E":"ᗴ","F":"ᖴ","G":"ᘜ","H":"ᕼ","I":"ᓮ","J":"ᒍ",
    "K":"ᛕ","L":"ᒪ","M":"ᗰ","N":"ᑎ","O":"ᗝ","P":"ᑭ","Q":"ᑫ","R":"ᖇ","S":"ᔕ","T":"ᖶ",
    "U":"ᑌ","V":"ᐯ","W":"ᗯ","X":"᙭","Y":"Ƴ","Z":"ᘔ",
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

let allFontCategories: [(String, [FontStyleDef])] = [
    ("클래식", [
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
    ]),
    ("모던", [
        FontStyleDef(name: "Wide",         convert: { _oc($0, 0xFF21, 0xFF41, 0xFF10) }),
        FontStyleDef(name: "Dark",         convert: { _oc($0, 0x1D56C, 0x1D586, nil) }),
        FontStyleDef(name: "Sans",         convert: { _oc($0, 0x1D5A0, 0x1D5BA, 0x1D7E2) }),
        FontStyleDef(name: "Sans Italic",  convert: { _oc($0, 0x1D608, 0x1D622, nil) }),
        FontStyleDef(name: "Heavy",        convert: { _oc($0, 0x1D63C, 0x1D656, nil) }),
    ]),
    ("굵게", [
        FontStyleDef(name: "Serif Bold",   convert: { _oc($0, 0x1D400, 0x1D41A, 0x1D7CE) }),
        FontStyleDef(name: "Chunky",       convert: { _oc($0, 0x1F150, 0x1F150, nil) }),
        FontStyleDef(name: "Block",        convert: { _oc($0, 0x1F170, 0x1F170, nil) }),
    ]),
    ("재미있는", [
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
    ("장식", [
        FontStyleDef(name: "Overline",     convert: { _cc($0, "\u{0305}") }),
        FontStyleDef(name: "Sparkle",      convert: { _cc($0, "꙰") }),
        FontStyleDef(name: "Candy",        convert: { $0.map { $0 == " " ? " " : "♡\($0)♡" }.joined() }),
        FontStyleDef(name: "Pinched",      convert: { _cc($0, "\u{0303}") }),
    ]),
    ("추가스타일", [
        FontStyleDef(name: "Ringed",       convert: { _cc($0, "\u{030A}") }),
        FontStyleDef(name: "Dotted",       convert: { _cc($0, "\u{0323}") }),
        FontStyleDef(name: "Box",          convert: { $0.map { $0 == " " ? " " : "[\($0)]" }.joined() }),
        FontStyleDef(name: "Sub",          convert: { _cm($0, _subMap) }),
    ]),
    ("독특한", [
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
        case fonts = 0, translate, calculator, emoticon, textTemplate, special, dotArt, gif, favorites
        var title: String {
            switch self {
            case .fonts:        return "Aa"
            case .translate:    return "번역"
            case .calculator:   return ""  // SF Symbol image used instead (plus.minus.circle)
            case .emoticon:     return "( • ɞ• )"
            case .textTemplate: return "💬"
            case .special:      return "✦"
            case .dotArt:       return "⣿"
            case .gif:          return "GIF"
            case .favorites:    return "♥"
            }
        }
        var fontSize: CGFloat {
            switch self {
            case .emoticon:  return 9
            case .special:   return 16
            case .dotArt:    return 16
            case .translate: return 12
            default:         return 14
            }
        }
    }

    // MARK: - State

    private var currentMode: Mode = .fonts
    private var fontCatIndex = 0
    private var fontStyleIndex = 0
    private var fontPickerExpanded = false
    private weak var fontCategoryRowView: UIView?
    private weak var fontToggleButton: UIButton?

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
        return [("즐겨찾기", favDefs)] + allFontCategories
    }
    private var isShifted = false
    private var isCapsLock = false
    private var lastFontShiftTime: Date?
    private var isNumberMode = false
    private var isSymbolPage2 = false
    private var savedFontScrollOffset: CGPoint = .zero
    private weak var fontStyleScrollView: UIScrollView?
    private var savedEmoticonCatOffset: CGPoint = .zero
    private weak var emoticonCatScrollView: UIScrollView?
    private var savedSpecialCatOffset: CGPoint = .zero
    private weak var specialCatScrollView: UIScrollView?

    // MARK: - Views

    private var mainStack: UIStackView!
    private let modeBar = UIStackView()
    private let contentView = UIView()
    private var letterKeys: [UIButton] = []

    // MARK: - QWERTY Layout

    private let qwertyRows: [[String]] = [
        ["q","w","e","r","t","y","u","i","o","p"],
        ["a","s","d","f","g","h","j","k","l"],
        ["z","x","c","v","b","n","m"]
    ]

    // MARK: - Emoticon Data

    private let emoticonCategories: [(String, [String])] = [
        ("행복", ["(◕‿◕)", "(｡◕‿◕｡)", "ヽ(＾▽＾)ノ", "(★‿★)", "٩(◕‿◕)۶", "(*^▽^*)", "(≧◡≦)", "ヾ(＾∇＾)",
                  "ʕ ᐢ ᵕ ᐢ ʔ", "⌯⦁⩊⦁⌯ಣ", "≽^•༚• ྀི≼", "(՞•-•՞)", "૮₍ •̀ ⩊ •́ ₎ა", "໒꒰ྀི˶•⤙•˶꒱ྀིა",
                  "(๑˃́ꇴ˂̀๑)", "(๑>ᴗ<๑)", "(๑′ᴗ‵๑)", "(๑•᎑<๑)ｰ☆", "٩(•̮̮̃•̃)۶", "(´•᎑•`)♡",
                  "✪‿✪", "꜆₍ᐢ˶•ᴗ•˶ᐢ₎꜆", "( ՞ෆ ෆ՞ )",
                  "ツ", "㋡", "◡̎", "⎝⍥⎠", "( ◡̉̈ )"]),
        ("슬픔", ["(；﹏；)", "(╥_╥)", "(T_T)", "(つ﹏⊂)", "(っ˘̩╭╮˘̩)っ", "(-_-)zzZ", "(ಥ_ಥ)", "(◞‸◟)",
                  "ʕ ﹷ ᴥ ﹷʔ", ".·°՞(っ-ᯅ-ς)՞°·.", "꒰ ᐢ ◞‸◟ᐢ꒱", "｡°(° ᷄ᯅ ᷅°)°｡",
                  "૮₍´›̥̥̥ ᜊ ‹̥̥̥ `₎ა", "( ˘•∽•˘ )", "໒꒰ ྀི ′̥̥̥ ᵔ ‵̥̥̥ ꒱ྀིა", "(ˊ̥̥̥̥̥ ³ ˋ̥̥̥̥̥)",
                  ".·´¯`(>▂<)´¯`·.", "（ｉДｉ）", "(•̩̩̩̩＿•̩̩̩̩)", "(•́ɞ•̀)",
                  "( •̥ ˍ •̥ )", "( ;ᯅ; )", "(っ◞‸◟c)", "₍ᐡඉ ̫ ඉᐡ₎",
                  "༼ ˃ɷ˂ഃ༽", "⚲_⚲", "(˘•̥-•̥˘)", "(•̥̥̥⌓•̥̥̥)", "⩌ ᯅ ⩌"]),
        ("화남", ["( ᴖ_ᴖ )💢", "ᐡ ᵒ̴ – ᵒ̴ ᐡ💢", "ヽ(｀⌒´メ)ノ",
                  "̿' ̿'\\̵͇̿̿\\з=( ͡ °_̯͡° )=ε/̵͇̿̿/'̿'̿ ̿", "✧ `↼´˵", "ʕ •̀ o •́ ʔ",
                  "¸◕ˇ‸ˇ◕˛", "ʕ •̀ ω •́ ʔ", "(◟‸◞)", "(  '-'  ꐦ)",
                  "(◦`~´◦)", "( ｡ •̀ ⤙ •́ ｡ )", "ʕ•̀⤙•́ ʔ", "૮(•᷄‎ࡇ•᷅ )ა",
                  "( ò_ó)", "(   ꐦ •̀ ⤙ •́ )  =3", "૮(っ `O´  c)ა", "• ︡ᯅ•︠",
                  "/ᐠ •̀ ˕ •́ マ", "ʕ•̀ ω •́ʔ.:",
                  "◠̈"]),
        ("동물", ["(=^･ω･^=)", "ʕ•ᴥ•ʔ", "(◕ᴥ◕)", "=^.^=", "(づ｡◕‿‿◕｡)づ", "ʕ·͡ᴥ·ʔ", "(^・ω・^ )", "≽^•⩊•^≼",
                  "ʕ•ᴥ•.ʔ", "ʕ๑•ﻌ•๑ʔ", "ʕ•͡ɛ•͡ʼʼʔ", "( ⁻(❢)⁻ )", "₍ᐢ•ᴥ•ᐢ₎", "(✦(ᴥ)✦)",
                  "ʕ òᴥó ʔ", "ʕ*•-•ʔฅ", "ʕ•̀д•́ʔﾉ", "/ᐠ ˵• ﻌ •˵マ", "꜀(^｡ ̫ ｡^꜀ )꜆੭",
                  "/.\\___/.\\ <(야옹)", "o(=´∇｀=)o", "/ᐠ - ̫ -マ", "(=･ｪ･=?", "●ᴥ●",
                  "૮₍ ՛◐ ᴥ ◐`₎ʖ", "໒( ̿･ ᴥ ̿･ )ʋ", "ᘳ´• ᴥ •`ᘰ", "૮ ｡ˊᯅˋ ა", "૮₍ •̀ᴥ•́ ₎ა",
                  "૮ ・ﻌ・ა", "ヽ(°ᴥ°)ﾉ", "(ᐡ -.- ᐡ)", "( ੭ ˙🐽˙ )੭", "( ˶˙🐽˙˵ ᐡ )",
                  "(՞•Ꙫ•՞)ﾉ?", "₍ᐢ`🐽´ᐢ₎", "₍՞ • 🐽 • ՞₎", "(´・(oo)・｀)", "𓃟",
                  "(̂•͈Ꙫ•͈⑅)̂ ୭", "₍ᐢ. ֑ .ᐢ₎", "( ᐢ, ,ᐢ)", "⎛⑉・⊝・⑉⎞", "•᷅ ʚ •᷄",
                  "ʚ(•Θ•)ɞ", "୧(•̀ө•́)୨", "(๑•̀ɞ•́๑)✧", "( • ɞ• )", "(・ε・)",
                  "(๑❛ө❛๑ )三", "（ˇ ⊖ˇ）", "( ˙◊˙ )", "( 'Θ')ﾉ", "𓆩(•࿉•)𓆪"]),
        ("사랑", ["(♥ω♥)", "(づ￣³￣)づ", "( ˘ ³˘)♥", "(っ´▽`)っ♥", "(/^▽^)/♥", "(◍•ᴗ•◍)❤", "♡(˘▽˘>", "(˘⌣˘)♡",
                  "꜀(  ꜆-⩊-)꜆♡", "( ˶'ᵕ'🫶🏻)💕", "(⸝⸝´▽︎ `⸝⸝)", "( ⸝⸝⸝•   •⸝⸝⸝)",
                  "＞ ̫＜ ♡", "(ღˇᴗˇ)", "(๑•́ ₃ •̀๑)", "(●´□`)♡",
                  "( ๑ ❛ ڡ ❛ ๑ )❤", "⸜(♡ ॑ᗜ ॑♡)⸝", "•́ε•̀٥", "( ◜ᴗ◝ )♡",
                  "(ღ•͈ᴗ•͈ღ)♥", "໒( ♥ ◡ ♥ )७", "♡ ᐡ◕ ̫ ◕ᐡ ♡", "♥(〃´૩`〃)♥",
                  "( . ̫ .)💗", "(♡´౪`♡)", "( っ꒪⌓꒪)っ—̳͟͞͞♡", "૮ - ﻌ • ა ♥", "⁎⁍̴̆Ɛ⁍̴̆⁎"]),
        ("반응", ["(°ロ°)", "Σ(°△°)", "¯\\_(ツ)_/¯", "(-_-;)", "m(_ _)m", "(；一_一)", "╰(*°▽°*)╯", "(・o・)",
                  "･ᴗ･ )੭''", "( *´ᗜ`*)ﾉ", "(๑'• ֊ •'๑)੭", "٩( ´◡` )( ´◡` )۶", "_(._.)_",
                  "( •⍸• )", "c(   'o')っ", "(⊙_⊙)", "( ´o` )", "ᯤ ᯅ ᯤ",
                  "૮₍ •́ ₃•̀₎ა", "ϲ( ´•ϲ̲̃ ̲̃•` )ɔ", "( っ •‌ᜊ•‌ )う", "ˣ‿ˣ", "(๑•́‧̫•̀๑)",
                  "⊙△⊙", "⊙﹏⊙", "ㅇࡇㅇ?", "૮˘･_･˘ა", "( ･̆ω･̆ )",
                  "₍ᐢ - ̫ - ᐢ₎", "( > ~ < )💦", "•́.•̀", "•̆₃•̑", "( ᖛ ̫ ᖛ )",
                  "( • ̀ω•́ )✧", "(๑•̆૩•̆)", "👉🏻(˚ ˃̣̣̥ ▵ ˂̣̣̥ )꒱👈🏻💧", "˙∧˙", "（≩∇≨）",
                  "❛‿˂̵✧", "(  > ᴗ • )", "( ͡~ ͜ʖ ͡°)", "(･ω<)☆", "˶ˊᜊˋ˶ಣ"]),
        ("최고", ["ദ്ദിᐢ. .ᐢ₎", "ദ്ദി（• ˕ •マ.ᐟ", "ദ്ദി •⤙• )", "( ദ്ദി ˙ᗜ˙ )",
                  "ჱ̒՞ ̳ᴗ ̫ ᴗ ̳՞꒱", "(՞ •̀֊•́՞)ฅ", "ჱ̒^. ̫ .^）", "ദ്ദി*ˊᗜˋ*)",
                  "( 　'-' )ノദ്ദി)`-' )", "ჱ̒⸝⸝•̀֊•́⸝⸝)", "ദ്ദി  ॑꒳ ॑c)", "ദ്ദിᐢ- ̫-ᐢ₎",
                  "ദ്ദി˙∇˙)ว", "ദ്ദി  ॑꒳ ॑c)", "ദ്ദി（• ˕ •マ.ᐟ", "ദി՞˶ෆ . ෆ˶ ՞",
                  "( ദ്ദി ˙ᗜ˙ )", "👍🏻ᖛ ̫ ᖛ )", "ദ്ദി¯•ω•¯ )", "ദ്ദി•̀.̫•́✧",
                  "ദ്ദി ˘ ͜ʖ ˘)", "ദ്ദി  ͡° ͜ʖ ͡°)", "ദ്ദി❁´◡`❁)",
                  "ദ്ദി * ॑꒳ ॑*)⸝⋆｡✧♡", "ദ്ദി ≽^⎚˕⎚^≼ .ᐟ"]),
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
    ]
    private var selectedEmoticonCat = 0

    // MARK: - Special Character Data

    private let specialCategories: [(String, [String])] = [
        ("하트",  ["♡", "♥", "❥", "❦", "❧", "☙", "▷♡◁", "♡̴", "ꕤ", "ʚ♡ɞ", "﹤𝟹",
                  "۵", "ლ", "ஐ", "༺♡༻", "(✿◡‿◡)", "♡̷",
                  "ꯁ", "ɞ", "ʚ", "εïз", "♡=͟͟͞͞ ³ ³", "»-♡→", "-\u{0060}♥´-", "-\u{0060}♡´-", "⸜♡⸝\u{200D}", "-ˋˏ ♡ ˎˊ-", "ʚ◡̈ɞ", "₊⁺♡̶₊⁺", "˚ෆ*₊"]),
        ("별/꽃", ["★", "☆", "✦", "✧", "✿", "❀", "✾", "❁", "✺", "❋", "✹", "✸",
                  "⁂", "✼", "✽", "❃", "❅", "❆", "⋆", "˚", "✶", "✵",
                  "⛤", "✰", "✮", "✪", "✳"]),
        ("화살표", ["→", "←", "↑", "↓", "➜", "⇒", "⟶", "⇄", "↔",
                  "↖", "↗", "↘", "↙", "⇐", "⇑", "⇓", "⇔", "⇕", "⇖", "⇗", "⇘", "⇙",
                  "↺", "↻", "⟰", "⟱", "⤴\u{FE0E}", "⤵\u{FE0E}", "↨", "⇅", "⇆",
                  "⇦", "⇧", "⇨", "⇩", "⌦", "⌫", "⇰", "⤶", "⤷", "➲", "⇣", "⇤", "⇥", "↰", "↱", "↲", "↳", "↶", "↷"
        ]),
        ("장식",  ["꩜", "⁂", "✳\u{FE0E}", "❊", "✦", "❈", "⁕", "꧁", "꧂", "࿇", "꒰", "꒱",
                  "⌘", "⌥", "⇧", "⌫", "☯\u{FE0E}", "☸\u{FE0E}", "♾\u{FE0E}", "⚜\u{FE0E}",
                  "✡\u{FE0E}", "☪\u{FE0E}",
                  "※", "✥", "✤", "✣", "❖", "ꔛ", "ꕀ", "｡", "･", "∘", "•", "‥", "…",
                  "⌒", "˘", "‿", "⌣", "╰╯", "╭╮", "﹏", "﹋", "﹌", "︵", "︶",
                  "〔", "〕", "【", "】", "《", "》", "〈", "〉", "「", "」", "『", "』"]),
        ("기호", ["©", "®", "™", "°", "%", "&", "@", "#", "$", "€", "£", "¥", "₩", "¢",
                "±", "×", "÷", "≠", "≈", "∞", "√", "π", "∑",
                "♩", "♪", "♫", "♬",
                "☎\u{FE0E}", "✉\u{FE0E}", "✂\u{FE0E}", "✏\u{FE0E}", "✒\u{FE0E}",
                "✄", "✎", "✓", "✔", "✆", "✉", "❛", "❜"]),
        ("도형", ["■", "□", "▪", "▫", "▲", "△", "▶", "▷", "▼", "▽", "◀", "◁",
                "●", "○", "◆", "◇", "◉", "◎", "▣", "▤", "▥", "▦", "▧", "▨",
                "⛶"]),
        ("상형문자", ["𓁹", "𓂡", "𓂢", "𓂩", "𓂽", "𓂾", "𓃀", "𓃒", "𓃔", "𓃗", "𓃙", "𓃟", "𓃡", "𓃩",
                   "𓃬", "𓃰", "𓃱", "𓃴", "𓃵", "𓃹", "𓃾", "𓄁", "𓄀", "𓄃", "𓄇", "𓅺", "𓅬", "𓆙",
                   "𓆟", "𓇼", "𓇽", "𓈉", "𓊍", "𓊎", "𓍳"]),
        ("패턴", ["░", "▒", "▓", "█", "▌", "▐", "▀", "▄", "┼", "╬", "═", "║",
                "╔", "╗", "╚", "╝", "┌", "┐", "└", "┘", "├", "┤", "┬", "┴"]),
        ("장식선", ["════════════════", "────────────────", "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄",
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
        ("으이구 인간아", " 으이구 인간아 ᕙ( ︡\'︡益\'︠)ง 으이구 인간아 ᕙ( ︡\'︡益\'︠)ง  으이구 인간아 ᕙ( ︡\'︡益\'︠)ง 으이구 인간아 ᕙ( ︡\'︡益\'︠)ง  으이구 인간아 ᕙ( ︡\'︡益\'︠)ง 으이구 인간아 ᕙ( ︡\'︡益\'︠)ง")
    ]

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
"""
        ])
    ]
    private var selectedDotArtCat = 0

    // MARK: - GIF State

    private let gifCategories: [(String, String?)] = [
        ("인기", nil),
        ("재미있는", "funny"),
        ("사랑", "love"),
        ("슬픔", "sad"),
        ("반응", "reaction"),
        ("화남", "angry"),
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
        ("🇰🇷 한국어", "Korean"), ("🇺🇸 영어", "English"), ("🇯🇵 일본어", "Japanese"),
        ("🇨🇳 중국어", "Chinese"), ("🇪🇸 스페인어", "Spanish"), ("🇫🇷 프랑스어", "French"),
        ("🇩🇪 독일어", "German"), ("🇻🇳 베트남어", "Vietnamese"), ("🇹🇭 태국어", "Thai"),
        ("🇮🇩 인니어", "Indonesian"),
    ]
    private weak var translateKeyboardContainer: UIStackView?
    private weak var translateNumToggleButton: UIButton?
    private weak var translateInputField: UITextView?
    private weak var translatePlaceholderLabel: UILabel?
    private weak var translateCloseButton: UIButton?
    private weak var translateCounterLabel: UILabel?
    private weak var translateResultLabel: UILabel?
    private var translationFieldView: UIView?

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
    private var sourceLangIndex = 0   // 🇰🇷 한국어
    private var targetLangIndex = 1   // 🇺🇸 영어
    private var isKoreanMode = true
    private var isTranslateShifted = false
    private var isTranslateCapsLock = false
    private var isTranslateNumberMode = false
    private var isTranslateSymbolPage2 = false
    private var lastShiftTime: Date?

    // ㅂㅈㄷㄱㅅ → ㅃㅉㄸㄲㅆ
    private let korShiftMap: [String: String] = ["ㅂ":"ㅃ", "ㅈ":"ㅉ", "ㄷ":"ㄸ", "ㄱ":"ㄲ", "ㅅ":"ㅆ"]

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
    // compound jongsung → (remaining jong, new chosung index)
    private let JSP: [Int: (Int, Int)] = [
        3:(1,9), 5:(4,12), 6:(4,18),
        9:(8,0), 10:(8,6), 11:(8,7), 12:(8,9), 13:(8,15), 14:(8,16), 15:(8,18),
        18:(17,9),
    ]

    // MARK: - Lifecycle

    private var isPremiumUser = false
    private var userTier = "free" // "free" | "premium" | "lifetime"
    private var canTranslateUnlimited = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // 프리미엄 체크 (App Group UserDefaults 통해 메인 앱에서 동기화)
        checkPremiumStatus()

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

        let kbHeight: CGFloat = (view.window?.windowScene?.screen ?? UIScreen.main).bounds.height < 700 ? 260 :
                                (view.window?.windowScene?.screen ?? UIScreen.main).bounds.height < 850 ? 307 : 320
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: kbHeight)
        heightConstraint.priority = UILayoutPriority(999)
        heightConstraint.isActive = true
    }

    /// Device-branched keyboard height — single source of truth used by
    /// viewDidLoad (view.heightAnchor) and by each build method (container height).
    private var kbHeight: CGFloat {
        (view.window?.windowScene?.screen ?? UIScreen.main).bounds.height < 700 ? 260 :
        (view.window?.windowScene?.screen ?? UIScreen.main).bounds.height < 850 ? 307 : 320
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
        for mode in Mode.allCases {
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
        currentMode = mode
        updateModeBar()
        clearContent()

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
                                       fullBottomBar: true)
        case .special:   buildGridMode(categories: specialCategories,
                                       selected: selectedSpecialCat,
                                       cols: 4, fontSize: 22,
                                       onCatChange: { [weak self] i in
                                           self?.selectedSpecialCat = i
                                           self?.showMode(.special)
                                       },
                                       scrollTag: 200)
        case .dotArt:    buildDotArtMode()
        case .gif:       buildGifMode()
        case .translate: buildTranslateMode()
        case .favorites: buildFavoritesMode()
        case .textTemplate: buildTextTemplateMode()
        case .calculator: buildCalculatorMode()
        }
    }

    private func clearContent() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        letterKeys.removeAll()
        translationFieldView?.removeFromSuperview()
        translationFieldView = nil
    }

    // MARK: - Mode Bar

    private func makeModeButton(_ mode: Mode) -> UIButton {
        let btn = UIButton(type: .system)
        if mode == .calculator {
            let config = UIImage.SymbolConfiguration(pointSize: mode.fontSize, weight: .semibold)
            btn.setImage(UIImage(systemName: "plus.minus.circle", withConfiguration: config), for: .normal)
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
        for case let btn as UIButton in modeBar.arrangedSubviews {
            let sel = btn.tag == currentMode.rawValue
            btn.backgroundColor = sel ? mainPink : .clear
            btn.setTitleColor(sel ? .white : .darkGray, for: .normal)
            if btn.tag == Mode.calculator.rawValue {
                btn.tintColor = sel ? .white : .darkGray
            }
        }
    }

    @objc private func modeTapped(_ s: UIButton) {
        showMode(Mode(rawValue: s.tag) ?? .fonts)
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

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        pinToEdges(stack, in: contentView)

        // ── Font picker: single-row collapsed / expanded (+ toggle) ──
        let visibleCats = visibleFontCategories()
        let safeCatIndex = min(fontCatIndex, max(visibleCats.count - 1, 0))

        // Category row — always created; toggle animates isHidden/alpha only.
        // FontScrollView lets drags on category buttons cancel into scroll.
        let catScroll = FontScrollView()
        catScroll.showsHorizontalScrollIndicator = false
        catScroll.delaysContentTouches = false
        catScroll.canCancelContentTouches = true
        catScroll.setHeight(36)
        let catRow = UIStackView()
        catRow.axis = .horizontal; catRow.spacing = 8
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
            btn.backgroundColor = sel ? mainPink : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? .white : .darkGray, for: .normal)
            btn.isExclusiveTouch = false
            btn.addTarget(self, action: #selector(fontCatTapped(_:)), for: .touchUpInside)
            catRow.addArrangedSubview(btn)
        }
        catScroll.isHidden = !fontPickerExpanded
        catScroll.alpha = fontPickerExpanded ? 1 : 0
        stack.addArrangedSubview(catScroll)
        fontCategoryRowView = catScroll

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
            let btn = UIButton(type: .system)
            btn.setTitle(displayFontName(style), for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            btn.titleLabel?.adjustsFontSizeToFitWidth = true
            btn.titleLabel?.minimumScaleFactor = 0.6
            btn.tag = i
            btn.layer.cornerRadius = 16
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            let sel = i == fontStyleIndex
            btn.backgroundColor = sel ? mainPink : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? .white : .darkGray, for: .normal)
            if isFavoriteFont(style.name) {
                btn.layer.borderWidth = 1.5
                btn.layer.borderColor = mainPink.cgColor
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

        // Restore scroll offset after layout
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let sv = self.fontStyleScrollView else { return }
            sv.setContentOffset(self.savedFontScrollOffset, animated: false)
        }

        if isNumberMode {
            // Number/symbol rows — row 3 has [page toggle] + [5 char keys] + [⌫]
            // mirroring the iOS native symbols keyboard layout.
            let pageRows = isSymbolPage2 ? numberRowsPage2 : numberRowsPage1
            for (ri, row) in pageRows.enumerated() {
                let rowStack = UIStackView()
                rowStack.axis = .horizontal
                rowStack.distribution = .fillEqually
                rowStack.spacing = 4
                rowStack.heightAnchor.constraint(equalToConstant: 52).isActive = true

                if ri == 2 {
                    let pageToggle = makeSpecialKey(isSymbolPage2 ? "123" : "#+=")
                    pageToggle.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
                    pageToggle.addTarget(self, action: #selector(toggleSymbolPage), for: .touchUpInside)
                    rowStack.addArrangedSubview(pageToggle)
                }

                for key in row {
                    let btn = makeLetterKey(key)
                    btn.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
                    rowStack.addArrangedSubview(btn)
                    letterKeys.append(btn)
                }

                if ri == 2 {
                    let del = makeSpecialKey("⌫")
                    del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
                    attachBackspaceLongPress(to: del)
                    rowStack.addArrangedSubview(del)
                }

                stack.addArrangedSubview(rowStack)
            }
        } else {
            // QWERTY rows — flexible height.
            for (ri, row) in qwertyRows.enumerated() {
                let rowStack = UIStackView()
                rowStack.axis = .horizontal
                rowStack.distribution = .fillEqually
                rowStack.spacing = 4
                rowStack.heightAnchor.constraint(equalToConstant: 52).isActive = true

                if ri == 2 {
                    let shift = makeSpecialKey("⇧")
                    shift.addTarget(self, action: #selector(shiftTapped), for: .touchUpInside)
                    if isCapsLock {
                        shift.backgroundColor = mainPink
                        shift.setTitle("", for: .normal)
                        let capsConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
                        shift.setImage(UIImage(systemName: "capslock.fill", withConfiguration: capsConfig), for: .normal)
                        shift.tintColor = .white
                    } else if isShifted {
                        shift.backgroundColor = mainPink
                        shift.setTitleColor(.white, for: .normal)
                    }
                    rowStack.addArrangedSubview(shift)
                }

                for key in row {
                    let label = isShifted ? key.uppercased() : key
                    let btn = makeLetterKey(label)
                    btn.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
                    rowStack.addArrangedSubview(btn)
                    letterKeys.append(btn)
                }

                if ri == 2 {
                    let del = makeSpecialKey("⌫")
                    del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
                    attachBackspaceLongPress(to: del)
                    rowStack.addArrangedSubview(del)
                }
                stack.addArrangedSubview(rowStack)
            }
        }

        // Bottom row: 123/ABC + space + 완료
        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = 4
        bottom.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let toggleKey = makeSpecialKey(isNumberMode ? "ABC" : "123")
        toggleKey.addTarget(self, action: #selector(toggleNumberMode), for: .touchUpInside)
        toggleKey.setWidth(44)
        bottom.addArrangedSubview(toggleKey)

        let space = makeLetterKey("space")
        space.titleLabel?.font = .systemFont(ofSize: 14)
        space.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)
        bottom.addArrangedSubview(space)

        let done = makeSpecialKey("완료")
        done.backgroundColor = mainPink
        done.setTitleColor(.white, for: .normal)
        done.addTarget(self, action: #selector(returnTapped), for: .touchUpInside)
        done.setWidth(50)
        bottom.addArrangedSubview(done)

        stack.addArrangedSubview(bottom)
    }

    // MARK: - Grid Mode (Emoticon / Special)

    private func buildGridMode(categories: [(String, [String])],
                               selected: Int, cols: Int, fontSize: CGFloat,
                               onCatChange: @escaping (Int) -> Void,
                               scrollTag: Int = 0,
                               fullBottomBar: Bool = false) {
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
            btn.backgroundColor = sel ? mainPink : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? .white : .darkGray, for: .normal)
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

        // Bottom bar — emoticon tab gets the full [ABC][space][⌫] bar (52pt);
        // other grids (special chars) keep the compact backspace-only bar (36pt).
        let bottomBar = UIStackView()
        bottomBar.axis = .horizontal
        bottomBar.spacing = 4
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomBar)

        let bottomBarHeight: CGFloat
        if fullBottomBar {
            bottomBarHeight = 52

            let abcBtn = makeSpecialKey("ABC")
            abcBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            abcBtn.setWidth(48)
            abcBtn.addAction(UIAction { [weak self] _ in
                UIDevice.current.playInputClick()
                self?.advanceToNextInputMode()
            }, for: .touchUpInside)
            bottomBar.addArrangedSubview(abcBtn)

            let spaceBtn = makeLetterKey("space")
            spaceBtn.titleLabel?.font = .systemFont(ofSize: 14)
            spaceBtn.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)
            bottomBar.addArrangedSubview(spaceBtn)

            let del = makeSpecialKey("⌫")
            del.setWidth(48)
            del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
            attachBackspaceLongPress(to: del)
            bottomBar.addArrangedSubview(del)
        } else {
            bottomBarHeight = 36

            let del = makeSpecialKey("⌫")
            del.setWidth(44)
            del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
            attachBackspaceLongPress(to: del)

            bottomBar.addArrangedSubview(UIView()) // spacer
            bottomBar.addArrangedSubview(del)
        }

        // Grid scroll view — pinned between catScroll and bottomBar
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
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -4),

            bottomBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: bottomBarHeight),
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

        for row in chunked {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 5
            if isBigEmoticon {
                rowStack.isLayoutMarginsRelativeArrangement = true
                rowStack.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            }
            for item in row {
                let btn = UIButton(type: .system)
                btn.setTitle(item, for: .normal)
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
                btn.setTitleColor(.darkGray, for: .normal)
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

        // Bottom bar: ABC / space / ⌫ — matches emoticon tab pattern.
        let bottomBar = UIStackView()
        bottomBar.axis = .horizontal
        bottomBar.spacing = 4
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomBar)

        let abcBtn = makeSpecialKey("ABC")
        abcBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        abcBtn.setWidth(48)
        abcBtn.addAction(UIAction { [weak self] _ in
            UIDevice.current.playInputClick()
            self?.advanceToNextInputMode()
        }, for: .touchUpInside)
        bottomBar.addArrangedSubview(abcBtn)

        let spaceBtn = makeLetterKey("space")
        spaceBtn.titleLabel?.font = .systemFont(ofSize: 14)
        spaceBtn.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)
        bottomBar.addArrangedSubview(spaceBtn)

        let del = makeSpecialKey("⌫")
        del.setWidth(48)
        del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
        attachBackspaceLongPress(to: del)
        bottomBar.addArrangedSubview(del)

        // Vertical scroll view above bottom bar.
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -4),

            bottomBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 52),
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

                let cardPadding: CGFloat = 8
                let labelFont = UIFont(name: "Menlo", size: 4) ?? UIFont.monospacedSystemFont(ofSize: 4, weight: .regular)
                let label = UILabel()
                label.text = text
                label.font = labelFont
                label.textColor = .black
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
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        pinToEdges(container, in: contentView)

        // Bottom bar: 🌐 / spacer / ⌫
        let bottomBar = UIStackView()
        bottomBar.axis = .horizontal
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomBar)

        let globe = makeSpecialKey("🌐")
        globe.setWidth(44)
        globe.addAction(UIAction { [weak self] _ in
            UIDevice.current.playInputClick()
            self?.advanceToNextInputMode()
        }, for: .touchUpInside)
        let del = makeSpecialKey("⌫")
        del.setWidth(44)
        del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
        bottomBar.addArrangedSubview(globe)
        bottomBar.addArrangedSubview(UIView())
        bottomBar.addArrangedSubview(del)

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -4),

            bottomBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 34),
        ])

        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 6
        vStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(vStack)

        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 6),
            vStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 8),
            vStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -8),
            vStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -6),
            vStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -16),
        ])

        for (index, item) in textTemplates.enumerated() {
            let btn = UIButton(type: .system)
            btn.tag = index
            btn.setTitle(item.preview, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 14)
            btn.titleLabel?.lineBreakMode = .byTruncatingTail
            btn.titleLabel?.adjustsFontSizeToFitWidth = true
            btn.titleLabel?.minimumScaleFactor = 0.7
            btn.contentHorizontalAlignment = .left
            btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            btn.backgroundColor = .white
            btn.setTitleColor(.darkGray, for: .normal)
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth = 0.5
            btn.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
            btn.setHeight(40)
            btn.addTarget(self, action: #selector(textTemplateTapped(_:)), for: .touchUpInside)
            vStack.addArrangedSubview(btn)
        }
    }

    @objc private func textTemplateTapped(_ s: UIButton) {
        let idx = s.tag
        guard idx >= 0 && idx < textTemplates.count else { return }
        textDocumentProxy.insertText(textTemplates[idx].full)
        UIView.animate(withDuration: 0.06, animations: {
            s.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            s.backgroundColor = mainPink.withAlphaComponent(0.15)
        }) { _ in
            UIView.animate(withDuration: 0.06) {
                s.transform = .identity
                s.backgroundColor = .white
            }
        }
    }

    // MARK: - Calculator Mode

    private enum CalcKind { case digit, op, function, empty }

    /// Calculator button with auto-rounding corner radius (= bounds.height / 2),
    /// producing a pill/circle shape matching the native iOS calculator.
    private final class CalcButton: UIButton {
        override func layoutSubviews() {
            super.layoutSubviews()
            layer.cornerRadius = bounds.height / 2
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
        let displayBtn = UIButton(type: .system)
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
            [("AC", .function), ("+/-", .function), ("%", .function), ("÷", .op)],
            [("7", .digit),     ("8", .digit),      ("9", .digit),    ("×", .op)],
            [("4", .digit),     ("5", .digit),      ("6", .digit),    ("−", .op)],
            [("1", .digit),     ("2", .digit),      ("3", .digit),    ("+", .op)],
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

        // Row 5: 0 (double width) + . + =
        let row5 = UIStackView()
        row5.axis = .horizontal
        row5.spacing = 4
        row5.distribution = .fill
        let zeroBtn = makeCalcButton(title: "0", kind: .digit)
        let dotBtn = makeCalcButton(title: ".", kind: .digit)
        let eqBtn = makeCalcButton(title: "=", kind: .op)
        row5.addArrangedSubview(zeroBtn)
        row5.addArrangedSubview(dotBtn)
        row5.addArrangedSubview(eqBtn)
        dotBtn.widthAnchor.constraint(equalTo: eqBtn.widthAnchor).isActive = true
        zeroBtn.widthAnchor.constraint(equalTo: dotBtn.widthAnchor, multiplier: 2, constant: 4).isActive = true
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
        let btn = CalcButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 22, weight: .medium)
        btn.setTitleColor(.white, for: .normal)
        switch kind {
        case .digit:
            btn.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)      // #333333
            btn.addTarget(self, action: #selector(calcKeyTapped(_:)), for: .touchUpInside)
        case .op:
            btn.backgroundColor = UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1)    // #FF9500
            btn.addTarget(self, action: #selector(calcKeyTapped(_:)), for: .touchUpInside)
        case .function:
            btn.backgroundColor = UIColor(red: 0.647, green: 0.647, blue: 0.647, alpha: 1) // #A5A5A5
            btn.addTarget(self, action: #selector(calcKeyTapped(_:)), for: .touchUpInside)
        case .empty:
            btn.backgroundColor = .clear
            btn.isEnabled = false
        }
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
        case "+/-":
            if let d = Double(calcDisplay) { calcDisplay = formatCalcValue(-d) }
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
        UIDevice.current.playInputClick()
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
        UIDevice.current.playInputClick()
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
        UIDevice.current.playInputClick()
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
            btn.backgroundColor = sel ? mainPink : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? .white : .darkGray, for: .normal)
            btn.tag = i
            btn.addTarget(self, action: #selector(gifCategoryTapped(_:)), for: .touchUpInside)
            catRow.addArrangedSubview(btn)
        }

        // Bottom bar
        let bottomBar = UIStackView()
        bottomBar.axis = .horizontal
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomBar)
        let del = makeSpecialKey("⌫")
        del.setWidth(44)
        del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
        attachBackspaceLongPress(to: del)
        bottomBar.addArrangedSubview(UIView())
        bottomBar.addArrangedSubview(del)

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
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -4),

            bottomBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 36),

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

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
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
                    if gifs.isEmpty { self.gifLoadingLabel?.text = "결과 없음" }
                    self.renderGifGrid()
                }
            }
        }.resume()
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

        showToast("GIF 다운로드 중...")
        URLSession.shared.dataTask(with: gif.originalURL) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                guard let data = data else {
                    self?.showToast("다운로드 실패")
                    return
                }
                UIPasteboard.general.setData(data, forPasteboardType: "com.compuserve.gif")
                self?.showToast("GIF가 복사되었습니다")
            }
        }.resume()
    }

    // MARK: - Translate Mode

    private func buildTranslateMode() {
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
        srcBtn.setTitleColor(.darkGray, for: .normal)
        srcBtn.addTarget(self, action: #selector(translateSourceDropdown), for: .touchUpInside)
        topBar.addArrangedSubview(srcBtn)

        let arrowLabel = UILabel()
        arrowLabel.text = "→"
        arrowLabel.font = .systemFont(ofSize: 14, weight: .bold)
        arrowLabel.textColor = mainPink
        arrowLabel.textAlignment = .center
        arrowLabel.setWidth(20)
        topBar.addArrangedSubview(arrowLabel)

        let tgtBtn = UIButton(type: .system)
        tgtBtn.setTitle(translateLangs[targetLangIndex].0 + " ▼", for: .normal)
        tgtBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        tgtBtn.setTitleColor(mainPink, for: .normal)
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
        inputField.tintColor = mainPink
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
        placeholderLabel.text = "타이핑..."
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
        closeBtn.tintColor = mainPink
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

        // ── Result box ──
        let resultBox = UIView()
        resultBox.backgroundColor = UIColor(white: 0.95, alpha: 1)
        resultBox.layer.cornerRadius = 8

        let resultLabel = UILabel()
        resultLabel.text = "번역 결과가 여기에 표시됩니다"
        resultLabel.textColor = .lightGray
        resultLabel.font = .systemFont(ofSize: 12); resultLabel.numberOfLines = 0
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultBox.addSubview(resultLabel)
        translateResultLabel = resultLabel

        NSLayoutConstraint.activate([
            resultLabel.topAnchor.constraint(equalTo: resultBox.topAnchor, constant: 4),
            resultLabel.leadingAnchor.constraint(equalTo: resultBox.leadingAnchor, constant: 6),
            resultLabel.trailingAnchor.constraint(equalTo: resultBox.trailingAnchor, constant: -6),
            resultLabel.bottomAnchor.constraint(equalTo: resultBox.bottomAnchor, constant: -4),
        ])

        // Text areas row — compact fixed height (keypad 우선)
        let textRow = UIStackView()
        textRow.axis = .horizontal; textRow.spacing = 3; textRow.distribution = .fillEqually
        textRow.addArrangedSubview(inputBox)
        textRow.addArrangedSubview(resultBox)
        textRow.translatesAutoresizingMaskIntoConstraints = false
        textRow.heightAnchor.constraint(equalToConstant: 110).isActive = true
        fieldView.addArrangedSubview(textRow)

        // Insert fieldView above modeBar in mainStack (translation tab only)
        mainStack.insertArrangedSubview(fieldView, at: 0)
        translationFieldView = fieldView
        fieldView.heightAnchor.constraint(equalToConstant: 140).isActive = true

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

        // ── Bottom bar ── (크게: 52pt)
        let bottom = UIStackView()
        bottom.axis = .horizontal; bottom.spacing = 4
        bottom.translatesAutoresizingMaskIntoConstraints = false
        bottom.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let langToggle = makeSpecialKey("한/영")
        langToggle.backgroundColor = isKoreanMode ? UIColor.systemBlue.withAlphaComponent(0.15) : UIColor(white: 0.88, alpha: 1)
        langToggle.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        langToggle.setWidth(48)
        langToggle.addTarget(self, action: #selector(translateToggleKorEng), for: .touchUpInside)
        bottom.addArrangedSubview(langToggle)

        let numToggle = makeSpecialKey(isTranslateNumberMode ? "ABC" : "!?123")
        numToggle.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        numToggle.setWidth(50)
        numToggle.addTarget(self, action: #selector(translateToggleNumberMode), for: .touchUpInside)
        translateNumToggleButton = numToggle
        bottom.addArrangedSubview(numToggle)

        let space = makeLetterKey("space")
        space.titleLabel?.font = .systemFont(ofSize: 14)
        space.addTarget(self, action: #selector(translateSpaceTapped), for: .touchUpInside)
        bottom.addArrangedSubview(space)

        let trBtn = makeSpecialKey("번역")
        trBtn.backgroundColor = UIColor(white: 0.88, alpha: 1)
        trBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        trBtn.setWidth(48)
        trBtn.addTarget(self, action: #selector(translateTriggered), for: .touchUpInside)
        bottom.addArrangedSubview(trBtn)

        let insBtn = makeSpecialKey("삽입")
        insBtn.backgroundColor = mainPink; insBtn.setTitleColor(.white, for: .normal)
        insBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        insBtn.setWidth(48)
        insBtn.addTarget(self, action: #selector(translateInsertTapped), for: .touchUpInside)
        bottom.addArrangedSubview(insBtn)

        stack.addArrangedSubview(bottom)
        updateTranslateInputDisplay()
    }

    private func buildTranslateKeyboardRows(into stack: UIStackView) {
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
                    if shifted { shift.backgroundColor = mainPink; shift.setTitleColor(.white, for: .normal) }
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
            btn.backgroundColor = sel ? mainPink : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? .white : .darkGray, for: .normal)
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
        inputField.tintColor = mainPink
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
        pasteBtn.setTitleColor(mainPink, for: .normal)
        pasteBtn.addTarget(self, action: #selector(translatePasteTapped), for: .touchUpInside)
        actionRow.addArrangedSubview(pasteBtn)

        let directBtn = UIButton(type: .system)
        directBtn.setTitle("✏️ 직접입력", for: .normal)
        directBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        directBtn.setTitleColor(.systemBlue, for: .normal)
        directBtn.addTarget(self, action: #selector(translateToggleDirectInput), for: .touchUpInside)
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

        // Result box
        let resultBox = UIView()
        resultBox.backgroundColor = UIColor(white: 0.95, alpha: 1)
        resultBox.layer.cornerRadius = 10
        resultBox.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(resultBox)

        let resultLabel = UILabel()
        resultLabel.text = "번역 결과가 여기에 표시됩니다"
        resultLabel.textColor = .lightGray
        resultLabel.font = .systemFont(ofSize: 13)
        resultLabel.numberOfLines = 0
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultBox.addSubview(resultLabel)
        translateResultLabel = resultLabel

        NSLayoutConstraint.activate([
            resultLabel.topAnchor.constraint(equalTo: resultBox.topAnchor, constant: 8),
            resultLabel.leadingAnchor.constraint(equalTo: resultBox.leadingAnchor, constant: 10),
            resultLabel.trailingAnchor.constraint(equalTo: resultBox.trailingAnchor, constant: -10),
            resultLabel.bottomAnchor.constraint(equalTo: resultBox.bottomAnchor, constant: -8),
        ])

        // Bottom bar
        let bottomBar = UIStackView()
        bottomBar.axis = .horizontal; bottomBar.spacing = 6
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomBar)

        let translateBtn = makeSpecialKey("번역")
        translateBtn.backgroundColor = UIColor(white: 0.88, alpha: 1)
        translateBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        translateBtn.addTarget(self, action: #selector(translateTriggered), for: .touchUpInside)
        bottomBar.addArrangedSubview(translateBtn)

        let insertBtn = makeSpecialKey("번역 삽입")
        insertBtn.backgroundColor = mainPink
        insertBtn.setTitleColor(.white, for: .normal)
        insertBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        insertBtn.addTarget(self, action: #selector(translateInsertTapped), for: .touchUpInside)
        bottomBar.addArrangedSubview(insertBtn)

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

            resultBox.topAnchor.constraint(equalTo: inputBox.bottomAnchor, constant: 4),
            resultBox.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            resultBox.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            resultBox.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -4),
            resultBox.heightAnchor.constraint(equalTo: inputBox.heightAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            bottomBar.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            bottomBar.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            bottomBar.heightAnchor.constraint(equalToConstant: 36),
        ])

        updateTranslateInputDisplay()
    }

    // ── Direct Input Mode (QWERTY / Hangul) ────────────────────────────
    private func buildTranslateDirectMode() {
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
            btn.backgroundColor = sel ? mainPink : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? .white : .darkGray, for: .normal)
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
        pasteBtn.setTitleColor(mainPink, for: .normal)
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
        inputField.tintColor = mainPink
        inputField.returnKeyType = .done
        inputField.delegate = self
        inputField.layer.cornerRadius = 6; inputField.layer.masksToBounds = true
        translateInputField = inputField

        let resultLabel = UILabel()
        resultLabel.text = "번역 결과"
        resultLabel.textColor = .lightGray
        resultLabel.font = .systemFont(ofSize: 11); resultLabel.numberOfLines = 0
        resultLabel.backgroundColor = UIColor(white: 0.95, alpha: 1)
        resultLabel.layer.cornerRadius = 6; resultLabel.layer.masksToBounds = true
        translateResultLabel = resultLabel

        displayRow.addArrangedSubview(inputField)
        displayRow.addArrangedSubview(resultLabel)
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
                        shift.backgroundColor = mainPink
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

        let langToggle = makeSpecialKey("한/영")
        langToggle.backgroundColor = isKoreanMode ? UIColor.systemBlue.withAlphaComponent(0.15) : UIColor(white: 0.88, alpha: 1)
        langToggle.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        langToggle.setWidth(40)
        langToggle.addTarget(self, action: #selector(translateToggleKorEng), for: .touchUpInside)
        bottom.addArrangedSubview(langToggle)

        let numToggle = makeSpecialKey(isTranslateNumberMode ? "ABC" : "!?123")
        numToggle.titleLabel?.font = .systemFont(ofSize: 10, weight: .semibold)
        numToggle.setWidth(42)
        numToggle.addTarget(self, action: #selector(translateToggleNumberMode), for: .touchUpInside)
        bottom.addArrangedSubview(numToggle)

        let space = makeLetterKey("space")
        space.titleLabel?.font = .systemFont(ofSize: 12)
        space.addTarget(self, action: #selector(translateSpaceTapped), for: .touchUpInside)
        bottom.addArrangedSubview(space)

        let trBtn = makeSpecialKey("번역")
        trBtn.backgroundColor = UIColor(white: 0.88, alpha: 1)
        trBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        trBtn.setWidth(40)
        trBtn.addTarget(self, action: #selector(translateTriggered), for: .touchUpInside)
        bottom.addArrangedSubview(trBtn)

        let insBtn = makeSpecialKey("삽입")
        insBtn.backgroundColor = mainPink; insBtn.setTitleColor(.white, for: .normal)
        insBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        insBtn.setWidth(40)
        insBtn.addTarget(self, action: #selector(translateInsertTapped), for: .touchUpInside)
        bottom.addArrangedSubview(insBtn)

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
            let btn = makePopupButton(title: lang.0, color: i == sourceLangIndex ? mainPink : .darkGray) {
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
            let btn = makePopupButton(title: lang.0, color: i == targetLangIndex ? mainPink : .darkGray) {
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
            showToast("클립보드가 비어있어요")
            return
        }
        translationInput = text
        updateTranslateInputDisplay()
        showToast("붙여넣기 완료")
    }

    @objc private func translatePasteAndTranslate() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else {
            showToast("클립보드가 비어있어요")
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
        translateResultLabel?.text = "번역 결과가 여기에 표시됩니다"
        translateResultLabel?.textColor = .lightGray
        updateTranslateInputDisplay()
    }

    @objc private func dismissTranslateKeyboard() {
        translateInputField?.resignFirstResponder()
        hgFlush()
    }

    /// Rebuild only the keyboard rows (fast path).
    /// Falls back to a full `showMode` if the container is gone.
    private func rebuildTranslateKeys() {
        guard let container = translateKeyboardContainer else {
            showMode(.translate)
            return
        }

        UIView.performWithoutAnimation {
            container.arrangedSubviews.forEach { $0.removeFromSuperview() }
            buildTranslateKeyboardRows(into: container)
        }
    }

    @objc private func translateToggleKorEng() {
        hgFlush()
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
            isTranslateNumberMode ? "ABC" : "!?123", for: .normal)
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
        UIDevice.current.playInputClick()
        if isKoreanMode && !isTranslateNumberMode {
            handleHangulInput(key)
            // Auto-release one-shot shift → defer rebuild to next runloop for smoother typing
            if isTranslateShifted && !isTranslateCapsLock {
                isTranslateShifted = false
                DispatchQueue.main.async { [weak self] in
                    self?.rebuildTranslateKeys()
                }
            }
        } else {
            hgFlush()
            translateTargetAppend(key)
        }
    }

    @objc private func translateSpaceTapped() {
        UIDevice.current.playInputClick()
        hgFlush()
        translateTargetAppend(" ")
    }

    @objc private func translateDeleteTapped() {
        performTranslateDelete()
        UIDevice.current.playInputClick()
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


    private func hgReplaceLast(_ s: String) {
        translateTargetRemoveLast()
        translateTargetAppend(s)
    }

    private func handleHangulInput(_ key: String) {
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
        guard !translationInput.isEmpty else { return }
        UIDevice.current.playInputClick()

        // Full Access check — keyboard extensions cannot make network
        // requests without Full Access in Settings.
        if !hasFullAccess {
            showTranslateError("'전체 접근 허용'이 꺼져 있어요\n설정 → 일반 → 키보드 → 키보드 → Fonki Keyboard\n→ 전체 접근 허용 ON")
            print("[Translate] hasFullAccess = false — aborting network request")
            return
        }

        // Refresh tier from App Group (main app may have updated it)
        checkPremiumStatus()

        #if !DEBUG
        // Lifetime: translation not included in lifetime plan
        if userTier == "lifetime" {
            showTranslateError("번역은 주/연간 구독에서만 가능합니다")
            return
        }

        // Free: subscription required (no free translations)
        if !canTranslateUnlimited {
            showTranslateError("번역은 구독자 전용이에요\nFonki 앱에서 프리미엄 구독 후 이용해주세요 ✨")
            return
        }
        #endif

        // Premium (weekly/yearly) — unlimited translation
        // DEBUG: all checks above are bypassed for development/testing
        translateResultLabel?.text = "번역 중..."
        translateResultLabel?.textColor = .darkGray

        // ── Debug log: key prefix + source/target ──
        let keyPrefix = String(openAIKey.prefix(10))
        print("[Translate] Starting request. keyPrefix=\(keyPrefix)... len=\(openAIKey.count), src=\(translateLangs[sourceLangIndex].1), tgt=\(translateLangs[targetLangIndex].1), inputLen=\(translationInput.count)")

        let srcLang = translateLangs[sourceLangIndex].1
        let tgtLang = translateLangs[targetLangIndex].1
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a professional translator. Your goal is to translate the given text naturally and accurately while preserving the speaker's original tone, nuance, and intent.\n\nGuidelines:\n- Translate naturally as a native speaker would say it, not word-for-word\n- Preserve the original tone: casual/formal, emotional intensity, humor, sarcasm\n- Keep slang, abbreviations, and internet expressions in a culturally equivalent form\n- If the text contains emojis or emoticons, keep them as-is\n- Do not add explanations or notes — output only the translated text\n- If the source and target language are the same, return the text as-is\n\nTranslate from \(srcLang) to \(tgtLang)."],
                ["role": "user", "content": translationInput],
            ],
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

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let bodyText = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                print("[Translate] HTTP \(statusCode)  error=\(error?.localizedDescription ?? "nil")")
                print("[Translate] Response body (first 500 chars):\n\(bodyText.prefix(500))")

                // 1) Network transport error (offline, timeout, DNS 등)
                if let error = error {
                    let ns = error as NSError
                    print("[Translate] NSError domain=\(ns.domain) code=\(ns.code) userInfo=\(ns.userInfo)")
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
                self.lastTranslation = translated.trimmingCharacters(in: .whitespacesAndNewlines)
                self.translateResultLabel?.text = self.lastTranslation
                self.translateResultLabel?.textColor = .darkText
            }
        }.resume()
    }

    private func showTranslateError(_ message: String) {
        translateResultLabel?.text = message
        translateResultLabel?.textColor = .systemRed
        translateResultLabel?.numberOfLines = 0
    }

    @objc private func translateInsertTapped() {
        guard !lastTranslation.isEmpty else {
            showToast("먼저 번역해주세요")
            return
        }
        textDocumentProxy.insertText(lastTranslation)
        UIDevice.current.playInputClick()
        showToast("삽입됨")
    }

    private func todayString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    // MARK: - Favorites Mode (♥)

    private func buildFavoritesMode() {
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let emoFavs    = loadFavList(Self.favKeyEmoticon)
        let dotArtFavs = loadFavList(Self.favKeyDotArt)
        let gifFavs    = loadFavList(Self.favKeyGif)
        // Font favorites — resolve names saved under "favoriteFonts" to their
        // FontStyleDef entries; silently drop any name that no longer exists.
        let fontFavDefs: [FontStyleDef] = {
            let names = loadFavoriteFontNames()
            guard !names.isEmpty else { return [] }
            var byName: [String: FontStyleDef] = [:]
            for (_, styles) in allFontCategories {
                for s in styles where byName[s.name] == nil { byName[s.name] = s }
            }
            return names.compactMap { byName[$0] }
        }()
        let allEmpty   = emoFavs.isEmpty && dotArtFavs.isEmpty && gifFavs.isEmpty && fontFavDefs.isEmpty

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
            btn.backgroundColor = sel ? mainPink : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? .white : .darkGray, for: .normal)
            btn.tag = i
            btn.addTarget(self, action: #selector(favCategoryTapped(_:)), for: .touchUpInside)
            catRow.addArrangedSubview(btn)
        }

        // Bottom bar
        let bottomBar = UIStackView()
        bottomBar.axis = .horizontal
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomBar)
        let del = makeSpecialKey("⌫")
        del.setWidth(44)
        del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
        attachBackspaceLongPress(to: del)
        bottomBar.addArrangedSubview(UIView())
        bottomBar.addArrangedSubview(del)

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
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -4),

            bottomBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 36),
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

        // Determine what to show
        let showFont   = favCategoryIndex == 0 || favCategoryIndex == 1
        let showEmo    = favCategoryIndex == 0 || favCategoryIndex == 2 || favCategoryIndex == 3
        let showDotArt = favCategoryIndex == 0 || favCategoryIndex == 4
        let showGif    = favCategoryIndex == 0 || favCategoryIndex == 5
        let filteredEmo = showEmo ? emoFavs : []
        let filteredDA  = showDotArt ? dotArtFavs : []
        let filteredGif = showGif ? gifFavs : []
        let filteredFont = showFont ? fontFavDefs : []

        let totalEmpty = filteredEmo.isEmpty && filteredDA.isEmpty && filteredGif.isEmpty && filteredFont.isEmpty

        if totalEmpty {
            let emptyLabel = UILabel()
            let fontOnly = favCategoryIndex == 1
            emptyLabel.text = fontOnly
                ? "폰트를 꾹 눌러서 즐겨찾기에 추가하세요"
                : (allEmpty
                    ? "이모티콘이나 특수문자를 꾹 누르면\n즐겨찾기에 추가돼요 ♥"
                    : "이 카테고리에 즐겨찾기가 없어요")
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

        // Font favorite rows — 2 cols, styled name serves as visual sample.
        if !filteredFont.isEmpty {
            let cols = 2
            let chunked = stride(from: 0, to: filteredFont.count, by: cols).map {
                Array(filteredFont[$0..<min($0 + cols, filteredFont.count)])
            }
            for row in chunked {
                let rowStack = UIStackView()
                rowStack.axis = .horizontal
                rowStack.distribution = .fillEqually
                rowStack.spacing = 5
                for style in row {
                    let btn = UIButton(type: .system)
                    btn.setTitle(displayFontName(style), for: .normal)
                    btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
                    btn.titleLabel?.adjustsFontSizeToFitWidth = true
                    btn.titleLabel?.minimumScaleFactor = 0.5
                    btn.backgroundColor = .white
                    btn.layer.cornerRadius = 10
                    btn.layer.borderWidth = 1
                    btn.layer.borderColor = mainPink.cgColor
                    btn.setTitleColor(.darkGray, for: .normal)
                    btn.setHeight(44)
                    btn.accessibilityIdentifier = style.name
                    btn.addTarget(self, action: #selector(favFontTapped(_:)), for: .touchUpInside)
                    let lp = UILongPressGestureRecognizer(target: self, action: #selector(favFontLongPressed(_:)))
                    lp.minimumPressDuration = 0.5
                    btn.addGestureRecognizer(lp)
                    rowStack.addArrangedSubview(btn)
                }
                for _ in 0..<(cols - row.count) { rowStack.addArrangedSubview(UIView()) }
                gridStack.addArrangedSubview(rowStack)
            }
        }
    }

    @objc private func favFontTapped(_ sender: UIButton) {
        guard let name = sender.accessibilityIdentifier else { return }
        let cats = visibleFontCategories()
        for (ci, cat) in cats.enumerated() {
            if let si = cat.1.firstIndex(where: { $0.name == name }) {
                fontCatIndex = ci
                fontStyleIndex = si
                savedFontScrollOffset = .zero
                showMode(.fonts)
                return
            }
        }
    }

    @objc private func favFontLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let btn = gesture.view as? UIButton,
              let name = btn.accessibilityIdentifier else { return }
        var favs = loadFavoriteFontNames()
        favs.removeAll { $0 == name }
        saveFavoriteFontNames(favs)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showToast("즐겨찾기 제거됨")
        showMode(.favorites)
    }

    // MARK: - Key Actions

    @objc private func letterTapped(_ s: UIButton) {
        guard var ch = s.title(for: .normal) else { return }
        if isShifted { ch = ch.uppercased() }
        let cats = visibleFontCategories()
        let safeCat = min(fontCatIndex, max(cats.count - 1, 0))
        let styles = cats.isEmpty ? [] : cats[safeCat].1
        guard !styles.isEmpty else { return }
        let safeStyle = min(fontStyleIndex, styles.count - 1)
        let style = styles[safeStyle]
        let converted = style.convert(ch)
        textDocumentProxy.insertText(converted)
        UIDevice.current.playInputClick()
        tapFeedback(s)
        if isShifted && !isCapsLock {
            isShifted = false
            DispatchQueue.main.async { [weak self] in
                self?.showMode(.fonts)
            }
        }
    }

    @objc private func spaceTapped() {
        textDocumentProxy.insertText(" ")
        UIDevice.current.playInputClick()
    }

    @objc private func backspaceTapped() {
        textDocumentProxy.deleteBackward()
        UIDevice.current.playInputClick()
    }

    // MARK: - Backspace long-press (repeat delete)

    private var deleteTimer: Timer?
    private var deleteTickCount = 0
    private var deleteTranslateMode = false

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
            performBackspaceForCurrentMode()
            deleteTimer?.invalidate()
            deleteTimer = Timer.scheduledTimer(
                withTimeInterval: 0.1, repeats: true
            ) { [weak self] _ in
                guard let self = self else { return }
                self.performBackspaceForCurrentMode()
                self.deleteTickCount += 1
                // After ~0.5s of slow deletes, accelerate to 0.06s interval.
                if self.deleteTickCount == 5 {
                    self.deleteTimer?.invalidate()
                    self.deleteTimer = Timer.scheduledTimer(
                        withTimeInterval: 0.06, repeats: true
                    ) { [weak self] _ in
                        self?.performBackspaceForCurrentMode()
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
        textDocumentProxy.insertText("\n")
    }

    @objc private func styleTapped(_ s: UIButton) {
        fontStyleIndex = s.tag
        showMode(.fonts)
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

        // Remember current selection by NAME so we preserve position after rebuild.
        let currentCatName = cats[safeCat].0
        let currentStyleName = styleName // same as the one just long-pressed

        // Toggle favorite
        var favs = loadFavoriteFontNames()
        if favs.contains(styleName) {
            favs.removeAll { $0 == styleName }
            saveFavoriteFontNames(favs)
            showToast("즐겨찾기 제거됨")
        } else {
            favs.append(styleName)
            saveFavoriteFontNames(favs)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showToast("⭐ 즐겨찾기 추가됨")
        }

        // Re-map indices to same category/style name in new layout
        let newCats = visibleFontCategories()
        if let newCat = newCats.firstIndex(where: { $0.0 == currentCatName }) {
            fontCatIndex = newCat
            if let newStyle = newCats[newCat].1.firstIndex(where: { $0.name == currentStyleName }) {
                fontStyleIndex = newStyle
            }
        }
        showMode(.fonts)
    }

    @objc private func fontCatTapped(_ s: UIButton) {
        fontCatIndex = s.tag
        fontStyleIndex = 0
        savedFontScrollOffset = .zero
        showMode(.fonts)
    }

    @objc private func fontPickerToggleTapped() {
        guard let catRow = fontCategoryRowView else { return }
        fontPickerExpanded.toggle()
        let expanded = fontPickerExpanded
        fontToggleButton?.setTitle(expanded ? "▲" : "▼", for: .normal)
        UIView.animate(withDuration: 0.2) {
            catRow.isHidden = !expanded
            catRow.alpha = expanded ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }

    @objc private func toggleNumberMode() {
        isNumberMode.toggle()
        if !isNumberMode { isSymbolPage2 = false }
        showMode(.fonts)
    }

    @objc private func toggleSymbolPage() {
        isSymbolPage2.toggle()
        showMode(.fonts)
    }

    @objc private func gridItemTapped(_ s: UIButton) {
        guard let text = s.title(for: .normal) else { return }
        // 장식선: copy to clipboard instead of insert (long text)
        if currentMode == .special && selectedSpecialCat < specialCategories.count
            && specialCategories[selectedSpecialCat].0 == "장식선" {
            UIPasteboard.general.string = text
            showToast("복사됨")
        } else {
            textDocumentProxy.insertText(text)
        }
        UIDevice.current.playInputClick()
        tapFeedback(s)
    }

    @objc private func dotArtTapped(_ s: UIButton) {
        let items = dotArtCategories.first?.1 ?? []
        guard s.tag < items.count else { return }
        textDocumentProxy.insertText(items[s.tag])
        tapFeedback(s)
    }

    // MARK: - Favorites Storage

    private static let favKeyEmoticon = "favorites"
    private static let favKeyDotArt   = "favorites_dotart"
    private static let favKeyGif      = "favorites_gif"
    private static let favAppGroup    = "group.com.yourapp.fontkeyboard"
    private static let maxFav         = 100

    private var favCategoryIndex = 0
    private let favCategoryNames = ["전체", "폰트", "이모티콘", "특수문자", "도트아트", "GIF"]

    private func favDefaults() -> UserDefaults {
        UserDefaults(suiteName: Self.favAppGroup) ?? .standard
    }

    private func loadFavList(_ key: String) -> [String] {
        favDefaults().stringArray(forKey: key) ?? []
    }

    private func saveFavList(_ key: String, _ items: [String]) {
        favDefaults().set(items, forKey: key)
    }

    private func loadFavorites() -> [String] { loadFavList(Self.favKeyEmoticon) }

    private func addFavorite(_ text: String, key: String = favKeyEmoticon) {
        var items = loadFavList(key)
        guard !items.contains(text) else {
            showToast("이미 즐겨찾기에 있어요")
            return
        }
        if items.count >= Self.maxFav { items.removeLast() }
        items.insert(text, at: 0)
        saveFavList(key, items)
        showToast("즐겨찾기에 추가됐어요 ♥")
    }

    private func removeFavorite(_ text: String, key: String) {
        var items = loadFavList(key)
        items.removeAll { $0 == text }
        saveFavList(key, items)
        showToast("즐겨찾기에서 삭제됐어요")
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
        guard let text = s.title(for: .normal) else { return }
        textDocumentProxy.insertText(text)
        tapFeedback(s)
    }

    @objc private func favDotArtTapped(_ s: UIButton) {
        let dotArtFavs = loadFavList(Self.favKeyDotArt)
        guard s.tag < dotArtFavs.count else { return }
        textDocumentProxy.insertText(dotArtFavs[s.tag])
        tapFeedback(s)
    }

    @objc private func favGifTapped(_ s: UIButton) {
        let gifFavs = loadFavList(Self.favKeyGif)
        guard s.tag < gifFavs.count, let url = URL(string: gifFavs[s.tag]) else { return }
        showToast("GIF 다운로드 중...")
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                guard let data = data else { self?.showToast("다운로드 실패"); return }
                UIPasteboard.general.setData(data, forPasteboardType: "com.compuserve.gif")
                self?.showToast("GIF가 복사되었습니다")
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

        let favBtn = makePopupButton(title: "♥ 즐겨찾기 추가", color: mainPink) {
            overlay.removeFromSuperview()
            self.addFavorite(text, key: favKey)
        }
        stack.addArrangedSubview(favBtn)

        if !isDotArt && !isGif {
            let copyBtn = makePopupButton(title: "📋 복사", color: .systemBlue) {
                overlay.removeFromSuperview()
                UIPasteboard.general.string = text
                self.showToast("복사됨")
            }
            stack.addArrangedSubview(copyBtn)
        }

        stack.addArrangedSubview(makePopupButton(title: "취소", color: .darkGray) {
            overlay.removeFromSuperview()
        })
    }

    private func showRemovePopup(text: String, favKey: String) {
        let overlay = makeOverlay()
        let stack = makePopupStack(in: overlay)

        stack.addArrangedSubview(makePopupButton(title: "🗑 즐겨찾기 삭제", color: .systemRed) {
            overlay.removeFromSuperview()
            self.removeFavorite(text, key: favKey)
        })
        stack.addArrangedSubview(makePopupButton(title: "취소", color: .darkGray) {
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
        let defaults = UserDefaults(suiteName: "group.com.yourapp.fontkeyboard") ?? .standard
        isPremiumUser = defaults.bool(forKey: "is_premium")
        userTier = defaults.string(forKey: "tier") ?? "free"
        canTranslateUnlimited = defaults.bool(forKey: "can_translate_unlimited")
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === fontStyleScrollView {
            savedFontScrollOffset = scrollView.contentOffset
        } else if scrollView === emoticonCatScrollView {
            savedEmoticonCatOffset = scrollView.contentOffset
        } else if scrollView === specialCatScrollView {
            savedSpecialCatOffset = scrollView.contentOffset
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
        let toast = UILabel()
        toast.text = message
        toast.textColor = .white
        toast.backgroundColor = UIColor(white: 0, alpha: 0.75)
        toast.font = .systemFont(ofSize: 13, weight: .medium)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 14
        toast.layer.masksToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        toast.alpha = 0
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            toast.heightAnchor.constraint(equalToConstant: 28),
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
            btn.backgroundColor = mainPink.withAlphaComponent(0.15)
        }) { _ in
            UIView.animate(withDuration: 0.05, delay: 0,
                           options: [.allowUserInteraction, .curveEaseInOut]) {
                btn.transform = .identity
                btn.backgroundColor = originalBG
            }
        }
    }

    private func makeLetterKey(_ title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 22, weight: .regular)
        btn.backgroundColor = keyBG
        btn.setTitleColor(.black, for: .normal)
        btn.layer.cornerRadius = 5
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 1)
        btn.layer.shadowOpacity = 0.15
        btn.layer.shadowRadius = 0.5
        btn.adjustsImageWhenHighlighted = false
        return btn
    }

    private func makeSpecialKey(_ title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        btn.backgroundColor = specialKeyBG
        btn.setTitleColor(.black, for: .normal)
        btn.layer.cornerRadius = 5
        btn.adjustsImageWhenHighlighted = false
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

