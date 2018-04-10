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

extension QQ: TencentSessionDelegate {

  public func tencentDidLogin() {
    guard let token = oauth.accessToken, !token.isEmpty,
      let openID = oauth.openId, !openID.isEmpty,
      let date = oauth.expirationDate, date > Date()
      else {
        let error = SocialError.api(reason: """
          invalid credential data. E.g. nil access token, openID, expiration \
          date, or already expired.
          """)
        end(with: .login(result: nil, error: error))
        return
    }

    // next step
    oauth.getUserInfo()
  }

  public func tencentDidNotLogin(_ cancelled: Bool) {
    var error: Error
    if cancelled {
      error = SocialError.canceled(reason: "canceled by user")
    } else {
      error = SocialError.other(reason: nil)
    }
    end(with: .login(result: nil, error: error))

  }

  public func tencentDidNotNetWork() {
    let error = SocialError.send(reason: "network error")
    end(with: .login(result: nil, error: error))
  }

  public func getUserInfoResponse(_ response: APIResponse!) {
    do {
      let result = try QQLoginResult(response: response, oauth: oauth)
      end(with: .login(result: result, error: nil))
    } catch {
      end(with: .login(result: nil, error: error))
    }
  }
}

