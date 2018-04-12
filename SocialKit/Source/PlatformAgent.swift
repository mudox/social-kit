import Foundation

import JacKit
fileprivate let jack = Jack.with(levelOfThisFile: .verbose)

/// Base class for concrete social platform agent classes
public class BasePlatformAgent: NSObject {

  // MARK: - Manage Task

  enum Task {
    case sharing(completion: SharingCompletion?)
    case login(completion: LoginCompletion?)
  }

  private var _task: Task?

  enum TaskResult {
    case sharing(error: SocialError?)
    case login(result: BaseLoginResult?, error: SocialError?)
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
    case let .login(result, error):
      jack.assert(
        (result == nil && error != nil) || (result != nil && error == nil),
        "result and error should not be nil or non-nil at the same time"
      )
      _loginCompletion(result, error)
    }
  }

  // MARK: - Manage Completion Blocks

  public typealias SharingCompletion = (SocialError?) -> ()
  public typealias LoginCompletion = (BaseLoginResult?, SocialError?) -> ()

  // default sharing completion block
  private let _defaultSharingCompletion: SharingCompletion = { error in
    if let error = error {
      jack.error("Unhandled social sharing task error: \(error)")
    } else {
      jack.debug("Unhandled social sharing task result: success")
    }
  }

  // default login completion block
  private let _defaultLoginCompletion: LoginCompletion = { result, error in
    // check nullability combination
    if result == nil && error == nil {
      jack.error("reuslt and error should not be nil at the same time")
    }

    if result != nil && error != nil {
      jack.error("reuslt and error should not be non-nil at the same time")
    }

    if let error = error {
      jack.error("Unhandled social login task error: \(error)")
    } else {
      jack.debug("Unhandled social login task result: \(result!)")
    }
  }


  private var _sharingCompletion: SharingCompletion {
    guard let task = _task else {
      jack.assertFailure("Current task is nil")
      return _defaultSharingCompletion
    }

    if case let .sharing(completion: block) = task {
      return block ?? _defaultSharingCompletion
    } else {
      jack.assertFailure("task type (login) does not match result type (sharing)")
      return _defaultSharingCompletion
    }
  }

  private var _loginCompletion: LoginCompletion {
    guard let task = _task else {
      jack.assertFailure("Current task is nil")
      return _defaultLoginCompletion
    }

    if case let .login(completion: block) = task {
      return block ?? _defaultLoginCompletion
    } else {
      jack.assertFailure("task type (login) does not match result type (sharing)")
      return _defaultLoginCompletion
    }
  }
  
  // MARK: - Helpers
  
  func validate(accessToken token: String?, openID id: String?, expirationDate date: Date?) -> SocialError? {
    
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
