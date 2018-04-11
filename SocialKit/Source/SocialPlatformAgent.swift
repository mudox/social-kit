import Foundation

import JacKit
fileprivate let jack = Jack.with(levelOfThisFile: .verbose)

public class BaseLoginResult {

  public let accessToken: String
  public let openID: String
  public let expirationDate: Date

  init(accessToken: String, openID: String, expirationDate: Date) {
    self.accessToken = accessToken
    self.openID = openID
    self.expirationDate = expirationDate
  }

}


/// Base class for concrete social platform agent classes
public class SocialPlatformAgent: NSObject {

  // MARK: - Manage Task

  enum Task {
    case sharing(completion: SharingCompletion?)
    case login(completion: LoginCompletion?)
  }

  private(set) var task: Task?

  enum TaskResult {
    case sharing(error: Error?)
    case login(result: BaseLoginResult?, error: Error?)
  }

  func begin(_ newTask: Task) {
    if task != nil {
      jack.warn("Previous task unclean")
    }

    task = newTask
  }

  func end(with result: TaskResult) {
    defer { task = nil }

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

  public typealias SharingCompletion = (Error?) -> ()
  public typealias LoginCompletion = (BaseLoginResult?, Error?) -> ()

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
    guard let task = self.task else {
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
    guard let task = self.task else {
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
}
