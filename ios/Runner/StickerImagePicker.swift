// MARK: - StickerImagePicker
//
// Presents PHPickerViewController for the "이미지로 스티커 만들기" feature.
//
// Single selection (unchanged from before multi-select): hands the picked
// item back to Dart as `{"kind": "single", "type": "png"|"gif", "data": <bytes>}`
// — Dart shows a preview (`Image.memory`, which animates automatically for
// multi-frame GIF data) with a save/cancel choice, then calls back in to
// save it.
//
// Multi-selection: no per-item preview — every picked item is processed
// and saved to the App Group sticker library natively, right here, and the
// result comes back as one aggregate
// `{"kind": "batch", "saved": <Int>, "failed": <Int>}`. Reuses the exact
// same per-item load logic as the single-selection path (`loadPickedItem`)
// rather than a separate implementation — a `DispatchGroup` just fans it
// out over every provider and waits for all of them.
//
// GIF vs static image are two genuinely different pipelines, not just a
// cosmetic branch, for both paths:
//   - Static images go through the existing center-crop-to-square +
//     UIImage-based PNG render.
//   - GIFs skip cropping entirely (out of scope for this pass — re-encoding
//     a cropped multi-frame GIF is a much bigger job) and read the
//     original file's raw bytes via `loadFileRepresentation`, never through
//     `UIImage` — `loadObject(ofClass: UIImage.self)` collapses an animated
//     GIF to its first frame, the same loss the GIF search tab's clipboard
//     copy had to work around earlier this session.
//
// Saving writes only to the App Group sticker library (see
// StickerLibrary.swift) — no Photos-app copy (removed; stickers are meant
// to live in the App Group only).

import Flutter
import Photos
import PhotosUI
import UIKit
import UniformTypeIdentifiers

final class StickerImagePicker: NSObject {
    private let channel: FlutterMethodChannel
    private weak var presentingViewController: UIViewController?
    private var pendingPickerResult: FlutterResult?

    /// Cropped square output size, in pixels — static images only. Fixed
    /// rather than derived from an on-screen view — there's no canvas to
    /// size against anymore.
    private static let outputPixelSize = 1024

    /// Upper bound on how many items can be picked at once. The system
    /// picker UI itself doesn't get slower with a higher number — this
    /// caps how many items our own sequential crop/read/save work has to
    /// get through afterward. The main app process has much more memory
    /// headroom than the keyboard extension (which needed the aggressive
    /// viewport-based caps used elsewhere in this feature), so this is a
    /// generous round number rather than a tightly-measured limit.
    private static let maxSelectionCount = 20

    init(messenger: FlutterBinaryMessenger, presentingViewController: UIViewController?) {
        self.channel = FlutterMethodChannel(
            name: "com.yunajung.fonki/sticker_image",
            binaryMessenger: messenger
        )
        self.presentingViewController = presentingViewController
        super.init()
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "pickImage":
            presentImagePicker(result: result)

        case "saveImageToPhotoLibrary":
            guard let args = call.arguments as? [String: Any],
                  let typedData = args["data"] as? FlutterStandardTypedData,
                  let type = args["type"] as? String
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "saveImageToPhotoLibrary needs data + type", details: nil))
                return
            }
            if StickerLibrary.save(data: typedData.data, type: type) != nil {
                result(nil)
            } else {
                result(FlutterError(code: "SAVE_FAILED", message: "Could not save the sticker", details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Picker

    private func presentImagePicker(result: @escaping FlutterResult) {
        guard let presenter = presentingViewController else {
            result(FlutterError(code: "NO_PRESENTER", message: "No view controller to present the picker from", details: nil))
            return
        }
        var config = PHPickerConfiguration(photoLibrary: .shared())
        // GIFs conform to `public.image` (GIF's own UTI, com.compuserve.gif,
        // is a subtype of it), so they're already selectable under this
        // filter — no separate GIF filter needed. Confirmed on-device as
        // part of this feature's test pass; see the PR notes.
        config.filter = .images
        config.selectionLimit = Self.maxSelectionCount
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        pendingPickerResult = result
        presenter.present(picker, animated: true)
    }

    /// Crops `image` to a centered square and resizes it to exactly
    /// `pixelSize × pixelSize` pixels. Static images only.
    private static func centerCroppedSquare(_ image: UIImage, pixelSize: Int) -> UIImage? {
        guard let cgImage = image.cgImage, pixelSize > 0 else { return nil }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let side = min(width, height)
        let cropRect = CGRect(x: (width - side) / 2, y: (height - side) / 2, width: side, height: side)
        guard let croppedCG = cgImage.cropping(to: cropRect) else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: pixelSize, height: pixelSize), format: format)
        let resized = renderer.image { _ in
            UIImage(cgImage: croppedCG).draw(in: CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
        }
        guard let resizedCG = resized.cgImage else { return nil }
        return UIImage(cgImage: resizedCG, scale: 1, orientation: .up)
    }
}

extension StickerImagePicker: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else {
            // Empty `results` means the user cancelled — not an error, just
            // report "nothing picked" (nil) rather than an error.
            pendingPickerResult?(nil)
            pendingPickerResult = nil
            return
        }

        if results.count == 1 {
            loadSingle(results[0].itemProvider)
        } else {
            loadAndSaveBatch(results.map { $0.itemProvider })
        }
    }

    // MARK: - Single pick (existing preview-then-save flow, unchanged)

    private func loadSingle(_ provider: NSItemProvider) {
        loadPickedItem(provider) { [weak self] outcome in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch outcome {
                case .success(let type, let data):
                    self.pendingPickerResult?([
                        "kind": "single",
                        "type": type,
                        "data": FlutterStandardTypedData(bytes: data),
                    ])
                case .failure(let message):
                    self.pendingPickerResult?(FlutterError(code: "LOAD_FAILED", message: message, details: nil))
                }
                self.pendingPickerResult = nil
            }
        }
    }

    // MARK: - Batch pick (no preview — process + save every item, report counts)

    /// Fans `loadPickedItem` out over every provider concurrently (their
    /// own completion handlers already run on arbitrary background queues,
    /// same as the single-pick path always did) and saves each one to the
    /// App Group as soon as it loads — never through Dart, since there's no
    /// per-item confirmation step to round-trip for. `savedCount`/
    /// `failedCount` are mutated from those concurrent callbacks, hence the
    /// lock; `group.notify` fires once every item has either saved or
    /// failed, and reports both counts back to Dart in a single call.
    private func loadAndSaveBatch(_ providers: [NSItemProvider]) {
        let group = DispatchGroup()
        let lock = NSLock()
        var savedCount = 0
        var failedCount = 0

        for provider in providers {
            group.enter()
            loadPickedItem(provider) { outcome in
                let ok: Bool
                switch outcome {
                case .success(let type, let data):
                    ok = StickerLibrary.save(data: data, type: type) != nil
                case .failure:
                    ok = false
                }
                lock.lock()
                if ok { savedCount += 1 } else { failedCount += 1 }
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.pendingPickerResult?([
                "kind": "batch",
                "saved": savedCount,
                "failed": failedCount,
            ])
            self?.pendingPickerResult = nil
        }
    }

    // MARK: - Shared per-item load (GIF raw bytes vs crop+PNG)

    private enum LoadOutcome {
        case success(type: String, data: Data)
        case failure(String)
    }

    /// Loads one picked item's bytes — GIF via raw file bytes (animation
    /// preserved), everything else via center-crop-to-square PNG. Used by
    /// both the single-pick and batch paths so this logic exists exactly
    /// once. Completion runs on whatever background queue the underlying
    /// `NSItemProvider` API calls back on, not necessarily the main thread
    /// — callers that touch UI-facing state must hop to main themselves
    /// (see `loadSingle`).
    private func loadPickedItem(_ provider: NSItemProvider, completion: @escaping (LoadOutcome) -> Void) {
        let gifType = UTType.gif.identifier
        if provider.hasItemConformingToTypeIdentifier(gifType) {
            // `loadFileRepresentation`'s URL is only valid inside this
            // completion handler (the system deletes the temp file right
            // after it returns), so the bytes are copied out synchronously
            // before returning.
            provider.loadFileRepresentation(forTypeIdentifier: gifType) { url, error in
                guard let url = url, error == nil, let data = try? Data(contentsOf: url) else {
                    completion(.failure(error?.localizedDescription ?? "Could not load the selected GIF"))
                    return
                }
                completion(.success(type: "gif", data: data))
            }
            return
        }

        guard provider.canLoadObject(ofClass: UIImage.self) else {
            completion(.failure("Unsupported item"))
            return
        }
        provider.loadObject(ofClass: UIImage.self) { object, error in
            guard let image = object as? UIImage, error == nil else {
                completion(.failure(error?.localizedDescription ?? "Could not load the selected image"))
                return
            }
            guard let cropped = Self.centerCroppedSquare(image, pixelSize: Self.outputPixelSize),
                  let pngData = cropped.pngData()
            else {
                completion(.failure("Could not crop the selected image"))
                return
            }
            completion(.success(type: "png", data: pngData))
        }
    }
}
