// MARK: - GifSearchKeypad
//
// A small, fully self-contained 두벌식-Hangul + English QWERTY keypad used
// only by the GIF tab's search box.
//
// Deliberately NOT sharing any code with the fonts-tab keypad or the
// translate-tab input routing (`letterTapped`, `handleHangulInput`,
// `translateTargetAppend`, the shared `hgCho`/`hgJung`/`hgJong` composer
// state, etc. in KeyboardViewController.swift) — this view owns its own
// copy of the Hangul composition tables and its own composer state, so
// nothing typed here can ever leave the shared translate/fonts composer in
// a half-finished state, and nothing here can regress those tabs. This is
// an intentional trade-off: some duplicated logic in exchange for this
// feature being impossible to entangle with the two already-stabilized
// tabs.
//
// Output never touches `textDocumentProxy` — it only ever updates this
// view's own `text` property (via the delegate), which the GIF tab uses as
// the Giphy search query. There is no first-responder/system-keyboard
// involvement at all: a keyboard extension can't summon a system keyboard
// for its own text fields, so every tap is routed through this view's own
// on-screen buttons, same as the rest of this app's custom keyboards.

import UIKit

protocol GifSearchKeypadDelegate: AnyObject {
    /// Fired on every text change (each tap that mutates the buffer).
    func gifSearchKeypad(_ keypad: GifSearchKeypadView, didChangeText text: String)
    /// Fired when the user taps the "검색" (search) key.
    func gifSearchKeypadDidRequestSearch(_ keypad: GifSearchKeypadView, text: String)
}

final class GifSearchKeypadView: UIView {
    weak var delegate: GifSearchKeypadDelegate?

    private(set) var text: String = "" {
        didSet { delegate?.gifSearchKeypad(self, didChangeText: text) }
    }

    /// Replaces the current buffer (e.g. re-opening the keypad after a
    /// previous search) without notifying the delegate — the caller already
    /// knows the text since it's the one supplying it.
    func setText(_ newText: String) {
        text = newText
        isShifted = false
        hgFlush()
        rebuildLetterRows()
    }

    private var isKorean = true
    private var isShifted = false

    // ── Hangul Composition Engine (own copy — see file header) ──────────
    private var hgCho = -1
    private var hgJung = -1
    private var hgJong = 0

    private let CHO: [String] = ["ㄱ","ㄲ","ㄴ","ㄷ","ㄸ","ㄹ","ㅁ","ㅂ","ㅃ","ㅅ","ㅆ","ㅇ","ㅈ","ㅉ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"]
    private let JUNG: [String] = ["ㅏ","ㅐ","ㅑ","ㅒ","ㅓ","ㅔ","ㅕ","ㅖ","ㅗ","ㅘ","ㅙ","ㅚ","ㅛ","ㅜ","ㅝ","ㅞ","ㅟ","ㅠ","ㅡ","ㅢ","ㅣ"]
    private let JONG: [String] = ["","ㄱ","ㄲ","ㄳ","ㄴ","ㄵ","ㄶ","ㄷ","ㄹ","ㄺ","ㄻ","ㄼ","ㄽ","ㄾ","ㄿ","ㅀ","ㅁ","ㅂ","ㅄ","ㅅ","ㅆ","ㅇ","ㅈ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"]
    private let CJ: [String: Int] = [
        "8,0":9, "8,1":10, "8,20":11,
        "13,4":14, "13,5":15, "13,20":16,
        "18,20":19,
    ]
    private let CK: [String: Int] = [
        "1,ㅅ":3, "4,ㅈ":5, "4,ㅎ":6,
        "8,ㄱ":9, "8,ㅁ":10, "8,ㅂ":11, "8,ㅅ":12, "8,ㅌ":13, "8,ㅍ":14, "8,ㅎ":15,
        "17,ㅅ":18,
    ]
    private let J2C: [Int: Int] = [
        1:0, 2:1, 4:2, 7:3, 8:5, 16:6, 17:7, 19:9, 20:10, 21:11, 22:12, 23:14, 24:15, 25:16, 26:17, 27:18
    ]
    private let JSP: [Int: (Int, Int)] = [
        3:(1,9), 5:(4,12), 6:(4,18),
        9:(8,0), 10:(8,6), 11:(8,7), 12:(8,9), 13:(8,16), 14:(8,17), 15:(8,18),
        18:(17,9),
    ]

    private func hgFlush() { hgCho = -1; hgJung = -1; hgJong = 0 }

    private func hgCompose() -> String {
        if hgCho >= 0 && hgJung >= 0 {
            return String(UnicodeScalar(0xAC00 + hgCho * 21 * 28 + hgJung * 28 + hgJong)!)
        } else if hgCho >= 0 {
            return CHO[hgCho]
        }
        return ""
    }

    private func appendText(_ s: String) { text += s }
    private func removeLastText() { if !text.isEmpty { text.removeLast() } }
    private func replaceLastText(_ s: String) { removeLastText(); appendText(s) }

    private func handleHangulInput(_ key: String) {
        let ci = CHO.firstIndex(of: key)
        let ji = JUNG.firstIndex(of: key)
        let isCon = ci != nil
        let isVow = ji != nil

        if hgCho < 0 {
            if isCon {
                hgCho = ci!
                appendText(hgCompose())
            } else if isVow {
                hgFlush()
                appendText(key)
            }
            return
        }

        if hgJung < 0 {
            if isVow {
                hgJung = ji!
                replaceLastText(hgCompose())
            } else if isCon {
                hgFlush()
                hgCho = ci!
                appendText(hgCompose())
            }
            return
        }

        if hgJong == 0 {
            if isVow {
                if let cj = CJ["\(hgJung),\(ji!)"] {
                    hgJung = cj
                    replaceLastText(hgCompose())
                    return
                }
                hgFlush()
                appendText(key)
            } else if isCon {
                let jIdx = JONG.firstIndex(of: key)
                if let jIdx = jIdx, jIdx > 0 {
                    hgJong = jIdx
                    replaceLastText(hgCompose())
                } else {
                    hgFlush()
                    hgCho = ci!
                    appendText(hgCompose())
                }
            }
            return
        }

        if isVow {
            if let split = JSP[hgJong] {
                hgJong = split.0
                replaceLastText(hgCompose())
                hgFlush()
                hgCho = split.1
                hgJung = ji!
                appendText(hgCompose())
            } else if let newCho = J2C[hgJong] {
                hgJong = 0
                replaceLastText(hgCompose())
                hgFlush()
                hgCho = newCho
                hgJung = ji!
                appendText(hgCompose())
            } else {
                hgFlush()
                appendText(key)
            }
        } else if isCon {
            if let ck = CK["\(hgJong),\(key)"] {
                hgJong = ck
                replaceLastText(hgCompose())
                return
            }
            hgFlush()
            hgCho = ci!
            appendText(hgCompose())
        }
    }

    private func handleHangulDelete() {
        if hgCho < 0 {
            removeLastText()
            return
        }
        if hgJong > 0 {
            if let split = JSP[hgJong] {
                hgJong = split.0
            } else {
                hgJong = 0
            }
            replaceLastText(hgCompose())
        } else if hgJung >= 0 {
            var found = false
            for (k, v) in CJ where v == hgJung {
                let parts = k.split(separator: ",")
                hgJung = Int(parts[0])!
                found = true
                break
            }
            if !found { hgJung = -1 }
            replaceLastText(hgCompose())
        } else {
            removeLastText()
            hgFlush()
        }
    }

    // ── Layouts ───────────────────────────────────────────────────────
    private let korN: [[String]] = [
        ["ㅂ","ㅈ","ㄷ","ㄱ","ㅅ","ㅛ","ㅕ","ㅑ","ㅐ","ㅔ"],
        ["ㅁ","ㄴ","ㅇ","ㄹ","ㅎ","ㅗ","ㅓ","ㅏ","ㅣ"],
        ["ㅋ","ㅌ","ㅊ","ㅍ","ㅠ","ㅜ","ㅡ"],
    ]
    private let korS: [[String]] = [
        ["ㅃ","ㅉ","ㄸ","ㄲ","ㅆ","ㅛ","ㅕ","ㅑ","ㅒ","ㅖ"],
        ["ㅁ","ㄴ","ㅇ","ㄹ","ㅎ","ㅗ","ㅓ","ㅏ","ㅣ"],
        ["ㅋ","ㅌ","ㅊ","ㅍ","ㅠ","ㅜ","ㅡ"],
    ]
    private let qwertyRows: [[String]] = [
        ["q","w","e","r","t","y","u","i","o","p"],
        ["a","s","d","f","g","h","j","k","l"],
        ["z","x","c","v","b","n","m"],
    ]

    // ── UI ────────────────────────────────────────────────────────────
    private let accentColor: UIColor
    private let searchButtonTitle: String
    private var lettersWrapper: UIStackView?
    private var shiftButton: UIButton?
    private var langToggleButton: UIButton?

    init(accentColor: UIColor, searchButtonTitle: String) {
        self.accentColor = accentColor
        self.searchButtonTitle = searchButtonTitle
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 0.95, alpha: 1)
        buildStaticLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let outerStack = UIStackView()

    private func buildStaticLayout() {
        outerStack.axis = .vertical
        outerStack.spacing = 4
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(outerStack)
        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            outerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            outerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            outerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
        ])
        rebuildLetterRows()
    }

    private func rebuildLetterRows() {
        outerStack.arrangedSubviews.forEach {
            outerStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let wrapper = UIStackView()
        wrapper.axis = .vertical
        wrapper.distribution = .fillEqually
        wrapper.spacing = 3
        lettersWrapper = wrapper

        let rows: [[String]] = isKorean ? (isShifted ? korS : korN) : qwertyRows
        for (ri, row) in rows.enumerated() {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 4

            if ri == 2 {
                let shift = makeKey("⇧", isSpecial: true)
                shift.backgroundColor = isShifted ? accentColor : UIColor(white: 0.85, alpha: 1)
                shift.setTitleColor(isShifted ? .white : .darkGray, for: .normal)
                shift.addTarget(self, action: #selector(shiftTapped), for: .touchUpInside)
                shiftButton = shift
                rowStack.addArrangedSubview(shift)
            }

            for key in row {
                let label = (!isKorean && isShifted) ? key.uppercased() : key
                let btn = makeKey(label, isSpecial: false)
                btn.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(btn)
            }

            if ri == 2 {
                let del = makeKey("⌫", isSpecial: true)
                del.backgroundColor = UIColor(white: 0.85, alpha: 1)
                del.setTitleColor(.darkGray, for: .normal)
                del.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
                rowStack.addArrangedSubview(del)
            }
            wrapper.addArrangedSubview(rowStack)
        }
        outerStack.addArrangedSubview(wrapper)

        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = 4
        bottom.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let lang = makeKey(isKorean ? "En" : "Ko", isSpecial: true)
        lang.backgroundColor = UIColor(white: 0.85, alpha: 1)
        lang.setTitleColor(.darkGray, for: .normal)
        lang.addTarget(self, action: #selector(langToggleTapped), for: .touchUpInside)
        langToggleButton = lang
        bottom.addArrangedSubview(lang)
        lang.widthAnchor.constraint(equalToConstant: 52).isActive = true

        let space = makeKey("space", isSpecial: false)
        // Letter keys use a larger font sized for a single jamo/character
        // (see `makeKey`); "space" is a 5-letter word, so it needs its own
        // smaller size to look proportionate rather than oversized.
        space.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        space.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)
        bottom.addArrangedSubview(space)

        let search = makeKey(searchButtonTitle, isSpecial: true)
        search.backgroundColor = accentColor
        search.setTitleColor(.white, for: .normal)
        search.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        search.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        bottom.addArrangedSubview(search)
        search.widthAnchor.constraint(equalToConstant: 64).isActive = true

        outerStack.addArrangedSubview(bottom)
    }

    private func makeKey(_ title: String, isSpecial: Bool) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: isSpecial ? 14 : 20, weight: isSpecial ? .semibold : .regular)
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        if !isSpecial {
            btn.backgroundColor = .white
            btn.setTitleColor(.black, for: .normal)
        }
        btn.layer.cornerRadius = 6
        btn.layer.masksToBounds = true
        return btn
    }

    // ── Handlers ─────────────────────────────────────────────────────
    @objc private func letterTapped(_ sender: UIButton) {
        guard let ch = sender.title(for: .normal) else { return }
        if isKorean {
            handleHangulInput(ch)
        } else {
            appendText(ch)
        }
        if isShifted {
            isShifted = false
            rebuildLetterRows()
        }
    }

    @objc private func backspaceTapped() {
        if isKorean {
            handleHangulDelete()
        } else {
            removeLastText()
        }
    }

    @objc private func spaceTapped() {
        hgFlush()
        appendText(" ")
    }

    @objc private func shiftTapped() {
        isShifted.toggle()
        rebuildLetterRows()
    }

    @objc private func langToggleTapped() {
        hgFlush()
        isKorean.toggle()
        isShifted = false
        rebuildLetterRows()
    }

    @objc private func searchTapped() {
        hgFlush()
        delegate?.gifSearchKeypadDidRequestSearch(self, text: text)
    }
}
