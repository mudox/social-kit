import Foundation

import JacKit
fileprivate let jack = Jack.with(levelOfThisFile: .verbose)


public enum LoginResult {
  case qq
}


/// Base class for concrete social platform agent classes
public class SocialPlatformAgent: NSObject {
  
  public typealias SharingCompletion = (Error?) -> ()
  public typealias LoginCompletion = (LoginResult?, Error?) -> ()
  
  // default sharing completion block
  let defaultSharingCompletion: SharingCompletion = { error in
    if let error = error {
      jack.error("Unhandled social sharing task error: \(error)")
    } else {
      jack.debug("Unhandled social sharing task result: success")
    }
  }
  
  // default login completion block
  let defaultLoginCompletion: LoginCompletion = { result, error in
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

  enum Task {
    case sharing(completion: SharingCompletion?)
    case login(completion: LoginCompletion?)
  }
  
  var task: Task?

  enum TaskResult {
    case sharing(error: Error?)
    case login(LoginResult?, error: Error?)
  }

  func begin(_ newTask: Task) {
    if task != nil {
      jack.warn("Uncleaned agent task: \(task!)")
    }

    task = newTask
  }

  func end(with result: TaskResult) {
    defer { task = nil }

    switch result {
    case let .sharing(error: error):
      sharingCompletion(error)
    case let .login(result, error):
      loginCompletion(result, error)
    }
  }

  var sharingCompletion: SharingCompletion {
    guard let task = self.task else {
      jack.assertFailure("Current task is nil")
      return defaultSharingCompletion
    }

    if case let .sharing(completion: block) = task {
      return block ?? defaultSharingCompletion
    } else {
      jack.assertFailure("task type (login) does not match result type (sharing)")
      return defaultSharingCompletion
    }
  }

  var loginCompletion: LoginCompletion {
    guard let task = self.task else {
      jack.assertFailure("Current task is nil")
      return defaultLoginCompletion
    }

    if case let .login(completion: block) = task {
      return block ?? defaultLoginCompletion
    } else {
      jack.assertFailure("task type (login) does not match result type (sharing)")
      return defaultLoginCompletion
    }
  }
}
