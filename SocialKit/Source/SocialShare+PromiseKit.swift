//
//  SocialShare+PromiseKit.swift
//  Pods
//
//  Created by Mudox on 18/04/2017.
//
//

import Foundation
import PromiseKit

// MARK: - PrommiseKit wrapper
extension SocialShare {

  public static func to(_ target: SSTarget, title: String, text: String, url: URL, previewImageData: Data) -> Promise<Void> {
    return PromiseKit.wrap { resolve in
      SocialShare.__to(target, withTitle: title, text: text, url: url, previewImageData: previewImageData, completion: resolve)
    }
  }

  public static func sso(to platform: SSPlatform) -> Promise<SSOResult> {
    return PromiseKit.wrap { resolve in
      SocialShare.__sso(to: platform, completion: resolve)
    }
  }

}
