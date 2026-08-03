import Flutter
import UIKit

/// Receives "Open with" file URLs — UIKit calls these instead of
/// AppDelegate's application(_:open:options:) once the app declares
/// UIApplicationSceneManifest (see Info.plist). Cold start comes in via
/// willConnectTo's connectionOptions; a launch while already running comes
/// in via openURLContexts.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    if let url = connectionOptions.urlContexts.first?.url {
      AppDelegate.pendingIncomingFilePath = AppDelegate.importIncomingFile(url)
    }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    guard let url = URLContexts.first?.url,
          let path = AppDelegate.importIncomingFile(url) else { return }
    AppDelegate.incomingFileChannel?.invokeMethod("onIncomingFile", arguments: path)
  }
}
