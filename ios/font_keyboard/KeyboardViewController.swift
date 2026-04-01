import UIKit

// MARK: - Constants

private let mainPink = UIColor(red: 1, green: 0.42, blue: 0.62, alpha: 1)
private let keyBG = UIColor.white
private let specialKeyBG = UIColor(white: 0.78, alpha: 1)

// MARK: - FontStyle

enum FontStyle: Int, CaseIterable {
    case normal, bold, italic, script, gothic, fullwidth, monospace

    var displayName: String {
        switch self {
        case .normal:    return "Normal"
        case .bold:      return "Bold"
        case .italic:    return "Italic"
        case .script:    return "Script"
        case .gothic:    return "Gothic"
        case .fullwidth: return "Fullwidth"
        case .monospace: return "Monospace"
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

// MARK: - Convert Function

func convertText(_ text: String, style: FontStyle) -> String {
    switch style {
    case .normal:    return text
    case .bold:      return mapChars(text, boldMap)
    case .italic:    return mapChars(text, italicMap)
    case .script:    return mapChars(text, scriptMap)
    case .gothic:    return mapChars(text, gothicMap)
    case .fullwidth: return mapChars(text, fullwidthMap)
    case .monospace: return mapChars(text, monospaceMap)
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

// MARK: - KeyboardViewController

class KeyboardViewController: UIInputViewController {

    // MARK: - Mode

    enum Mode: Int, CaseIterable {
        case fonts = 0, emoticon, special, favorites
        var title: String {
            switch self {
            case .fonts:     return "Aa"
            case .emoticon:  return "이모티콘"
            case .special:   return "특수문자"
            case .favorites: return "♥"
            }
        }
    }

    // MARK: - State

    private var currentMode: Mode = .fonts
    private var currentStyle: FontStyle = .normal
    private var isShifted = false

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
                  "✪‿✪", "꜆₍ᐢ˶•ᴗ•˶ᐢ₎꜆", "( ՞ෆ ෆ՞ )"]),
        ("슬픔", ["(；﹏；)", "(╥_╥)", "(T_T)", "(つ﹏⊂)", "(っ˘̩╭╮˘̩)っ", "(-_-)zzZ", "(ಥ_ಥ)", "(◞‸◟)",
                  "ʕ ﹷ ᴥ ﹷʔ", ".·°՞(っ-ᯅ-ς)՞°·.", "꒰ ᐢ ◞‸◟ᐢ꒱", "｡°(° ᷄ᯅ ᷅°)°｡",
                  "૮₍´›̥̥̥ ᜊ ‹̥̥̥ `₎ა", "( ˘•∽•˘ )", "໒꒰ ྀི ′̥̥̥ ᵔ ‵̥̥̥ ꒱ྀིა", "(ˊ̥̥̥̥̥ ³ ˋ̥̥̥̥̥)",
                  ".·´¯`(>▂<)´¯`·.", "（ｉДｉ）", "(•̩̩̩̩＿•̩̩̩̩)", "(•́ɞ•̀)",
                  "( •̥ ˍ •̥ )", "( ;ᯅ; )", "(っ◞‸◟c)", "₍ᐡඉ ̫ ඉᐡ₎",
                  "༼ ˃ɷ˂ഃ༽", "⚲_⚲", "(˘•̥-•̥˘)", "(•̥̥̥⌓•̥̥̥)", "⩌ ᯅ ⩌"]),
        ("화남", ["( ᴖ_ᴖ )💢", "ᐡ ᵒ̴ – ᵒ̴ ᐡ💢", "╭∩╮(►˛◄'!)", "ヽ(｀⌒´メ)ノ",
                  "̿' ̿'\\̵͇̿̿\\з=( ͡ °_̯͡° )=ε/̵͇̿̿/'̿'̿ ̿", "✧ `↼´˵", "ʕ •̀ o •́ ʔ", "凸( •̀_•́ )凸",
                  "¸◕ˇ‸ˇ◕˛", "ʕ •̀ ω •́ ʔ", "(◟‸◞)", "(  '-'  ꐦ)",
                  "(◦`~´◦)", "( ｡ •̀ ⤙ •́ ｡ )", "ʕ•̀⤙•́ ʔ", "૮(•᷄‎ࡇ•᷅ )ა",
                  "( ò_ó)", "(   ꐦ •̀ ⤙ •́ )  =3", "૮(っ `O´  c)ა", "• ︡ᯅ•︠",
                  "/ᐠ •̀ ˕ •́ マ", "ʕ•̀ ω •́ʔ.:"]),
        ("동물", ["(=^･ω･^=)", "ʕ•ᴥ•ʔ", "(◕ᴥ◕)", "=^.^=", "(づ｡◕‿‿◕｡)づ", "ʕ·͡ᴥ·ʔ", "(^・ω・^ )", "≽^•⩊•^≼"]),
        ("사랑", ["(♥ω♥)", "(づ￣³￣)づ", "( ˘ ³˘)♥", "(っ´▽`)っ♥", "(/^▽^)/♥", "(◍•ᴗ•◍)❤", "♡(˘▽˘>", "(˘⌣˘)♡"]),
        ("반응", ["(°ロ°)", "Σ(°△°)", "¯\\_(ツ)_/¯", "(-_-;)", "m(_ _)m", "(；一_一)", "╰(*°▽°*)╯", "(・o・)"]),
        ("최고", ["ദ്ദിᐢ. .ᐢ₎", "ദ്ദി（• ˕ •マ.ᐟ", "ദ്ദി •⤙• )", "( ദ്ദി ˙ᗜ˙ )",
                  "ჱ̒՞ ̳ᴗ ̫ ᴗ ̳՞꒱", "(՞ •̀֊•́՞)ฅ", "ჱ̒^. ̫ .^）", "ദ്ദി*ˊᗜˋ*)",
                  "( 　'-' )ノദ്ദി)`-' )", "ჱ̒⸝⸝•̀֊•́⸝⸝)", "ദ്ദി  ॑꒳ ॑c)", "ദ്ദിᐢ- ̫-ᐢ₎",
                  "ദ്ദി˙∇˙)ว", "ദ്ദി  ॑꒳ ॑c)", "ദ്ദി（• ˕ •マ.ᐟ", "ദി՞˶ෆ . ෆ˶ ՞",
                  "( ദ്ദി ˙ᗜ˙ )", "👍🏻ᖛ ̫ ᖛ )", "ദ്ദി¯•ω•¯ )", "ദ്ദി•̀.̫•́✧",
                  "ദ്ദി ˘ ͜ʖ ˘)", "ദ്ദി  ͡° ͜ʖ ͡°)", "ദ്ദി❁´◡`❁)",
                  "ദ്ദി * ॑꒳ ॑*)⸝⋆｡✧♡", "ദ്ദി ≽^⎚˕⎚^≼ .ᐟ"]),
    ]
    private var selectedEmoticonCat = 0

    // MARK: - Special Character Data

    private let specialCategories: [(String, [String])] = [
        ("하트",  ["♡", "♥", "❥", "❦", "❧", "☙", "▷♡◁", "♡̴", "ꕤ", "𓆸", "ʚ♡ɞ", "﹤𝟹"]),
        ("별/꽃", ["★", "☆", "✦", "✧", "✿", "❀", "✾", "❁", "✺", "❋", "✹", "✸"]),
        ("화살표", ["→", "←", "↑", "↓", "➜", "➡", "⇒", "⟶", "↩", "↪", "⇄", "↔"]),
        ("장식",  ["•", "·", "°", "※", "†", "‡", "§", "∞", "≈", "≠", "√", "~"]),
    ]
    private var selectedSpecialCat = 0

    // MARK: - Lifecycle

    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
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
                                       })
        case .special:   buildGridMode(categories: specialCategories,
                                       selected: selectedSpecialCat,
                                       cols: 4, fontSize: 22,
                                       onCatChange: { [weak self] i in
                                           self?.selectedSpecialCat = i
                                           self?.showMode(.special)
                                       })
        case .favorites: buildFavoritesMode()
        }
    }

    private func clearContent() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        letterKeys.removeAll()
    }

    // MARK: - Mode Bar

    private func makeModeButton(_ mode: Mode) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(mode.title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
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
        }
    }

    @objc private func modeTapped(_ s: UIButton) {
        showMode(Mode(rawValue: s.tag) ?? .fonts)
    }

    // MARK: - Fonts Mode (QWERTY + Style Picker)

    private func buildFontsMode() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        pinToEdges(stack, in: contentView)

        // Style picker (horizontal scroll)
        let styleScroll = UIScrollView()
        styleScroll.showsHorizontalScrollIndicator = false
        styleScroll.setHeight(32)

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

        for style in FontStyle.allCases {
            let btn = UIButton(type: .system)
            btn.setTitle(style.displayName, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            btn.tag = style.rawValue
            btn.layer.cornerRadius = 14
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
            let sel = style == currentStyle
            btn.backgroundColor = sel ? mainPink : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? .white : .darkGray, for: .normal)
            btn.addTarget(self, action: #selector(styleTapped(_:)), for: .touchUpInside)
            styleRow.addArrangedSubview(btn)
        }
        stack.addArrangedSubview(styleScroll)

        // QWERTY rows
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
                del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
                rowStack.addArrangedSubview(del)
            }
            stack.addArrangedSubview(rowStack)
        }

        // Bottom row: globe + space + return
        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = 6

        let globe = makeSpecialKey("🌐")
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        globe.setWidth(44)
        bottom.addArrangedSubview(globe)

        let space = makeLetterKey("space")
        space.titleLabel?.font = .systemFont(ofSize: 14)
        space.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)
        bottom.addArrangedSubview(space)

        let ret = makeSpecialKey("⏎")
        ret.addTarget(self, action: #selector(returnTapped), for: .touchUpInside)
        ret.setWidth(44)
        bottom.addArrangedSubview(ret)

        stack.addArrangedSubview(bottom)
    }

    // MARK: - Grid Mode (Emoticon / Special)

    private func buildGridMode(categories: [(String, [String])],
                               selected: Int, cols: Int, fontSize: CGFloat,
                               onCatChange: @escaping (Int) -> Void) {
        // Use manual layout instead of outer stack to avoid scrollView collapsing
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        pinToEdges(container, in: contentView)

        // Category tabs (horizontal scroll)
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
            btn.layer.cornerRadius = 14
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)
            let sel = i == selected
            btn.backgroundColor = sel ? mainPink : UIColor(white: 0.92, alpha: 1)
            btn.setTitleColor(sel ? .white : .darkGray, for: .normal)
            btn.tag = i
            btn.addAction(UIAction { _ in onCatChange(i) }, for: .touchUpInside)
            catRow.addArrangedSubview(btn)
        }

        // Bottom bar: globe + backspace
        let bottomBar = UIStackView()
        bottomBar.axis = .horizontal
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomBar)

        let globe = makeSpecialKey("🌐")
        globe.setWidth(44)
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)

        let del = makeSpecialKey("⌫")
        del.setWidth(44)
        del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)

        bottomBar.addArrangedSubview(globe)
        bottomBar.addArrangedSubview(UIView()) // spacer
        bottomBar.addArrangedSubview(del)

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
            bottomBar.heightAnchor.constraint(equalToConstant: 36),
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

        let items = categories[selected].1
        let chunked = stride(from: 0, to: items.count, by: cols).map {
            Array(items[$0..<min($0 + cols, items.count)])
        }

        for row in chunked {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 5
            for item in row {
                let btn = UIButton(type: .system)
                btn.setTitle(item, for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: fontSize)
                btn.titleLabel?.adjustsFontSizeToFitWidth = true
                btn.titleLabel?.minimumScaleFactor = 0.4
                btn.backgroundColor = .white
                btn.layer.cornerRadius = 8
                btn.layer.borderWidth = 0.5
                btn.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
                btn.setTitleColor(.darkGray, for: .normal)
                btn.setHeight(44)
                btn.addTarget(self, action: #selector(gridItemTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(btn)
            }
            // Fill empty cells
            for _ in 0..<(cols - row.count) { rowStack.addArrangedSubview(UIView()) }
            gridStack.addArrangedSubview(rowStack)
        }
    }

    // MARK: - Favorites Mode (♥)

    private func buildFavoritesMode() {
        let outerStack = UIStackView()
        outerStack.axis = .vertical
        outerStack.spacing = 4
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(outerStack)
        pinToEdges(outerStack, in: contentView)

        let label = UILabel()
        label.text = "즐겨찾기가 비어 있습니다"
        label.numberOfLines = 0
        label.textColor = .lightGray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15)
        outerStack.addArrangedSubview(UIView())
        outerStack.addArrangedSubview(label)
        outerStack.addArrangedSubview(UIView())

        // Bottom bar
        let bottomBar = UIStackView()
        bottomBar.axis = .horizontal
        let globe = makeSpecialKey("🌐")
        globe.setWidth(44)
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        bottomBar.addArrangedSubview(globe)
        bottomBar.addArrangedSubview(UIView())
        bottomBar.setHeight(36)
        outerStack.addArrangedSubview(bottomBar)
    }

    // MARK: - Key Actions

    @objc private func letterTapped(_ s: UIButton) {
        guard var ch = s.title(for: .normal) else { return }
        if isShifted { ch = ch.uppercased() }
        let converted = convertText(ch, style: currentStyle)
        textDocumentProxy.insertText(converted)
        tapFeedback(s)
        if isShifted { isShifted = false; updateKeyLabels() }
    }

    @objc private func spaceTapped() {
        textDocumentProxy.insertText(" ")
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

    @objc private func styleTapped(_ s: UIButton) {
        currentStyle = FontStyle(rawValue: s.tag) ?? .normal
        showMode(.fonts)
    }

    @objc private func gridItemTapped(_ s: UIButton) {
        guard let text = s.title(for: .normal) else { return }
        textDocumentProxy.insertText(text)
        tapFeedback(s)
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
        UIView.animate(withDuration: 0.05, animations: {
            btn.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            btn.backgroundColor = mainPink.withAlphaComponent(0.15)
        }) { _ in
            UIView.animate(withDuration: 0.05) {
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

// MARK: - UIView Size Helpers

private extension UIView {
    func setHeight(_ h: CGFloat) {
        heightAnchor.constraint(equalToConstant: h).isActive = true
    }
    func setWidth(_ w: CGFloat) {
        widthAnchor.constraint(equalToConstant: w).isActive = true
    }
}
