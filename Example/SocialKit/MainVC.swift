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

class MainVC: FormViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.title = "SocialKit"
    if #available(iOS 11.0, *) {
      navigationController?.navigationBar.prefersLargeTitles = true
    }

    form +++ Section()

    <<< ButtonRow() {
      $0.title = "QQ"
      $0.presentationMode = .show(controllerProvider: .callback(builder: QQVC.init), onDismiss: nil)
    }

    <<< ButtonRow() {
      $0.title = "WeChat"
      $0.presentationMode = .show(controllerProvider: .callback(builder: WeChatVC.init), onDismiss: nil)
    }

    <<< ButtonRow() {
      $0.title = "Weibo"
      $0.presentationMode = .show(controllerProvider: .callback(builder: WeiboVC.init), onDismiss: nil)
      $0.disabled = true
    }.cellSetup { cell, row in
      cell.textLabel?.textColor = .lightGray
    }
  }

}
