import Foundation

import JacKit
fileprivate let jack = Jack.with(fileLocalLevel: .verbose)

extension WeChat: WXApiDelegate {
  public func onResp(_ response: BaseResp!) {
    let error: SocialError?
    
    switch response.errCode {
    case WXSuccess.rawValue:
      error = nil
    case WXErrCodeUserCancel.rawValue:
      error = .canceled(reason: response.errStr)
    case WXErrCodeSentFail.rawValue:
      error = .send(reason: response.errStr)
    case WXErrCodeAuthDeny.rawValue:
      error = .authorization
    case WXErrCodeUnsupport.rawValue:
      error = .app(reason: "installed WeChat app does not support SDK")
    default:
      error = .other(reason: nil)
    }
    
    end(with: .sharing(error: error))
  }
  
  public func onReq(_ baseRequest: BaseReq!) {
    jack.warn("This callback is currently unhandled, argument `baseRequest`: \(baseRequest)")
  }
}
