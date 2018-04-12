import Foundation

import JacKit
fileprivate let jack = Jack.with(levelOfThisFile: .verbose)

public class QQLoginResult: BaseLoginResult, LoginResultType {

  public var nickname: String? {
    return userInfo["nickname"] as? String
  }

  public var gender: Gender? {
    if let text = userInfo["gender"] as? String {
      return text == "男" ? .male : .female
    } else {
      return nil
    }
  }

  public var avatarURL: URL? {
    if let urlString = userInfo["figureurl_qq_2"] as? String {
      return URL(string: urlString)
    } else {
      return nil
    }
  }

  public var location: String? {
    return userInfo["city"] as? String
  }

}

extension QQ {

  public static func login(completion: @escaping LoginCompletion) {
    QQ.shared._login(completion: completion)
  }

  private func _login(completion: @escaping LoginCompletion) {
    begin(.login(completion: completion))

    let permissions = [
      kOPEN_PERMISSION_GET_USER_INFO
    ]
    oauth.authorize(permissions)
  }

}

