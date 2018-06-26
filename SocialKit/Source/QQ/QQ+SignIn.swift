import Foundation

import JacKit
fileprivate let jack = Jack.fileScopeInstance().setLevel(.verbose)


extension QQ {

  public final class SignInResult: BaseSignInResult, SignInResultType {

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
    
  } // class SignInResult

  public static func signIn(completion: @escaping SignInCompletion) {
    QQ.shared._signIn(completion: completion)
  }

  private func _signIn(completion: @escaping SignInCompletion) {
    begin(.login(completion: completion))

    let permissions = [
      kOPEN_PERMISSION_GET_USER_INFO
    ]
    oauth.authorize(permissions)
  }

}
