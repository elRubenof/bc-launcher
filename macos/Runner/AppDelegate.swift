import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  /// Whether a window was closed, so the app quits; a window hidden while
  /// the game runs keeps it open.
  private var windowClosed = false

  override func awakeFromNib() {
    super.awakeFromNib()
    NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification, object: nil, queue: nil
    ) { [weak self] _ in
      self?.windowClosed = true
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return windowClosed
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
