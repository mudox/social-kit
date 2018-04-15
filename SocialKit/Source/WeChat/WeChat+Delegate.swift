import Foundation

import JacKit
fileprivate let jack = Jack.with(fileLocalLevel: .verbose)

extension WeChat: WXApiDelegate {
  public func onResp(_ baseResponse: BaseResp!) {
    guard let baseResponse = baseResponse else {
      jack.failure("got a nil `BaseResp` argument")
      return
    }
    
    let code = baseResponse.errCode
    let message = "code - \(code), message: \(baseResponse.errStr ?? "nil")"
    jack.verbose(message)

    let error: SocialKitError?
    switch code
    {
    case WXSuccess.rawValue:
      error = nil
    case WXErrCodeCommon.rawValue:
      error = .api(reason: """
        possible causes maybe:
          - not register app ID
          - not set app ID in URL types
          - the app ID used in the 2 places above mismatch
          - ...
        \(message)
        """)
    case WXErrCodeUserCancel.rawValue:
      error = .canceled(reason: message)
    case WXErrCodeSentFail.rawValue:
      error = .send(reason: message)
    case WXErrCodeAuthDeny.rawValue:
      error = .authorization
    case WXErrCodeUnsupport.rawValue:
      error = .app(reason: "installed WeChat app does not support SDK, \(message)")
    default:
      error = .other(reason: message)
    }

    switch baseResponse {
    case is SendMessageToWXResp:
      end(with: .sharing(error: error))
    case is PayResp:
      end(with: .payment(error: error))
    case is SendAuthResp:
      fatalError("Unimplemented")
    default:
      fatalError("Unimplemented")
    }
  }

  public func onReq(_ baseRequest: BaseReq!) {
    jack.failure("This callback is currently unhandled, argument `baseRequest`: \(baseRequest)")
  }
}
