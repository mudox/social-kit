
import Foundation

public enum SocialKitError: Swift.Error, CustomStringConvertible {

  /// Authorization failed.
  case authorization
  
  /// For example:
  /// - The QQ/TIM app is not installed.
  /// - The QQ/TIM need to be updated to support current SDK.
  ///
  /// Reaction:
  ///   Prompt user to install or update the platform client app.
  case app(reason: String?)

  /// For example:
  /// - The SDK need to be updated to support existing QQ/TIM app.
  ///
  /// Reaction:
  ///   Need to update the underlying platform SDK version tha
  ///   SocialKit is developed on.
  case sdk(reason: String?)

  /// For example:
  /// - App is not registered to platform SDK
  /// - Invalid message type for a specific target
  /// - Invalid message content, e.g. image too large
  /// - Invalid content for a message type
  ///
  /// Reaction:
  ///   SocialKit interal error, need clear them all on developing.
  case api(reason: String?)

  /// For example:
  /// - Networking errors.
  /// - Communication errors between apps.
  ///
  /// Reaction:
  ///   Common errors that can are inevitable.
  case send(reason: String?)

  /// For example:
  /// - User canceled the operation.
  ///
  /// Reaction:
  ///   No need to handle.
  case canceled(reason: String?)

  /// For example:
  /// - User sneak back, the task may completed or not
  ///
  /// Reaction:
  ///   Can not handle.
  case other(reason: String?)

  public var description: String {
    switch self {
    case .authorization:
      return "authorization failed"
    case .app(let reason):
      return "platform client app unavailable, \(reason ?? "reason unknown")"
    case .sdk(let reason):
      return "the platform SDK is incompatible, \(reason ?? "reason unknown")"
    case .api(let reason):
      return "API error, \(reason ?? "reason unknown")"
    case .send(let reason):
      return "failed to send request, \(reason ?? "reason unknown")"
    case .canceled(let reason):
      return "task canceled, \(reason ?? "reason unknown")"
    case .other(let reason):
      return "other error, \(reason ?? "reason unknown")"
    }
  }

}
