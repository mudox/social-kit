import Foundation

import JacKit
fileprivate let jack = Jack.with(levelOfThisFile: .verbose)

public class WeChat: SocialPlatformAgent {

  public static let shared = WeChat()

  //  private(set) var oauth: TencentOAuth!

  // MARK: Platform init

  override private init() {
    super.init()
    jack.info(_platformInfo, from: .custom("WeChat Platform Loaded"))
  }

  public static func initPlatform(appID: String) {
    guard WXApi.registerApp(appID) else {
      jack.error("WXApi.registerApp(...) returned false, WeChat SDK initialization failed.")
      return
    }
    _ = shared // force share instance initizliation
  }

  public static func open(_ url: URL) -> Bool {
    let handled = WXApi.handleOpen(url, delegate: WeChat.shared)

    jack.verbose("WXApi: \(handled ? "√" : "x")")

    return handled
  }

  // MARK: Helpers

  private var _platformInfo: String {
    let version = "\(WXApi.getVersion() ?? "unkown")"

    var app = ""
    if WXApi.isWXAppInstalled() {
      app = "Installed"
      if !WXApi.isWXAppSupport() {
        app += " OpenAPI ⚠️"
      }
    } else {
      app = "Not installed"
    }

    return """
      - SDK        :   \(version)
      - WeChat     :   \(app)
    """
  }

}
