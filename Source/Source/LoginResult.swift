import Foundation

import JacKit
fileprivate let jack = Jack()

public class BaseSignInResult {

  public let id: String
  public let accessToken: String
  public let expirationDate: Date

  /// User information in JSON format.
  public let userInfo: [String: Any]

  init(id: String, accessToken: String, expirationDate: Date, userInfo: [String: Any]) {
    self.accessToken = accessToken
    self.id = id
    self.expirationDate = expirationDate

    self.userInfo = userInfo
  }

}

public enum Gender {
  case male, female
}

public protocol SignInResultType {

  var nickname: String? { get }

  var gender: Gender? { get }

  var location: String? { get }

  var avatarURL: URL? { get }

}
