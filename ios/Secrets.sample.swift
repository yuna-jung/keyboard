// Template for ios/font_keyboard/Secrets.swift (which is gitignored).
//
// Setup:
//   cp ios/Secrets.sample.swift ios/font_keyboard/Secrets.swift
// Then edit ios/font_keyboard/Secrets.swift with your real API keys.
//
// This file lives OUTSIDE ios/font_keyboard/ on purpose so Xcode does not
// compile it — the synchronized group for font_keyboard only picks up files
// inside that folder.

import Foundation

enum Secrets {
    static let openAIKey = "YOUR_OPENAI_API_KEY"
    static let giphyApiKey = "YOUR_GIPHY_API_KEY"
}
