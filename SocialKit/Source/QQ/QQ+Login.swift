import Foundation

import JacKit
fileprivate let jack = Jack.with(levelOfThisFile: .verbose)

class QQLoginResult: BaseLoginResult {

  let nickname: String
  let avatarURL: URL
  let originalJSON: [String: Any]

  init(accessToken: String, openID: String, expirationDate: Date, nickname: String, avatarURL: URL, originalJSON: [String: Any]) {
    self.nickname = nickname
    self.avatarURL = avatarURL
    self.originalJSON = originalJSON

    super.init(accessToken: accessToken, openID: openID, expirationDate: expirationDate)
  }
}

extension QQ {
  func login() {
    let permissions = [
      kOPEN_PERMISSION_GET_USER_INFO
    ]
    oauth.authorize(permissions)
  }
}

extension QQ: TencentSessionDelegate {

  public func tencentDidLogin() {
    guard let token = oauth.accessToken, !token.isEmpty else {
      let error = SocialError.api(reason: """
        Login operation failed with internal error: authorization passed \
        but got an empty access token.
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
      error = SocialError.canceled(reason: "Login operation is canceled")
    } else {
      error = SocialError.other(reason: "Login operation failed with unknown reason")
    }
    end(with: .login(result: nil, error: error))

  }

  public func tencentDidNotNetWork() {
    let error = SocialError.send(reason: "Login operation failed with network error")
    end(with: .login(result: nil, error: error))
  }

  public func getUserInfoResponse(_ response: APIResponse!) {
    guard response.retCode == URLREQUEST_SUCCEED.rawValue else {
      let error = SocialError.api(reason: """
        Fetching user information failed: \(response.message ?? "reason unknown")
        """)
      end(with: .login(result: nil, error: error))
      return
    }

    guard let json = response.jsonResponse as? [String: Any],
      let nickname = json["nickname"] as? String,
      let avatarURL = URL(string: json["figureurl_qq_2"] as? String ?? ""),
      let accessToken = oauth.accessToken,
      let openID = oauth.openId,
      let expirationDate = oauth.expirationDate
      else {
        let error = SocialError.api(reason: """
          Fetching user information failed: no error message, but got a nil JSON content.
          """)
        end(with: .login(result: nil, error: error))
        return
    }

    let result = QQLoginResult(
      accessToken: accessToken,
      openID: openID,
      expirationDate: expirationDate,
      nickname: nickname,
      avatarURL: avatarURL,
      originalJSON: json
    )

    end(with: .login(result: result, error: nil))
  }
}

