import Foundation

import JacKit
fileprivate let jack = Jack.usingLocalFileScope().setLevel(.verbose)

public class WeChat: BasePlatformAgent {

  public static let shared = WeChat()

  //  private(set) var oauth: TencentOAuth!

  // MARK: Platform init

  override private init() {
    super.init()
    jack.info(platformInfo, from: .custom("WeChat Platform Loaded"))
  }

  public static func initPlatform(appID: String) {
    #if DEDUG
    WXApi.startLog(by: .detail) { log in
      jack.debug(log, from: .custom("WXApi"))
    }
    #endif
    
    guard WXApi.registerApp(appID) else {
      jack.error("WXApi.registerApp(...) returned false, WeChat SDK initialization failed.")
      return
    }

    _ = shared // force share instance initizliation
  }

}

// MARK: - PlatformAgentType

extension WeChat: PlatformAgentType {

  public enum SharingTarget {
    case session
    case timeline
    case favorites
  }

  public var platformInfo: String {
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

  public static func open(_ url: URL) -> Bool {
    let handled = WXApi.handleOpen(url, delegate: WeChat.shared)

    jack.verbose("WXApi: \(handled ? "√" : "x")")

    return handled
  }

  public var canLogin: Bool {
    return WXApi.isWXAppInstalled() && WXApi.isWXAppSupport()
  }

  public var canShare: Bool {
    return canLogin
  }

}
