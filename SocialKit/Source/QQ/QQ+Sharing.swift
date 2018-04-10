import Foundation

import JacKit
fileprivate let jack = Jack.with(levelOfThisFile: .verbose)

extension QQ {

  fileprivate func handleSendResultCode(_ code: QQApiSendResultCode) {

    guard let task = self.task else {
      jack.assertFailure("Property `task` should not be nil")
      // no task stored, no need to call the default completion block
      return
    }

    var error: SocialError? = nil
    defer {
      switch task {
      case .sharing:
        end(with: .sharing(error: error))
      case .login:
        jack.assertFailure("Property `.task` should be a Task.sharing case")
      }
    }

    switch code {
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
        App key is not registered to QQ SDK, need to call `SocialPlatforms.load([.qq(appKey: ...), ...]) in \
        `AppDelegate.application(_:didFinishLaunchingWithOptions:launchOptions:)`
      """)
    case EQQAPISHAREDESTUNKNOWN:
      error = .api(reason: "`QQApiObject.shareDestType` is not given a valid target value")
    case EQQAPIMESSAGETYPEINVALID:
      error = .api(reason: "Invalid message type")
    case EQQAPIMESSAGECONTENTNULL:
      error = .api(reason: "Empty message content")
    case EQQAPIMESSAGECONTENTINVALID:
      error = .api(reason: "Incorrect message content")
    case EQQAPIMESSAGEARKCONTENTNULL:
      error = .api(reason: "Empty message ARK content")
    case EQQAPIQZONENOTSUPPORTTEXT:
      error = .api(reason: "Qzone does not support `QQApiTextObject`, use `QQApiImageArrayForQZoneObject`")
    case EQQAPIQZONENOTSUPPORTIMAGE:
      error = .api(reason: "Qzone does not support `QQApiImageObject`, use `QQApiImageArrayForQZoneObject`")

      // Sharing through H5 interface
    case EQQAPIAPPSHAREASYNC:
      jack.verbose("Message is sent asynchronously, perhaps through H5 interface")

      // Sending requests failed
    case EQQAPISENDFAILD:
      error = .send(reason: "Sending request to QQ failed")
    case EQQAPITIMSENDFAILD:
      error = .send(reason: "Sending request to TIM failed")

    default:
      error = .other(reason: "Unhandled seding result code: \(code)")
    }
  }

  /// Base method of sharing, the more convenient `shareXXX` methods is prefered.
  ///
  /// - Parameters:
  ///   - target: Sharing target.
  ///   - object: The message content object.
  ///   - block: completion block.
  public func send(to target: SharingTarget = .qq, object: QQApiObject, completion block: SharingCompletion?) {
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
    QQApiInterface.send(request)
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
  ///   - imageData: Image data, not bigger than __5M__.
  ///   - title: title.
  ///   - description: description.
  ///   - block: completion block.
  public static func share(
    to target: SharingTarget = .qq,
    image data: Data,
    title: String,
    description: String? = nil,
    completion block: SharingCompletion?
  ) {
    QQ.shared._share(
      to: target,
      image: data,
      title: title,
      description: description,
      completion: block
    )
  }

  private func _share(
    to target: SharingTarget = .qq,
    image data: Data,
    title: String,
    description: String? = nil,
    completion block: SharingCompletion?
  ) {
    let object = QQApiImageObject(
      data: data,
      previewImageData: data,
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
  ///   - url: New address.
  ///   - previewImage: Preview mage data, not bigger than __1M__.
  ///   - title: title.
  ///   - description: description.
  ///   - block: completion block.
  public static func share(
    to target: SharingTarget = .qq,
    link url: URL,
    previewImage data: Data,
    title: String,
    description: String? = nil,
    completion block: SharingCompletion?
  ) {
    QQ.shared._share(
      to: target,
      link: url,
      previewImage: data,
      title: title,
      description: description,
      completion: block
    )
  }

  private func _share(
    to target: SharingTarget = .qq,
    link url: URL,
    previewImage data: Data,
    title: String,
    description: String? = nil,
    completion block: SharingCompletion?
  ) {
    let object = QQApiNewsObject(
      url: url,
      title: title,
      description: description,
      previewImageData: data,
      targetContentType: QQApiURLTargetTypeNews
    )
    send(
      to: target,
      object: object!,
      completion: block
    )
  }

}

// MARK: - QQApiInterfaceDelegate
extension QQ: QQApiInterfaceDelegate {

  public func onReq(_ baseReqeust: QQBaseReq!) {
    jack.warn("This callback is currently unhandled, argument `response`: \(baseReqeust)")
  }

  public func onResp(_ baseResponse: QQBaseResp!) {
    switch baseResponse {
    case let response as SendMessageToQQResp:
      if let errorDescription = response.errorDescription {
        end(with: .sharing(error: SocialError.send(reason: errorDescription)))
      } else {
        end(with: .sharing(error: nil))
      }
    default:
      let message = "Isn't SendMessageToQQResp` the only subclass of `QQBaseResp`?"
      end(with: .sharing(error: SocialError.other(reason: message)))
    }
  }

  public func isOnlineResponse(_ response: [AnyHashable: Any]!) {
    jack.warn("This callback is currently unhandled, argument `response`: \(response)")
  }

}

