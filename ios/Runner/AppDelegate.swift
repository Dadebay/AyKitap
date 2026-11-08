import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // The channel SceneDelegate hands "Open with" file paths to, and the
  // Dart-side name IncomingFileService listens on (see MainActivity.kt for
  // the Android counterpart of this contract).
  static let incomingFileChannelName = "com.aykitap.aykitap/incoming_file"
  static var incomingFileChannel: FlutterMethodChannel?
  // Set by SceneDelegate when the app is cold-launched via "Open with",
  // before the Flutter engine (and this channel) exists yet.
  static var pendingIncomingFilePath: String?

  // Same contract as above, for the `aykitap://book/<id>` deep link (see
  // MainActivity.kt for the Android counterpart). Dart-side name is
  // DeepLinkService.
  static let deepLinkChannelName = "com.aykitap.aykitap/deep_link"
  static var deepLinkChannel: FlutterMethodChannel?
  static var pendingDeepLink: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: AppDelegate.incomingFileChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "getInitialFile" {
        result(AppDelegate.pendingIncomingFilePath)
        AppDelegate.pendingIncomingFilePath = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    AppDelegate.incomingFileChannel = channel

    let deepLinkChannel = FlutterMethodChannel(
      name: AppDelegate.deepLinkChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    deepLinkChannel.setMethodCallHandler { call, result in
      if call.method == "getInitialLink" {
        result(AppDelegate.pendingDeepLink)
        AppDelegate.pendingDeepLink = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    AppDelegate.deepLinkChannel = deepLinkChannel
  }

  /// Copies a book file handed to us via "Open with" into our own sandbox
  /// (the source URL is security-scoped and only briefly valid, and may
  /// live in another app's container) and returns the local path Dart can
  /// read with dart:io. Shared with SceneDelegate, which is what actually
  /// receives the URL — this app opts into UIScene (see Info.plist), so
  /// UIKit routes "Open with" there instead of to AppDelegate.
  static func importIncomingFile(_ url: URL) -> String? {
    let accessed = url.startAccessingSecurityScopedResource()
    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
    let fileManager = FileManager.default
    let incomingDir = fileManager.temporaryDirectory.appendingPathComponent("incoming", isDirectory: true)
    do {
      try fileManager.createDirectory(at: incomingDir, withIntermediateDirectories: true)
      let destURL = incomingDir.appendingPathComponent(url.lastPathComponent)
      if fileManager.fileExists(atPath: destURL.path) {
        try fileManager.removeItem(at: destURL)
      }
      try fileManager.copyItem(at: url, to: destURL)
      return destURL.path
    } catch {
      return nil
    }
  }
}
