import Foundation

import JacKit
fileprivate let jack = Jack()

public class Weibo: BasePlatformAgent {

  public static let shared = Weibo()

  // MARK: Platform init

  override private init() {
    super.init()
    Jack("Weibo").info(platformInfo, options: .messageOnly)
  }

  public static func initPlatform(appID: String) {
    #if DEBUG
      WeiboSDK.enableDebugMode(true)
    #endif

    WeiboSDK.registerApp(appID)
    _ = shared // force share instance initizliation
  }

}

extension Weibo: PlatformAgentType {

  public enum SharingTarget {
    case timeline
    case story
  }

  public var platformInfo: String {
    let version = "\(WeiboSDK.getVersion() ?? "unkown")"

    var app = ""
    if WeiboSDK.isWeiboAppInstalled() {
      app = "Installed"
      if !WeiboSDK.isCanSSOInWeiboApp() {
        app += " SSO ⚠️"
      }
      if !WeiboSDK.isCanShareInWeiboAPP() {
        app += " Share ⚠️"
      }
    } else {
      app = "Not installed"
    }

    return """
      🍋 Weibo
        - SDK        :   \(version)
        - Weibo      :   \(app)
      """ + "\n"
  }

  public static func open(_ url: URL) -> Bool {
    let handled = WeiboSDK.handleOpen(url, delegate: Weibo.shared)

    jack.verbose("WeiboSDK: \(handled ? "√" : "x")")

    return handled
  }

  public var canLogin: Bool {
    return WeiboSDK.isWeiboAppInstalled() && WeiboSDK.isCanSSOInWeiboApp()
  }

  public var canShare: Bool {
    return WeiboSDK.isWeiboAppInstalled() && WeiboSDK.isCanShareInWeiboAPP()
  }


}
