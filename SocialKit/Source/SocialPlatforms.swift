import Foundation

import JacKit
fileprivate let jack = Jack.with(fileLocalLevel: .verbose)

public class SocialPlatforms {

  public enum LoadingInfo: Hashable, CustomStringConvertible {
    // Sina
    case weibo(appKey: String)
    // Tencent
    case qq(appKey: String)
    case weChat(appKey: String)
    // Alibaba
    case aliPay(appKey: String)

    public func open(_ url: URL) -> Bool {
      switch self {
      case .weibo:
        fatalError("Unimplemented")
      case .aliPay:
        fatalError("Unimplemented")
      case .qq:
        return QQ.open(url)
      case .weChat:
        fatalError("Unimplemented")
      }
    }

    public var description: String {
      switch self {
      case .qq: return "QQ"
      case .weibo: return "Weibo"
      case .weChat: return "WeChat"
      case .aliPay: return "AliPay"
      }
    }
  }

  private static var _platforms: Set<LoadingInfo> = []

  public static func load(_ platforms: Set<LoadingInfo>) {
    _platforms = platforms

    _platforms.forEach { info in
      switch info {
      case .qq(let appKey):
        QQ.initPlatform(appKey: appKey)
      case .weChat(let appKey):
        WeChat.initPlatform(appKey: appKey)
      case .weibo(let appKey):
        Weibo.initPlatform(appKey: appKey)
      case .aliPay(let appKey):
        AliPay.initPlatform(appKey: appKey)
      }
    }

  }

  public static func open(_ url: URL) -> Bool {
    for p in _platforms {
      let handled = p.open(url)
      if handled {
        jack.verbose("Platform \(p) handled URL \(url)")
        return true
      }
    }
    jack.verbose("No loaded platform can handle URL \(url)")
    return false
  }

}

