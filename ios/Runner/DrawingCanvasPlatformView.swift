// MARK: - DrawingCanvasPlatformView
//
// Embeds a native PKCanvasView (PencilKit) into the Flutter (Runner) app via
// a Flutter platform view, for the sticker-drawing feature.
//
// Built directly against PencilKit rather than a third-party Flutter
// wrapper package so the PNG export step can use exactly
// `UIGraphicsImageRenderer` with `isOpaque = false` as specified, and so
// this phase's additions (flood fill, photo import) can extend the same
// native view without depending on a low-adoption package's internals.
//
// Layering: `containerView` holds two full-bounds subviews — `backgroundImageView`
// (a raster layer, bottom) and `canvasView` (PencilKit's vector strokes, top).
// PKDrawing can't represent an arbitrary filled region or an imported photo,
// so both the bucket tool's flood fill and image import write into that
// raster layer instead; strokes stay purely vector on top of it. Final PNG
// export composites both layers.
//
// Undo: PencilKit auto-registers undo actions on `canvasView.undoManager`
// for live strokes, but never for programmatic `canvasView.drawing = ...`
// assignments. Flood fills and image imports register their own undo step
// on that *same* `undoManager` instance via `registerUndo(withTarget:handler:)`
// (a standard Foundation `UndoManager` API, unrelated to PencilKit
// internals), so vector strokes and raster background changes interleave
// correctly in one chronological undo/redo stack with no extra
// coordination code.
//
// Eraser: PKEraserTool only ever erases vector strokes — it has no
// awareness of `backgroundImageView`, so it silently does nothing over a
// bucket fill or an imported photo. Rather than reimplementing PencilKit's
// own stroke hit-testing to erase vector content ourselves, entering
// eraser mode flattens any live strokes into the raster background layer
// once (`flattenDrawingIntoBackgroundIfNeeded`) and erasing thereafter is
// a plain raster operation (`handleEraseGesture`), consistent with the
// bucket tool. See that flatten step's own doc comment for how undo stays
// exact across the vector→raster transition.

import Flutter
import PencilKit
import Photos
import PhotosUI
import UIKit

final class DrawingCanvasViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    private weak var presentingViewController: UIViewController?

    init(messenger: FlutterBinaryMessenger, presentingViewController: UIViewController?) {
        self.messenger = messenger
        self.presentingViewController = presentingViewController
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        DrawingCanvasPlatformView(
            frame: frame,
            viewId: viewId,
            messenger: messenger,
            presentingViewController: presentingViewController
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

/// Plain container that keeps its two full-bounds children (`backgroundImageView`,
/// `canvasView`) in sync on any frame change (e.g. rotation) — `layoutSubviews`
/// is the one reliable hook for that regardless of what caused the resize.
private final class DrawingContainerView: UIView {
    var onLayout: ((CGRect) -> Void)?
    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?(bounds)
    }
}

final class DrawingCanvasPlatformView: NSObject, FlutterPlatformView {
    private let containerView: DrawingContainerView
    private let backgroundImageView: UIImageView
    private let canvasView: PKCanvasView
    private let channel: FlutterMethodChannel
    private weak var presentingViewController: UIViewController?

    private var tapGestureRecognizer: UITapGestureRecognizer?
    private var eraseGestureRecognizer: UIPanGestureRecognizer?
    private var bucketColor: UIColor = .black
    private var eraserWidthIndex: Int = 2 // middle of 5 — matches Dart's default
    private var pendingPickerResult: FlutterResult?

    // Erase-gesture-scoped state — only meaningful between a pan's `.began`
    // and `.ended`/`.cancelled`; reset to nil outside that window.
    private var eraseWorkingBuffer: [UInt8]?
    private var eraseGestureStartImage: UIImage?
    private var lastErasePoint: CGPoint?

    init(
        frame: CGRect,
        viewId: Int64,
        messenger: FlutterBinaryMessenger,
        presentingViewController: UIViewController?
    ) {
        let container = DrawingContainerView(frame: frame)
        container.backgroundColor = .clear

        let bgView = UIImageView(frame: container.bounds)
        bgView.contentMode = .scaleToFill
        bgView.backgroundColor = .clear
        bgView.isUserInteractionEnabled = false

        let canvas = PKCanvasView(frame: container.bounds)
        // Transparent from the start, per spec — PKCanvasView defaults to an
        // opaque white background otherwise.
        canvas.isOpaque = false
        canvas.backgroundColor = .clear
        // Phones don't have Apple Pencil-only use cases here; allow finger
        // drawing too (PencilKit's own default varies by context, so this is
        // set explicitly rather than relied upon).
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: DrawingCanvasPlatformView.penWidths[1])

        self.containerView = container
        self.backgroundImageView = bgView
        self.canvasView = canvas
        self.presentingViewController = presentingViewController

        self.channel = FlutterMethodChannel(
            name: "com.yunajung.fonki/drawing_canvas_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        container.addSubview(bgView)
        container.addSubview(canvas)
        container.onLayout = { [weak self] bounds in
            self?.backgroundImageView.frame = bounds
            self?.canvasView.frame = bounds
        }

        // Armed only while the bucket tool is active (see `setRasterMode`)
        // — `canvasView` itself is disabled at the same time so a tap can't
        // simultaneously register as the start of a pencil stroke.
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleContainerTap(_:)))
        tap.isEnabled = false
        container.addGestureRecognizer(tap)
        tapGestureRecognizer = tap

        // Armed only while the eraser is active — same mutual-exclusion
        // reasoning as the tap recognizer above.
        let erase = UIPanGestureRecognizer(target: self, action: #selector(handleEraseGesture(_:)))
        erase.isEnabled = false
        container.addGestureRecognizer(erase)
        eraseGestureRecognizer = erase

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    func view() -> UIView { containerView }

    // Thin/medium/thick — index selected by the Dart-side toolbar.
    private static let penWidths: [CGFloat] = [3, 8, 16]
    // Eraser gets its own, wider size range (5 steps, larger top end than
    // the pen's thickest) — erasing typically needs to cover more area
    // than a single stroke. Matches `_eraserWidthLabels` on the Dart side.
    private static let eraserWidths: [CGFloat] = [5, 10, 18, 28, 40]

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
            setRasterMode(.none)
            result(nil)

        case "setEraserTool":
            // The eraser operates entirely on the raster background layer
            // (see file header for why) rather than PencilKit's own
            // PKEraserTool, so live vector strokes are flattened into that
            // layer first — see `flattenDrawingIntoBackgroundIfNeeded`.
            guard let args = call.arguments as? [String: Any],
                  let widthIndex = args["widthIndex"] as? Int,
                  widthIndex >= 0, widthIndex < Self.eraserWidths.count
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "setEraserTool needs widthIndex", details: nil))
                return
            }
            eraserWidthIndex = widthIndex
            flattenDrawingIntoBackgroundIfNeeded()
            setRasterMode(.erase)
            result(nil)

        case "setBucketTool":
            guard let args = call.arguments as? [String: Any],
                  let colorHex = args["colorHex"] as? String,
                  let color = UIColor(fonkiiHex: colorHex)
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "setBucketTool needs colorHex", details: nil))
                return
            }
            bucketColor = color
            setRasterMode(.bucket)
            result(nil)

        case "undo":
            canvasView.undoManager?.undo()
            result(nil)

        case "redo":
            canvasView.undoManager?.redo()
            result(nil)

        case "clear":
            canvasView.drawing = PKDrawing()
            backgroundImageView.image = nil
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

        case "pickAndSetBackgroundImage":
            presentImagePicker(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private enum RasterMode { case none, bucket, erase }

    /// Exactly one of PencilKit's own touch handling / the bucket tap
    /// recognizer / the erase pan recognizer is ever enabled at a time, so a
    /// touch can never be interpreted as more than one of stroke/fill/erase.
    private func setRasterMode(_ mode: RasterMode) {
        canvasView.isUserInteractionEnabled = (mode == .none)
        tapGestureRecognizer?.isEnabled = (mode == .bucket)
        eraseGestureRecognizer?.isEnabled = (mode == .erase)
    }

    @objc private func handleContainerTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        performFloodFill(at: gesture.location(in: containerView), color: bucketColor)
    }

    // MARK: - Eraser (raster)

    /// Merges any live vector strokes into the raster background layer — the
    /// eraser can only operate on raster pixels (see file header), so
    /// anything still vector when eraser mode is entered must become raster
    /// first. A no-op if there's nothing to flatten (drawing already
    /// empty, e.g. the eraser was already active). Registers ONE undo step
    /// that restores both the pre-flatten `PKDrawing` and the pre-flatten
    /// background image together — via `restoreFlattenedState`, not
    /// `setBackgroundImage` — so undoing an erase that followed a flatten
    /// genuinely restores the original separate strokes, not just
    /// "whatever the raster looked like a moment ago".
    private func flattenDrawingIntoBackgroundIfNeeded() {
        guard !canvasView.drawing.strokes.isEmpty else { return }
        let previousDrawing = canvasView.drawing
        let previousBackground = backgroundImageView.image

        let bounds = canvasView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }
        let scale = UIScreen.main.scale
        let drawingImage = previousDrawing.image(from: bounds, scale: scale)

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
        let merged = renderer.image { _ in
            previousBackground?.draw(in: CGRect(origin: .zero, size: bounds.size))
            drawingImage.draw(in: CGRect(origin: .zero, size: bounds.size))
        }

        backgroundImageView.image = merged
        canvasView.drawing = PKDrawing()

        canvasView.undoManager?.registerUndo(withTarget: self) { target in
            target.restoreFlattenedState(drawing: previousDrawing, background: previousBackground)
        }
    }

    /// Inverse of `flattenDrawingIntoBackgroundIfNeeded` — restores both
    /// layers together and re-registers the redo step (same idiom as
    /// `setBackgroundImage`, just covering two layers instead of one).
    private func restoreFlattenedState(drawing: PKDrawing, background: UIImage?) {
        let currentDrawing = canvasView.drawing
        let currentBackground = backgroundImageView.image
        canvasView.drawing = drawing
        backgroundImageView.image = background
        canvasView.undoManager?.registerUndo(withTarget: self) { target in
            target.restoreFlattenedState(drawing: currentDrawing, background: currentBackground)
        }
    }

    /// One undo step per erase *gesture* (not per touch-move event, which
    /// would flood the undo stack) — `eraseGestureStartImage` snapshots the
    /// background right before the drag starts, and only the final result
    /// at `.ended` is compared against it and registered.
    @objc private func handleEraseGesture(_ gesture: UIPanGestureRecognizer) {
        let bounds = canvasView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }
        let scale = UIScreen.main.scale
        let width = Int(bounds.width * scale)
        let height = Int(bounds.height * scale)
        guard width > 0, height > 0 else { return }
        let radiusPoints = Self.eraserWidths[eraserWidthIndex]

        switch gesture.state {
        case .began:
            eraseGestureStartImage = backgroundImageView.image
            if let bg = backgroundImageView.image, let cg = bg.cgImage, cg.width == width, cg.height == height {
                eraseWorkingBuffer = Self.rgba8Bytes(from: cg, width: width, height: height)
            } else {
                eraseWorkingBuffer = [UInt8](repeating: 0, count: width * height * 4)
            }
            let point = gesture.location(in: containerView)
            lastErasePoint = point
            stampErase(at: point, radiusPoints: radiusPoints, width: width, height: height, scale: scale)
            updateBackgroundFromEraseBuffer(width: width, height: height, scale: scale)

        case .changed:
            let point = gesture.location(in: containerView)
            if let last = lastErasePoint {
                interpolateErase(from: last, to: point, radiusPoints: radiusPoints, width: width, height: height, scale: scale)
            }
            lastErasePoint = point
            updateBackgroundFromEraseBuffer(width: width, height: height, scale: scale)

        case .ended, .cancelled, .failed:
            let capturedPrevious = eraseGestureStartImage
            eraseWorkingBuffer = nil
            eraseGestureStartImage = nil
            lastErasePoint = nil
            canvasView.undoManager?.registerUndo(withTarget: self) { target in
                target.setBackgroundImage(capturedPrevious, registerUndo: true)
            }

        default:
            break
        }
    }

    private func stampErase(at point: CGPoint, radiusPoints: CGFloat, width: Int, height: Int, scale: CGFloat) {
        guard eraseWorkingBuffer != nil else { return }
        let radius = Int(radiusPoints * scale)
        let cx = Int(point.x * scale)
        let cy = Int(point.y * scale)
        Self.eraseCircle(centerX: cx, centerY: cy, radius: radius, width: width, height: height, into: &eraseWorkingBuffer!)
    }

    /// Stamps circles along the segment from `from` to `to` rather than just
    /// at `to` — a fast drag can jump several points between consecutive
    /// `.changed` callbacks, which would otherwise leave visible gaps in the
    /// erased path.
    private func interpolateErase(from: CGPoint, to: CGPoint, radiusPoints: CGFloat, width: Int, height: Int, scale: CGFloat) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let distance = (dx * dx + dy * dy).squareRoot()
        let step = max(radiusPoints / 2, 1)
        let steps = max(Int(distance / step), 1)
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            stampErase(
                at: CGPoint(x: from.x + dx * t, y: from.y + dy * t),
                radiusPoints: radiusPoints, width: width, height: height, scale: scale
            )
        }
    }

    private func updateBackgroundFromEraseBuffer(width: Int, height: Int, scale: CGFloat) {
        guard let buffer = eraseWorkingBuffer,
              let image = Self.image(fromRGBA8: buffer, width: width, height: height, scale: scale)
        else { return }
        // Direct assignment, not `setBackgroundImage` — undo is registered
        // once for the whole gesture in `handleEraseGesture`'s `.ended`
        // case, not on every intermediate frame.
        backgroundImageView.image = image
    }

    private static func eraseCircle(centerX: Int, centerY: Int, radius: Int, width: Int, height: Int, into buffer: inout [UInt8]) {
        guard radius > 0 else { return }
        let minX = max(0, centerX - radius)
        let maxX = min(width - 1, centerX + radius)
        let minY = max(0, centerY - radius)
        let maxY = min(height - 1, centerY + radius)
        guard minX <= maxX, minY <= maxY else { return }
        let radiusSquared = radius * radius
        for y in minY...maxY {
            let dy = y - centerY
            for x in minX...maxX {
                let dx = x - centerX
                if dx * dx + dy * dy > radiusSquared { continue }
                let idx = (y * width + x) * 4
                buffer[idx] = 0
                buffer[idx + 1] = 0
                buffer[idx + 2] = 0
                buffer[idx + 3] = 0
            }
        }
    }

    // MARK: - Flood fill

    /// Flood-fills the closed region containing `point` (view coordinates)
    /// with `color`, writing only into `backgroundImageView` — strokes stay
    /// untouched vector data. Boundaries are wherever `canvasView.drawing`
    /// has ink (its alpha channel), not the existing background content, so
    /// re-filling an already-filled region with a new color simply replaces
    /// it within the same stroke-bounded area.
    private func performFloodFill(at point: CGPoint, color: UIColor) {
        let bounds = canvasView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }
        let scale = UIScreen.main.scale
        let width = Int(bounds.width * scale)
        let height = Int(bounds.height * scale)
        guard width > 0, height > 0 else { return }

        let startX = Int(point.x * scale)
        let startY = Int(point.y * scale)
        guard startX >= 0, startX < width, startY >= 0, startY < height else { return }

        // 1. Stroke-only raster — its alpha channel is the flood fill's wall map.
        //
        // KNOWN LIMITATION: this only sees *live vector* strokes
        // (`canvasView.drawing`). If the eraser has already run once, any
        // strokes that existed at that point were flattened into
        // `backgroundImageView` by `flattenDrawingIntoBackgroundIfNeeded`
        // and are no longer part of `canvasView.drawing` — so the bucket
        // tool can no longer see them as walls and may flood-fill straight
        // through lines that look intact on screen. Deliberately deferred:
        // fixing this needs a separate persistent "wall mask" raster layer
        // that accumulates stroke alpha at flatten time (independent of the
        // color background, which gets overwritten by fills/photos), so
        // wall detection becomes `canvasView.drawing` alpha OR that mask.
        // Not implemented yet.
        let strokeImage = canvasView.drawing.image(from: bounds, scale: scale)
        guard let strokeCG = strokeImage.cgImage else { return }
        let strokeBytes = Self.rgba8Bytes(from: strokeCG, width: width, height: height)
        var strokeAlpha = [UInt8](repeating: 0, count: width * height)
        for i in 0..<(width * height) {
            strokeAlpha[i] = strokeBytes[i * 4 + 3]
        }

        // 2. Existing background buffer — fill writes on top of whatever's
        // already there (previous fills / an imported photo / nothing).
        var bgBuffer: [UInt8]
        if let bgImage = backgroundImageView.image, let bgCG = bgImage.cgImage,
           bgCG.width == width, bgCG.height == height {
            bgBuffer = Self.rgba8Bytes(from: bgCG, width: width, height: height)
        } else {
            bgBuffer = [UInt8](repeating: 0, count: width * height * 4)
        }

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let fillColor = (r: UInt8(r * 255), g: UInt8(g * 255), b: UInt8(b * 255), a: UInt8(255))

        Self.floodFillStack(
            strokeAlpha: strokeAlpha,
            width: width,
            height: height,
            startX: startX,
            startY: startY,
            into: &bgBuffer,
            fillColor: fillColor
        )

        guard let newBackground = Self.image(fromRGBA8: bgBuffer, width: width, height: height, scale: scale) else { return }
        setBackgroundImage(newBackground, registerUndo: true)
    }

    /// Stack-based flood fill (never recursive — a recursive implementation
    /// risks a stack overflow on a large open region, e.g. an empty canvas).
    /// Operates directly on raw RGBA8 bytes rather than `CGContext` per-pixel
    /// get/set, which is far too slow at canvas resolution (roughly
    /// 1–1.4 million pixels on current devices).
    private static func floodFillStack(
        strokeAlpha: [UInt8],
        width: Int,
        height: Int,
        startX: Int,
        startY: Int,
        into buffer: inout [UInt8],
        fillColor: (r: UInt8, g: UInt8, b: UInt8, a: UInt8)
    ) {
        let wallThreshold: UInt8 = 24 // stroke alpha above this blocks the fill
        let startIdx = startY * width + startX
        if strokeAlpha[startIdx] > wallThreshold { return } // tapped directly on a line

        var visited = [Bool](repeating: false, count: width * height)
        var stack: [(Int, Int)] = [(startX, startY)]
        visited[startIdx] = true

        while let (x, y) = stack.popLast() {
            let idx = y * width + x
            let byteIdx = idx * 4
            buffer[byteIdx] = fillColor.r
            buffer[byteIdx + 1] = fillColor.g
            buffer[byteIdx + 2] = fillColor.b
            buffer[byteIdx + 3] = fillColor.a

            for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] {
                guard nx >= 0, nx < width, ny >= 0, ny < height else { continue }
                let nIdx = ny * width + nx
                if visited[nIdx] { continue }
                if strokeAlpha[nIdx] > wallThreshold { continue }
                visited[nIdx] = true
                stack.append((nx, ny))
            }
        }
    }

    // MARK: - Background layer + undo

    /// Sets the raster background layer and, when `registerUndo` is true,
    /// registers a matching undo step on `canvasView.undoManager` — the same
    /// instance PencilKit uses for live strokes, so fills/imports and
    /// drawing interleave in one chronological stack. The handler
    /// re-registers itself on undo, which is what makes the action redoable
    /// too (standard `UndoManager` usage).
    private func setBackgroundImage(_ image: UIImage?, registerUndo: Bool) {
        let previousImage = backgroundImageView.image
        backgroundImageView.image = image
        guard registerUndo else { return }
        canvasView.undoManager?.registerUndo(withTarget: self) { target in
            target.setBackgroundImage(previousImage, registerUndo: true)
        }
    }

    // MARK: - Image import

    private func presentImagePicker(result: @escaping FlutterResult) {
        guard let presenter = presentingViewController else {
            result(FlutterError(code: "NO_PRESENTER", message: "No view controller to present the picker from", details: nil))
            return
        }
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        pendingPickerResult = result
        presenter.present(picker, animated: true)
    }

    /// Crops `image` to a centered square and resizes it to exactly
    /// `pixelSize × pixelSize` pixels (matching the canvas's own raster
    /// buffer convention), returning a `UIImage` whose `.scale` is set so
    /// its reported point size equals the canvas's point size — consistent
    /// with `image(fromRGBA8:)`, so both fills and imported photos behave
    /// identically as the background layer.
    private static func centerCroppedSquare(_ image: UIImage, pixelSize: Int, scale: CGFloat) -> UIImage? {
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
        return UIImage(cgImage: resizedCG, scale: scale, orientation: .up)
    }

    // MARK: - PNG export

    /// Renders the current drawing to transparent PNG data. Composites the
    /// raster background layer (fills / imported photo, if any) *under* the
    /// PencilKit strokes, using `UIGraphicsImageRenderer` with
    /// `isOpaque = false` as specified — the canvas stays transparent
    /// wherever neither layer has content.
    private func renderPNGData() -> FlutterStandardTypedData? {
        let bounds = canvasView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let scale = UIScreen.main.scale
        let drawingImage = canvasView.drawing.image(from: bounds, scale: scale)
        let backgroundImage = backgroundImageView.image

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
        let finalImage = renderer.image { _ in
            backgroundImage?.draw(in: CGRect(origin: .zero, size: bounds.size))
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

    // MARK: - Raw pixel buffer helpers

    private static func rgba8Bytes(from cgImage: CGImage, width: Int, height: Int) -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(
            data: &buffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return buffer }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }

    private static func image(fromRGBA8 buffer: [UInt8], width: Int, height: Int, scale: CGFloat) -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let provider = CGDataProvider(data: Data(buffer) as CFData) else { return nil }
        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
}

extension DrawingCanvasPlatformView: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
            // Empty `results` means the user cancelled — not an error, just
            // report "nothing changed".
            pendingPickerResult?(false)
            pendingPickerResult = nil
            return
        }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard let image = object as? UIImage, error == nil else {
                    self.pendingPickerResult?(FlutterError(
                        code: "LOAD_FAILED",
                        message: error?.localizedDescription ?? "Could not load the selected image",
                        details: nil
                    ))
                    self.pendingPickerResult = nil
                    return
                }
                let bounds = self.canvasView.bounds
                let scale = UIScreen.main.scale
                let pixelSize = Int(bounds.width * scale)
                guard let cropped = Self.centerCroppedSquare(image, pixelSize: pixelSize, scale: scale) else {
                    self.pendingPickerResult?(FlutterError(code: "CROP_FAILED", message: "Could not crop the selected image", details: nil))
                    self.pendingPickerResult = nil
                    return
                }
                self.setBackgroundImage(cropped, registerUndo: true)
                self.pendingPickerResult?(true)
                self.pendingPickerResult = nil
            }
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
