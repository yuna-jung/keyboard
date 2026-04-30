import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let appGroupID = "group.com.yunajung.fonki"
  private var appGroupChannel: FlutterMethodChannel?
  /// Set when the keyboard extension launches us via `fonkii://paywall` before
  /// Flutter's Dart-side method handler is wired up. Drained by Dart via
  /// `consumePendingPaywall` once `HomeScreen` finishes its first build.
  private var pendingPaywall = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // ── App Group MethodChannel ──────────────────────────────────────────
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.yunajung.fonki/appgroup",
      binaryMessenger: controller.binaryMessenger
    )
    appGroupChannel = channel

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

      case "syncPremium":
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
          return
        }
        let defaults = UserDefaults(suiteName: self.appGroupID)
        if let isPremium = args["is_premium"] as? Bool {
          defaults?.set(isPremium, forKey: "is_premium")
        }
        if let tier = args["tier"] as? String {
          defaults?.set(tier, forKey: "tier")
        }
        if let canTranslate = args["can_translate_unlimited"] as? Bool {
          defaults?.set(canTranslate, forKey: "can_translate_unlimited")
        }
        defaults?.synchronize()
        result(nil)

      case "getLastCopiedGifUrl":
        // Read the URL written by the keyboard extension when a GIF is copied.
        let defaults = UserDefaults(suiteName: self.appGroupID)
        result(defaults?.string(forKey: "lastCopiedGifUrl"))

      case "clearLastCopiedGifUrl":
        // Wipe the stash after the host app has consumed it.
        let defaults = UserDefaults(suiteName: self.appGroupID)
        defaults?.removeObject(forKey: "lastCopiedGifUrl")
        defaults?.synchronize()
        result(nil)

      case "consumePendingPaywall":
        // Cold-start drain: Dart polls this once on startup to handle a
        // `fonkii://paywall` URL that arrived before the Dart-side method
        // handler was registered.
        let pending = self.pendingPaywall
        self.pendingPaywall = false
        result(pending)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Handle `fonkii://paywall` deep links coming from the keyboard extension's
  /// "1주 무료 체험 시작하기" button. We both flip the cold-start flag *and*
  /// fire `openPaywall` immediately — warm starts catch the live event, cold
  /// starts fall back to the flag drain.
  override func application(_ application: UIApplication,
                            open url: URL,
                            options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if url.scheme?.lowercased() == "fonkii",
       url.host?.lowercased() == "paywall" {
      pendingPaywall = true
      appGroupChannel?.invokeMethod("openPaywall", arguments: nil)
      return true
    }
    return super.application(application, open: url, options: options)
  }
}
