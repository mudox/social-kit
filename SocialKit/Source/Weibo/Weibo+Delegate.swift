import Foundation

import JacKit
fileprivate let jack = Jack.usingLocalFileScope().setLevel(.verbose)

extension Weibo: WeiboSDKDelegate {

  public func didReceiveWeiboRequest(_ request: WBBaseRequest!) {
    Jack.failure("This callback is currently unhandled, argument `request`: \(request)")
  }

  public func didReceiveWeiboResponse(_ baseResponse: WBBaseResponse!) {
    guard let baseResponse = baseResponse else {
      Jack.failure("Got a nil `WBBaseResponse` argument")
      return
    }

    switch baseResponse {
    case let response as WBAuthorizeResponse:
      _handle(response)
    case let response as WBSendMessageToWeiboResponse:
      _handle(response)
    default:
      Jack.failure("Unhandled response kind \(type(of: baseResponse))")
    }
  }

  private func _handle(_ response: WBAuthorizeResponse) {
    do {
      if let error = _error(for: response) {
        throw error
      } else {

        let token = response.accessToken
        let id = response.userID
        let date = response.expirationDate

        if let error = validate(accessToken: token, openID: id, expirationDate: date) {
          throw error
        }

        _getUserInfo(accessToken: token!, userID: id!) { [weak self] json, error in
          guard let ss = self else {
            Jack.failure("`self` should last forever")
            return
          }
          
          if let error = error {
            ss.end(with: .login(result: nil, error: error))
            return
          }
          
          guard let json = json else {
            ss.end(with: .login(result: nil, error: .api(reason: "the `json` argument should be non-nil")))
            return
          }
          
          let result = WeiboLoginResult(accessToken: token!, openID: id!, expirationDate: date!, userInfo: json)
          ss.end(with: .login(result: result, error: nil))
        }
      }
    } catch {
      end(with: .login(result: nil, error: (error as! SocialKitError)))
    }
  }

  private func _handle(_ response: WBSendMessageToWeiboResponse) {
    end(with: .sharing(error: _error(for: response)))
  }

  private func _error(for response: WBBaseResponse) -> SocialKitError? {
    switch response.statusCode {

    case .success:
      return nil
    case .userCancel:
      return .canceled(reason: nil)
    case .sentFail:
      return .send(reason: nil)
    case .authDeny:
      return .authorization
    case .userCancelInstall:
      return .canceled(reason: "user canceled Weibo client app installation")
    case .payFail:
      return .api(reason: "payment failed")
    case .shareInSDKFailed:
      return .api(reason: "userinfo: \(response.userInfo)")
    case .unsupport:
      return .api(reason: "unsupported request")
    case .unknown:
      return .other(reason: nil)
    }
  }

}

extension Weibo: WBMediaTransferProtocol {
  public func wbsdk_TransferDidReceive(_ object: Any!) {
    print(object)
  }
  
  public func wbsdk_TransferDidFailWith(_ errorCode: WBSDKMediaTransferErrorCode, andError error: Error!) {
    print("\(errorCode) - \(error)")
  }
  
  
}
