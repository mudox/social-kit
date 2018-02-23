//
//  ViewController.swift
//  SocialKit
//
//  Created by mudox on 11/13/2017.
//  Copyright (c) 2017 mudox. All rights reserved.
//

import UIKit
import Eureka
import JacKit

fileprivate let jack = Jack.with(levelOfThisFile: .debug)

class RootViewController: FormViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    form +++ Section("简单分享")
    <<< ButtonRow() { row in
      row.title = "到微信"
    }.onCellSelection { cell, row in
      jack.warn("Share to Wechat")
    }
    <<< ButtonRow() { row in
      row.title = "到微博"
    }.onCellSelection { cell, row in
      jack.warn("Share to Weibo")
    }
    <<< ButtonRow() { row in
      row.title = "到 QQ"
    }.onCellSelection { cell, row in
      jack.warn("Share to QQ")
    }
  }

}
