import Foundation

import JacKit
fileprivate let jack = Jack.with(levelOfThisFile: .verbose)

public class QQ: SocialPlatformAgent {

  public static let shared = QQ()

  private(set) var oauth: TencentOAuth!

  // MARK: Platform init

  override private init() {
    super.init()
    jack.info(_platformInfo, from: .custom("QQ Platform Loaded"))
  }

  public static func initPlatform(appID: String) {
    let oauth = TencentOAuth(appId: appID, andDelegate: QQ.shared)
    QQ.shared.oauth = oauth
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

  // MARK: Helpers

  private var _platformInfo: String {
    var version = "\(TencentOAuth.sdkVersion() ?? "unkown") - \(TencentOAuth.sdkSubVersion() ?? "unknown")"
    if TencentOAuth.isLiteSDK() {
      version += " (Lite)"
    }

    var qq = ""
    if QQApiInterface.isQQInstalled() {
      qq = "Installed"
      if !TencentOAuth.iphoneQQSupportSSOLogin() {
        qq += " Login ⚠️"
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

}
