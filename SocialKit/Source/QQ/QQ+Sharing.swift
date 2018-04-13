import Foundation

import JacKit
fileprivate let jack = Jack.with(levelOfThisFile: .verbose)

extension QQ {

  fileprivate func _handle(_ code: QQApiSendResultCode) -> SocialError? {
    let error: SocialError?

    switch code {
    case EQQAPISENDSUCESS:
      error = nil

      // QQ app not available
    case EQQAPIQQNOTINSTALLED, EQQAPIQQNOTSUPPORTAPI:
      error = .app(reason: "QQ app is not installed or not updated")
      // Platform SDK is outdated for existing QQ app
    case EQQAPIVERSIONNEEDUPDATE:
      error = .sdk(reason: "QQ SDK is outdated for existing QQ app")
      // TIM app not available
    case EQQAPITIMNOTINSTALLED, EQQAPITIMNOTSUPPORTAPI:
      error = .app(reason: "TIM app is not installed or not updated")
      // Platform SDK is outdated for existing TIM app
    case ETIMAPIVERSIONNEEDUPDATE:
      error = .sdk(reason: "QQ SDK is outdated for existing TIM app")

      // SocialKit error
    case EQQAPIAPPNOTREGISTED:
      error = .api(reason: """
        app ID is not registered to QQ SDK, need to call `SocialPlatforms.load([.qq(appID: <Your appID>), ...]) in \
        `AppDelegate.application(_:didFinishLaunchingWithOptions:launchOptions:)`
      """)
    case EQQAPISHAREDESTUNKNOWN:
      error = .api(reason: "`QQApiObject.shareDestType` is not given a valid target value")
    case EQQAPIMESSAGETYPEINVALID:
      error = .api(reason: "invalid message type")
    case EQQAPIMESSAGECONTENTNULL:
      error = .api(reason: "empty message content")
    case EQQAPIMESSAGECONTENTINVALID:
      error = .api(reason: "incorrect message content")
    case EQQAPIMESSAGEARKCONTENTNULL:
      error = .api(reason: "empty message ARK content")
    case EQQAPIQZONENOTSUPPORTTEXT:
      error = .api(reason: "Qzone does not support `QQApiTextObject`, use `QQApiImageArrayForQZoneObject`")
    case EQQAPIQZONENOTSUPPORTIMAGE:
      error = .api(reason: "Qzone does not support `QQApiImageObject`, use `QQApiImageArrayForQZoneObject`")

      // Sharing through H5 interface
    case EQQAPIAPPSHAREASYNC:
      jack.verbose("Message is sent asynchronously, perhaps through H5 interface")
      error = nil

      // Sending requests failed
    case EQQAPISENDFAILD:
      error = .send(reason: "sending request to QQ failed")
    case EQQAPITIMSENDFAILD:
      error = .send(reason: "sending request to TIM failed")

    default:
      error = .other(reason: "unhandled seding result code: \(code)")
    }

    return error
  }

  func _checkImageSizeNotExceeds5M(_ data: Data, completion block: SharingCompletion?) -> Bool {
    if data.count > 5 * 1024 * 1024 {
      let error = SocialError.api(reason: "Image data size (\(data.count)) exceeds 5M")
      begin(.sharing(completion: block))
      end(with: .sharing(error: error)) // invoke default completion block is user pass a nil block.
      return false
    } else {
      return true
    }
  }

  func _checkPreviewImageSizeNotExceeds1M(_ data: Data?, completion block: SharingCompletion?) -> Bool {
    if let data = data, data.count > 1 * 1024 * 1024 {
      let error = SocialError.api(reason: "Preview image size (\(data.count)) exceeds 1M")
      begin(.sharing(completion: block))
      end(with: .sharing(error: error)) // invoke default completion block is user pass a nil block.
      return false
    } else {
      return true
    }
  }


  /// Base method of sharing, the more convenient `shareXXX` methods is prefered.
  ///
  /// - Parameters:
  ///   - target: Sharing target.
  ///   - object: The message content object.
  ///   - block: completion block.
  public func send(
    to target: SharingTarget,
    object: QQApiObject,
    completion block: SharingCompletion?
  ) {
    QQ.shared.begin(.sharing(completion: block))

    switch target {
    case .qq:
      object.shareDestType = ShareDestTypeQQ
    case .tim:
      object.shareDestType = ShareDestTypeTIM
    case .qzone:
      object.shareDestType = ShareDestTypeQQ
      object.cflag = UInt64(kQQAPICtrlFlagQZoneShareOnStart)
    case .favorites:
      object.shareDestType = ShareDestTypeQQ
      object.cflag = UInt64(kQQAPICtrlFlagQQShareFavorites)
    }

    let request = SendMessageToQQReq(content: object)!
    let code = QQApiInterface.send(request)
    let error = _handle(code)

    if error != nil {
      end(with: .sharing(error: error))
    }
  }

  // MARK: - Share a Text Message

  /// Share a local image.
  ///
  /// - Parameters:
  ///   - target: Sharing target.
  ///   - text: The text content to share.
  ///   - block: completion block.
  public static func share(
    to target: SharingTarget = .qq,
    text: String, completion
    block: SharingCompletion?
  ) {
    QQ.shared._share(
      to: target,
      text: text,
      completion: block
    )
  }

  private func _share(
    to target: SharingTarget = .qq,
    text: String,
    completion block: SharingCompletion?
  ) {
    let object = QQApiTextObject(text: text)
    send(
      to: target,
      object: object!,
      completion: block
    )
  }

  // MARK: - Share an Image

  /// Share a local image.
  ///
  /// - Parameters:
  ///   - target: Sharing target.
  ///   - imageData: Image data size should not exceeeds __5M__.
  ///   - previewImage: Preview mage data size should not exceeeds __1M__.
  ///   - title: title.
  ///   - description: description.
  ///   - block: completion block.
  public static func share(
    to target: SharingTarget = .qq,
    image: Data,
    previewImage: Data? = nil,
    title: String,
    description: String? = nil,
    completion block: SharingCompletion?
  ) {
    QQ.shared._share(
      to: target,
      image: image,
      previewImage: previewImage,
      title: title,
      description: description,
      completion: block
    )
  }

  private func _share(
    to target: SharingTarget,
    image: Data,
    previewImage: Data? = nil,
    title: String,
    description: String? = nil,
    completion block: SharingCompletion?
  ) {
    guard _checkImageSizeNotExceeds5M(image, completion: block) else { return }
    guard _checkPreviewImageSizeNotExceeds1M(previewImage, completion: block) else { return }

    if let data = previewImage, data.count > 1 * 1024 * 1024 {
      let error = SocialError.api(reason: "Preview image size (\(data.count)) exceeds 1M")
      begin(.sharing(completion: block))
      end(with: .sharing(error: error)) // invoke default completion block is user pass a nil block.
      return
    }

    let object = QQApiImageObject(
      data: image,
      previewImageData: previewImage,
      title: title,
      description: description
    )
    send(
      to: target,
      object: object!,
      completion: block
    )
  }

  // MARK: - Share a Link

  /// Share a local image.
  ///
  /// - Parameters:
  ///   - target: Sharing target.
  ///   - url: Link address.
  ///   - previewImage: Preview mage data size should not exceeeds __1M__.
  ///   - title: title.
  ///   - description: description.
  ///   - block: completion block.
  public static func share(
    to target: SharingTarget = .qq,
    link url: URL,
    previewImage: Data,
    title: String,
    description: String? = nil,
    completion block: SharingCompletion?
  ) {
    QQ.shared._share(
      to: target,
      link: url,
      previewImage: previewImage,
      title: title,
      description: description,
      completion: block
    )
  }

  private func _share(
    to target: SharingTarget,
    link url: URL,
    previewImage: Data,
    title: String,
    description: String? = nil,
    completion block: SharingCompletion?
  ) {
    guard _checkPreviewImageSizeNotExceeds1M(previewImage, completion: block) else { return }

    let object = QQApiNewsObject(
      url: url,
      title: title,
      description: description,
      previewImageData: previewImage,
      targetContentType: QQApiURLTargetTypeNews
    )
    send(
      to: target,
      object: object!,
      completion: block
    )
  }

}
