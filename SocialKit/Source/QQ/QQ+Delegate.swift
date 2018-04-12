import Foundation

import JacKit
fileprivate let jack = Jack.with(fileLocalLevel: .verbose)

// MARK: - TencentSessionDelegate

extension QQ: TencentSessionDelegate {

  public func tencentDidLogin() {
    if let error = validate(accessToken: oauth.accessToken, openID: oauth.openId, expirationDate: oauth.expirationDate) {
      end(with: .login(result: nil, error: error))
      return
    }

    // next step
    oauth.getUserInfo()
  }

  public func tencentDidNotLogin(_ cancelled: Bool) {
    var error: SocialError
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

    guard response.retCode == URLREQUEST_SUCCEED.rawValue else {
      end(with: .login(result: nil, error: .api(reason: "`response.retCode` != `URLREQUEST_SUCCEED.rawValue`")))
      return
    }

    guard let json = response.jsonResponse as? [String: Any] else {
      end(with: .login(result: nil, error: .api(reason: "fail to cast response.jsonResponse to `[String: Any]`")))
      return
    }

    if let error = validate(accessToken: oauth.accessToken, openID: oauth.openId, expirationDate: oauth.expirationDate) {
      end(with: .login(result: nil, error: error))
      return
    }

    let result = QQLoginResult(
      accessToken: oauth.accessToken,
      openID: oauth.openId,
      expirationDate: oauth.expirationDate,
      userInfo: json
    )
    end(with: .login(result: result, error: nil))
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




