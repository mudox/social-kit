import UIKit
import Eureka
import Kingfisher

import SocialKit
import MudoxKit

import JacKit
fileprivate let jack = Jack.usingLocalFileScope().setLevel(.verbose)

class WeiboVC: FormViewController {

  var loginResultView: LoginResultView!

  var titleInput: String? {
    return self.form.values()["title"] as? String
  }

  var descriptionInput: String? {
    return self.form.values()["description"] as? String
  }

  var sharingTarget: Weibo.SharingTarget {
    return self.form.values()["sharingTarget"] as! Weibo.SharingTarget
  }

  var image: Data {
    let image = #imageLiteral(resourceName: "imageToShare")
    return UIImagePNGRepresentation(image)!
  }

  var previewImage: Data {
    let previewImage = #imageLiteral(resourceName: "previewImageToShare")
    return UIImagePNGRepresentation(previewImage)!
  }

  var imageGroup: [UIImage] {
    return [#imageLiteral(resourceName: "image04")]
  }

  let url = URL(string: "https://github.com/mudox")!

  func completion(for action: String) -> Weibo.SharingCompletion {
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

    navigationItem.title = "Weibo"

    let nib = UINib(nibName: "LoginResultView", bundle: nil)
    let view = nib.instantiate(withOwner: nil, options: nil).first as! LoginResultView
    tableView.tableHeaderView = view
    loginResultView = view

    form.inlineRowHideOptions = [.AnotherInlineRowIsShown, .FirstResponderChanges]

    form +++ Section()

    <<< ButtonRow() {
      $0.title = "Login"
    }.onCellSelection { cell, row in
      Weibo.login { baseResult, error in
        DispatchQueue.main.async { [weak self] in
          guard let ss = self else { return }

          guard let baseResult = baseResult else {
            jack.error("Failed to login Weibo: \(error!)")
            ss.view.mbp.execute(.failure(title: "登录失败"))
            return
          }

          guard let result = baseResult as? WeiboLoginResult else {
            jack.error("Can not cast BaseLoginResult instance to WeiboLoginResult")
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
      $0.value = "Test"
    }

    <<< TextRow("description") {
      $0.title = "Description"
      $0.value = "SocialKit framework"
    }

    <<< PickerInlineRow<Weibo.SharingTarget>("sharingTarget") {
      $0.title = "Target"
      $0.options = [.timeline, .story]
      $0.value = $0.options[0]
      $0.displayValueFor = {
        switch $0! {
        case .timeline: return "Timeline"
        case .story: return "Story"
        }
      }
    }

    form +++ Section("Share")

    <<< ButtonRow() {
      $0.title = "Simple text"
    }.onCellSelection { [weak self] cell, row in
      guard let ss = self else { return }
      Weibo.share(
        to: ss.sharingTarget,
        text: "Hey, this is a test message from SocialKit framework",
        completion: ss.completion(for: "text")
      )
    }

    <<< ButtonRow() {
      $0.title = "Single Image"
    }.onCellSelection { [weak self] cell, row in
      guard let ss = self else { return }
      Weibo.share(
        to: ss.sharingTarget,
        image: ss.image,
        title: ss.titleInput ?? "Test SocialKit",
        completion: ss.completion(for: "a group of images")
      )
    }
    
//    <<< ButtonRow() {
//      $0.title = "A Group of Images"
//    }.onCellSelection { [weak self] cell, row in
//      guard let ss = self else { return }
//      Weibo.share(
//        to: ss.sharingTarget,
//        images: ss.imageGroup,
//        title: ss.titleInput ?? "Test SocialKit",
//        completion: ss.completion(for: "a group of images")
//      )
//    }
  }

}
