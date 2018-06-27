import Foundation

import JacKit
fileprivate let jack = Jack()


public final class Platforms {

  public enum LoadingInfo: Hashable, CustomStringConvertible {
    
    case weibo(appID: String)
    case qq(appID: String)
    case weChat(appID: String)
    case aliPay(appID: String)

    public func open(_ url: URL) -> Bool {
      switch self {
      case .weibo:
        return Weibo.open(url)
      case .aliPay:
        fatalError("Unimplemented")
      case .qq:
        return QQ.open(url)
      case .weChat:
        return WeChat.open(url)
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
      case .qq(let appID):
        QQ.initPlatform(appID: appID)
      case .weChat(let appID):
        WeChat.initPlatform(appID: appID)
      case .weibo(let appID):
        Weibo.initPlatform(appID: appID)
      case .aliPay(let appID):
        fatalError("Unimplemented")
      }
    }

  }
  
  public static func load(_ platforms: LoadingInfo...) {
    load(Set(platforms))
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

