package com.yunajung.fonki

import android.annotation.SuppressLint
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.BitmapFactory
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
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import com.yunajung.fonki.BuildConfig
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
    /// Default accent — used when the user hasn't picked a palette color yet.
    private val DEFAULT_ACCENT = Color.parseColor("#FF6BA0")
    /// User-customizable accent. Stored in SharedPreferences `fonkii_prefs`
    /// under key `"fonkii_accent_color"` (mirrors iOS `accentColor` /
    /// `"fonkii_accent_color"` in NSUserDefaults). Read every access so a
    /// `setAccentColor` write is reflected the next time `showMode` rebuilds
    /// any tab. The legacy name `PINK` is kept so existing call sites don't
    /// need a mass rename — semantically it's the active accent now.
    private val PINK: Int
        get() = getSharedPreferences("fonkii_prefs", Context.MODE_PRIVATE)
            .getInt("fonkii_accent_color", DEFAULT_ACCENT)
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
    /// Live references to the font-style pills currently in view.
    /// `selectFontStyle` walks this map to repaint selection state without
    /// rebuilding the whole tab — preserves the picker's scroll offset.
    private val fontStyleButtons = mutableMapOf<Int, TextView>()
    private var isShifted = false
    /// `true` while the inline category row is shown above the font row.
    /// Toggled by the ▼/▲ button next to the font scroll. Resets to false
    /// after a category is picked so the row auto-hides.
    private var isCategoryExpanded = false
    /// Aa-tab keypad mode: false = QWERTY, true = number/symbol page.
    /// `isSymbolPage2` only matters when `isNumberMode == true` and toggles
    /// between the 123 (digits + common punct) and #+= (brackets + symbols)
    /// pages — mirrors iOS `isNumberMode` / `isSymbolPage2`.
    private var isNumberMode = false
    private var isSymbolPage2 = false
    private var emoticonCatIndex = 0
    private var specialCatIndex = 0

    // Calculator state
    private var calcDisplay = "0"
    private var calcExpression = ""
    private var calcPrev: Double? = null
    private var calcOp: String? = null
    private var calcJustEvaluated = false

    // ── GIF state ────────────────────────────────────────────────────────
    private data class GifItem(val id: String, val originalUrl: String, val thumbUrl: String)
    /// `null` = trending feed, otherwise a search query (Korean label or
    /// English keyword from the category bar / EditText).
    private var gifQuery: String? = null
    private var gifResults: List<GifItem> = emptyList()
    private var gifLoading: Boolean = false
    /// Hop counter so a stale fetch landing late can't overwrite a newer one.
    private var gifFetchToken: Int = 0
    /// Set true once the trending feed has fired off at least once — prevents
    /// rebuilding the GIF tab from re-fetching on every redraw.
    private var gifInitialFetchTriggered: Boolean = false

    // ── Long-press delete plumbing ───────────────────────────────────────
    private val deleteHandler = Handler(Looper.getMainLooper())
    private val deleteRepeater = object : Runnable {
        override fun run() {
            // Route through `backspace()` so surrogate-pair-aware deletion
            // (Bold/Script/etc. supplementary glyphs) is consistent with
            // single-tap delete.
            backspace()
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
            "계산" to Mode.CALCULATOR,
            "😀" to Mode.EMOTICON,
            "✦" to Mode.SPECIAL,
            "도트" to Mode.DOT_ART,
            "GIF" to Mode.GIF,
            "♥" to Mode.FAVORITES,
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
                    // Tinted accent (~15% alpha) so the selected tab matches
                    // the user's palette pick instead of being stuck on pink.
                    setColor(Color.argb(38, Color.red(PINK), Color.green(PINK), Color.blue(PINK)))
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

        val cats = FontConverter.fontCategories
        if (fontCatIndex !in cats.indices) fontCatIndex = 0
        if (fontStyleIndex !in FontConverter.fontStyles.indices) fontStyleIndex = 0
        val currentCat = cats[fontCatIndex]
        // If the active style isn't in the active category (e.g. category
        // just changed), snap to that category's first font.
        val activeStyle = FontConverter.fontStyles[fontStyleIndex]
        if (activeStyle !in currentCat.styles) {
            fontStyleIndex = FontConverter.fontStyles.indexOf(currentCat.styles.first())
        }
        fontStyleButtons.clear()

        // 1a) Optional category row — only renders when `isCategoryExpanded`
        //     is true. Tapping a category swaps the font row underneath and
        //     auto-collapses the category row (sets `isCategoryExpanded =
        //     false` before the rebuild) so the user lands back on the
        //     single-row picker.
        if (isCategoryExpanded) {
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
                        val selectedStyle = FontConverter.fontStyles[fontStyleIndex]
                        if (selectedStyle !in tappedCat.styles) {
                            fontStyleIndex = FontConverter.fontStyles.indexOf(tappedCat.styles.first())
                        }
                        // Auto-collapse so the user returns to the compact
                        // single-row picker after picking a category.
                        isCategoryExpanded = false
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
        }

        // 1b) Single-row font picker (active category's styles + ▼/▲ toggle).
        //     Each pill renders its own name through its own converter
        //     ("Bold" → "𝐁𝐨𝐥𝐝") for a live preview. The toggle on the right
        //     flips `isCategoryExpanded` and rebuilds — when expanded the
        //     category row above appears, when collapsed only this row shows.
        val pickerRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val styleScroll = HorizontalScrollView(this).apply { isHorizontalScrollBarEnabled = false }
        val styleRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        for (style in currentCat.styles) {
            val styleGlobalIdx = FontConverter.fontStyles.indexOf(style)
            val isSelected = styleGlobalIdx == fontStyleIndex
            val styledLabel = FontConverter.convert(style.name, style)
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
                setOnClickListener { selectFontStyle(styleGlobalIdx) }
            }
            fontStyleButtons[styleGlobalIdx] = btn
            styleRow.addView(btn, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(dp(4), 0, dp(4), 0) })
        }
        styleScroll.addView(styleRow)
        // Scroll fills the row, ▼/▲ button is fixed-width on the right.
        pickerRow.addView(styleScroll, LinearLayout.LayoutParams(
            0, ViewGroup.LayoutParams.MATCH_PARENT, 1f
        ))
        val catToggle = TextView(this).apply {
            text = if (isCategoryExpanded) "▲" else "▼"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            gravity = Gravity.CENTER
            setTextColor(DARK_TEXT)
            background = roundedBg(Color.WHITE, dp(14).toFloat(), BORDER)
            setPadding(dp(12), dp(6), dp(12), dp(6))
            setOnClickListener {
                isCategoryExpanded = !isCategoryExpanded
                showMode(Mode.FONTS)
            }
        }
        pickerRow.addView(catToggle, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply { setMargins(dp(4), 0, dp(8), 0) })
        root.addView(pickerRow, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(40)
        ).apply { setMargins(dp(4), dp(4), dp(4), dp(4)) })

        // 3) Keypad. Two layouts share this slot:
        //    * `isNumberMode == false` → QWERTY (letters streamed through the
        //      active font style).
        //    * `isNumberMode == true`  → number/symbol pad. Page 1 (`123`)
        //      shows digits + common punctuation; page 2 (`#+=`) shows
        //      brackets + symbols. Toggle button on row 3 swaps pages.
        //    Letter taps re-read `fontStyleIndex` *at click time* via
        //    `currentFontStyle()` so `selectFontStyle` can update the active
        //    style without rebuilding the keypad.
        if (!isNumberMode) {
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
                                commit(FontConverter.convert(ch, currentFontStyle()))
                                if (isShifted) {
                                    isShifted = false
                                    showMode(Mode.FONTS)
                                }
                            }
                        }
                    }
                    if (isBackspace) bindDeleteButton(btn)
                    val lp = LinearLayout.LayoutParams(
                        0, dp(36), if (isShift || isBackspace) 1.5f else 1f
                    ).apply { setMargins(dp(2), dp(2), dp(2), dp(2)) }
                    rowLayout.addView(btn, lp)
                }
                root.addView(rowLayout, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ))
            }
        } else {
            // Number/symbol pad. Top two rows are the page payload (10 keys
            // each); row 3 is `pageToggle (1.5f)` + 5 common punct + ⌫ (1.5f),
            // matching iOS proportions (so the punct cells render slightly
            // wider than the 10-col rows above — that's by design).
            val (top1, top2) = if (!isSymbolPage2) {
                listOf("1","2","3","4","5","6","7","8","9","0") to
                listOf("-","/",":",";","(",")","€","&","@","\"")
            } else {
                listOf("[","]","{","}","#","%","^","*","+","=") to
                listOf("_","\\","|","~","<",">","$","£","¥","•")
            }
            val pageToggleLabel = if (isSymbolPage2) "123" else "#+="
            val punct = listOf(".", ",", "?", "!", "'")

            fun symbolRow(keys: List<String>) {
                val rowLayout = LinearLayout(this).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER
                }
                for (label in keys) {
                    val btn = makeKey(label, isWide = false) {
                        // Stream symbols through the active font style too,
                        // so digits restyle (Bold "1" etc.) and punctuation
                        // passes through unchanged.
                        commit(FontConverter.convert(label, currentFontStyle()))
                    }
                    rowLayout.addView(btn, LinearLayout.LayoutParams(0, dp(36), 1f).apply {
                        setMargins(dp(2), dp(2), dp(2), dp(2))
                    })
                }
                root.addView(rowLayout, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ))
            }
            symbolRow(top1)
            symbolRow(top2)

            // Row 3: page toggle + 5 punct + ⌫.
            val row3 = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
            }
            val toggleBtn = makeKey(pageToggleLabel, isWide = true) {
                isSymbolPage2 = !isSymbolPage2
                showMode(Mode.FONTS)
            }
            row3.addView(toggleBtn, LinearLayout.LayoutParams(0, dp(36), 1.5f).apply {
                setMargins(dp(2), dp(2), dp(2), dp(2))
            })
            for (p in punct) {
                val btn = makeKey(p, isWide = false) {
                    commit(FontConverter.convert(p, currentFontStyle()))
                }
                row3.addView(btn, LinearLayout.LayoutParams(0, dp(36), 1f).apply {
                    setMargins(dp(2), dp(2), dp(2), dp(2))
                })
            }
            val backBtn = makeKey("⌫", isWide = true) { /* bindDeleteButton */ }
            bindDeleteButton(backBtn)
            row3.addView(backBtn, LinearLayout.LayoutParams(0, dp(36), 1.5f).apply {
                setMargins(dp(2), dp(2), dp(2), dp(2))
            })
            root.addView(row3, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ))
        }

        // 4) Bottom bar. Toggle label flips between `?123` and `ABC` so the
        //    same row enters and exits number mode (mirrors iOS). `space`
        //    also styles its glyph so monospaced styles keep their spacing
        //    flavor.
        val bottom = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        val toggleLabel = if (isNumberMode) "ABC" else "?123"
        val toggle = makeKey(toggleLabel, isWide = true) {
            isNumberMode = !isNumberMode
            // Always re-enter on page 1 so a second `?123` tap doesn't land
            // the user on `#+=` from a stale state.
            isSymbolPage2 = false
            showMode(Mode.FONTS)
        }
        bottom.addView(toggle, LinearLayout.LayoutParams(0, dp(38), 1.5f).apply {
            setMargins(dp(2), dp(4), dp(2), dp(2))
        })
        val space = makeKey("space", isWide = false) {
            commit(FontConverter.convert(" ", currentFontStyle()))
        }
        bottom.addView(space, LinearLayout.LayoutParams(0, dp(38), 5f).apply {
            setMargins(dp(2), dp(4), dp(2), dp(2))
        })
        val enterLabel = if (isNumberMode) "완료" else "⏎"
        val enter = makeKey(enterLabel, isWide = isNumberMode) { commit("\n") }
        bottom.addView(enter, LinearLayout.LayoutParams(0, dp(38), 1.5f).apply {
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

    /// Currently-selected font style — read on every keypress so a
    /// `selectFontStyle` change is honored without rebuilding the QWERTY
    /// keypad (which would lose the picker's scroll position).
    private fun currentFontStyle(): FontConverter.UnicodeStyle {
        return FontConverter.fontStyles.getOrNull(fontStyleIndex)
            ?: FontConverter.fontStyles[0]
    }

    /// Apply a new font style: track which category it belongs to, retro-
    /// convert text in front of the cursor (or the current selection) so
    /// previously typed text restyles in place, and repaint just the font
    /// pills' selection state. No `showMode` rebuild — preserves the
    /// picker's scroll offset and avoids the "first-pill snap" jolt.
    private fun selectFontStyle(globalIdx: Int) {
        val newStyle = FontConverter.fontStyles.getOrNull(globalIdx) ?: return
        fontStyleIndex = globalIdx
        // Track which category owns this style for downstream lookups.
        val catIdx = FontConverter.fontCategories.indexOfFirst { newStyle in it.styles }
        if (catIdx >= 0) fontCatIndex = catIdx

        // Retro-convert existing text. iOS picks selectedText first and
        // falls back to the last 100 chars before the cursor; we follow
        // that contract here.
        convertExistingText(newStyle)

        // Repaint pills — only the buttons currently in `fontStyleButtons`
        // (i.e. the expanded category) are reachable; that's expected.
        fontStyleButtons.forEach { (idx, btn) ->
            val isSel = idx == globalIdx
            btn.setTextColor(if (isSel) Color.WHITE else DARK_TEXT)
            btn.background = roundedBg(
                if (isSel) PINK else Color.WHITE,
                dp(14).toFloat(),
                if (isSel) PINK else BORDER
            )
        }
    }

    /// Retro-convert host-side text to the new style. Selected text wins
    /// (matches iOS `styleTapped` selectedText branch); otherwise we read
    /// the last 100 chars before the cursor and replace them.
    ///
    /// Pipeline: existing styled glyphs → `normalizeToASCII` strips them
    /// back to plain ASCII → `FontConverter.convert` re-applies the chosen
    /// style. Lets users restyle text mid-sentence (e.g. switch from Bold
    /// to Italic and have the previous Bold turn Italic, not stay Bold).
    private fun convertExistingText(style: FontConverter.UnicodeStyle) {
        val ic = currentInputConnection ?: return
        val selected = ic.getSelectedText(0)
        if (!selected.isNullOrEmpty()) {
            val normalized = normalizeToASCII(selected.toString())
            val converted = FontConverter.convert(normalized, style)
            ic.commitText(converted, 1)  // active selection → replaced in place
            return
        }
        val before = ic.getTextBeforeCursor(100, 0) ?: return
        if (before.isEmpty()) return
        val normalized = normalizeToASCII(before.toString())
        val converted = FontConverter.convert(normalized, style)
        if (converted == before.toString()) return  // no-op (Normal style etc.)
        ic.beginBatchEdit()
        ic.deleteSurroundingText(before.length, 0)
        ic.commitText(converted, 1)
        ic.endBatchEdit()
    }

    /// Strip every offset-based math/decorative codepoint back to its plain
    /// ASCII counterpart so a fresh `FontConverter.convert` can re-style it.
    /// iterates by Unicode codepoint (handles supplementary surrogate pairs
    /// correctly — math alphanumerics are all in U+1D400+).
    ///
    /// Coverage: any style backed by `upper`/`lower`/`digit` offsets +
    /// the `exceptions` BMP-fallback table (Italic h, Script B/E/F/…,
    /// Fraktur C/H/I/…, Double-struck C/H/N/…). Charmap-based styles
    /// (Comic, Cursive, Small Caps, Super, Sub) and decorators (Cloudy,
    /// Candy, Box, Sad, Happy, Flip, …) pass through unchanged — porting
    /// iOS's `_cmReverseMap` / `_udReverseMap` and the combining-mark
    /// stripper would be a follow-up.
    private fun normalizeToASCII(text: String): String {
        val sb = StringBuilder()
        var i = 0
        while (i < text.length) {
            val cp = text.codePointAt(i)
            i += Character.charCount(cp)
            val ascii = findASCIIForCodePoint(cp)
            if (ascii >= 0) sb.appendCodePoint(ascii) else sb.appendCodePoint(cp)
        }
        return sb.toString()
    }

    private fun findASCIIForCodePoint(cp: Int): Int {
        // Already plain ASCII? Pass through (shortcut + skips Normal style's
        // identity offsets which would otherwise match every ASCII char).
        if (cp in 0x41..0x5A || cp in 0x61..0x7A || cp in 0x30..0x39) return cp
        for (style in FontConverter.fontStyles) {
            // Skip Normal — its 0x41/0x61/0x30 ranges would always match.
            if (style.upper == 0x0041 && style.lower == 0x0061 &&
                (style.digit == null || style.digit == 0x0030)
            ) continue
            // Uppercase block (26 letters).
            if (cp >= style.upper && cp < style.upper + 26) {
                return 0x41 + (cp - style.upper)
            }
            // Lowercase block.
            if (cp >= style.lower && cp < style.lower + 26) {
                return 0x61 + (cp - style.lower)
            }
            // Digit block (10 digits) when defined.
            val d = style.digit
            if (d != null && cp >= d && cp < d + 10) {
                return 0x30 + (cp - d)
            }
            // Reserved BMP fallback exceptions (e.g. Italic h → ℎ U+210E).
            for ((ascii, styled) in style.exceptions) {
                if (cp == styled) return ascii
            }
        }
        return -1
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

        // 1) Search row — submit on keyboard "search" action or 🔍 button.
        val searchRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        val search = EditText(this).apply {
            hint = "GIF 검색"
            setPadding(dp(12), dp(6), dp(12), dp(6))
            background = roundedBg(LIGHT_GRAY, dp(18).toFloat())
            inputType = InputType.TYPE_CLASS_TEXT
            imeOptions = EditorInfo.IME_ACTION_SEARCH
            // Restore last-searched text so swapping tabs doesn't blank the box.
            gifQuery?.takeIf { it.isNotBlank() }?.let { setText(it) }
            setOnEditorActionListener { v, actionId, _ ->
                if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                    val q = v.text.toString().trim()
                    gifQuery = q.ifEmpty { null }
                    fetchGifs(gifQuery)
                    true
                } else false
            }
        }
        val searchBtn = TextView(this).apply {
            text = "🔍"
            gravity = Gravity.CENTER
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            background = roundedBg(Color.WHITE, dp(18).toFloat(), BORDER)
            setOnClickListener {
                val q = search.text.toString().trim()
                gifQuery = q.ifEmpty { null }
                fetchGifs(gifQuery)
            }
        }
        searchRow.addView(search, LinearLayout.LayoutParams(0, dp(36), 1f).apply {
            setMargins(dp(8), dp(0), dp(4), dp(0))
        })
        searchRow.addView(searchBtn, LinearLayout.LayoutParams(dp(44), dp(36)).apply {
            setMargins(dp(0), dp(0), dp(8), dp(0))
        })
        root.addView(searchRow, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(40)
        ).apply { setMargins(0, dp(4), 0, dp(2)) })

        // 2) Category bar — Korean labels mapped to English GIPHY queries
        //    (null → trending feed).
        val categories = listOf<Pair<String, String?>>(
            "인기" to null,
            "재미있는" to "funny",
            "사랑" to "love",
            "슬픔" to "sad",
            "반응" to "reaction",
            "화남" to "angry",
        )
        val catScroll = HorizontalScrollView(this).apply { isHorizontalScrollBarEnabled = false }
        val catRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        for ((label, query) in categories) {
            val isSelected = (query == null && gifQuery == null) ||
                (query != null && gifQuery == query)
            val btn = TextView(this).apply {
                text = label
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                setTextColor(if (isSelected) Color.WHITE else DARK_TEXT)
                background = roundedBg(
                    if (isSelected) PINK else Color.WHITE,
                    dp(14).toFloat(),
                    if (isSelected) PINK else BORDER
                )
                setPadding(dp(12), dp(6), dp(12), dp(6))
                setOnClickListener {
                    gifQuery = query
                    search.setText(query ?: "")
                    fetchGifs(query)
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
        ))

        // 3) Body — empty/loading/error/grid by state.
        val bodyContainer = FrameLayout(this)
        when {
            BuildConfig.GIPHY_API_KEY.isEmpty() -> {
                bodyContainer.addView(centeredMsg("GIPHY API 키가 설정되지 않았습니다"))
            }
            gifLoading -> {
                bodyContainer.addView(centeredMsg("로딩 중…"))
            }
            gifResults.isEmpty() -> {
                bodyContainer.addView(centeredMsg(
                    if (gifInitialFetchTriggered) "결과가 없어요" else "로딩 중…"
                ))
                if (!gifInitialFetchTriggered) {
                    gifInitialFetchTriggered = true
                    fetchGifs(gifQuery)
                }
            }
            else -> {
                val scroll = ScrollView(this)
                val grid = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
                val cols = 3
                gifResults.chunked(cols).forEach { chunk ->
                    val rowL = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
                    for (item in chunk) {
                        val iv = ImageView(this).apply {
                            scaleType = ImageView.ScaleType.CENTER_CROP
                            background = roundedBg(LIGHT_GRAY, dp(8).toFloat(), BORDER)
                            // GIPHY URLs already include ?cid= etc.; copy the
                            // original GIF link so the host app can display
                            // the animated asset (e.g. KakaoTalk paste).
                            setOnClickListener {
                                copyToClipboard(item.originalUrl, "GIF가 복사되었습니다")
                            }
                        }
                        loadGifThumb(item.thumbUrl, iv)
                        rowL.addView(iv, LinearLayout.LayoutParams(0, dp(72), 1f).apply {
                            setMargins(dp(3), dp(3), dp(3), dp(3))
                        })
                    }
                    for (pad in chunk.size until cols) {
                        rowL.addView(View(this), LinearLayout.LayoutParams(0, dp(72), 1f).apply {
                            setMargins(dp(3), dp(3), dp(3), dp(3))
                        })
                    }
                    grid.addView(rowL, LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                    ))
                }
                scroll.addView(grid, ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ))
                bodyContainer.addView(scroll, FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                ))
            }
        }
        root.addView(bodyContainer, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f
        ).apply { setMargins(dp(4), dp(2), dp(4), dp(2)) })

        root.addView(buildBottomBar())
        area.addView(root, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ))
    }

    private fun centeredMsg(text: String): TextView = TextView(this).apply {
        this.text = text
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
        setTextColor(Color.GRAY)
        gravity = Gravity.CENTER
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
    }

    /// Fire a Trending or Search request to GIPHY and re-render the GIF tab
    /// when the response lands. Stale fetches (token mismatch) are silently
    /// dropped so a quick category retap doesn't get scrambled by an older
    /// reply finishing later.
    private fun fetchGifs(query: String?) {
        val key = BuildConfig.GIPHY_API_KEY
        if (key.isEmpty()) {
            showToast("GIPHY API 키가 설정되지 않았습니다")
            return
        }
        gifLoading = true
        val token = ++gifFetchToken
        if (currentMode == Mode.GIF) showMode(Mode.GIF)
        Thread {
            val main = Handler(Looper.getMainLooper())
            try {
                val urlStr = if (query.isNullOrBlank()) {
                    "https://api.giphy.com/v1/gifs/trending?api_key=$key&limit=50&rating=pg"
                } else {
                    val encoded = java.net.URLEncoder.encode(query, "UTF-8")
                    "https://api.giphy.com/v1/gifs/search?api_key=$key&q=$encoded&limit=50&rating=pg"
                }
                val conn = java.net.URL(urlStr).openConnection() as java.net.HttpURLConnection
                conn.connectTimeout = 15000
                conn.readTimeout = 30000
                val response = conn.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
                val data = org.json.JSONObject(response).getJSONArray("data")
                val parsed = mutableListOf<GifItem>()
                for (i in 0 until data.length()) {
                    val obj = data.getJSONObject(i)
                    val id = obj.optString("id", "")
                    val images = obj.optJSONObject("images") ?: continue
                    val original = images.optJSONObject("original")?.optString("url", "")
                        ?: images.optJSONObject("downsized")?.optString("url", "")
                    val thumb = images.optJSONObject("fixed_height_small")?.optString("url", "")
                        ?: images.optJSONObject("preview_gif")?.optString("url", "")
                        ?: original
                    if (id.isNotEmpty() && !original.isNullOrEmpty() && !thumb.isNullOrEmpty()) {
                        parsed.add(GifItem(id, original, thumb))
                    }
                }
                main.post {
                    if (token != gifFetchToken) return@post  // stale
                    gifResults = parsed
                    gifLoading = false
                    if (currentMode == Mode.GIF) showMode(Mode.GIF)
                }
            } catch (e: Exception) {
                main.post {
                    if (token != gifFetchToken) return@post
                    gifLoading = false
                    if (currentMode == Mode.GIF) showMode(Mode.GIF)
                    showToast("GIF 로드 실패: ${e.message ?: "unknown"}")
                }
            }
        }.start()
    }

    /// Per-thumbnail image fetch. BitmapFactory decodes the first frame of a
    /// GIF (no animation) — fine for a grid; the original URL is copied to
    /// the clipboard so the receiving app can animate it.
    private fun loadGifThumb(url: String, target: ImageView) {
        Thread {
            try {
                val conn = java.net.URL(url).openConnection() as java.net.HttpURLConnection
                conn.connectTimeout = 10000
                conn.readTimeout = 20000
                val bytes = conn.inputStream.use { it.readBytes() }
                val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                if (bitmap != null) {
                    Handler(Looper.getMainLooper()).post {
                        target.setImageBitmap(bitmap)
                    }
                }
            } catch (_: Exception) {
                // Silent — the placeholder background remains.
            }
        }.start()
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
        // Budget for the 260dp `keypad_area`:
        //   expression 14 + display 44 + display margin 2 +
        //   5 rows × 38 (row 190) + 5 × row vertical margin 2 (10) = 260dp.
        // No shared bottom bar — calc has its own ⌫ on row 1 so the
        // 🌐/space/⌫ row would be redundant and would push the keypad
        // past 260dp (the layout we ship in `keyboard_view.xml`).
        val root = vlinear()
        val expr = TextView(this).apply {
            text = calcExpression
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setTextColor(Color.GRAY)
            gravity = Gravity.END
            setPadding(dp(12), 0, dp(12), 0)
        }
        root.addView(expr, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(14)
        ))
        val display = TextView(this).apply {
            text = calcDisplay
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 26f)
            setTextColor(DARK_TEXT)
            gravity = Gravity.END or Gravity.CENTER_VERTICAL
            setPadding(dp(12), 0, dp(12), 0)
            background = roundedBg(LIGHT_GRAY, dp(8).toFloat())
        }
        root.addView(display, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(44)
        ).apply { setMargins(dp(8), 0, dp(8), dp(2)) })

        // iOS calculator layout. `=` now commits the result to the host
        // (replaces the old 삽입 row). ⌫ on row 1 deletes the trailing digit
        // of the current display. AC/%/+/-/⌫ are the muted-gray "function"
        // bucket; ÷×−+= are the orange "operator" bucket; digits + `.` are
        // the dark "number" bucket — matches iOS Calculator.app palette.
        val OP_ORANGE = Color.parseColor("#FF9500")
        val FN_GRAY = Color.parseColor("#A5A5A5")
        val NUM_DARK = Color.parseColor("#333333")
        val rows = listOf(
            listOf("⌫", "AC", "%", "÷"),
            listOf("7", "8", "9", "×"),
            listOf("4", "5", "6", "−"),
            listOf("1", "2", "3", "+"),
            listOf("+/-", "0", ".", "="),
        )
        val opKeys = setOf("÷", "×", "−", "+", "=")
        val fnKeys = setOf("AC", "%", "+/-", "⌫")
        for (row in rows) {
            val rl = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            for (key in row) {
                val bg = when (key) {
                    in opKeys -> OP_ORANGE
                    in fnKeys -> FN_GRAY
                    else -> NUM_DARK
                }
                val btn = TextView(this).apply {
                    text = key
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
                    gravity = Gravity.CENTER
                    setTextColor(Color.WHITE)
                    // Half-height radius = capsule pill, matches iOS shape.
                    background = roundedBg(bg, dp(19).toFloat())
                    setOnClickListener { onCalcKey(key) }
                }
                // NB: ⌫ here drops a digit from `calcDisplay` (handled in
                // `onCalcKey`), *not* a char from the host editor — so we
                // keep the ordinary tap handler and skip `bindDeleteButton`.
                rl.addView(btn, LinearLayout.LayoutParams(0, dp(38), 1f).apply {
                    setMargins(dp(3), dp(2), dp(3), 0)
                })
            }
            root.addView(rl, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ))
        }
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
            "⌫" -> {
                // Drop the trailing character of the current display. After a
                // result lands (`calcJustEvaluated`) ⌫ behaves like AC for
                // the display only — chaining a delete onto a fresh result
                // doesn't make sense.
                if (calcJustEvaluated) {
                    calcDisplay = "0"
                    calcJustEvaluated = false
                } else {
                    calcDisplay = if (calcDisplay.length <= 1 ||
                        (calcDisplay.length == 2 && calcDisplay.startsWith("-"))
                    ) "0" else calcDisplay.dropLast(1)
                }
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
                // = both finalizes the math and commits the result to the
                // host editor (replaces the old 삽입 button). When `=` lands
                // on a chain that already has prev/op queued, evaluate first
                // and commit the result; when there's nothing to evaluate,
                // commit the current display verbatim.
                val d = calcDisplay.toDoubleOrNull()
                val prev = calcPrev
                val op = calcOp
                if (d != null && prev != null && op != null) {
                    calcExpression += "$calcDisplay ="
                    val r = doCalc(prev, d, op)
                    calcDisplay = formatCalc(r)
                    calcPrev = null; calcOp = null; calcJustEvaluated = true
                }
                commit(calcDisplay)
            }
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
    /// Palette tab — port of iOS `showPalettePicker`. 6 preset colors as
    /// circular buttons (3×2) with a check mark on the active one, plus RGB
    /// sliders + live preview + 적용 button. Tapping a preset commits
    /// immediately; sliders only mutate `staged` until 적용 dismisses the
    /// staged color into the saved accentColor (matches iOS's tap-to-commit
    /// model — single accent write per session, single showMode rebuild).
    private fun buildPaletteView(area: FrameLayout) {
        val root = vlinear()
        val current = PINK

        // 1) Preset color grid (3 columns × 2 rows).
        val presets = listOf(
            Color.parseColor("#FF6BA0"), // 핑크 (기본)
            Color.parseColor("#1A1A1A"), // 블랙
            Color.parseColor("#FF2E2E"), // 레드
            Color.parseColor("#0099FF"), // 블루
            Color.parseColor("#34C759"), // 그린
            Color.parseColor("#AF52DE"), // 퍼플
        )
        for (rowColors in presets.chunked(3)) {
            val rl = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
            }
            for (color in rowColors) {
                val isSelected = colorsClose(color, current)
                val swatch = TextView(this).apply {
                    if (isSelected) {
                        text = "✓"
                        setTextColor(Color.WHITE)
                        setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                        gravity = Gravity.CENTER
                    }
                    background = GradientDrawable().apply {
                        shape = GradientDrawable.OVAL
                        setColor(color)
                    }
                    setOnClickListener { setAccentColor(color) }
                }
                rl.addView(swatch, LinearLayout.LayoutParams(dp(36), dp(36)).apply {
                    setMargins(dp(8), dp(4), dp(8), dp(4))
                })
            }
            root.addView(rl, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(44)
            ))
        }

        // 2) RGB sliders + live-updating preview circle.
        //    `staged` holds the slider-driven value until 적용 commits it.
        val staged = intArrayOf(Color.red(current), Color.green(current), Color.blue(current))
        val previewCircle = View(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(current)
            }
        }
        fun refreshPreview() {
            (previewCircle.background as? GradientDrawable)
                ?.setColor(Color.rgb(staged[0], staged[1], staged[2]))
        }

        listOf("R" to 0, "G" to 1, "B" to 2).forEach { (label, idx) ->
            val sliderRow = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }
            val labelView = TextView(this).apply {
                text = label
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                setTextColor(DARK_TEXT)
                gravity = Gravity.CENTER
            }
            val seekBar = android.widget.SeekBar(this).apply {
                max = 255
                progress = staged[idx]
                setOnSeekBarChangeListener(object : android.widget.SeekBar.OnSeekBarChangeListener {
                    override fun onProgressChanged(
                        sb: android.widget.SeekBar?, progress: Int, fromUser: Boolean
                    ) {
                        if (fromUser) {
                            staged[idx] = progress
                            refreshPreview()
                        }
                    }
                    override fun onStartTrackingTouch(sb: android.widget.SeekBar?) {}
                    override fun onStopTrackingTouch(sb: android.widget.SeekBar?) {}
                })
            }
            sliderRow.addView(labelView, LinearLayout.LayoutParams(dp(20), dp(28)).apply {
                setMargins(dp(8), 0, dp(4), 0)
            })
            sliderRow.addView(seekBar, LinearLayout.LayoutParams(0, dp(28), 1f).apply {
                setMargins(dp(4), 0, dp(8), 0)
            })
            root.addView(sliderRow, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(28)
            ))
        }

        // 3) Preview + 적용 row.
        val applyRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        applyRow.addView(previewCircle, LinearLayout.LayoutParams(dp(32), dp(32)).apply {
            setMargins(dp(12), dp(4), dp(8), dp(4))
        })
        val applyBtn = makeKey("적용", isWide = false, accent = true) {
            setAccentColor(Color.rgb(staged[0], staged[1], staged[2]))
        }
        applyRow.addView(applyBtn, LinearLayout.LayoutParams(0, dp(32), 1f).apply {
            setMargins(dp(8), dp(4), dp(12), dp(4))
        })
        root.addView(applyRow, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(40)
        ))

        // Spacer so the bottom bar pins to the bottom even when content fits.
        root.addView(View(this), LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f
        ))
        root.addView(buildBottomBar())
        area.addView(root, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ))
    }

    /// Persist the new accent color and force a full UI rebuild so every
    /// `PINK`-using surface (tabs, font alongs, calculator op buttons,
    /// accent-styled key borders, …) picks up the change immediately.
    /// Mirrors iOS `accentColor` setter → `applyAccentColor()` →
    /// `showMode(currentMode)`.
    private fun setAccentColor(color: Int) {
        getSharedPreferences("fonkii_prefs", Context.MODE_PRIVATE)
            .edit()
            .putInt("fonkii_accent_color", color)
            .apply()
        showMode(currentMode)
    }

    /// Tolerance-based equality check for the preset-color check mark.
    /// iOS uses ±0.015 (≈ ±4/255); we match that with an integer rounding.
    private fun colorsClose(a: Int, b: Int): Boolean {
        return Math.abs(Color.red(a) - Color.red(b)) <= 4 &&
            Math.abs(Color.green(a) - Color.green(b)) <= 4 &&
            Math.abs(Color.blue(a) - Color.blue(b)) <= 4
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

    /// Surrogate-pair-aware backspace. `deleteSurroundingText(1, 0)` removes
    /// a single UTF-16 code unit, which splits the supplementary-plane glyphs
    /// the Aa tab produces (Bold/Italic/Script/… in U+1D400–U+1D7FF are all
    /// surrogate pairs). The orphaned high surrogate then renders as `?`.
    /// We peek at the last two code units, decide whether the trailing char
    /// is the low surrogate of a pair, and delete 1 or 2 units accordingly.
    private fun backspace() {
        val ic = currentInputConnection ?: return
        val before = ic.getTextBeforeCursor(2, 0) ?: return
        if (before.isEmpty()) return
        val lastChar = before[before.length - 1]
        val deleteCount = if (before.length >= 2 &&
            Character.isLowSurrogate(lastChar) &&
            Character.isHighSurrogate(before[before.length - 2])
        ) 2 else 1
        ic.deleteSurroundingText(deleteCount, 0)
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
