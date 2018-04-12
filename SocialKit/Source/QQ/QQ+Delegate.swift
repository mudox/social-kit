import Foundation

import JacKit
fileprivate let jack = Jack.with(fileLocalLevel: .verbose)

// MARK: - TencentSessionDelegate

extension QQ: TencentSessionDelegate {

  public func tencentDidLogin() {
    guard let token = oauth.accessToken, !token.isEmpty,
      let openID = oauth.openId, !openID.isEmpty,
      let date = oauth.expirationDate, date > Date()
      else {
        let reason = TencentOAuth.getLastErrorMsg()
        let error = SocialError.api(reason: """
          invalid credential data. May be:
            - nil access token, open ID, expiration date.
            - expiration date already expired.
          TencenOAuth.getLastErrorMsg: \(reason ?? "nil")
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
      let reason = TencentOAuth.getLastErrorMsg()
      error = SocialError.other(reason: """
        TencenOAuth.getLastErrorMsg: \(reason ?? "nil")
        """)
    }
    end(with: .login(result: nil, error: error))

  }

  public func tencentDidNotNetWork() {
    let reason = TencentOAuth.getLastErrorMsg()
    let error = SocialError.send(reason: """
      network error.
      TencenOAuth.getLastErrorMsg: \(reason ?? "nil")
      """)
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

// MARK: - QQApiInterfaceDelegate

extension QQ: QQApiInterfaceDelegate {

  public func onReq(_ baseReqeust: QQBaseReq!) {
    jack.warn("This callback is currently unhandled, argument `baseRequest`: \(baseReqeust)")
  }

  public func onResp(_ baseResponse: QQBaseResp!) {
    switch baseResponse {
    case let response as SendMessageToQQResp:
      jack.debug("response.result: \(response.result), TCOpenSDKErrorMsgSuccess: \(TCOpenSDKErrorMsgSuccess)")

      if let errorDescription = response.errorDescription {
        end(with: .sharing(error: SocialError.send(reason: errorDescription)))
      } else {
        end(with: .sharing(error: nil))
      }
    default:
      let message = "Isn't SendMessageToQQResp` the only subclass of `QQBaseResp`?"
      end(with: .sharing(error: SocialError.other(reason: message)))
    }
  }

  public func isOnlineResponse(_ response: [AnyHashable: Any]!) {
    jack.warn("This callback is currently unhandled, argument `response`: \(response)")
  }

}




