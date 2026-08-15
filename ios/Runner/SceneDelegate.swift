import Flutter
import UIKit

/// Receives "Open with" file URLs and `aykitap://` deep links — UIKit calls
/// these instead of AppDelegate's application(_:open:options:) once the app
/// declares UIApplicationSceneManifest (see Info.plist). Cold start comes in
/// via willConnectTo's connectionOptions; a launch while already running
/// comes in via openURLContexts.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    guard let url = connectionOptions.urlContexts.first?.url else { return }
    if url.scheme == "aykitap" {
      AppDelegate.pendingDeepLink = url.absoluteString
    } else {
      AppDelegate.pendingIncomingFilePath = AppDelegate.importIncomingFile(url)
    }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    guard let url = URLContexts.first?.url else { return }
    if url.scheme == "aykitap" {
      AppDelegate.deepLinkChannel?.invokeMethod("onDeepLink", arguments: url.absoluteString)
    } else if let path = AppDelegate.importIncomingFile(url) {
      AppDelegate.incomingFileChannel?.invokeMethod("onIncomingFile", arguments: path)
    }
  }
}
