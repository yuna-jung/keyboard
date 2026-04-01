import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let appGroupID = "group.com.yourapp.fontkeyboard"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // ── App Group MethodChannel ──────────────────────────────────────────
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.yourapp.fontkeyboard/appgroup",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }

      switch call.method {
      case "syncFavorites":
        guard let args = call.arguments as? [String: Any],
              let items = args["items"] as? [String] else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
          return
        }
        let defaults = UserDefaults(suiteName: self.appGroupID)
        defaults?.set(items, forKey: "favorites_v2")
        defaults?.synchronize()
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
