import UIKit

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Constants
// ═══════════════════════════════════════════════════════════════════════════════

private let appGroupID  = "group.com.yourapp.fontkeyboard"
private let pinkColor   = UIColor(red: 1.0, green: 0.42, blue: 0.62, alpha: 1.0)
private let keyBG       = UIColor.white
private let specialKeyBG = UIColor(white: 0.78, alpha: 1)

// Legacy target (not compiled into current app). Real key lives in
// ios/font_keyboard/Secrets.swift (gitignored).
private let giphyApiKey = "YOUR_GIPHY_API_KEY"

struct GiphyImage {
    let id: String
    let previewURL: URL
    let originalURL: URL
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - KeyboardViewController
// ═══════════════════════════════════════════════════════════════════════════════

class KeyboardViewController: UIInputViewController {

    // ── Mode ────────────────────────────────────────────────────────────────
    enum Mode: Int, CaseIterable {
        case fonts = 0, emoticon, textTemplate, special, dotArt, gif, favorites
        var title: String {
            switch self {
            case .fonts:        return "Aa"
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
            default:         return 14
            }
        }
    }

    // ── Font Style ──────────────────────────────────────────────────────────
    struct UnicodeStyle {
        let name: String
        let upper: Int
        let lower: Int
        let digit: Int?
        let exceptions: [Int: Int]

        init(_ name: String, _ upper: Int, _ lower: Int,
             digit: Int? = nil, exceptions: [Int: Int] = [:]) {
            self.name = name; self.upper = upper; self.lower = lower
            self.digit = digit; self.exceptions = exceptions
        }
    }

    // ── State ───────────────────────────────────────────────────────────────
    private var currentMode: Mode = .fonts
    private var currentStyleIndex = 0
    private var isShifted = false
    private var inputBuffer = ""

    // ── Views ───────────────────────────────────────────────────────────────
    private var mainStack: UIStackView!
    private let modeBar = UIStackView()
    private let contentView = UIView()
    private var letterKeys: [UIButton] = []

    // ── QWERTY ──────────────────────────────────────────────────────────────
    private let qwertyRows: [[String]] = [
        ["q","w","e","r","t","y","u","i","o","p"],
        ["a","s","d","f","g","h","j","k","l"],
        ["z","x","c","v","b","n","m"]
    ]

    // ── Font Styles ─────────────────────────────────────────────────────────
    private let fontStyles: [UnicodeStyle] = [
        UnicodeStyle("Normal",  0x0041, 0x0061, digit: 0x0030),
        UnicodeStyle("Bold",    0x1D400, 0x1D41A, digit: 0x1D7CE),
        UnicodeStyle("Italic",  0x1D434, 0x1D44E, exceptions: [0x68: 0x210E]),
        UnicodeStyle("Script",  0x1D49C, 0x1D4B6, exceptions: [
            0x42:0x212C, 0x45:0x2130, 0x46:0x2131, 0x48:0x210B,
            0x49:0x2110, 0x4C:0x2112, 0x4D:0x2133, 0x52:0x211B,
            0x65:0x212F, 0x67:0x210A, 0x6F:0x2134]),
        UnicodeStyle("Double",  0x1D538, 0x1D552, digit: 0x1D7D8, exceptions: [
            0x43:0x2102, 0x48:0x210D, 0x4E:0x2115, 0x50:0x2119,
            0x51:0x211A, 0x52:0x211D, 0x5A:0x2124]),
        UnicodeStyle("Gothic",  0x1D504, 0x1D51E, exceptions: [
            0x43:0x212D, 0x48:0x210C, 0x49:0x2111, 0x52:0x211C, 0x5A:0x2128]),
        UnicodeStyle("Mono",    0x1D670, 0x1D68A, digit: 0x1D7F6),
        UnicodeStyle("Bubble",  0x24B6, 0x24D0),
    ]

    // ── Emoticons ───────────────────────────────────────────────────────────
    private let emoticonCategories: [(String, [String])] = [
        ("행복", ["(◕‿◕)","(｡◕‿◕｡)","ヽ(＾▽＾)ノ","(★‿★)","٩(◕‿◕)۶",
                 "(◠‿◠)","(≧▽≦)","(✧ω✧)","(◕ᴗ◕✿)","(✿◠‿◠)",
                 "(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧","(ᗒᗨᗕ)",
                 "ʕ ᐢ ᵕ ᐢ ʔ","⌯⦁⩊⦁⌯ಣ","≽^•༚• ྀི≼","(՞•-•՞)","૮₍ •̀ ⩊ •́ ₎ა","໒꒰ྀི˶•⤙•˶꒱ྀིა",
                 "(๑˃́ꇴ˂̀๑)","(๑>ᴗ<๑)","(๑′ᴗ‵๑)","(๑•᎑<๑)ｰ☆","٩(•̮̮̃•̃)۶","(´•᎑•`)♡",
                 "✪‿✪","꜆₍ᐢ˶•ᴗ•˶ᐢ₎꜆","( ՞ෆ ෆ՞ )",
                 "ツ","㋡","◡̎","⎝⍥⎠","( ◡̉̈ )"]),
        ("슬픔", ["(；﹏；)","(╥_╥)","(T_T)","(つ﹏⊂)","(ಥ_ಥ)",
                 "(｡•́︿•̀｡)","(っ˘̩╭╮˘̩)っ","(｡ŏ﹏ŏ)","(ノ_<、)",
                 "(´;ω;｀)","(ᗒᗩᗕ)","｡ﾟ(ﾟ´Д｀ﾟ)ﾟ｡",
                 "ʕ ﹷ ᴥ ﹷʔ",".·°՞(っ-ᯅ-ς)՞°·.","꒰ ᐢ ◞‸◟ᐢ꒱","｡°(° ᷄ᯅ ᷅°)°｡",
                 "૮₍´›̥̥̥ ᜊ ‹̥̥̥ `₎ა","( ˘•∽•˘ )","໒꒰ ྀི ′̥̥̥ ᵔ ‵̥̥̥ ꒱ྀིა","(ˊ̥̥̥̥̥ ³ ˋ̥̥̥̥̥)",
                 ".·´¯`(>▂<)´¯`·.","（ｉДｉ）","(•̩̩̩̩＿•̩̩̩̩)","(•́ɞ•̀)",
                 "( •̥ ˍ •̥ )","( ;ᯅ; )","(っ◞‸◟c)","₍ᐡඉ ̫ ඉᐡ₎",
                 "༼ ˃ɷ˂ഃ༽","⚲_⚲","(˘•̥-•̥˘)","(•̥̥̥⌓•̥̥̥)","⩌ ᯅ ⩌"]),
        ("화남", ["( ᴖ_ᴖ )💢","ᐡ ᵒ̴ – ᵒ̴ ᐡ💢","╭∩╮(►˛◄'!)","ヽ(｀⌒´メ)ノ",
                 "̿' ̿'\\̵͇̿̿\\з=( ͡ °_̯͡° )=ε/̵͇̿̿/'̿'̿ ̿","✧ `↼´˵","ʕ •̀ o •́ ʔ","凸( •̀_•́ )凸",
                 "¸◕ˇ‸ˇ◕˛","ʕ •̀ ω •́ ʔ","(◟‸◞)","(  '-'  ꐦ)",
                 "(◦`~´◦)","( ｡ •̀ ⤙ •́ ｡ )","ʕ•̀⤙•́ ʔ","૮(•᷄‎ࡇ•᷅ )ა",
                 "( ò_ó)","(   ꐦ •̀ ⤙ •́ )  =3","૮(っ `O´  c)ა","• ︡ᯅ•︠",
                 "/ᐠ •̀ ˕ •́ マ","ʕ•̀ ω •́ʔ.:",
                 "◠̈"]),
        ("동물", ["(=^･ω･^=)","(◕ᴥ◕)","ʕ•ᴥ•ʔ","(ΦωΦ)","ʕ·ᴥ·ʔ",
                 "(U・ω・U)","(=①ω①=)","(・⊝・)","≧◉ᴥ◉≦",
                 "(ᵔᴥᵔ)","₍ᐢ..ᐢ₎","ᘛ⁐̤ᕐᐷ",
                 "ʕ•ᴥ•.ʔ","ʕ๑•ﻌ•๑ʔ","ʕ•͡ɛ•͡ʼʼʔ","( ⁻(❢)⁻ )","₍ᐢ•ᴥ•ᐢ₎","(✦(ᴥ)✦)",
                 "ʕ òᴥó ʔ","ʕ*•-•ʔฅ","ʕ•̀д•́ʔﾉ","/ᐠ ˵• ﻌ •˵マ","꜀(^｡ ̫ ｡^꜀ )꜆੭",
                 "/.\\___/.\\ <(야옹)","o(=´∇｀=)o","/ᐠ - ̫ -マ","(=･ｪ･=?","●ᴥ●",
                 "૮₍ ՛◐ ᴥ ◐`₎ʖ","໒( ̿･ ᴥ ̿･ )ʋ","ᘳ´• ᴥ •`ᘰ","૮ ｡ˊᯅˋ ა","૮₍ •̀ᴥ•́ ₎ა",
                 "૮ ・ﻌ・ა","ヽ(°ᴥ°)ﾉ","(ᐡ -.- ᐡ)","( ੭ ˙🐽˙ )੭","( ˶˙🐽˙˵ ᐡ )",
                 "(՞•Ꙫ•՞)ﾉ?","₍ᐢ`🐽´ᐢ₎","₍՞ • 🐽 • ՞₎","(´・(oo)・｀)","𓃟",
                 "(̂•͈Ꙫ•͈⑅)̂ ୭","₍ᐢ. ֑ .ᐢ₎","( ᐢ, ,ᐢ)","⎛⑉・⊝・⑉⎞","•᷅ ʚ •᷄",
                 "ʚ(•Θ•)ɞ","୧(•̀ө•́)୨","(๑•̀ɞ•́๑)✧","( • ɞ• )","(・ε・)",
                 "(๑❛ө❛๑ )三","（ˇ ⊖ˇ）","( ˙◊˙ )","( 'Θ')ﾉ","𓆩(•࿉•)𓆪"]),
        ("사랑", ["(♥ω♥)","(づ￣ ³￣)づ","(灬♥ω♥灬)","(*˘︶˘*).｡*♡",
                 "(◍•ᴗ•◍)❤","(♡°▽°♡)","(✿ ♥‿♥)","( ˘ ³˘)♥",
                 "(❤ω❤)","♡＾▽＾♡","(´,,•ω•,,)♡","(⺣◡⺣)♡*",
                 "꜀(  ꜆-⩊-)꜆♡","( ˶'ᵕ'🫶🏻)💕","(⸝⸝´▽︎ `⸝⸝)","( ⸝⸝⸝•   •⸝⸝⸝)",
                 "＞ ̫＜ ♡","(ღˇᴗˇ)","(๑•́ ₃ •̀๑)","(●´□`)♡",
                 "( ๑ ❛ ڡ ❛ ๑ )❤","⸜(♡ ॑ᗜ ॑♡)⸝","•́ε•̀٥","( ◜ᴗ◝ )♡",
                 "(ღ•͈ᴗ•͈ღ)♥","໒( ♥ ◡ ♥ )७","♡ ᐡ◕ ̫ ◕ᐡ ♡","♥(〃´૩`〃)♥",
                 "( . ̫ .)💗","(♡´౪`♡)","( っ꒪⌓꒪)っ—̳͟͞͞♡","૮ - ﻌ • ა ♥","⁎⁍̴̆Ɛ⁍̴̆⁎"]),
        ("반응", ["･ᴗ･ )੭''","( *´ᗜ`*)ﾉ","(๑'• ֊ •'๑)੭","٩( ´◡` )( ´◡` )۶","_(._.)_",
                 "( •⍸• )","c(   'o')っ","(⊙_⊙)","( ´o` )","ᯤ ᯅ ᯤ",
                 "૮₍ •́ ₃•̀₎ა","ϲ( ´•ϲ̲̃ ̲̃•` )ɔ","( っ •‌ᜊ•‌ )う","ˣ‿ˣ","(๑•́‧̫•̀๑)",
                 "⊙△⊙","⊙﹏⊙","ㅇࡇㅇ?","૮˘･_･˘ა","( ･̆ω･̆ )",
                 "₍ᐢ - ̫ - ᐢ₎","( > ~ < )💦","•́.•̀","•̆₃•̑","( ᖛ ̫ ᖛ )",
                 "( • ̀ω•́ )✧","(๑•̆૩•̆)","👉🏻(˚ ˃̣̣̥ ▵ ˂̣̣̥ )꒱👈🏻💧","˙∧˙","（≩∇≨）",
                 "❛‿˂̵✧","(  > ᴗ • )","( ͡~ ͜ʖ ͡°)","(･ω<)☆","˶ˊᜊˋ˶ಣ"]),
        ("최고", ["ദ്ദിᐢ. .ᐢ₎","ദ്ദി（• ˕ •マ.ᐟ","ദ്ദി •⤙• )","( ദ്ദി ˙ᗜ˙ )",
                 "ჱ̒՞ ̳ᴗ ̫ ᴗ ̳՞꒱","(՞ •̀֊•́՞)ฅ","ჱ̒^. ̫ .^）","ദ്ദി*ˊᗜˋ*)",
                 "( 　'-' )ノദ്ദി)`-' )","ჱ̒⸝⸝•̀֊•́⸝⸝)","ദ്ദി  ॑꒳ ॑c)","ദ്ദിᐢ- ̫-ᐢ₎",
                 "ദ്ദി˙∇˙)ว","ദ്ദി  ॑꒳ ॑c)","ദ്ദി（• ˕ •マ.ᐟ","ദി՞˶ෆ . ෆ˶ ՞",
                 "( ദ്ദി ˙ᗜ˙ )","👍🏻ᖛ ̫ ᖛ )","ദ്ദി¯•ω•¯ )","ദ്ദി•̀.̫•́✧",
                 "ദ്ദി ˘ ͜ʖ ˘)","ദ്ദി  ͡° ͜ʖ ͡°)","ദ്ദി❁´◡`❁)",
                 "ദ്ദി * ॑꒳ ॑*)⸝⋆｡✧♡","ദ്ദി ≽^⎚˕⎚^≼ .ᐟ"]),
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
                 "╭◜◝ ͡ ◜◝╮    몽실   ╭◜◝ ͡ ◜◝╮\n ( •ㅅ•    ) 몽실몽실 (   •ㅅ•  )\n ╰◟◞ ͜ ╭◜◝ ͡ ◜◝╮몽실몽실 ͜ ◟◞╯\n  몽몽실(  •ㅅ•   ) 몽실\n 몽실몽 ╰◟◞ ◟◞╯몽실몽실"]),
    ]
    private var selectedEmoticonCat = 0

    // ── Special Chars ───────────────────────────────────────────────────────
    private let specialCategories: [(String, [String])] = [
        ("화살표", ["→","←","↑","↓","➜","⇒","⟶",
                  "↗","↘","↙","↖","⤴\u{FE0E}","⤵\u{FE0E}","➤","↔","⇔","⟷",
                  "⇐","⇑","⇓","⇕","⇖","⇗","⇘","⇙",
                  "↺","↻","⟰","⟱","↨","⇄","⇅","⇆",
                  "⇦","⇧","⇨","⇩","⌦","⌫","⇰","⤶","⤷","➲","⇣","⇤","⇥","↰","↱","↲","↳","↶","↷"
        ]),
        ("도형",  ["■","□","▪","▫","▲","△","▶","▷","▼","▽","◀","◁",
                  "●","○","◆","◇","◉","◎","▣","▤","▥","▦","▧","▨",
                  "⛶"]),
        ("상형문자",["𓁹","𓂡","𓂢","𓂩","𓂽","𓂾","𓃀","𓃒","𓃔","𓃗","𓃙","𓃟","𓃡","𓃩",
                  "𓃬","𓃰","𓃱","𓃴","𓃵","𓃹","𓃾","𓄁","𓄀","𓄃","𓄇","𓅺","𓅬","𓆙",
                  "𓆟","𓇼","𓇽","𓈉","𓊍","𓊎","𓍳"]),
        ("하트",  ["♡","♥","❥","❦","❧","☙","▷♡◁",
                  "♡̴","ꕤ","𓆸","ʚ♡ɞ","﹤𝟹",
                  "ꯁ","ɞ","ʚ","εïз","♡=͟͟͞͞ ³ ³","»-♡→","-\u{0060}♥´-","-\u{0060}♡´-","⸜♡⸝\u{200D}","-ˋˏ ♡ ˎˊ-","ʚ◡̈ɞ","₊⁺♡̶₊⁺","˚ෆ*₊"]),
        ("별/꽃", ["✿","❀","✾","❁","✦","✧","❋","✺","✵","✶",
                  "✷","✸","❂","❃","✻","❄","❅","❆","✱","※",
                  "⛤","✰","✮","✪","✳"]),
        ("수학",  ["±","×","÷","≠","≈","≤","≥","∞","√","∑",
                  "∏","∫","∂","∆","∇","∈","∅","⊂","⊃","⊥"]),
        ("장식",  ["꩜","⁂","✳\u{FE0E}","❊","✦","❈","⁕","꧁","꧂","࿇","꒰","꒱",
                  "⌘","⌥","⇧","⌫","☯\u{FE0E}","☸\u{FE0E}","♾\u{FE0E}","⚜\u{FE0E}",
                  "✡\u{FE0E}","☪\u{FE0E}"]),
        ("기호", ["©","®","™","°","%","&","@","#","$","€","£","¥","₩","¢",
                "±","×","÷","≠","≈","∞","√","π","∑",
                "♩","♪","♫","♬",
                "☎\u{FE0E}","✉\u{FE0E}","✂\u{FE0E}","✏\u{FE0E}","✒\u{FE0E}",
                "✄","✎","✓","✔","✆","✉","❛","❜"]),
        ("십자가", ["✝\u{FE0E}","✞","✟","☩","♰","♱","†","‡","✠","☦\u{FE0E}"]),
        ("패턴", ["░","▒","▓","█","▌","▐","▀","▄","┼","╬","═","║",
                "╔","╗","╚","╝","┌","┐","└","┘","├","┤","┬","┴"]),
    ]
    private var selectedSpecialCat = 0

    // ── Text Templates ──────────────────────────────────────────────────────
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

    // ── Dot Art ─────────────────────────────────────────────────────────────
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
"""
        ])
    ]
    private var selectedDotArtCat = 0
    private var dotArtImages: [UIImage] = []

    // ── GIF State ──────────────────────────────────────────────────────────
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
    private weak var gifSearchField: UITextField?
    private weak var gifGridStack: UIStackView?
    private weak var gifLoadingLabel: UILabel?

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - Lifecycle
    // ═════════════════════════════════════════════════════════════════════════

    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.95, alpha: 1)
        setupLayout()
        showMode(.fonts)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if heightConstraint == nil {
            heightConstraint = view.heightAnchor.constraint(equalToConstant: 260)
            heightConstraint?.priority = .defaultHigh
            heightConstraint?.isActive = true
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - Layout
    // ═════════════════════════════════════════════════════════════════════════

    private func setupLayout() {
        // 모드 바
        modeBar.axis = .horizontal
        modeBar.distribution = .fillEqually
        modeBar.spacing = 4
        for mode in Mode.allCases {
            let btn = makeModeButton(mode)
            modeBar.addArrangedSubview(btn)
        }

        // 메인 스택
        mainStack = UIStackView(arrangedSubviews: [modeBar, contentView])
        mainStack.axis = .vertical
        mainStack.spacing = 2
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 3),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -3),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -3),
            modeBar.heightAnchor.constraint(equalToConstant: 34),
        ])
    }

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - Mode Switching
    // ═════════════════════════════════════════════════════════════════════════

    private func showMode(_ mode: Mode) {
        currentMode = mode
        updateModeBar()
        clearContent()
        inputBuffer = ""

        switch mode {
        case .fonts:     buildFontsMode()
        case .emoticon:  buildGridMode(categories: emoticonCategories,
                                        selected: selectedEmoticonCat,
                                        cols: 3, fontSize: 14,
                                        onCatChange: { [weak self] i in
                                            self?.selectedEmoticonCat = i
                                            self?.showMode(.emoticon)
                                        })
        case .special:   buildGridMode(categories: specialCategories,
                                        selected: selectedSpecialCat,
                                        cols: 5, fontSize: 22,
                                        onCatChange: { [weak self] i in
                                            self?.selectedSpecialCat = i
                                            self?.showMode(.special)
                                        })
        case .dotArt:    buildDotArtMode()
        case .gif:       buildGifMode()
        case .favorites: buildFavoritesMode()
        case .textTemplate: buildTextTemplateMode()
        }
    }

    private func clearContent() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        letterKeys.removeAll()
    }

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - Mode Bar
    // ═════════════════════════════════════════════════════════════════════════

    private func makeModeButton(_ mode: Mode) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(mode.title, for: .normal)
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
            btn.backgroundColor = sel ? pinkColor : .clear
            btn.setTitleColor(sel ? .white : .darkGray, for: .normal)
        }
    }

    @objc private func modeTapped(_ s: UIButton) {
        showMode(Mode(rawValue: s.tag) ?? .fonts)
    }

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - Fonts Mode (QWERTY + Style Picker + Preview)
    // ═════════════════════════════════════════════════════════════════════════

    private var previewLabel: UILabel!

    private func buildFontsMode() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 3
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        pinToEdges(stack, in: contentView)

        // ── Preview ─────────────────────────────────────────────────────
        previewLabel = UILabel()
        previewLabel.text = "텍스트를 입력하세요"
        previewLabel.textColor = .lightGray
        previewLabel.textAlignment = .center
        previewLabel.font = .systemFont(ofSize: 17)
        previewLabel.backgroundColor = .white
        previewLabel.layer.cornerRadius = 8
        previewLabel.layer.masksToBounds = true
        previewLabel.setHeight(36)
        stack.addArrangedSubview(previewLabel)

        // ── Style Picker (horizontal scroll) ────────────────────────────
        let styleScroll = UIScrollView()
        styleScroll.showsHorizontalScrollIndicator = false
        styleScroll.setHeight(30)

        let styleRow = UIStackView()
        styleRow.axis = .horizontal
        styleRow.spacing = 6
        styleRow.translatesAutoresizingMaskIntoConstraints = false
        styleScroll.addSubview(styleRow)
        NSLayoutConstraint.activate([
            styleRow.topAnchor.constraint(equalTo: styleScroll.topAnchor),
            styleRow.leadingAnchor.constraint(equalTo: styleScroll.leadingAnchor, constant: 4),
            styleRow.trailingAnchor.constraint(equalTo: styleScroll.trailingAnchor, constant: -4),
            styleRow.bottomAnchor.constraint(equalTo: styleScroll.bottomAnchor),
            styleRow.heightAnchor.constraint(equalTo: styleScroll.heightAnchor),
        ])
        for (i, style) in fontStyles.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(style.name, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            btn.tag = i
            btn.layer.cornerRadius = 12
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
            let sel = i == currentStyleIndex
            btn.backgroundColor = sel ? pinkColor : UIColor(white: 0.90, alpha: 1)
            btn.setTitleColor(sel ? .white : .darkGray, for: .normal)
            btn.addTarget(self, action: #selector(styleTapped(_:)), for: .touchUpInside)
            styleRow.addArrangedSubview(btn)
        }
        stack.addArrangedSubview(styleScroll)

        // ── QWERTY Rows ─────────────────────────────────────────────────
        for (ri, row) in qwertyRows.enumerated() {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 4

            if ri == 2 {
                let shift = makeSpecialKey("⇧")
                shift.addTarget(self, action: #selector(shiftTapped), for: .touchUpInside)
                rowStack.addArrangedSubview(shift)
            }

            for key in row {
                let btn = makeLetterKey(key)
                btn.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(btn)
                letterKeys.append(btn)
            }

            if ri == 2 {
                let del = makeSpecialKey("⌫")
                del.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
                rowStack.addArrangedSubview(del)
            }
            stack.addArrangedSubview(rowStack)
        }

        // ── Bottom Row: 🌐 + space + 삽입 + ⏎ ──────────────────────────
        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = 6

        let globe = makeSpecialKey("🌐")
        globe.addTarget(self, action: #selector(globeTapped), for: .touchUpInside)
        globe.setWidth(44)
        bottom.addArrangedSubview(globe)

        let space = makeLetterKey("space")
        space.titleLabel?.font = .systemFont(ofSize: 14)
        space.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)
        bottom.addArrangedSubview(space)

        let insert = makeSpecialKey("삽입")
        insert.backgroundColor = pinkColor
        insert.setTitleColor(.white, for: .normal)
        insert.addTarget(self, action: #selector(insertTapped), for: .touchUpInside)
        insert.setWidth(56)
        bottom.addArrangedSubview(insert)

        let ret = makeSpecialKey("⏎")
        ret.addTarget(self, action: #selector(returnTapped), for: .touchUpInside)
        ret.setWidth(44)
        bottom.addArrangedSubview(ret)

        stack.addArrangedSubview(bottom)
    }

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - Grid Mode (이모티콘 / 특수문자)
    // ═════════════════════════════════════════════════════════════════════════

    private func buildGridMode(categories: [(String, [String])],
                                selected: Int, cols: Int, fontSize: CGFloat,
                                onCatChange: @escaping (Int) -> Void) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        pinToEdges(container, in: contentView)

        // ── Category Tabs ───────────────────────────────────────────────
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

        for (i, cat) in categories.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(cat.0, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            btn.layer.cornerRadius = 12
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)
            let sel = i == selected
            btn.backgroundColor = sel ? pinkColor : UIColor(white: 0.90, alpha: 1)
            btn.setTitleColor(sel ? .white : .darkGray, for: .normal)
            btn.tag = i
            btn.addAction(UIAction { _ in onCatChange(i) }, for: .touchUpInside)
            catRow.addArrangedSubview(btn)
        }

        // ── Bottom Bar ──────────────────────────────────────────────────
        let bottomBar = UIStackView()
        bottomBar.axis = .horizontal
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomBar)

        let globe = makeSpecialKey("🌐")
        globe.setWidth(44)
        globe.addTarget(self, action: #selector(globeTapped), for: .touchUpInside)
        let del = makeSpecialKey("⌫")
        del.setWidth(44)
        del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
        bottomBar.addArrangedSubview(globe)
        bottomBar.addArrangedSubview(UIView()) // spacer
        bottomBar.addArrangedSubview(del)

        // ── Grid ────────────────────────────────────────────────────────
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            catScroll.topAnchor.constraint(equalTo: container.topAnchor),
            catScroll.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            catScroll.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            catScroll.heightAnchor.constraint(equalToConstant: 30),

            scrollView.topAnchor.constraint(equalTo: catScroll.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -4),

            bottomBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 34),
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

        // Detect "도트아트" — render as 1-column tall cells
        let categoryName = categories[selected].0
        let isDotArt = categoryName == "도트아트"
        let actualCols = isDotArt ? 1 : cols
        let cellHeight: CGFloat = isDotArt ? 130 : 42

        let items = categories[selected].1
        let chunked = stride(from: 0, to: items.count, by: actualCols).map {
            Array(items[$0..<min($0 + actualCols, items.count)])
        }

        for row in chunked {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 5
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
                btn.setHeight(cellHeight)
                btn.addTarget(self, action: #selector(gridTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(btn)
            }
            for _ in 0..<(actualCols - row.count) { rowStack.addArrangedSubview(UIView()) }
            gridStack.addArrangedSubview(rowStack)
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - Dot Art Mode (가로 스크롤)
    // ═════════════════════════════════════════════════════════════════════════

    private func buildDotArtMode() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        pinToEdges(container, in: contentView)

        let bottomBar = UIStackView()
        bottomBar.axis = .horizontal
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomBar)

        let globe = makeSpecialKey("🌐")
        globe.setWidth(44)
        globe.addTarget(self, action: #selector(globeTapped), for: .touchUpInside)
        let del = makeSpecialKey("⌫")
        del.setWidth(44)
        del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
        bottomBar.addArrangedSubview(globe)
        bottomBar.addArrangedSubview(UIView())
        bottomBar.addArrangedSubview(del)

        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.isPagingEnabled = true
        scrollView.decelerationRate = .fast
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

        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .top
        hStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            hStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -12),
            hStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -8),
        ])

        let cardWidth: CGFloat = 250
        let cardPadding: CGFloat = 8
        let labelFont = UIFont(name: "Menlo", size: 4) ?? UIFont.monospacedSystemFont(ofSize: 4, weight: .regular)
        let items = dotArtCategories.first?.1 ?? []
        for (index, item) in items.enumerated() {
            let btn = UIButton(type: .custom)
            btn.tag = index
            btn.backgroundColor = .white
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth = 0.8
            btn.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.4).cgColor
            btn.clipsToBounds = true
            btn.widthAnchor.constraint(equalToConstant: cardWidth).isActive = true
            btn.heightAnchor.constraint(equalToConstant: cardWidth).isActive = true
            btn.addTarget(self, action: #selector(dotArtTapped(_:)), for: .touchUpInside)

            let label = UILabel()
            label.text = item
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

            hStack.addArrangedSubview(btn)
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - Text Template Mode (세로 스크롤)
    // ═════════════════════════════════════════════════════════════════════════

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
        globe.addTarget(self, action: #selector(globeTapped), for: .touchUpInside)
        let del = makeSpecialKey("⌫")
        del.setWidth(44)
        del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
        bottomBar.addArrangedSubview(globe)
        bottomBar.addArrangedSubview(UIView())
        bottomBar.addArrangedSubview(del)

        // Vertical scroll above bottom bar
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
            s.backgroundColor = pinkColor.withAlphaComponent(0.15)
        }) { _ in
            UIView.animate(withDuration: 0.06) {
                s.transform = .identity
                s.backgroundColor = .white
            }
        }
    }

    // MARK: - Dot Art → Image

    private func dotArtToImage(_ text: String) -> UIImage {
        let padding: CGFloat = 8
        let font = UIFont(name: "Courier New", size: 7)
            ?? .monospacedSystemFont(ofSize: 7, weight: .regular)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.minimumLineHeight = 8
        paragraphStyle.maximumLineHeight = 8
        paragraphStyle.alignment = .left

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
            .kern: 0,
            .paragraphStyle: paragraphStyle,
        ]

        let attrString = NSAttributedString(string: text, attributes: attributes)

        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude,
                             height: CGFloat.greatestFiniteMagnitude)
        let textRect = attrString.boundingRect(
            with: maxSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )

        let canvasSize = CGSize(
            width: ceil(textRect.width) + padding * 2,
            height: ceil(textRect.height) + padding * 2
        )

        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvasSize))
            attrString.draw(at: CGPoint(x: padding, y: padding))
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - GIF Mode
    // ═════════════════════════════════════════════════════════════════════════

    private func buildGifMode() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        pinToEdges(container, in: contentView)

        let searchField = UITextField()
        searchField.placeholder = "GIF 검색..."
        searchField.borderStyle = .roundedRect
        searchField.font = .systemFont(ofSize: 14)
        searchField.returnKeyType = .search
        searchField.clearButtonMode = .whileEditing
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.addTarget(self, action: #selector(gifSearchTriggered), for: .editingDidEndOnExit)
        container.addSubview(searchField)
        gifSearchField = searchField

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
            btn.backgroundColor = sel ? pinkColor : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? .white : .darkGray, for: .normal)
            btn.tag = i
            btn.addTarget(self, action: #selector(gifCategoryTapped(_:)), for: .touchUpInside)
            catRow.addArrangedSubview(btn)
        }

        let bottomBar = UIStackView()
        bottomBar.axis = .horizontal
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomBar)
        let globe = makeSpecialKey("🌐")
        globe.setWidth(44)
        globe.addTarget(self, action: #selector(globeTapped), for: .touchUpInside)
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

        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 5
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(gridStack)
        gifGridStack = gridStack

        let loadingLabel = UILabel()
        loadingLabel.text = "불러오는 중..."
        loadingLabel.font = .systemFont(ofSize: 13)
        loadingLabel.textColor = .lightGray
        loadingLabel.textAlignment = .center
        loadingLabel.numberOfLines = 0
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(loadingLabel)
        gifLoadingLabel = loadingLabel

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            searchField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            searchField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            searchField.heightAnchor.constraint(equalToConstant: 32),

            catScroll.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 4),
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
            bottomBar.heightAnchor.constraint(equalToConstant: 34),

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

    private func loadGifs() {
        let category = gifCategories[gifCategoryIndex]
        gifImages = []
        if let query = category.1 {
            fetchGiphy(isSearch: true, query: query)
        } else {
            fetchGiphy(isSearch: false, query: nil)
        }
    }

    private func fetchGiphy(isSearch: Bool, query: String?) {
        gifLoadingLabel?.text = "불러오는 중..."
        gifLoadingLabel?.isHidden = false

        let urlString: String
        if isSearch, let q = query?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString = "https://api.giphy.com/v1/gifs/search?api_key=\(giphyApiKey)&q=\(q)&limit=20&lang=ko"
        } else {
            urlString = "https://api.giphy.com/v1/gifs/trending?api_key=\(giphyApiKey)&limit=20&lang=ko"
        }
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["data"] as? [[String: Any]]
            else {
                DispatchQueue.main.async {
                    self.gifImages = []
                    self.gifLoadingLabel?.text = "GIF 불러오기 실패\nAPI Key를 확인해주세요"
                    self.renderGifGrid()
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
                self.gifImages = gifs
                self.gifLoadingLabel?.isHidden = !gifs.isEmpty
                if gifs.isEmpty { self.gifLoadingLabel?.text = "결과 없음" }
                self.renderGifGrid()
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

    @objc private func gifCategoryTapped(_ sender: UIButton) {
        gifCategoryIndex = sender.tag
        gifSearchField?.text = nil
        showMode(.gif)
    }

    @objc private func gifSearchTriggered() {
        guard let query = gifSearchField?.text, !query.isEmpty else { return }
        fetchGiphy(isSearch: true, query: query)
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

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - Favorites Mode
    // ═════════════════════════════════════════════════════════════════════════

    private func buildFavoritesMode() {
        let favorites = loadFavoritesFromAppGroup()

        let outerStack = UIStackView()
        outerStack.axis = .vertical
        outerStack.spacing = 4
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(outerStack)
        pinToEdges(outerStack, in: contentView)

        if favorites.isEmpty {
            let label = UILabel()
            label.text = "아직 즐겨찾기가 없어요\n메인 앱에서 추가해주세요"
            label.numberOfLines = 0
            label.textColor = .lightGray
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 15)
            outerStack.addArrangedSubview(UIView()) // top spacer
            outerStack.addArrangedSubview(label)
            outerStack.addArrangedSubview(UIView()) // bottom spacer
        } else {
            let scrollView = UIScrollView()
            scrollView.alwaysBounceVertical = true
            outerStack.addArrangedSubview(scrollView)

            let gridStack = UIStackView()
            gridStack.axis = .vertical
            gridStack.spacing = 6
            gridStack.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(gridStack)
            NSLayoutConstraint.activate([
                gridStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
                gridStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                gridStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                gridStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -4),
                gridStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            ])

            for item in favorites {
                let btn = UIButton(type: .system)
                btn.setTitle(item, for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 16)
                btn.titleLabel?.adjustsFontSizeToFitWidth = true
                btn.titleLabel?.minimumScaleFactor = 0.5
                btn.backgroundColor = .white
                btn.layer.cornerRadius = 10
                btn.layer.borderWidth = 0.5
                btn.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
                btn.setTitleColor(.darkGray, for: .normal)
                btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
                btn.contentHorizontalAlignment = .left
                btn.addTarget(self, action: #selector(gridTapped(_:)), for: .touchUpInside)
                gridStack.addArrangedSubview(btn)
            }
        }

        // Bottom bar
        let bottomBar = UIStackView()
        bottomBar.axis = .horizontal
        let globe = makeSpecialKey("🌐")
        globe.setWidth(44)
        globe.addTarget(self, action: #selector(globeTapped), for: .touchUpInside)
        bottomBar.addArrangedSubview(globe)
        bottomBar.addArrangedSubview(UIView())
        bottomBar.setHeight(34)
        outerStack.addArrangedSubview(bottomBar)
    }

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - Key Actions
    // ═════════════════════════════════════════════════════════════════════════

    @objc private func letterTapped(_ s: UIButton) {
        guard var ch = s.title(for: .normal) else { return }
        if isShifted { ch = ch.uppercased() }
        inputBuffer += ch
        updatePreview()
        if isShifted { isShifted = false; updateKeyLabels() }
    }

    @objc private func spaceTapped() {
        inputBuffer += " "
        updatePreview()
    }

    @objc private func deleteTapped() {
        if !inputBuffer.isEmpty {
            inputBuffer.removeLast()
            updatePreview()
        } else {
            textDocumentProxy.deleteBackward()
        }
    }

    @objc private func backspaceTapped() {
        textDocumentProxy.deleteBackward()
    }

    @objc private func shiftTapped() {
        isShifted.toggle()
        updateKeyLabels()
    }

    @objc private func returnTapped() {
        textDocumentProxy.insertText("\n")
    }

    @objc private func insertTapped() {
        guard !inputBuffer.isEmpty else { return }
        let style = fontStyles[currentStyleIndex]
        let converted = convertText(inputBuffer, style: style)
        textDocumentProxy.insertText(converted)
        inputBuffer = ""
        updatePreview()
    }

    @objc private func globeTapped() {
        advanceToNextInputMode()
    }

    @objc private func styleTapped(_ s: UIButton) {
        currentStyleIndex = s.tag
        showMode(.fonts)
    }

    @objc private func gridTapped(_ s: UIButton) {
        guard let text = s.title(for: .normal) else { return }
        textDocumentProxy.insertText(text)
        // 탭 피드백
        UIView.animate(withDuration: 0.06, animations: {
            s.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            s.backgroundColor = pinkColor.withAlphaComponent(0.15)
        }) { _ in
            UIView.animate(withDuration: 0.06) {
                s.transform = .identity
                s.backgroundColor = .white
            }
        }
    }

    @objc private func dotArtTapped(_ s: UIButton) {
        guard s.tag < dotArtImages.count else { return }
        let image = dotArtImages[s.tag]
        UIPasteboard.general.image = image
        showToast("이미지가 복사되었습니다")
        UIView.animate(withDuration: 0.06, animations: {
            s.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.06) {
                s.transform = .identity
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

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - Preview / Key Labels
    // ═════════════════════════════════════════════════════════════════════════

    private func updatePreview() {
        guard let label = previewLabel else { return }
        if inputBuffer.isEmpty {
            label.text = "텍스트를 입력하세요"
            label.textColor = .lightGray
        } else {
            let style = fontStyles[currentStyleIndex]
            label.text = convertText(inputBuffer, style: style)
            label.textColor = .darkText
        }
    }

    private func updateKeyLabels() {
        for btn in letterKeys {
            guard let t = btn.title(for: .normal) else { continue }
            btn.setTitle(isShifted ? t.uppercased() : t.lowercased(), for: .normal)
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - Unicode Conversion
    // ═════════════════════════════════════════════════════════════════════════

    private func convertText(_ input: String, style: UnicodeStyle) -> String {
        // Normal은 변환 없이 반환
        if style.upper == 0x0041 && style.lower == 0x0061 { return input }

        var result = ""
        for scalar in input.unicodeScalars {
            let c = Int(scalar.value)
            if let mapped = style.exceptions[c] {
                result += String(UnicodeScalar(mapped)!)
            } else if c >= 0x41 && c <= 0x5A {
                result += String(UnicodeScalar(style.upper + (c - 0x41))!)
            } else if c >= 0x61 && c <= 0x7A {
                result += String(UnicodeScalar(style.lower + (c - 0x61))!)
            } else if let d = style.digit, c >= 0x30 && c <= 0x39 {
                result += String(UnicodeScalar(d + (c - 0x30))!)
            } else {
                result += String(scalar)
            }
        }
        return result
    }

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - App Group Data
    // ═════════════════════════════════════════════════════════════════════════

    private func loadFavoritesFromAppGroup() -> [String] {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let jsonArray = defaults.array(forKey: "favorites_v2") as? [String]
        else { return [] }

        var texts: [String] = []
        for jsonStr in jsonArray {
            guard let data = jsonStr.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text = dict["text"] as? String
            else { continue }
            texts.append(text)
        }
        return texts
    }

    // ═════════════════════════════════════════════════════════════════════════
    // MARK: - UI Helpers
    // ═════════════════════════════════════════════════════════════════════════

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
        return btn
    }

    private func makeSpecialKey(_ title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        btn.backgroundColor = specialKeyBG
        btn.setTitleColor(.black, for: .normal)
        btn.layer.cornerRadius = 5
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

// ═════════════════════════════════════════════════════════════════════════════
// MARK: - UIView Height/Width Helpers
// ═════════════════════════════════════════════════════════════════════════════

private extension UIView {
    func setHeight(_ h: CGFloat) {
        heightAnchor.constraint(equalToConstant: h).isActive = true
    }
    func setWidth(_ w: CGFloat) {
        widthAnchor.constraint(equalToConstant: w).isActive = true
    }
}
