package com.yunajung.fonki

import android.annotation.SuppressLint
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.inputmethodservice.InputMethodService
import android.os.Handler
import android.os.Looper
import android.text.InputType
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import org.json.JSONArray

/**
 * Fonkii Android IME — port of the iOS keyboard extension at
 * `ios/font_keyboard/KeyboardViewController.swift`.
 *
 * Aa tab streams each keypress through [FontConverter.convert] with the
 * currently-selected style and commits directly to the host (no preview,
 * no buffered "insert" step).
 *
 * The ⌫ key on every tab supports tap-to-delete-once and hold-to-repeat
 * (50ms cadence, identical to a hardware key repeat) via the shared
 * [deleteRepeater] runnable.
 */
class FonkiiKeyboardService : InputMethodService() {

    enum class Mode { FONTS, EMOTICON, SPECIAL, DOT_ART, GIF, FAVORITES, CALCULATOR, PALETTE }

    // ── Theme ────────────────────────────────────────────────────────────
    private val PINK = Color.parseColor("#FF6BA0")
    private val DARK_TEXT = Color.parseColor("#222222")
    private val LIGHT_GRAY = Color.parseColor("#F5F5F5")
    private val BORDER = Color.parseColor("#DDDDDD")

    // ── View references ──────────────────────────────────────────────────
    private var rootView: View? = null
    private var tabBar: LinearLayout? = null
    private var keypadArea: FrameLayout? = null
    private val tabButtons = mutableListOf<Pair<TextView, Mode>>()

    // ── Per-tab state ────────────────────────────────────────────────────
    private var currentMode = Mode.FONTS
    private var fontCatIndex = 0
    private var fontStyleIndex = 0
    private var isShifted = false
    private var emoticonCatIndex = 0
    private var specialCatIndex = 0

    // Calculator state
    private var calcDisplay = "0"
    private var calcExpression = ""
    private var calcPrev: Double? = null
    private var calcOp: String? = null
    private var calcJustEvaluated = false

    // ── Long-press delete plumbing ───────────────────────────────────────
    private val deleteHandler = Handler(Looper.getMainLooper())
    private val deleteRepeater = object : Runnable {
        override fun run() {
            currentInputConnection?.deleteSurroundingText(1, 0)
            deleteHandler.postDelayed(this, 50L)
        }
    }

    // ── Lifecycle ────────────────────────────────────────────────────────
    override fun onCreateInputView(): View {
        val v = layoutInflater.inflate(R.layout.keyboard_view, null)
        rootView = v
        tabBar = v.findViewById(R.id.tab_bar)
        keypadArea = v.findViewById(R.id.keypad_area)
        buildTabBar()
        showMode(Mode.FONTS)
        return v
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        super.onFinishInputView(finishingInput)
        // Always cancel any in-flight repeating delete when the IME hides.
        deleteHandler.removeCallbacks(deleteRepeater)
    }

    // ── Tab bar ──────────────────────────────────────────────────────────
    private fun buildTabBar() {
        val bar = tabBar ?: return
        bar.removeAllViews()
        tabButtons.clear()
        val tabs = listOf(
            "Aa" to Mode.FONTS,
            "😀" to Mode.EMOTICON,
            "✦" to Mode.SPECIAL,
            "도트" to Mode.DOT_ART,
            "GIF" to Mode.GIF,
            "♥" to Mode.FAVORITES,
            "계산" to Mode.CALCULATOR,
            "🎨" to Mode.PALETTE,
        )
        for ((label, mode) in tabs) {
            val btn = TextView(this).apply {
                text = label
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                gravity = Gravity.CENTER
                setPadding(dp(14), dp(6), dp(14), dp(6))
                setOnClickListener { showMode(mode) }
            }
            val lp = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            bar.addView(btn, lp)
            tabButtons += btn to mode
        }
    }

    private fun updateTabHighlight() {
        for ((btn, mode) in tabButtons) {
            val selected = mode == currentMode
            btn.setTextColor(if (selected) PINK else DARK_TEXT)
            btn.background = if (selected) {
                GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    cornerRadius = dp(16).toFloat()
                    setColor(Color.parseColor("#FFEAF2"))
                }
            } else null
        }
    }

    // ── Mode switching ───────────────────────────────────────────────────
    private fun showMode(mode: Mode) {
        currentMode = mode
        // Cancel any repeating delete from a previous tab before tearing down.
        deleteHandler.removeCallbacks(deleteRepeater)
        updateTabHighlight()
        val area = keypadArea ?: return
        area.removeAllViews()
        when (mode) {
            Mode.FONTS -> buildFontsView(area)
            Mode.EMOTICON -> buildGridView(area, KeyboardData.emoticonCategories, emoticonCatIndex,
                cols = 3) { emoticonCatIndex = it; showMode(Mode.EMOTICON) }
            Mode.SPECIAL -> buildGridView(area, KeyboardData.specialCategories, specialCatIndex,
                cols = 5) { specialCatIndex = it; showMode(Mode.SPECIAL) }
            Mode.DOT_ART -> buildDotArtView(area)
            Mode.GIF -> buildGifView(area)
            Mode.FAVORITES -> buildFavoritesView(area)
            Mode.CALCULATOR -> buildCalculatorView(area)
            Mode.PALETTE -> buildPaletteView(area)
        }
    }

    // ── Aa (Fonts) ───────────────────────────────────────────────────────
    private fun buildFontsView(area: FrameLayout) {
        val root = vlinear()

        // Defensive bounds — categories/styles never shrink in normal flow,
        // but keep the index sane after data edits.
        val cats = FontConverter.fontCategories
        if (fontCatIndex !in cats.indices) fontCatIndex = 0
        val currentCat = cats[fontCatIndex]
        if (fontStyleIndex !in FontConverter.fontStyles.indices) fontStyleIndex = 0
        var activeStyle = FontConverter.fontStyles[fontStyleIndex]
        // If the current style isn't in the current category (e.g. user just
        // tapped a new category and we haven't snapped yet), default to the
        // category's first entry.
        if (activeStyle !in currentCat.styles) {
            fontStyleIndex = FontConverter.fontStyles.indexOf(currentCat.styles.first())
            activeStyle = FontConverter.fontStyles[fontStyleIndex]
        }
        val style = activeStyle

        // 1) Category scroll bar (클래식 / 모던 / 굵게 / …).
        val catScroll = HorizontalScrollView(this).apply { isHorizontalScrollBarEnabled = false }
        val catRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        for ((idx, cat) in cats.withIndex()) {
            val isSelected = idx == fontCatIndex
            val btn = TextView(this).apply {
                text = cat.name
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                setTextColor(if (isSelected) Color.WHITE else DARK_TEXT)
                background = roundedBg(
                    if (isSelected) PINK else Color.WHITE,
                    dp(14).toFloat(),
                    if (isSelected) PINK else BORDER
                )
                setPadding(dp(12), dp(6), dp(12), dp(6))
                setOnClickListener {
                    fontCatIndex = idx
                    val tappedCat = cats[idx]
                    val keepStyle = FontConverter.fontStyles[fontStyleIndex] in tappedCat.styles
                    if (!keepStyle) {
                        fontStyleIndex = FontConverter.fontStyles.indexOf(tappedCat.styles.first())
                    }
                    showMode(Mode.FONTS)
                }
            }
            catRow.addView(btn, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(dp(4), 0, dp(4), 0) })
        }
        catScroll.addView(catRow)
        root.addView(catScroll, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(34)
        ).apply { setMargins(dp(4), dp(4), dp(4), dp(2)) })

        // 2) Style scroll bar — only the styles in the active category.
        //    Each pill renders its own name *through* its converter so the user
        //    sees a live preview (e.g. Bold's button literally shows "𝐁𝐨𝐥𝐝").
        val styleScroll = HorizontalScrollView(this).apply { isHorizontalScrollBarEnabled = false }
        val styleRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        for (st in currentCat.styles) {
            val isSelected = st == activeStyle
            val styledLabel = FontConverter.convert(st.name, st)
            val btn = TextView(this).apply {
                text = styledLabel
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                setTextColor(if (isSelected) Color.WHITE else DARK_TEXT)
                background = roundedBg(
                    if (isSelected) PINK else Color.WHITE,
                    dp(14).toFloat(),
                    if (isSelected) PINK else BORDER
                )
                setPadding(dp(12), dp(6), dp(12), dp(6))
                setOnClickListener {
                    fontStyleIndex = FontConverter.fontStyles.indexOf(st)
                    showMode(Mode.FONTS)
                }
            }
            styleRow.addView(btn, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(dp(4), 0, dp(4), 0) })
        }
        styleScroll.addView(styleRow)
        root.addView(styleScroll, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(36)
        ).apply { setMargins(dp(4), dp(2), dp(4), dp(4)) })

        // QWERTY keypad. Each non-modifier tap immediately converts the single
        // tapped letter through the active style and commits to the host —
        // no preview, no buffer, no "insert" button.
        val rows = listOf(
            "qwertyuiop".toCharArray().map { it.toString() },
            "asdfghjkl".toCharArray().map { it.toString() },
            listOf("⇧") + "zxcvbnm".toCharArray().map { it.toString() } + listOf("⌫")
        )
        for (row in rows) {
            val rowLayout = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
            }
            for (label in row) {
                val isShift = label == "⇧"
                val isBackspace = label == "⌫"
                val displayLabel = when {
                    isShift -> "⇧"
                    isBackspace -> "⌫"
                    isShifted -> label.uppercase()
                    else -> label
                }
                val btn = makeKey(displayLabel, isWide = isShift || isBackspace) {
                    when {
                        isShift -> { isShifted = !isShifted; showMode(Mode.FONTS) }
                        isBackspace -> { /* handled by bindDeleteButton below */ }
                        else -> {
                            val ch = if (isShifted) label.uppercase() else label
                            commit(FontConverter.convert(ch, style))
                            if (isShifted) {
                                isShifted = false
                                showMode(Mode.FONTS)
                            }
                        }
                    }
                }
                if (isBackspace) bindDeleteButton(btn)
                val lp = LinearLayout.LayoutParams(
                    0, dp(38), if (isShift || isBackspace) 1.5f else 1f
                ).apply { setMargins(dp(2), dp(2), dp(2), dp(2)) }
                rowLayout.addView(btn, lp)
            }
            root.addView(rowLayout, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ))
        }

        // Bottom bar: 🌐 / space / ⏎ (no "삽입" — keys commit immediately).
        val bottom = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        val globe = makeKey("🌐", isWide = false) { switchToNextInputMethod() }
        bottom.addView(globe, LinearLayout.LayoutParams(0, dp(40), 1f).apply {
            setMargins(dp(2), dp(4), dp(2), dp(2))
        })
        val space = makeKey("space", isWide = false) {
            commit(FontConverter.convert(" ", style))
        }
        bottom.addView(space, LinearLayout.LayoutParams(0, dp(40), 5f).apply {
            setMargins(dp(2), dp(4), dp(2), dp(2))
        })
        val enter = makeKey("⏎", isWide = false) { commit("\n") }
        bottom.addView(enter, LinearLayout.LayoutParams(0, dp(40), 1f).apply {
            setMargins(dp(2), dp(4), dp(2), dp(2))
        })
        root.addView(bottom, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ))

        area.addView(root, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ))
    }

    // ── Grid (emoticon + special) ────────────────────────────────────────
    private fun buildGridView(
        area: FrameLayout,
        categories: List<Pair<String, List<String>>>,
        selected: Int,
        cols: Int,
        onCatChange: (Int) -> Unit
    ) {
        val root = vlinear()

        val catScroll = HorizontalScrollView(this).apply { isHorizontalScrollBarEnabled = false }
        val catRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        for ((idx, pair) in categories.withIndex()) {
            val btn = TextView(this).apply {
                text = pair.first
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                setTextColor(if (idx == selected) Color.WHITE else DARK_TEXT)
                background = roundedBg(
                    if (idx == selected) PINK else Color.WHITE,
                    dp(14).toFloat(),
                    if (idx == selected) PINK else BORDER
                )
                setPadding(dp(12), dp(6), dp(12), dp(6))
                setOnClickListener { onCatChange(idx) }
            }
            catRow.addView(btn, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(dp(4), 0, dp(4), 0) })
        }
        catScroll.addView(catRow)
        root.addView(catScroll, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(36)
        ).apply { setMargins(0, dp(4), 0, dp(4)) })

        val items = categories.getOrNull(selected)?.second ?: emptyList()
        val scroll = ScrollView(this)
        val grid = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        items.chunked(cols).forEach { chunk ->
            val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            for (item in chunk) {
                val btn = TextView(this).apply {
                    text = item
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, if (cols >= 5) 16f else 13f)
                    gravity = Gravity.CENTER
                    setTextColor(DARK_TEXT)
                    setPadding(dp(4), dp(8), dp(4), dp(8))
                    background = roundedBg(Color.WHITE, dp(8).toFloat(), BORDER)
                    setOnClickListener { commit(item) }
                }
                row.addView(btn, LinearLayout.LayoutParams(0, dp(48), 1f).apply {
                    setMargins(dp(3), dp(3), dp(3), dp(3))
                })
            }
            for (pad in chunk.size until cols) {
                row.addView(View(this), LinearLayout.LayoutParams(0, dp(48), 1f).apply {
                    setMargins(dp(3), dp(3), dp(3), dp(3))
                })
            }
            grid.addView(row, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ))
        }
        scroll.addView(grid, ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ))
        root.addView(scroll, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f
        ))
        root.addView(buildBottomBar())
        area.addView(root, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ))
    }

    // ── Dot Art ──────────────────────────────────────────────────────────
    private fun buildDotArtView(area: FrameLayout) {
        val root = vlinear()
        val items = KeyboardData.dotArtCategories.firstOrNull()?.second ?: emptyList()
        val scroll = ScrollView(this)
        val list = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        for (text in items) {
            val card = TextView(this).apply {
                this.text = text
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 8f)
                typeface = android.graphics.Typeface.MONOSPACE
                setTextColor(DARK_TEXT)
                gravity = Gravity.CENTER
                setPadding(dp(8), dp(8), dp(8), dp(8))
                background = roundedBg(Color.WHITE, dp(10).toFloat(), BORDER)
                setOnClickListener { copyToClipboard(text, "도트아트가 복사되었어요") }
            }
            list.addView(card, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(dp(8), dp(4), dp(8), dp(4)) })
        }
        scroll.addView(list, ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ))
        root.addView(scroll, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f
        ))
        root.addView(buildBottomBar())
        area.addView(root, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ))
    }

    // ── GIF (search + categories scaffold) ───────────────────────────────
    private fun buildGifView(area: FrameLayout) {
        val root = vlinear()
        val search = EditText(this).apply {
            hint = "GIF 검색"
            setPadding(dp(12), dp(8), dp(12), dp(8))
            background = roundedBg(LIGHT_GRAY, dp(18).toFloat())
            inputType = InputType.TYPE_CLASS_TEXT
        }
        root.addView(search, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(40)
        ).apply { setMargins(dp(8), dp(6), dp(8), dp(6)) })

        val catScroll = HorizontalScrollView(this).apply { isHorizontalScrollBarEnabled = false }
        val catRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        listOf("인기", "재미있는", "사랑", "슬픔", "반응", "화남").forEach { name ->
            val btn = TextView(this).apply {
                text = name
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                setTextColor(DARK_TEXT)
                background = roundedBg(Color.WHITE, dp(14).toFloat(), BORDER)
                setPadding(dp(12), dp(6), dp(12), dp(6))
                setOnClickListener { showToast("GIF 검색은 준비 중이에요 ($name)") }
            }
            catRow.addView(btn, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(dp(4), 0, dp(4), 0) })
        }
        catScroll.addView(catRow)
        root.addView(catScroll, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(36)
        ))

        val msg = TextView(this).apply {
            text = "GIF 검색 결과가 여기에 표시돼요\n(GIPHY API 키 연동 필요)"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setTextColor(Color.GRAY)
            gravity = Gravity.CENTER
        }
        root.addView(msg, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f
        ).apply { setMargins(dp(8), dp(20), dp(8), dp(20)) })

        root.addView(buildBottomBar())
        area.addView(root, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ))
    }

    // ── Favorites ────────────────────────────────────────────────────────
    private fun buildFavoritesView(area: FrameLayout) {
        val root = vlinear()
        val prefs = getSharedPreferences("fonkii_prefs", Context.MODE_PRIVATE)
        val raw = prefs.getString("favorites_v2", null)
        val items = mutableListOf<String>()
        if (raw != null) {
            try {
                val arr = JSONArray(raw)
                for (i in 0 until arr.length()) items.add(arr.getString(i))
            } catch (_: Exception) {
                // ignore — render empty list
            }
        }

        if (items.isEmpty()) {
            val empty = TextView(this).apply {
                text = "즐겨찾기가 비어있어요\n이모티콘이나 특수문자를 길게 눌러 추가해보세요"
                gravity = Gravity.CENTER
                setTextColor(Color.GRAY)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            }
            root.addView(empty, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f
            ).apply { setMargins(dp(8), dp(20), dp(8), dp(20)) })
        } else {
            val scroll = ScrollView(this)
            val list = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
            for (item in items) {
                val btn = TextView(this).apply {
                    text = item
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                    setTextColor(DARK_TEXT)
                    setPadding(dp(12), dp(10), dp(12), dp(10))
                    background = roundedBg(Color.WHITE, dp(8).toFloat(), BORDER)
                    setOnClickListener { commit(item) }
                }
                list.addView(btn, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ).apply { setMargins(dp(8), dp(3), dp(8), dp(3)) })
            }
            scroll.addView(list, ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ))
            root.addView(scroll, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f
            ))
        }
        root.addView(buildBottomBar())
        area.addView(root, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ))
    }

    // ── Calculator ───────────────────────────────────────────────────────
    private fun buildCalculatorView(area: FrameLayout) {
        val root = vlinear()
        val expr = TextView(this).apply {
            text = calcExpression
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setTextColor(Color.GRAY)
            gravity = Gravity.END
            setPadding(dp(12), dp(2), dp(12), dp(0))
        }
        root.addView(expr, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(20)
        ))
        val display = TextView(this).apply {
            text = calcDisplay
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 28f)
            setTextColor(DARK_TEXT)
            gravity = Gravity.END
            setPadding(dp(12), dp(0), dp(12), dp(6))
            background = roundedBg(LIGHT_GRAY, dp(8).toFloat())
        }
        root.addView(display, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(50)
        ).apply { setMargins(dp(8), dp(2), dp(8), dp(6)) })

        val rows = listOf(
            listOf("AC", "+/-", "%", "÷"),
            listOf("7", "8", "9", "×"),
            listOf("4", "5", "6", "−"),
            listOf("1", "2", "3", "+"),
            listOf("0", ".", "삽입", "="),
        )
        for (row in rows) {
            val rl = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            for (key in row) {
                val isOp = key in listOf("÷", "×", "−", "+", "=")
                val isFn = key in listOf("AC", "+/-", "%", "삽입")
                val btn = TextView(this).apply {
                    text = key
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                    gravity = Gravity.CENTER
                    setTextColor(Color.WHITE)
                    background = roundedBg(
                        when {
                            isOp -> PINK
                            isFn -> Color.parseColor("#A5A5A5")
                            else -> Color.parseColor("#333333")
                        },
                        dp(20).toFloat()
                    )
                    setOnClickListener { onCalcKey(key) }
                }
                rl.addView(btn, LinearLayout.LayoutParams(0, dp(40), 1f).apply {
                    setMargins(dp(3), dp(3), dp(3), dp(3))
                })
            }
            root.addView(rl, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ))
        }
        root.addView(buildBottomBar())
        area.addView(root, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ))
    }

    private fun onCalcKey(key: String) {
        when (key) {
            in listOf("0", "1", "2", "3", "4", "5", "6", "7", "8", "9") -> {
                if (calcJustEvaluated) {
                    calcDisplay = "0"
                    calcJustEvaluated = false
                    if (calcPrev == null) calcExpression = ""
                }
                calcDisplay = if (calcDisplay == "0") key else calcDisplay + key
            }
            "." -> if (!calcDisplay.contains(".")) calcDisplay += "."
            "AC" -> {
                calcDisplay = "0"; calcExpression = ""
                calcPrev = null; calcOp = null; calcJustEvaluated = false
            }
            "+/-" -> calcDisplay.toDoubleOrNull()?.let { calcDisplay = formatCalc(-it) }
            "%" -> calcDisplay.toDoubleOrNull()?.let { calcDisplay = formatCalc(it / 100.0) }
            "+", "−", "×", "÷" -> {
                calcDisplay.toDoubleOrNull()?.let { d ->
                    calcExpression += "$calcDisplay $key "
                    val prev = calcPrev
                    val op = calcOp
                    if (prev != null && op != null && !calcJustEvaluated) {
                        val r = doCalc(prev, d, op)
                        calcPrev = r
                        calcDisplay = formatCalc(r)
                    } else {
                        calcPrev = d
                    }
                    calcOp = key
                    calcJustEvaluated = true
                }
            }
            "=" -> {
                val d = calcDisplay.toDoubleOrNull()
                val prev = calcPrev
                val op = calcOp
                if (d != null && prev != null && op != null) {
                    calcExpression += "$calcDisplay ="
                    val r = doCalc(prev, d, op)
                    calcDisplay = formatCalc(r)
                    calcPrev = null; calcOp = null; calcJustEvaluated = true
                }
            }
            "삽입" -> commit(calcDisplay)
        }
        showMode(Mode.CALCULATOR)
    }

    private fun doCalc(a: Double, b: Double, op: String): Double = when (op) {
        "+" -> a + b
        "−" -> a - b
        "×" -> a * b
        "÷" -> if (b == 0.0) 0.0 else a / b
        else -> b
    }

    private fun formatCalc(v: Double): String =
        if (v == v.toLong().toDouble()) v.toLong().toString() else v.toString()

    // ── Palette ──────────────────────────────────────────────────────────
    private fun buildPaletteView(area: FrameLayout) {
        val root = vlinear()
        val title = TextView(this).apply {
            text = "팔레트 — 탭하면 hex 코드가 입력돼요"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setTextColor(Color.GRAY)
            gravity = Gravity.CENTER
            setPadding(dp(8), dp(8), dp(8), dp(8))
        }
        root.addView(title, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ))
        val palette = listOf(
            "#FF6BA0" to "Pink",
            "#1A1A1A" to "Black",
            "#FF2E2E" to "Red",
            "#0099FF" to "Blue",
            "#34C759" to "Green",
            "#AF52DE" to "Purple",
        )
        for (row in palette.chunked(3)) {
            val rl = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            for ((hex, name) in row) {
                val cell = LinearLayout(this).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER
                    setPadding(dp(8), dp(8), dp(8), dp(8))
                    background = roundedBg(Color.WHITE, dp(12).toFloat(), BORDER)
                    setOnClickListener { commit(hex) }
                }
                val swatch = View(this).apply {
                    background = roundedBg(Color.parseColor(hex), dp(28).toFloat())
                }
                cell.addView(swatch, LinearLayout.LayoutParams(dp(48), dp(48)))
                val label = TextView(this).apply {
                    text = "$name\n$hex"
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
                    gravity = Gravity.CENTER
                    setTextColor(DARK_TEXT)
                }
                cell.addView(label, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ))
                rl.addView(cell, LinearLayout.LayoutParams(0,
                    ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                    setMargins(dp(6), dp(6), dp(6), dp(6))
                })
            }
            root.addView(rl, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ))
        }
        root.addView(View(this), LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f
        ))
        root.addView(buildBottomBar())
        area.addView(root, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ))
    }

    // ── Common bottom bar (🌐 + ⌫) ───────────────────────────────────────
    private fun buildBottomBar(): LinearLayout {
        val bar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val globe = makeKey("🌐", isWide = false) { switchToNextInputMethod() }
        bar.addView(globe, LinearLayout.LayoutParams(0, dp(38), 1f).apply {
            setMargins(dp(4), dp(4), dp(4), dp(4))
        })
        bar.addView(View(this), LinearLayout.LayoutParams(0, dp(38), 4f))
        val back = makeKey("⌫", isWide = false) { /* handled by bindDeleteButton */ }
        bindDeleteButton(back)
        bar.addView(back, LinearLayout.LayoutParams(0, dp(38), 1f).apply {
            setMargins(dp(4), dp(4), dp(4), dp(4))
        })
        return bar
    }

    /**
     * Wire a button so a tap deletes one char and a long-press repeats deletion
     * every 50ms until the finger lifts. We re-set the click listener here to
     * override whatever no-op handler `makeKey` originally attached.
     */
    @SuppressLint("ClickableViewAccessibility")
    private fun bindDeleteButton(btn: View) {
        btn.setOnClickListener { backspace() }
        btn.setOnLongClickListener {
            deleteHandler.removeCallbacks(deleteRepeater)
            deleteHandler.post(deleteRepeater)
            true
        }
        btn.setOnTouchListener { _, event ->
            if (event.action == MotionEvent.ACTION_UP || event.action == MotionEvent.ACTION_CANCEL) {
                deleteHandler.removeCallbacks(deleteRepeater)
            }
            false
        }
    }

    // ── View helpers ─────────────────────────────────────────────────────
    private fun makeKey(label: String, isWide: Boolean, accent: Boolean = false, onTap: () -> Unit): TextView {
        return TextView(this).apply {
            text = label
            gravity = Gravity.CENTER
            setTextSize(TypedValue.COMPLEX_UNIT_SP, if (isWide) 14f else 16f)
            setTextColor(if (accent) Color.WHITE else DARK_TEXT)
            background = roundedBg(
                if (accent) PINK else Color.WHITE,
                dp(8).toFloat(),
                if (accent) PINK else BORDER
            )
            setOnClickListener { onTap() }
        }
    }

    private fun vlinear(): LinearLayout = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
    }

    private fun roundedBg(fill: Int, radius: Float, stroke: Int? = null): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = radius
            setColor(fill)
            if (stroke != null) setStroke(dp(1), stroke)
        }
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    // ── Input plumbing ───────────────────────────────────────────────────
    private fun commit(text: String) {
        currentInputConnection?.commitText(text, 1)
    }

    private fun backspace() {
        currentInputConnection?.deleteSurroundingText(1, 0)
    }

    private fun switchToNextInputMethod() {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        imm?.showInputMethodPicker()
    }

    private fun copyToClipboard(text: String, toastMsg: String = "복사됨") {
        val cm = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
        cm?.setPrimaryClip(ClipData.newPlainText("Fonkii", text))
        showToast(toastMsg)
    }

    private fun showToast(msg: String) {
        Toast.makeText(applicationContext, msg, Toast.LENGTH_SHORT).show()
    }
}
