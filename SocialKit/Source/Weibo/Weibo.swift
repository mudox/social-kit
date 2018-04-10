import Foundation

class Weibo {
  static func initPlatform(appKey: String) {
    WeiboSDK.registerApp(appKey)
  }
}
