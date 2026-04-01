import 'package:characters/characters.dart';
import '../models/font_style_model.dart';

class UnicodeConverter {
  // ── Singleton ──────────────────────────────────────────────────────────
  UnicodeConverter._();
  static final instance = UnicodeConverter._();

  // ── Public API ─────────────────────────────────────────────────────────
  List<FontStyleModel> get styles => _styles;

  // ── Style definitions ──────────────────────────────────────────────────
  final List<FontStyleModel> _styles = [
    FontStyleModel(
      name: 'Normal',
      convert: _normal,
      isPremium: false,
    ),
    FontStyleModel(
      name: 'Bold',
      convert: _bold,
      isPremium: false,
    ),
    FontStyleModel(name: 'Italic', convert: _italic),
    FontStyleModel(name: 'Bold Italic', convert: _boldItalic),
    FontStyleModel(name: 'Script', convert: _script),
    FontStyleModel(name: 'Double Struck', convert: _doubleStruck),
    FontStyleModel(name: 'Monospace', convert: _monospace),
    FontStyleModel(name: 'Fullwidth', convert: _fullwidth),
    FontStyleModel(name: 'Gothic', convert: _gothic),
    FontStyleModel(name: 'Bold Gothic', convert: _boldGothic),
    FontStyleModel(name: 'Strikethrough', convert: _strikethrough),
    FontStyleModel(name: 'Underline', convert: _underline),
    FontStyleModel(name: 'Overline', convert: _overline),
    FontStyleModel(name: 'Flip', convert: _flip),
    FontStyleModel(name: 'Bubble', convert: _bubble),
    FontStyleModel(name: 'Square', convert: _square),
  ];

  // ── Converters ─────────────────────────────────────────────────────────

  static String _normal(String input) => input;

  // 𝐀 = U+1D400 (upper), 𝐚 = U+1D41A (lower), 𝟎 = U+1D7CE (digit)
  static String _bold(String input) => _mapChars(
        input,
        upper: 0x1D400,
        lower: 0x1D41A,
        digit: 0x1D7CE,
      );

  // 𝐴 = U+1D434 (upper), 𝑎 = U+1D44E (lower)
  // italic has special: h → ℎ (U+210E)
  static String _italic(String input) => _mapChars(
        input,
        upper: 0x1D434,
        lower: 0x1D44E,
        exceptions: {0x68: 0x210E}, // h
      );

  // 𝑨 = U+1D468 (upper), 𝒂 = U+1D482 (lower), 𝟎 = U+1D7CE (digit)
  static String _boldItalic(String input) => _mapChars(
        input,
        upper: 0x1D468,
        lower: 0x1D482,
        digit: 0x1D7CE,
      );

  // 𝒜 = U+1D49C (upper), 𝒶 = U+1D4B6 (lower)
  // Script has many exceptions for uppercase
  static String _script(String input) => _mapChars(
        input,
        upper: 0x1D49C,
        lower: 0x1D4B6,
        exceptions: {
          0x42: 0x212C, // B → ℬ
          0x45: 0x2130, // E → ℰ
          0x46: 0x2131, // F → ℱ
          0x48: 0x210B, // H → ℋ
          0x49: 0x2110, // I → ℐ
          0x4C: 0x2112, // L → ℒ
          0x4D: 0x2133, // M → ℳ
          0x52: 0x211B, // R → ℛ
          0x65: 0x212F, // e → ℯ
          0x67: 0x210A, // g → ℊ
          0x6F: 0x2134, // o → ℴ
        },
      );

  // 𝔸 = U+1D538 (upper), 𝕒 = U+1D552 (lower), 𝟘 = U+1D7D8 (digit)
  // Double-struck exceptions: C H N P Q R Z
  static String _doubleStruck(String input) => _mapChars(
        input,
        upper: 0x1D538,
        lower: 0x1D552,
        digit: 0x1D7D8,
        exceptions: {
          0x43: 0x2102, // C → ℂ
          0x48: 0x210D, // H → ℍ
          0x4E: 0x2115, // N → ℕ
          0x50: 0x2119, // P → ℙ
          0x51: 0x211A, // Q → ℚ
          0x52: 0x211D, // R → ℝ
          0x5A: 0x2124, // Z → ℤ
        },
      );

  // 𝙰 = U+1D670 (upper), 𝚊 = U+1D68A (lower), 𝟶 = U+1D7F6 (digit)
  static String _monospace(String input) => _mapChars(
        input,
        upper: 0x1D670,
        lower: 0x1D68A,
        digit: 0x1D7F6,
      );

  // Ａ = U+FF21 (upper), ａ = U+FF41 (lower), ０ = U+FF10 (digit)
  // Also maps space → U+3000 (ideographic space) and ASCII ! to ~ range
  static String _fullwidth(String input) {
    final buffer = StringBuffer();
    for (final ch in input.characters) {
      final code = ch.runes.first;
      if (code >= 0x21 && code <= 0x7E) {
        // ASCII printable (excl. space) → fullwidth
        buffer.writeCharCode(0xFF01 + (code - 0x21));
      } else if (code == 0x20) {
        buffer.writeCharCode(0x3000); // ideographic space
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  // 𝔄 = U+1D504 (upper), 𝔞 = U+1D51E (lower)
  // Gothic (Fraktur) exceptions: C H I R Z
  static String _gothic(String input) => _mapChars(
        input,
        upper: 0x1D504,
        lower: 0x1D51E,
        exceptions: {
          0x43: 0x212D, // C → ℭ
          0x48: 0x210C, // H → ℌ
          0x49: 0x2111, // I → ℑ
          0x52: 0x211C, // R → ℜ
          0x5A: 0x2128, // Z → ℨ
        },
      );

  // 𝕬 = U+1D56C (upper), 𝖆 = U+1D586 (lower)
  static String _boldGothic(String input) => _mapChars(
        input,
        upper: 0x1D56C,
        lower: 0x1D586,
      );

  // Combining strikethrough: U+0336 after each grapheme
  static String _strikethrough(String input) =>
      _addCombining(input, 0x0336);

  // Combining underline: U+0332 after each grapheme
  static String _underline(String input) =>
      _addCombining(input, 0x0332);

  // Combining overline: U+0305 after each grapheme
  static String _overline(String input) =>
      _addCombining(input, 0x0305);

  // Flip text upside-down and reverse order
  static String _flip(String input) {
    final flipped = input.characters.map((ch) {
      return _flipMap[ch] ?? ch;
    }).toList();
    return flipped.reversed.join();
  }

  // Circled letters: Ⓐ = U+24B6 (upper), ⓐ = U+24D0 (lower), ⓪①… (digit)
  static String _bubble(String input) {
    final buffer = StringBuffer();
    for (final ch in input.characters) {
      final code = ch.runes.first;
      if (code >= 0x41 && code <= 0x5A) {
        buffer.writeCharCode(0x24B6 + (code - 0x41));
      } else if (code >= 0x61 && code <= 0x7A) {
        buffer.writeCharCode(0x24D0 + (code - 0x61));
      } else if (code == 0x30) {
        buffer.writeCharCode(0x24EA); // ⓪
      } else if (code >= 0x31 && code <= 0x39) {
        buffer.writeCharCode(0x2460 + (code - 0x31)); // ①‥⑨
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  // Squared letters: 🄰 = U+1F130 (upper), lower → treated as upper
  static String _square(String input) {
    final buffer = StringBuffer();
    for (final ch in input.characters) {
      final code = ch.runes.first;
      if (code >= 0x41 && code <= 0x5A) {
        buffer.writeCharCode(0x1F130 + (code - 0x41));
      } else if (code >= 0x61 && code <= 0x7A) {
        buffer.writeCharCode(0x1F130 + (code - 0x61));
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Maps A-Z, a-z, and optionally 0-9 to their Unicode math-styled codepoints.
  /// [exceptions] overrides specific ASCII codepoints with dedicated Unicode chars.
  static String _mapChars(
    String input, {
    required int upper,
    required int lower,
    int? digit,
    Map<int, int> exceptions = const {},
  }) {
    final buffer = StringBuffer();
    for (final ch in input.characters) {
      final code = ch.runes.first;
      if (exceptions.containsKey(code)) {
        buffer.writeCharCode(exceptions[code]!);
      } else if (code >= 0x41 && code <= 0x5A) {
        buffer.writeCharCode(upper + (code - 0x41));
      } else if (code >= 0x61 && code <= 0x7A) {
        buffer.writeCharCode(lower + (code - 0x61));
      } else if (digit != null && code >= 0x30 && code <= 0x39) {
        buffer.writeCharCode(digit + (code - 0x30));
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  /// Appends a combining character after each visible grapheme cluster.
  static String _addCombining(String input, int combiningChar) {
    final buffer = StringBuffer();
    for (final ch in input.characters) {
      buffer.write(ch);
      // Don't add combining marks to whitespace
      if (ch.trim().isNotEmpty) {
        buffer.writeCharCode(combiningChar);
      }
    }
    return buffer.toString();
  }

  // ── Flip map ───────────────────────────────────────────────────────────
  static const _flipMap = {
    'a': 'ɐ', 'b': 'q', 'c': 'ɔ', 'd': 'p', 'e': 'ǝ',
    'f': 'ɟ', 'g': 'ƃ', 'h': 'ɥ', 'i': 'ᴉ', 'j': 'ɾ',
    'k': 'ʞ', 'l': 'l', 'm': 'ɯ', 'n': 'u', 'o': 'o',
    'p': 'd', 'q': 'b', 'r': 'ɹ', 's': 's', 't': 'ʇ',
    'u': 'n', 'v': 'ʌ', 'w': 'ʍ', 'x': 'x', 'y': 'ʎ',
    'z': 'z',
    'A': '∀', 'B': 'q', 'C': 'Ɔ', 'D': 'p', 'E': 'Ǝ',
    'F': 'Ⅎ', 'G': 'פ', 'H': 'H', 'I': 'I', 'J': 'ſ',
    'K': 'ʞ', 'L': '˥', 'M': 'W', 'N': 'N', 'O': 'O',
    'P': 'Ԁ', 'Q': 'Q', 'R': 'ɹ', 'S': 'S', 'T': '⊥',
    'U': '∩', 'V': 'Λ', 'W': 'M', 'X': 'X', 'Y': '⅄',
    'Z': 'Z',
    '0': '0', '1': 'Ɩ', '2': 'ᄅ', '3': 'Ɛ', '4': 'ㄣ',
    '5': 'ϛ', '6': '9', '7': 'ㄥ', '8': '8', '9': '6',
    '.': '˙', ',': '\'', '\'': ',', '"': '„', '`': ',',
    '?': '¿', '!': '¡', '(': ')', ')': '(', '[': ']',
    ']': '[', '{': '}', '}': '{', '<': '>', '>': '<',
    '&': '⅋', '_': '‾', ';': '؛',
  };
}
