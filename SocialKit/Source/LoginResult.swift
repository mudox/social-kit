import Foundation

import JacKit
fileprivate let jack = Jack.with(fileLocalLevel: .verbose)

public class BaseLoginResult {

  public let accessToken: String
  public let openID: String
  public let expirationDate: Date

  public let userInfo: [String: Any]

  init(accessToken: String, openID: String, expirationDate: Date, userInfo: [String: Any]) {
    self.accessToken = accessToken
    self.openID = openID
    self.expirationDate = expirationDate

    self.userInfo = userInfo
  }

}

public enum Gender {
  case male, female
}

public protocol LoginResultType {

  var nickname: String? { get }

  var gender: Gender? { get }

  var location: String? { get }

  var avatarURL: URL? { get }

}
