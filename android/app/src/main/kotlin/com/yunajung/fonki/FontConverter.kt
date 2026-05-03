package com.yunajung.fonki

/**
 * 46 font styles ported from iOS `KeyboardViewController.swift` `allFontCategories`
 * (line 208+). The Swift version uses several conversion strategies (`_oc` offset,
 * `_cm` char-map, `_cc` combining-char, `_ud` upside-down, plus per-char wrappers);
 * we model all of them on a single [UnicodeStyle] with optional fields and
 * dispatch in [convert].
 *
 * Resolution order (first non-null wins):
 *   charMap  → upsideDown → wrapBefore/wrapAfter → combining → offset
 */
object FontConverter {

    data class UnicodeStyle(
        val name: String,
        val upper: Int = 0x0041,
        val lower: Int = 0x0061,
        val digit: Int? = null,
        val exceptions: Map<Int, Int> = emptyMap(),
        // Combining mark(s) appended after each non-whitespace input char.
        val combining: String? = null,
        // Direct char-to-string lookup (Comic / Cursive / Small Caps / Super / Sub).
        val charMap: Map<Char, String>? = null,
        // Per-char wrapping. `wrapBefore`-only = Cloudy ("☁X"); both = Candy/Box.
        val wrapBefore: String? = null,
        val wrapAfter: String? = null,
        // Apply an upside-down char-map then reverse the whole string (Flip).
        val upsideDown: Map<Char, String>? = null,
    )

    // ── BMP exception tables ─────────────────────────────────────────────
    // Apple/Unicode reserve a handful of math-alphanumeric slots in the BMP for
    // backwards compatibility — these maps redirect those scalars.

    /** Italic: `h` → `ℎ` (PLANCK CONSTANT). */
    private val itX: Map<Int, Int> = mapOf(0x68 to 0x210E)

    /** Script (calligraphic) reserved letters. */
    private val scX: Map<Int, Int> = mapOf(
        0x42 to 0x212C, 0x45 to 0x2130, 0x46 to 0x2131, 0x48 to 0x210B,
        0x49 to 0x2110, 0x4C to 0x2112, 0x4D to 0x2133, 0x52 to 0x211B,
        0x65 to 0x212F, 0x67 to 0x210A, 0x6F to 0x2134,
    )

    /** Fraktur (Gothic) reserved letters. */
    private val goX: Map<Int, Int> = mapOf(
        0x43 to 0x212D, 0x48 to 0x210C, 0x49 to 0x2111, 0x52 to 0x211C, 0x5A to 0x2128,
    )

    /** Double-struck (Outline) reserved letters. */
    private val dbX: Map<Int, Int> = mapOf(
        0x43 to 0x2102, 0x48 to 0x210D, 0x4E to 0x2115, 0x50 to 0x2119,
        0x51 to 0x211A, 0x52 to 0x211D, 0x5A to 0x2124,
    )

    // ── Char maps (verbatim from iOS) ────────────────────────────────────

    /** Comic — Canadian Aboriginal syllabics + Cherokee glyphs. */
    private val alienMap: Map<Char, String> = mapOf(
        'a' to "ᗩ", 'b' to "ᗷ", 'c' to "ᑕ", 'd' to "ᗪ", 'e' to "ᗴ", 'f' to "ᖴ", 'g' to "ᘜ", 'h' to "ᕼ", 'i' to "I", 'j' to "ᒍ",
        'k' to "ᛕ", 'l' to "ᒪ", 'm' to "ᗰ", 'n' to "ᑎ", 'o' to "O", 'p' to "ᑭ", 'q' to "ᑫ", 'r' to "ᖇ", 's' to "ᔕ", 't' to "ᖶ",
        'u' to "ᑌ", 'v' to "ᐯ", 'w' to "ᗯ", 'x' to "᙭", 'y' to "Ƴ", 'z' to "ᘔ",
        'A' to "ᗩ", 'B' to "ᗷ", 'C' to "ᑕ", 'D' to "ᗪ", 'E' to "ᗴ", 'F' to "ᖴ", 'G' to "ᘜ", 'H' to "ᕼ", 'I' to "I", 'J' to "ᒍ",
        'K' to "ᛕ", 'L' to "ᒪ", 'M' to "ᗰ", 'N' to "ᑎ", 'O' to "O", 'P' to "ᑭ", 'Q' to "ᑫ", 'R' to "ᖇ", 'S' to "ᔕ", 'T' to "ᖶ",
        'U' to "ᑌ", 'V' to "ᐯ", 'W' to "ᗯ", 'X' to "᙭", 'Y' to "Ƴ", 'Z' to "ᘔ",
    )

    /** Cursive — math italic + Sundanese/Cyrillic look-alikes. */
    private val cursiveMap: Map<Char, String> = mapOf(
        'a' to "ᥲ", 'b' to "𝘣", 'c' to "ᥴ", 'd' to "ᦔ", 'e' to "ᥱ",
        'f' to "𝘧", 'g' to "g", 'h' to "һ", 'i' to "і", 'j' to "𝘫",
        'k' to "𝘬", 'l' to "ᥣ", 'm' to "𝘮", 'n' to "𝘯", 'o' to "𝘰",
        'p' to "𝘱", 'q' to "𝘲", 'r' to "r", 's' to "s", 't' to "𝗍",
        'u' to "ᥙ", 'v' to "᥎", 'w' to "𝘸", 'x' to "𝘹", 'y' to "ᥡ", 'z' to "𝘻",
        'A' to "ᥲ", 'B' to "𝘣", 'C' to "ᥴ", 'D' to "ᦔ", 'E' to "ᥱ",
        'F' to "𝘧", 'G' to "g", 'H' to "һ", 'I' to "і", 'J' to "𝘫",
        'K' to "𝘬", 'L' to "ᥣ", 'M' to "𝘮", 'N' to "𝘯", 'O' to "𝘰",
        'P' to "𝘱", 'Q' to "𝘲", 'R' to "r", 'S' to "s", 'T' to "𝗍",
        'U' to "ᥙ", 'V' to "᥎", 'W' to "𝘸", 'X' to "𝘹", 'Y' to "ᥡ", 'Z' to "𝘻",
    )

    /** Small Caps — only lowercase mapped; uppercase passes through. */
    private val scMap: Map<Char, String> = mapOf(
        'a' to "ᴀ", 'b' to "ʙ", 'c' to "ᴄ", 'd' to "ᴅ", 'e' to "ᴇ", 'f' to "ꜰ", 'g' to "ɢ", 'h' to "ʜ", 'i' to "ɪ", 'j' to "ᴊ",
        'k' to "ᴋ", 'l' to "ʟ", 'm' to "ᴍ", 'n' to "ɴ", 'o' to "ᴏ", 'p' to "ᴘ", 'q' to "q", 'r' to "ʀ", 's' to "s", 't' to "ᴛ",
        'u' to "ᴜ", 'v' to "ᴠ", 'w' to "ᴡ", 'x' to "x", 'y' to "ʏ", 'z' to "ᴢ",
    )

    /** Superscript. */
    private val supMap: Map<Char, String> = mapOf(
        'A' to "ᴬ", 'B' to "ᴮ", 'C' to "ᶜ", 'D' to "ᴰ", 'E' to "ᴱ", 'F' to "ᶠ", 'G' to "ᴳ", 'H' to "ᴴ", 'I' to "ᴵ", 'J' to "ᴶ",
        'K' to "ᴷ", 'L' to "ᴸ", 'M' to "ᴹ", 'N' to "ᴺ", 'O' to "ᴼ", 'P' to "ᴾ", 'Q' to "Q", 'R' to "ᴿ", 'S' to "ˢ", 'T' to "ᵀ",
        'U' to "ᵁ", 'V' to "ⱽ", 'W' to "ᵂ", 'X' to "ˣ", 'Y' to "ʸ", 'Z' to "ᶻ",
        'a' to "ᵃ", 'b' to "ᵇ", 'c' to "ᶜ", 'd' to "ᵈ", 'e' to "ᵉ", 'f' to "ᶠ", 'g' to "ᵍ", 'h' to "ʰ", 'i' to "ⁱ", 'j' to "ʲ",
        'k' to "ᵏ", 'l' to "ˡ", 'm' to "ᵐ", 'n' to "ⁿ", 'o' to "ᵒ", 'p' to "ᵖ", 'q' to "q", 'r' to "ʳ", 's' to "ˢ", 't' to "ᵗ",
        'u' to "ᵘ", 'v' to "ᵛ", 'w' to "ʷ", 'x' to "ˣ", 'y' to "ʸ", 'z' to "ᶻ",
        '0' to "⁰", '1' to "¹", '2' to "²", '3' to "³", '4' to "⁴", '5' to "⁵", '6' to "⁶", '7' to "⁷", '8' to "⁸", '9' to "⁹",
    )

    /** Subscript. */
    private val subMap: Map<Char, String> = mapOf(
        'a' to "ₐ", 'b' to "♭", 'c' to "꜀", 'd' to "d", 'e' to "ₑ", 'f' to "բ", 'g' to "₉", 'h' to "ₕ", 'i' to "ᵢ", 'j' to "ⱼ",
        'k' to "ₖ", 'l' to "ₗ", 'm' to "ₘ", 'n' to "ₙ", 'o' to "ₒ", 'p' to "ₚ", 'q' to "q", 'r' to "ᵣ", 's' to "ₛ", 't' to "ₜ",
        'u' to "ᵤ", 'v' to "ᵥ", 'w' to "w", 'x' to "ₓ", 'y' to "ᵧ", 'z' to "z",
        'A' to "ₐ", 'B' to "♭", 'C' to "꜀", 'D' to "D", 'E' to "ₑ", 'F' to "բ", 'G' to "₉", 'H' to "ₕ", 'I' to "ᵢ", 'J' to "ⱼ",
        'K' to "ₖ", 'L' to "ₗ", 'M' to "ₘ", 'N' to "ₙ", 'O' to "ₒ", 'P' to "ₚ", 'Q' to "Q", 'R' to "ᵣ", 'S' to "ₛ", 'T' to "ₜ",
        'U' to "ᵤ", 'V' to "ᵥ", 'W' to "W", 'X' to "ₓ", 'Y' to "ᵧ", 'Z' to "Z",
        '0' to "₀", '1' to "₁", '2' to "₂", '3' to "₃", '4' to "₄", '5' to "₅", '6' to "₆", '7' to "₇", '8' to "₈", '9' to "₉",
    )

    /** Upside-down map for Flip. The output string is also reversed. */
    private val udMap: Map<Char, String> = mapOf(
        'a' to "ɐ", 'b' to "q", 'c' to "ɔ", 'd' to "p", 'e' to "ǝ", 'f' to "ɟ", 'g' to "ƃ", 'h' to "ɥ", 'i' to "ᴉ", 'j' to "ɾ",
        'k' to "ʞ", 'l' to "l", 'm' to "ɯ", 'n' to "u", 'o' to "o", 'p' to "d", 'q' to "b", 'r' to "ɹ", 's' to "s", 't' to "ʇ",
        'u' to "n", 'v' to "ʌ", 'w' to "ʍ", 'x' to "x", 'y' to "ʎ", 'z' to "z",
        'A' to "∀", 'B' to "ᗺ", 'C' to "Ɔ", 'D' to "ᗡ", 'E' to "Ǝ", 'F' to "Ⅎ", 'G' to "⅁", 'H' to "H", 'I' to "I", 'J' to "ſ",
        'K' to "ʞ", 'L' to "˥", 'M' to "W", 'N' to "N", 'O' to "O", 'P' to "Ԁ", 'Q' to "Q", 'R' to "ᴚ", 'S' to "S", 'T' to "⊥",
        'U' to "∩", 'V' to "Λ", 'W' to "M", 'X' to "X", 'Y' to "⅄", 'Z' to "Z",
        '1' to "Ɩ", '2' to "ᄅ", '3' to "Ɛ", '4' to "ㄣ", '5' to "ϛ", '6' to "9", '7' to "ㄥ", '8' to "8", '9' to "6", '0' to "0",
        '.' to "˙", ',' to "'", '!' to "¡", '?' to "¿", '(' to ")", ')' to "(",
    )

    // ── 46 styles (matches iOS allFontCategories order) ──────────────────
    val fontStyles: List<UnicodeStyle> = listOf(
        // 클래식
        UnicodeStyle("Normal"),
        UnicodeStyle("Italic",       0x1D434, 0x1D44E, exceptions = itX),
        UnicodeStyle("Bold",         0x1D5D4, 0x1D5EE, digit = 0x1D7EC),
        UnicodeStyle("Bold Italic",  0x1D468, 0x1D482, digit = 0x1D7CE),
        UnicodeStyle("Script",       0x1D49C, 0x1D4B6, exceptions = scX),
        UnicodeStyle("Bold Script",  0x1D4D0, 0x1D4EA),
        UnicodeStyle("Gothic",       0x1D504, 0x1D51E, exceptions = goX),
        UnicodeStyle("Typewriter",   0x1D670, 0x1D68A, digit = 0x1D7F6),
        UnicodeStyle("Outline",      0x1D538, 0x1D552, digit = 0x1D7D8, exceptions = dbX),
        UnicodeStyle("Comic",        charMap = alienMap),
        UnicodeStyle("Cursive",      charMap = cursiveMap),

        // 모던
        UnicodeStyle("Wide",         0xFF21, 0xFF41, digit = 0xFF10),
        UnicodeStyle("Dark",         0x1D56C, 0x1D586),
        UnicodeStyle("Sans",         0x1D5A0, 0x1D5BA, digit = 0x1D7E2),
        UnicodeStyle("Sans Italic",  0x1D608, 0x1D622),
        UnicodeStyle("Heavy",        0x1D63C, 0x1D656),

        // 굵게
        UnicodeStyle("Serif Bold",   0x1D400, 0x1D41A, digit = 0x1D7CE),
        // Chunky / Block: enclosed alphanumerics that share a single block —
        // both A and a map to the same codepoint, so upper == lower.
        UnicodeStyle("Chunky",       0x1F150, 0x1F150),
        UnicodeStyle("Block",        0x1F170, 0x1F170),

        // 재미있는
        UnicodeStyle("Flip",         upsideDown = udMap),
        UnicodeStyle("Bubble",       0x24B6,  0x24D0),
        UnicodeStyle("Square",       0x1F130, 0x1F130),
        UnicodeStyle("Small Caps",   charMap = scMap),
        UnicodeStyle("Sad",          combining = "̈"),
        UnicodeStyle("Happy",        combining = "̤"),
        UnicodeStyle("Clouds",       combining = "͓̽"),
        UnicodeStyle("Stinky",       combining = "̇"),
        UnicodeStyle("Wiggle",       combining = "͠"),
        UnicodeStyle("Rays",         combining = "̾"),
        UnicodeStyle("Skyline",      combining = "̲"), // = Underline
        UnicodeStyle("Blinds",       combining = "̶"), // = Strikethrough
        UnicodeStyle("Arrows",       combining = "⃗"),
        UnicodeStyle("Super",        charMap = supMap),
        UnicodeStyle("Cloudy",       wrapBefore = "☁"),

        // 장식
        UnicodeStyle("Overline",     combining = "̅"),
        UnicodeStyle("Sparkle",      combining = "꙰"), // ꙰
        UnicodeStyle("Candy",        wrapBefore = "♡", wrapAfter = "♡"),
        UnicodeStyle("Pinched",      combining = "̃"),

        // 추가스타일
        UnicodeStyle("Ringed",       combining = "̊"),
        UnicodeStyle("Dotted",       combining = "̣"),
        UnicodeStyle("Box",          wrapBefore = "[", wrapAfter = "]"),
        UnicodeStyle("Sub",          charMap = subMap),

        // 독특한
        UnicodeStyle("Chaos",        combining = "҉"),
        UnicodeStyle("Zalgo",        combining = "̴̰̈"),
        // Ancient: Old Italic block (0x10300+) shares both A-Z and a-z onto
        // the same codepoint range — upper == lower mirrors iOS's
        // `_oc(t, 0x10300, 0x10300, nil)`.
        UnicodeStyle("Ancient",      0x10300, 0x10300),
        UnicodeStyle("Halo",         combining = "͜"),
    )

    /** Group of related styles surfaced as a tab in the Aa keypad. Matches the
     *  category grouping in iOS `KeyboardViewController.swift` `allFontCategories`. */
    data class FontCategory(val name: String, val styles: List<UnicodeStyle>)

    val fontCategories: List<FontCategory> = listOf(
        FontCategory("클래식", listOf(
            // Normal, Italic, Bold, Bold Italic, Script, Bold Script,
            // Gothic, Typewriter, Outline, Comic, Cursive
            fontStyles[0], fontStyles[1], fontStyles[2], fontStyles[3],
            fontStyles[4], fontStyles[5], fontStyles[6], fontStyles[7],
            fontStyles[8], fontStyles[9], fontStyles[10],
        )),
        FontCategory("모던", listOf(
            // Wide, Dark, Sans, Sans Italic, Heavy
            fontStyles[11], fontStyles[12], fontStyles[13], fontStyles[14], fontStyles[15],
        )),
        FontCategory("굵게", listOf(
            // Serif Bold, Chunky, Block
            fontStyles[16], fontStyles[17], fontStyles[18],
        )),
        FontCategory("재미있는", listOf(
            // Flip, Bubble, Square, Small Caps, Sad, Happy, Clouds, Stinky,
            // Wiggle, Rays, Skyline, Blinds, Arrows, Super, Cloudy
            fontStyles[19], fontStyles[20], fontStyles[21], fontStyles[22], fontStyles[23],
            fontStyles[24], fontStyles[25], fontStyles[26], fontStyles[27], fontStyles[28],
            fontStyles[29], fontStyles[30], fontStyles[31], fontStyles[32], fontStyles[33],
        )),
        FontCategory("장식", listOf(
            // Overline, Sparkle, Candy, Pinched
            fontStyles[34], fontStyles[35], fontStyles[36], fontStyles[37],
        )),
        FontCategory("추가", listOf(
            // Ringed, Dotted, Box, Sub
            fontStyles[38], fontStyles[39], fontStyles[40], fontStyles[41],
        )),
        FontCategory("독특한", listOf(
            // Chaos, Zalgo, Ancient, Halo
            fontStyles[42], fontStyles[43], fontStyles[44], fontStyles[45],
        )),
    )

    fun convert(input: String, style: UnicodeStyle): String {
        // 1) Direct char-map (Comic, Cursive, Small Caps, Super, Sub).
        style.charMap?.let { map ->
            return input.map { c -> map[c] ?: c.toString() }.joinToString("")
        }

        // 2) Upside-down (Flip): apply per-char map, then reverse the whole string.
        style.upsideDown?.let { map ->
            val mapped = input.map { c -> map[c] ?: c.toString() }.joinToString("")
            return mapped.reversed()
        }

        // 3) Per-char wrapping (Cloudy, Candy, Box). Spaces preserved untouched.
        if (style.wrapBefore != null || style.wrapAfter != null) {
            val before = style.wrapBefore ?: ""
            val after = style.wrapAfter ?: ""
            return input.map { c ->
                if (c == ' ') " " else "$before$c$after"
            }.joinToString("")
        }

        // 4) Combining marks appended after each non-whitespace char.
        style.combining?.let { mark ->
            val sb = StringBuilder()
            for (c in input) {
                sb.append(c)
                if (!c.isWhitespace()) sb.append(mark)
            }
            return sb.toString()
        }

        // 5) Default: codepoint offset (Bold, Italic, Wide, …).
        if (style.upper == 0x0041 && style.lower == 0x0061 && style.digit == null
            && style.exceptions.isEmpty()
        ) {
            return input
        }
        val sb = StringBuilder()
        input.codePoints().forEach { c ->
            when {
                style.exceptions.containsKey(c) -> sb.appendCodePoint(style.exceptions[c]!!)
                c in 0x41..0x5A -> sb.appendCodePoint(style.upper + (c - 0x41))
                c in 0x61..0x7A -> sb.appendCodePoint(style.lower + (c - 0x61))
                style.digit != null && c in 0x30..0x39 -> sb.appendCodePoint(style.digit + (c - 0x30))
                else -> sb.appendCodePoint(c)
            }
        }
        return sb.toString()
    }
}
