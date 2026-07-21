// MARK: - DrawingCanvasPlatformView
//
// Embeds a native PKCanvasView (PencilKit) into the Flutter (Runner) app via
// a Flutter platform view, for the sticker-drawing feature's phase 1 (main
// app canvas screen only — no keyboard extension, no App Group, no bucket
// tool; see the Dart-side screen for the full scope note).
//
// Built directly against PencilKit rather than a third-party Flutter
// wrapper package so the PNG export step can use exactly
// `UIGraphicsImageRenderer` with `isOpaque = false` as specified, and so
// later phases (flood fill, App Group export) can extend this same native
// view without depending on a low-adoption package's internals.

import Flutter
import PencilKit
import Photos
import UIKit

final class DrawingCanvasViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        DrawingCanvasPlatformView(frame: frame, viewId: viewId, messenger: messenger)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

final class DrawingCanvasPlatformView: NSObject, FlutterPlatformView {
    private let canvasView: PKCanvasView
    private let channel: FlutterMethodChannel

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger) {
        let canvas = PKCanvasView(frame: frame)
        // Transparent from the start, per spec — PKCanvasView defaults to an
        // opaque white background otherwise.
        canvas.isOpaque = false
        canvas.backgroundColor = .clear
        // Phones don't have Apple Pencil-only use cases here; allow finger
        // drawing too (PencilKit's own default varies by context, so this is
        // set explicitly rather than relied upon).
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: DrawingCanvasPlatformView.penWidths[1])
        self.canvasView = canvas

        self.channel = FlutterMethodChannel(
            name: "com.yunajung.fonki/drawing_canvas_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    func view() -> UIView { canvasView }

    // Thin/medium/thick — index selected by the Dart-side toolbar.
    private static let penWidths: [CGFloat] = [3, 8, 16]

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setPenTool":
            guard let args = call.arguments as? [String: Any],
                  let widthIndex = args["widthIndex"] as? Int,
                  widthIndex >= 0, widthIndex < Self.penWidths.count,
                  let colorHex = args["colorHex"] as? String,
                  let color = UIColor(fonkiiHex: colorHex)
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "setPenTool needs widthIndex + colorHex", details: nil))
                return
            }
            canvasView.tool = PKInkingTool(.pen, color: color, width: Self.penWidths[widthIndex])
            result(nil)

        case "setEraserTool":
            // `.vector` erases whole strokes at the touch point rather than
            // punching raster holes — the more predictable "partial eraser"
            // behavior for a finger/pencil eraser tool.
            canvasView.tool = PKEraserTool(.vector)
            result(nil)

        case "undo":
            canvasView.undoManager?.undo()
            result(nil)

        case "redo":
            canvasView.undoManager?.redo()
            result(nil)

        case "clear":
            canvasView.drawing = PKDrawing()
            result(nil)

        case "renderPNG":
            result(renderPNGData())

        case "saveImageToPhotoLibrary":
            guard let args = call.arguments as? [String: Any],
                  let typedData = args["pngData"] as? FlutterStandardTypedData,
                  let image = UIImage(data: typedData.data)
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "saveImageToPhotoLibrary needs pngData", details: nil))
                return
            }
            Self.saveToPhotoLibrary(image) { success, error in
                DispatchQueue.main.async {
                    if success {
                        result(nil)
                    } else {
                        result(FlutterError(
                            code: "SAVE_FAILED",
                            message: error?.localizedDescription ?? "Permission denied or unknown error",
                            details: nil
                        ))
                    }
                }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Renders the current drawing to transparent PNG data. Sources pixels
    /// from `PKDrawing.image(from:scale:)` (PencilKit's own strokes-only
    /// renderer — never draws a background) but performs the actual PNG
    /// encode through `UIGraphicsImageRenderer` with `isOpaque = false`, as
    /// specified, rather than `UIImage.pngData()` on the PencilKit image
    /// directly.
    private func renderPNGData() -> FlutterStandardTypedData? {
        let bounds = canvasView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let scale = UIScreen.main.scale
        let drawingImage = canvasView.drawing.image(from: bounds, scale: scale)

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
        let finalImage = renderer.image { _ in
            drawingImage.draw(in: CGRect(origin: .zero, size: bounds.size))
        }
        guard let pngData = finalImage.pngData() else { return nil }
        return FlutterStandardTypedData(bytes: pngData)
    }

    private static func saveToPhotoLibrary(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                completion(false, NSError(
                    domain: "DrawingCanvasPlatformView",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Photo Library permission denied"]
                ))
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, error in
                completion(success, error)
            })
        }
    }
}

private extension UIColor {
    /// Parses a `"#RRGGBB"` or `"#RRGGBBAA"` hex string. Returns `nil` on
    /// malformed input rather than silently falling back to some default
    /// color, so a bad value from the Dart side surfaces as an error instead
    /// of a wrong-but-valid-looking tool color.
    convenience init?(fonkiiHex hex: String) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8, let value = UInt32(s, radix: 16) else { return nil }
        let hasAlpha = s.count == 8
        let r, g, b, a: UInt32
        if hasAlpha {
            r = (value >> 24) & 0xFF
            g = (value >> 16) & 0xFF
            b = (value >> 8) & 0xFF
            a = value & 0xFF
        } else {
            r = (value >> 16) & 0xFF
            g = (value >> 8) & 0xFF
            b = value & 0xFF
            a = 0xFF
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
