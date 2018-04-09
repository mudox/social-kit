//
//  ViewController.swift
//  SocialKit
//
//  Created by mudox on 11/13/2017.
//  Copyright (c) 2017 mudox. All rights reserved.
//

import UIKit
import Eureka

import SocialKit
import iOSKit

import JacKit
fileprivate let jack = Jack.with(fileLocalLevel: .verbose)

class MainVC: FormViewController {

  var titleInput: String? {
    return self.form.values()["title"] as? String
  }

  var descriptionInput: String? {
    return self.form.values()["description"] as? String
  }

  var qqTarget: QQ.SharingTarget {
    return self.form.values()["qqTarget"] as! QQ.SharingTarget
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    form.inlineRowHideOptions = [.AnotherInlineRowIsShown, .FirstResponderChanges]

    form +++ Section("COMMON INPUTS")

    <<< TextRow("title") {
      $0.title = "Title"
      $0.value = "Test"
    }

    <<< TextRow("description") {
      $0.title = "Description"
      $0.value = "SocialKit framework"
    }

    form +++ Section("QQ")

    <<< PickerInlineRow<QQ.SharingTarget>("qqTarget") {
      $0.title = "Target"
      $0.options = [.qq, .tim]
      $0.value = $0.options[0]
    }

    <<< ButtonRow() {
      $0.title = "Simple text"
    }.onCellSelection { [weak self] cell, row in
      guard let ss = self else { return }
      QQ.share(to: ss.qqTarget, text: "SocialKit test: share a simple text message to QQ") { error in
        if let error = error {
          ss.view.mbp.execute(.failure(title: "分享失败"))
          jack.error("Sharing a simple text message to \(ss.qqTarget) failed: \(error)")
        } else {
          ss.view.mbp.execute(.success(title: "分享成功"))
          jack.info("Sharing a simple text message to \(ss.qqTarget) succeeded")
        }
      }
    }

    <<< ButtonRow() {
      $0.title = "Local Image"
    }.onCellSelection { [weak self] cell, row in
      guard let ss = self else { return }
      let image = #imageLiteral(resourceName: "ImageToShare")
      let data = UIImagePNGRepresentation(image)!
      QQ.share(to: ss.qqTarget, image: data) { error in
        if let error = error {
          ss.view.mbp.execute(.failure(title: "分享失败"))
          jack.error("Sharing a local image message to \(ss.qqTarget) failed: \(error)")
        } else {
          ss.view.mbp.execute(.success(title: "分享成功"))
          jack.info("Sharing a local image message to \(ss.qqTarget) succeeded")
        }
      }
    }


  }

}
