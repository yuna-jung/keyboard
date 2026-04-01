import UIKit

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Constants
// ═══════════════════════════════════════════════════════════════════════════════

private let appGroupID  = "group.com.yourapp.fontkeyboard"
private let pinkColor   = UIColor(red: 1.0, green: 0.42, blue: 0.62, alpha: 1.0)
private let keyBG       = UIColor.white
private let specialKeyBG = UIColor(white: 0.78, alpha: 1)

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - KeyboardViewController
// ═══════════════════════════════════════════════════════════════════════════════

class KeyboardViewController: UIInputViewController {

    // ── Mode ────────────────────────────────────────────────────────────────
    enum Mode: Int, CaseIterable {
        case fonts = 0, emoticon, special, favorites
        var title: String {
            switch self {
            case .fonts:     return "Aa"
            case .emoticon:  return "(◕‿◕)"
            case .special:   return "★"
            case .favorites: return "♥"
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
                 "✪‿✪","꜆₍ᐢ˶•ᴗ•˶ᐢ₎꜆","( ՞ෆ ෆ՞ )"]),
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
                 "/ᐠ •̀ ˕ •́ マ","ʕ•̀ ω •́ʔ.:"]),
        ("동물", ["(=^･ω･^=)","(◕ᴥ◕)","ʕ•ᴥ•ʔ","(ΦωΦ)","ʕ·ᴥ·ʔ",
                 "(U・ω・U)","(=①ω①=)","(・⊝・)","≧◉ᴥ◉≦",
                 "(ᵔᴥᵔ)","₍ᐢ..ᐢ₎","ᘛ⁐̤ᕐᐷ"]),
        ("사랑", ["(♥ω♥)","(づ￣ ³￣)づ","(灬♥ω♥灬)","(*˘︶˘*).｡*♡",
                 "(◍•ᴗ•◍)❤","(♡°▽°♡)","(✿ ♥‿♥)","( ˘ ³˘)♥",
                 "(❤ω❤)","♡＾▽＾♡","(´,,•ω•,,)♡","(⺣◡⺣)♡*"]),
        ("최고", ["ദ്ദിᐢ. .ᐢ₎","ദ്ദി（• ˕ •マ.ᐟ","ദ്ദി •⤙• )","( ദ്ദി ˙ᗜ˙ )",
                 "ჱ̒՞ ̳ᴗ ̫ ᴗ ̳՞꒱","(՞ •̀֊•́՞)ฅ","ჱ̒^. ̫ .^）","ദ്ദി*ˊᗜˋ*)",
                 "( 　'-' )ノദ്ദി)`-' )","ჱ̒⸝⸝•̀֊•́⸝⸝)","ദ്ദി  ॑꒳ ॑c)","ദ്ദിᐢ- ̫-ᐢ₎",
                 "ദ്ദി˙∇˙)ว","ദ്ദി  ॑꒳ ॑c)","ദ്ദി（• ˕ •マ.ᐟ","ദി՞˶ෆ . ෆ˶ ՞",
                 "( ദ്ദി ˙ᗜ˙ )","👍🏻ᖛ ̫ ᖛ )","ദ്ദി¯•ω•¯ )","ദ്ദി•̀.̫•́✧",
                 "ദ്ദി ˘ ͜ʖ ˘)","ദ്ദി  ͡° ͜ʖ ͡°)","ദ്ദി❁´◡`❁)",
                 "ദ്ദി * ॑꒳ ॑*)⸝⋆｡✧♡","ദ്ദി ≽^⎚˕⎚^≼ .ᐟ"]),
    ]
    private var selectedEmoticonCat = 0

    // ── Special Chars ───────────────────────────────────────────────────────
    private let specialCategories: [(String, [String])] = [
        ("화살표", ["→","←","↑","↓","➜","➡","⇒","⟶","↩","↪",
                  "↗","↘","↙","↖","⤴","⤵","➤","↔","⇔","⟷"]),
        ("도형",  ["■","□","▲","△","▼","▽","◆","◇","●","○",
                  "◉","◎","★","☆","▶","◀","▷","◁","⬤","◈"]),
        ("하트",  ["♡","♥","❥","❦","❧","☙","▷♡◁",
                  "♡̴","ꕤ","𓆸","ʚ♡ɞ","﹤𝟹"]),
        ("별/꽃", ["✿","❀","✾","❁","✦","✧","❋","✺","✵","✶",
                  "✷","✸","❂","❃","✻","❄","❅","❆","✱","※"]),
        ("수학",  ["±","×","÷","≠","≈","≤","≥","∞","√","∑",
                  "∏","∫","∂","∆","∇","∈","∅","⊂","⊃","⊥"]),
    ]
    private var selectedSpecialCat = 0

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
        case .favorites: buildFavoritesMode()
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
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
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
                btn.setHeight(42)
                btn.addTarget(self, action: #selector(gridTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(btn)
            }
            for _ in 0..<(cols - row.count) { rowStack.addArrangedSubview(UIView()) }
            gridStack.addArrangedSubview(rowStack)
        }
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
