//
//  ViewController.swift
//  SocialKit
//
//  Created by mudox on 11/13/2017.
//  Copyright (c) 2017 mudox. All rights reserved.
//

import UIKit
import Eureka
import Kingfisher

import SocialKit
import iOSKit

import JacKit
fileprivate let jack = Jack.with(fileLocalLevel: .verbose)

class QQVC: FormViewController {

  var loginResultView: LoginResultView!

  var titleInput: String? {
    return self.form.values()["title"] as? String
  }

  var descriptionInput: String? {
    return self.form.values()["description"] as? String
  }

  var sharingTarget: QQ.SharingTarget {
    return self.form.values()["sharingTarget"] as! QQ.SharingTarget
  }

  var image: Data {
    let image = #imageLiteral(resourceName: "imageToShare")
    return UIImagePNGRepresentation(image)!
  }

  var previewImage: Data {
    let image = #imageLiteral(resourceName: "previewImageToShare")
    return UIImagePNGRepresentation(image)!
  }


  let url = URL(string: "https://github.com/mudox")!

  func completion(for action: String) -> QQ.SharingCompletion {
    return { [weak self] error in
      guard let ss = self else { return }
      if let error = error {
        ss.view.mbp.execute(.failure(title: "分享失败"))
        jack.error("Sharing \(action) to \(ss.sharingTarget) failed: \(error)")
      } else {
        ss.view.mbp.execute(.success(title: "分享成功"))
        jack.info("Sharing \(action) to \(ss.sharingTarget) succeeded")
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.title = "QQ"

    let nib = UINib(nibName: "LoginResultView", bundle: nil)
    let view = nib.instantiate(withOwner: nil, options: nil).first as! LoginResultView
    tableView.tableHeaderView = view
    loginResultView = view

    form.inlineRowHideOptions = [.AnotherInlineRowIsShown, .FirstResponderChanges]

    form +++ Section()

    <<< ButtonRow() {
      $0.title = "Login"
    }.onCellSelection { cell, row in
      QQ.login { baseResult, error in
        DispatchQueue.main.async { [weak self] in
          guard let ss = self else { return }

          guard let baseResult = baseResult else {
            jack.error("Failed to login QQ: \(error!)")
            ss.view.mbp.execute(.failure(title: "登录失败"))
            return
          }

          guard let result = baseResult as? QQLoginResult else {
            jack.error("Can not cast LoginResult instance to QQLoginResult")
            ss.view.mbp.execute(.failure(title: "登录失败"))
            return
          }

          ss.view.mbp.execute(.success(title: "登录成功"))
          ss.loginResultView.set(with: result)
        }
      }
    }

    form +++ Section("INPUTS")

    <<< TextRow("title") {
      $0.title = "Title"
      $0.value = "Title: SocialKit Test"
    }

    <<< TextRow("description") {
      $0.title = "Description"
      $0.value = "Description: Shared from SocialKit demo app."
    }

    <<< PickerInlineRow<QQ.SharingTarget>("sharingTarget") {
      $0.title = "Target"
      $0.options = [.qq, .tim, .qzone, .favorites]
      $0.value = $0.options[0]
      $0.displayValueFor = {
        switch $0! {
        case .qq: return "QQ"
        case .tim: return "TIM"
        case .qzone: return "QZone"
        case .favorites: return "Favorites"
        }
      }
    }

    form +++ Section("Share")

    <<< ButtonRow() {
      $0.title = "Simple text"
    }.onCellSelection { [weak self] cell, row in
      guard let ss = self else { return }
      QQ.share(
        to: ss.sharingTarget,
        text: "Hey, this is a test message from SocialKit framework",
        completion: ss.completion(for: "text")
      )
    }

    <<< ButtonRow() {
      $0.title = "Local Image"
    }.onCellSelection { [weak self] cell, row in
      guard let ss = self else { return }
      QQ.share(
        to: ss.sharingTarget,
        image: ss.image,
        title: ss.titleInput ?? "Test SocialKit",
        description: ss.descriptionInput,
        completion: ss.completion(for: "image")
      )
    }


    <<< ButtonRow() {
      $0.title = "Link"
    }.onCellSelection { [weak self] cell, row in
      guard let ss = self else { return }
      QQ.share(
        to: ss.sharingTarget,
        link: ss.url,
        previewImage: ss.image,
        title: ss.titleInput ?? "Test SocialKit",
        description: ss.descriptionInput,
        completion: ss.completion(for: "link")
      )
    }

  }

}
