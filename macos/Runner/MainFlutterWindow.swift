import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  // 紅色關閉按鈕，以及選單列 Window -> Close (綁定 command+w) 的關閉對象 -> 隱藏視窗
  override func performClose(_ sender: Any?) {
    self.orderOut(nil)
  }
}
