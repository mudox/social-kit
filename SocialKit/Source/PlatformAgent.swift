import Foundation

import JacKit
fileprivate let jack = Jack.fileScopeInstance().setLevel(.verbose)

/// Base class for concrete social platform agent classes
public class BasePlatformAgent: NSObject {

  // MARK: - Manage Task

  /// Unlike normal network requests, each platform can start a one task at a time.
  enum Task {
    case sharing(completion: SharingCompletion?)
    case login(completion: SignInCompletion?)
    case payment(completion: PaymentCompletion?)
    
    var type: String {
      switch self {
      case .sharing: return "sharing"
      case .login: return "signIn"
      case .payment: return "payment"
      }
    }
  }

  private var _task: Task?

  enum TaskResult {
    case sharing(error: SocialKitError?)
    case signIn(result: BaseSignInResult?, error: SocialKitError?)
    case payment(error: SocialKitError?)
  }

  func begin(_ newTask: Task) {
    if _task != nil {
      jack.warn("Previous task unclean")
    }

    _task = newTask
  }

  func end(with result: TaskResult) {
    defer { _task = nil }

    switch result {
    case let .sharing(error: error):
      _sharingCompletion(error)
    case let .signIn(result, error):
      Jack.assert(
        (result == nil && error != nil) || (result != nil && error == nil),
        "result and error should not be nil or non-nil at the same time"
      )
      _loginCompletion(result, error)
    case let .payment(error: error):
      _paymentCompletion(error)
    }
  }

  // MARK: - Manage Completion Blocks

  public typealias SharingCompletion = (SocialKitError?) -> ()
  public typealias SignInCompletion = (BaseSignInResult?, SocialKitError?) -> ()
  public typealias PaymentCompletion = (SocialKitError?) -> ()

  // default sharing completion block
  private let _defaultSharingCompletion: SharingCompletion = { error in
    if let error = error {
      jack.error("Unhandled social sharing task error: \(error)")
    } else {
      jack.debug("Unhandled social sharing task result: success")
    }
  }

  // default login completion block
  private let _defaultSignInCompletion: SignInCompletion = { result, error in
    // check nullability combination
    if result == nil && error == nil {
      jack.error("reuslt and error should not be nil at the same time")
    }

    if result != nil && error != nil {
      jack.error("reuslt and error should not be non-nil at the same time")
    }

    if let error = error {
      jack.error("Unhandled social signIn task error: \(error)")
    } else {
      jack.debug("Unhandled social signIn task result: \(result!)")
    }
  }

  
  // default payment completion block
  private let _defaultPaymentCompletion: PaymentCompletion = { error in
    if let error = error {
      jack.error("Unhandled payment task error: \(error)")
    } else {
      jack.debug("Unhandled payment task result: success")
    }
  }

  private var _sharingCompletion: SharingCompletion {
    guard let task = _task else {
      Jack.failure("Current task is nil")
      return _defaultSharingCompletion
    }

    if case let .sharing(completion: block) = task {
      return block ?? _defaultSharingCompletion
    } else {
      Jack.failure("Expecting `_task` to be sharing task, got (\(_task!.type))")
      return _defaultSharingCompletion
    }
  }

  private var _loginCompletion: SignInCompletion {
    guard let task = _task else {
      Jack.failure("Value of `_task` should not be nil")
      return _defaultSignInCompletion
    }

    if case let .login(completion: block) = task {
      return block ?? _defaultSignInCompletion
    } else {
      Jack.failure("Expecting `_task` to be signIn task, got (\(_task!.type))")
      return _defaultSignInCompletion
    }
  }
  
  private var _paymentCompletion: PaymentCompletion {
    guard let task = _task else {
      Jack.failure("Current task is nil")
      return _defaultPaymentCompletion
    }
    
    if case let .payment(completion: block) = task {
      return block ?? _defaultPaymentCompletion
    } else {
      Jack.failure("Expecting `_task` to be payment task, got (\(_task!.type))")
      return _defaultSharingCompletion
    }
  }


  // MARK: - Helpers

  func validate(accessToken token: String?, openID id: String?, expirationDate date: Date?) -> SocialKitError? {

    guard let token = token, !token.isEmpty else {
      return .api(reason: "`oauth.accessToken` is nil or empty")
    }

    guard let id = id, !id.isEmpty else {
      return .api(reason: "`oauth.openId` is nil or empty")
    }

    guard let date = date else {
      return .api(reason: "`oauth.expirationDate` is nil")
    }

    guard date > Date() else {
      return .api(reason: "got a already expired date")
    }

    return nil
  }
}

public protocol PlatformAgentType {

  associatedtype SharingTarget

  var platformInfo: String { get }

  static func open(_ url: URL) -> Bool

  var canLogin: Bool { get }

  var canShare: Bool { get }

}
