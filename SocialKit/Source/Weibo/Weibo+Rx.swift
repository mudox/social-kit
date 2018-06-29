import UIKit

import JacKit
fileprivate let jack = Jack()

import RxSwift
import RxCocoa

extension Reactive where Base: Weibo {
  
  public static var signIn: Single<Weibo.SignInResult> {
    return .create { single -> Disposable in
      Base.signIn(completion: { result, error in
        if let e = error {
          single(.error(e))
        } else if let result = result {
          if let r = result as? Weibo.SignInResult {
            jack.info("\(r)")
            single(.success(r))
          } else {
            single(.error(SocialKit.Error.sdk(reason: "casting `result` to `Weibo.SignInResult` failed")))
          }
        } else {
          single(.error(SocialKit.Error.sdk(reason: "`result` & `error` should not both be nil")))
        }
      })
      return Disposables.create()
    } // return .create
  } // func signIn
  
}
