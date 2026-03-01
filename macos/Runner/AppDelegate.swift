import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // 最後一個視窗隱藏後不自動結束 app
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  // Dock icon 點擊 → 重新顯示視窗
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
    if !hasVisibleWindows {
      NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
