import Foundation

import JacKit
fileprivate let jack = Jack.with(levelOfThisFile: .verbose)

public class QQLoginResult: BaseLoginResult {

  public enum Gender {
    case male, female
  }

  public let nickname: String?
  public let city: String?
  public let gender: Gender?
  public let avatarURL: URL?

  public let originalJSON: [String: Any]

  init(response: APIResponse, oauth: TencentOAuth) throws {

    guard response.retCode == URLREQUEST_SUCCEED.rawValue else {
      throw SocialError.api(reason: "`response.retCode` != `URLREQUEST_SUCCEED.rawValue`")
    }

    guard let json = response.jsonResponse as? [String: Any] else {
      throw SocialError.api(reason: "fail to case response.jsonResponse to `[String: Any]`")
    }

    originalJSON = json
    
    nickname = json["nickname"] as? String
    avatarURL = URL(string: json["figureurl_qq_2"] as? String ?? "")
    city = json["city"] as? String

    if let text = json["gender"] as? String {
      if text == "男" {
        gender = .male
      } else {
        gender = .female
      }
    } else {
      gender = nil
    }

    guard let token = oauth.accessToken, !token.isEmpty else {
      throw SocialError.api(reason: "`oauth.accessToken` is nil or empty")
    }

    guard let id = oauth.openId, !id.isEmpty else {
      throw SocialError.api(reason: "`oauth.openId` is nil or empty")
    }

    guard let date = oauth.expirationDate else {
      throw SocialError.api(reason: "`oauth.expirationDate` is nil")
    }

    guard date > Date() else {
      throw SocialError.api(reason: "got a already expired date")
    }

    super.init(accessToken: token, openID: id, expirationDate: date)
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

