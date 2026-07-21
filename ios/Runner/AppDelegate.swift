import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let appGroupID = "group.com.yunajung.fonki"
  private var appGroupChannel: FlutterMethodChannel?
  /// Set when the keyboard extension launches us via `fonkii://paywall` before
  /// Flutter's Dart-side method handler is wired up. Drained by Dart via
  /// `consumePendingPaywall` once `HomeScreen` finishes its first build.
  private var pendingPaywall = false
  private var pendingAddPhrase = false
  private let myPhrasesKey = "user_custom_phrases"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Sticker drawing canvas (phase 1: main-app-only PencilKit screen, see
    // DrawingCanvasPlatformView.swift). Registered directly rather than via
    // a third-party Flutter PencilKit wrapper.
    if let drawingRegistrar = self.registrar(forPlugin: "DrawingCanvasPlugin") {
      let drawingCanvasFactory = DrawingCanvasViewFactory(messenger: drawingRegistrar.messenger())
      drawingRegistrar.register(drawingCanvasFactory, withId: "com.yunajung.fonki/drawing_canvas")
    }

    // flutter_local_notifications' recommended iOS setup — without this,
    // a trial-expiry reminder that happens to fire while the app is
    // foregrounded silently would not display (background delivery works
    // fine either way; this only covers that foreground edge case).
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate

    // ── App Group MethodChannel ──────────────────────────────────────────
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.yunajung.fonki/appgroup",
      binaryMessenger: controller.binaryMessenger
    )
    appGroupChannel = channel

    // ── Keyboard-enabled check channel ──────────────────────────────────
    // Onboarding page 2 calls this after the user returns from iOS Settings
    // so we can advance only when Fonkii is actually in their active input
    // modes — falling back to "any third-party keyboard" would silently let
    // users past with Gboard/Naver enabled but Fonkii not. Full Access is
    // intentionally not checked here: it can't be queried from the host
    // process, and gating onboarding on it deadlocks fresh users who
    // haven't typed with Fonkii yet. Features that actually need Full
    // Access (translation, etc.) surface their own hint in-extension.
    let keyboardCheckChannel = FlutterMethodChannel(
      name: "com.yunajung.fonki/keyboard_check",
      binaryMessenger: controller.binaryMessenger
    )
    keyboardCheckChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "isKeyboardEnabled":
        let targetID = "com.yunajung.fonki.keyboard"
        let enabled = UITextInputMode.activeInputModes.contains { mode in
          // `identifier` is read via KVC because the property is private —
          // a long-standing, App Store–accepted pattern for matching a
          // specific keyboard extension. The returned string for our
          // extension looks like "com.yunajung.fonki.keyboard@…" so a
          // prefix match handles the locale/layout suffix iOS appends.
          guard let id = mode.value(forKey: "identifier") as? String,
                mode.primaryLanguage != nil else { return false }
          return id.hasPrefix(targetID)
        }
        result(enabled)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

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
        let pending = self.pendingPaywall
        self.pendingPaywall = false
        result(pending)

      case "consumePendingAddPhrase":
        let pending = self.pendingAddPhrase
        self.pendingAddPhrase = false
        result(pending)

      case "getCustomPhrases":
        let defaults = UserDefaults(suiteName: self.appGroupID)
        result(defaults?.stringArray(forKey: self.myPhrasesKey) ?? [])

      case "addCustomPhrase":
        guard let args = call.arguments as? [String: Any],
              let phrase = args["phrase"] as? String,
              !phrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
          return
        }
        let defaults = UserDefaults(suiteName: self.appGroupID)
        var list = defaults?.stringArray(forKey: self.myPhrasesKey) ?? []
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        if !list.contains(trimmed) { list.insert(trimmed, at: 0) }
        defaults?.set(list, forKey: self.myPhrasesKey)
        defaults?.synchronize()
        result(nil)

      case "deleteCustomPhrase":
        guard let args = call.arguments as? [String: Any],
              let phrase = args["phrase"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
          return
        }
        let defaults = UserDefaults(suiteName: self.appGroupID)
        var list = defaults?.stringArray(forKey: self.myPhrasesKey) ?? []
        list.removeAll { $0 == phrase }
        defaults?.set(list, forKey: self.myPhrasesKey)
        defaults?.synchronize()
        result(nil)

      case "checkAndClearOpenMyList":
        print("🔥 [AppDelegate] checkAndClearOpenMyList called")
        let defaults = UserDefaults(suiteName: self.appGroupID)
        let val = defaults?.bool(forKey: "open_my_list")
        print("🔥 [AppDelegate] open_my_list = \(String(describing: val))")
        let flag = val ?? false
        if flag {
          defaults?.set(false, forKey: "open_my_list")
          defaults?.synchronize()
        }
        result(flag)

      case "getDebugInfo":
        let d = UserDefaults(suiteName: self.appGroupID)
        result([
          "full_access":       d?.bool(forKey: "debug_full_access") ?? false,
          "extension_context": d?.bool(forKey: "debug_extension_context") ?? false,
          "open_result":       d?.bool(forKey: "debug_open_result") ?? false,
        ] as [String: Bool])

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Cold start: the keyboard may have written `open_my_list` / `open_paywall`
    // to the App Group before this launch (e.g. the public `ctx.open()` call
    // brought us to the foreground without the URL callback firing). Check
    // once here so a cold launch picks it up immediately.
    checkPendingAppGroupFlags()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Warm resume: the app was already alive in the background when the
  /// keyboard extension called `ctx.open()`. `application(_:open:options:)` /
  /// `scene(_:openURLContexts:)` only fire when the URL callback actually
  /// reaches us — if it doesn't (Full Access edge cases, iOS quirks), the
  /// App Group flag written by `myListAddTapped`/`openPaywallApp` is the only
  /// surviving signal. Checking it here means every foreground transition —
  /// not just a successful URL open — picks up a pending deep link.
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    checkPendingAppGroupFlags()
  }

  /// Reads + clears `open_my_list` / `open_paywall` from the App Group and,
  /// if set, routes through the same in-memory pending-flag + live-invoke
  /// path `handleFonkiiURL` uses — so Dart needs no new wiring, it just sees
  /// another `openAddPhrase` / `openPaywall` event. Read-then-clear happens
  /// synchronously per flag, so calling this from both
  /// `didFinishLaunchingWithOptions` and `applicationDidBecomeActive` on the
  /// same cold start is safe: whichever runs first consumes the flag, the
  /// second sees it already `false` and no-ops.
  private func checkPendingAppGroupFlags() {
    let defaults = UserDefaults(suiteName: appGroupID)

    if defaults?.bool(forKey: "open_my_list") == true {
      defaults?.set(false, forKey: "open_my_list")
      defaults?.synchronize()
      pendingAddPhrase = true
      appGroupChannel?.invokeMethod("openAddPhrase", arguments: nil)
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
        guard let self, self.pendingAddPhrase else { return }
        self.appGroupChannel?.invokeMethod("openAddPhrase", arguments: nil)
      }
    }

    if defaults?.bool(forKey: "open_paywall") == true {
      defaults?.set(false, forKey: "open_paywall")
      defaults?.synchronize()
      pendingPaywall = true
      appGroupChannel?.invokeMethod("openPaywall", arguments: nil)
    }
  }

  /// Scene lifecycle URL handler — called when app is active/warm and opened
  /// via URL. Mirrors the application(_:open:options:) logic below.
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url,
          url.scheme?.lowercased() == "fonkii" else { return }
    handleFonkiiURL(url)
  }

  private func handleFonkiiURL(_ url: URL) {
    switch url.host?.lowercased() {
    case "paywall":
      print("🔥 [AppDelegate] paywall URL 수신됨")
      pendingPaywall = true
      appGroupChannel?.invokeMethod("openPaywall", arguments: nil)
    case "addphrase", "mylist":
      pendingAddPhrase = true
      appGroupChannel?.invokeMethod("openAddPhrase", arguments: nil)
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
        guard let self, self.pendingAddPhrase else { return }
        self.appGroupChannel?.invokeMethod("openAddPhrase", arguments: nil)
      }
    default:
      break
    }
  }

  /// Handle `fonkii://paywall` deep links coming from the keyboard extension's
  /// "1주 무료 체험 시작하기" button. We both flip the cold-start flag *and*
  /// fire `openPaywall` immediately — warm starts catch the live event, cold
  /// starts fall back to the flag drain.
  override func application(_ application: UIApplication,
                            open url: URL,
                            options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if url.scheme?.lowercased() == "fonkii" {
      handleFonkiiURL(url)
      return true
    }
    return super.application(application, open: url, options: options)
  }
}
