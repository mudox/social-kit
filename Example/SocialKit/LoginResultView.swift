import UIKit
import SocialKit
import iOSKit

class LoginResultView: UIView {

  override func awakeFromNib() {
    super.awakeFromNib()

    tipLabel.isHidden = false

    contentView.isHidden = true
  }

  func set(with userInfo: QQLoginResult) {
    tipLabel.isHidden = true
    contentView.isHidden = false

    accessTokenLabel.text = userInfo.accessToken
    openIDLabel.text = userInfo.openID

    let dateText = with(DateFormatter()) { fmt -> String in
      fmt.timeZone = TimeZone.current
      fmt.dateStyle = .short
      fmt.timeStyle = .short
      return fmt.string(from: userInfo.expirationDate)
    }

    let intervalText = with(DateComponentsFormatter()) { fmt -> String in
      fmt.unitsStyle = .abbreviated
      fmt.allowedUnits = [.day]
      return  fmt.string(from: userInfo.expirationDate.timeIntervalSince(Date())) ?? ""
    }
    
    expirationDateLabel.text = "\(dateText) \(intervalText)"
    

    nicknameLabel.text = userInfo.nickname ?? "N/A"
    cityLabel.text = userInfo.location ?? "N/A"
    genderLabel.text = userInfo.gender == .male ? "Male" : "Female"
    avatarView.kf.setImage(with: userInfo.avatarURL)
  }

  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var tipLabel: UILabel!

  @IBOutlet weak var accessTokenLabel: UILabel!
  @IBOutlet weak var openIDLabel: UILabel!
  @IBOutlet weak var expirationDateLabel: UILabel!

  @IBOutlet weak var avatarView: UIImageView!
  @IBOutlet weak var nicknameLabel: UILabel!
  @IBOutlet weak var genderLabel: UILabel!
  @IBOutlet weak var cityLabel: UILabel!

}
