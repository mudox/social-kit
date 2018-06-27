import Foundation

import JacKit
fileprivate let jack = Jack()

public class QQ: BasePlatformAgent {

  public static let shared = QQ()

  private(set) var oauth: TencentOAuth!

  // MARK: Platform init

  override private init() {
    super.init()
    Jack("QQ Platform").info(platformInfo)
  }

  public static func initPlatform(appID: String) {
    let oauth = TencentOAuth(appId: appID, andDelegate: QQ.shared)
    QQ.shared.oauth = oauth
  }

}

extension QQ: PlatformAgentType {
  
  public enum SharingTarget {
    // open QQ / TIM, show a sharing targets selector
    case qq
    case tim
    // open QQ and jump directly to integrated QZone interface
    case qzone
    // defaults to open QQ and jump directly to Favorites interface
    case favorites
  }

  public var platformInfo: String {
    var version = "\(TencentOAuth.sdkVersion() ?? "unkown") - \(TencentOAuth.sdkSubVersion() ?? "unknown")"
    if TencentOAuth.isLiteSDK() {
      version += " (Lite)"
    }

    var qq = ""
    if QQApiInterface.isQQInstalled() {
      qq = "Installed"
      if !TencentOAuth.iphoneQQSupportSSOLogin() {
        qq += " SSO ⚠️"
      }
      if !QQApiInterface.isQQSupportApi() {
        qq += " API ⚠️"
      }
      if !QQApiInterface.isSupportPushToQZone() {
        qq += " QZone ⚠️"
      }
    } else {
      qq = "Not installed"
    }

    var tim = ""
    if QQApiInterface.isTIMInstalled() {
      tim = "Installed"
      if !TencentOAuth.iphoneTIMSupportSSOLogin() {
        tim += " SSO ⚠️"
      }
      if !QQApiInterface.isTIMSupportApi() {
        tim += " API ⚠️"
      }
    } else {
      tim = "No installed"
    }

    return """
        - SDK        :   \(version)
        -  QQ        :   \(qq)
        - TIM        :   \(tim)
      """
  }

  public static func open(_ url: URL) -> Bool {
    let handledByTencentOAuth = TencentOAuth.handleOpen(url)
    let handledByQQApiInterface = QQApiInterface.handleOpen(url, delegate: shared)

    jack.verbose("""
      TencentOAuth: \(handledByTencentOAuth ? "√" : "x") | \
      QQApiInterface: \(handledByQQApiInterface ? "√" : "x")
      """)

    return handledByTencentOAuth || handledByQQApiInterface
  }

  public var canLogin: Bool {
    let qqOkay = TencentOAuth.iphoneQQInstalled() && TencentOAuth.iphoneQQSupportSSOLogin()
    let timOkay = TencentOAuth.iphoneTIMInstalled() && TencentOAuth.iphoneTIMSupportSSOLogin()
    return qqOkay || timOkay
  }

  public var canShare: Bool {
    let qqOkay = QQApiInterface.isQQInstalled() && QQApiInterface.isQQSupportApi()
    let timOkay =  QQApiInterface.isTIMInstalled() && QQApiInterface.isTIMSupportApi()
    return qqOkay || timOkay
  }
}
