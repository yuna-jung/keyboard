// MARK: - StickerLibrary
//
// Owns the App Group–shared "sticker library": a `Stickers/` folder of PNGs
// and GIFs plus a `stickers_manifest.json` recording creation time + type
// per file, both inside the shared container (`group.com.yunajung.fonki`,
// already entitled on both the Runner and font_keyboard targets — no new
// entitlement needed).
//
// Single source of truth for this folder/manifest format so both
// `AppDelegate.swift` (list/delete, exposed to Dart over the `appgroup`
// channel) and `StickerImagePicker.swift` (save, at the moment a sticker's
// bytes are already in hand) go through the same code rather than each
// re-implementing the file layout.
//
// Phase 2 scope: main-app read/write only. The keyboard extension only
// reads (`list()`) — manifest writes here aren't locked against concurrent
// writers, which is fine for a single writer process.

import Foundation

enum StickerLibrary {
    private static let appGroupID = "group.com.yunajung.fonki"
    private static let stickersFolderName = "Stickers"
    private static let manifestFileName = "stickers_manifest.json"

    struct Entry: Codable {
        let fileName: String
        let createdAt: Double // epoch milliseconds
        let type: String // "png" | "gif"

        private enum CodingKeys: String, CodingKey {
            case fileName, createdAt, type
        }

        init(fileName: String, createdAt: Double, type: String) {
            self.fileName = fileName
            self.createdAt = createdAt
            self.type = type
        }

        /// Manifest entries written before GIF support existed have no
        /// `type` key at all — default those to "png" (what they actually
        /// are) rather than failing to decode the whole entry.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            fileName = try container.decode(String.self, forKey: .fileName)
            createdAt = try container.decode(Double.self, forKey: .createdAt)
            type = (try? container.decode(String.self, forKey: .type)) ?? "png"
        }
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

    /// Saves `data` as a new sticker file (`.gif` when `type == "gif"`,
    /// `.png` otherwise) and appends a manifest entry. Returns the saved
    /// file's URL, or `nil` on any failure (App Group unavailable, disk
    /// write failed, etc.) — callers treat that as "the sticker library
    /// copy failed" without it affecting the separate Photos-library save
    /// this is always called alongside.
    @discardableResult
    static func save(data: Data, type: String) -> URL? {
        ensureFolderExists()
        guard let folder = stickersFolderURL else { return nil }
        let ext = type == "gif" ? "gif" : "png"
        let fileName = "sticker_\(UUID().uuidString).\(ext)"
        let fileURL = folder.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            return nil
        }
        var entries = loadManifest()
        entries.append(Entry(fileName: fileName, createdAt: Date().timeIntervalSince1970 * 1000, type: type))
        saveManifest(entries)
        return fileURL
    }

    /// Newest-first list of stickers currently on disk. Filters out any
    /// manifest entry whose file is missing (defensive — shouldn't happen
    /// through normal use, but avoids ever handing Dart a dead path).
    static func list() -> [(path: String, createdAt: Double, type: String)] {
        guard let folder = stickersFolderURL else { return [] }
        let entries = loadManifest().sorted { $0.createdAt > $1.createdAt }
        return entries.compactMap { entry in
            let fileURL = folder.appendingPathComponent(entry.fileName)
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
            return (path: fileURL.path, createdAt: entry.createdAt, type: entry.type)
        }
    }

    /// Deletes both the file and its manifest entry, matched by the
    /// absolute path `list()` handed to Dart (Dart hands the same string
    /// back here — only the last path component, the file name, actually
    /// needs to match). Extension-agnostic — matches by file name exactly
    /// as recorded in the manifest, so this works the same for `.png` and
    /// `.gif` entries. Returns `true` only if a manifest entry was actually
    /// found and removed.
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
