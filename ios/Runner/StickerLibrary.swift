// MARK: - StickerLibrary
//
// Owns the App Group–shared "sticker library": a `Stickers/` folder of PNGs
// plus a `stickers_manifest.json` recording creation time per file, both
// inside the shared container (`group.com.yunajung.fonki`, already
// entitled on both the Runner and font_keyboard targets — no new
// entitlement needed).
//
// Single source of truth for this folder/manifest format so both
// `AppDelegate.swift` (list/delete, exposed to Dart over the `appgroup`
// channel) and `DrawingCanvasPlatformView.swift` (save, at the moment a
// sticker's PNG bytes are already in hand) go through the same code rather
// than each re-implementing the file layout.
//
// Phase 2 scope: main-app read/write only. The keyboard extension doesn't
// touch this folder yet (that's phase 3) — manifest writes here aren't
// locked against concurrent writers, which is fine for a single process
// but will need revisiting once the extension also writes to it.

import Foundation

enum StickerLibrary {
    private static let appGroupID = "group.com.yunajung.fonki"
    private static let stickersFolderName = "Stickers"
    private static let manifestFileName = "stickers_manifest.json"

    struct Entry: Codable {
        let fileName: String
        let createdAt: Double // epoch milliseconds
    }

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    private static var stickersFolderURL: URL? {
        containerURL?.appendingPathComponent(stickersFolderName, isDirectory: true)
    }

    private static var manifestURL: URL? {
        containerURL?.appendingPathComponent(manifestFileName)
    }

    private static func ensureFolderExists() {
        guard let folder = stickersFolderURL else { return }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    private static func loadManifest() -> [Entry] {
        guard let url = manifestURL, let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }

    private static func saveManifest(_ entries: [Entry]) {
        guard let url = manifestURL, let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// Saves `pngData` as a new sticker file and appends a manifest entry.
    /// Returns the saved file's URL, or `nil` on any failure (App Group
    /// unavailable, disk write failed, etc.) — callers treat that as "the
    /// sticker library copy failed" without it affecting the separate
    /// Photos-library save this is always called alongside.
    @discardableResult
    static func save(pngData: Data) -> URL? {
        ensureFolderExists()
        guard let folder = stickersFolderURL else { return nil }
        let fileName = "sticker_\(UUID().uuidString).png"
        let fileURL = folder.appendingPathComponent(fileName)
        do {
            try pngData.write(to: fileURL, options: .atomic)
        } catch {
            return nil
        }
        var entries = loadManifest()
        entries.append(Entry(fileName: fileName, createdAt: Date().timeIntervalSince1970 * 1000))
        saveManifest(entries)
        return fileURL
    }

    /// Newest-first list of stickers currently on disk. Filters out any
    /// manifest entry whose file is missing (defensive — shouldn't happen
    /// through normal use, but avoids ever handing Dart a dead path).
    static func list() -> [(path: String, createdAt: Double)] {
        guard let folder = stickersFolderURL else { return [] }
        let entries = loadManifest().sorted { $0.createdAt > $1.createdAt }
        return entries.compactMap { entry in
            let fileURL = folder.appendingPathComponent(entry.fileName)
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
            return (path: fileURL.path, createdAt: entry.createdAt)
        }
    }

    /// Deletes both the file and its manifest entry, matched by the
    /// absolute path `list()` handed to Dart (Dart hands the same string
    /// back here — only the last path component, the file name, actually
    /// needs to match). Returns `true` only if a manifest entry was
    /// actually found and removed.
    @discardableResult
    static func delete(path: String) -> Bool {
        guard let folder = stickersFolderURL else { return false }
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        try? FileManager.default.removeItem(at: folder.appendingPathComponent(fileName))

        var entries = loadManifest()
        let originalCount = entries.count
        entries.removeAll { $0.fileName == fileName }
        guard entries.count < originalCount else { return false }
        saveManifest(entries)
        return true
    }
}
