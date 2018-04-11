import Foundation

import JacKit
fileprivate let jack = Jack.with(levelOfThisFile: .verbose)

extension WeChat {

  public enum SharingTarget {
    case session
    case timeline
    case favorites
  }
  
  func _checkImageSizeNotExceeds10M(_ data: Data, completion block: SharingCompletion?) -> Bool {
    if data.count > 10 * 1024 * 1024 {
      let error = SocialError.api(reason: "Image data size (\(data.count)) exceeds 10M")
      begin(.sharing(completion: block))
      end(with: .sharing(error: error)) // invoke default completion block is user pass a nil block.
      return false
    } else {
      return true
    }
  }
  
  func _checkPreviewImageSizeNotExceeds32K(_ data: Data?, completion block: SharingCompletion?) -> Bool {
    if let data = data, data.count > 32 * 1024 {
      let error = SocialError.api(reason: "Preview image size (\(data.count)) exceeds 32K")
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
    to target: SharingTarget = .session,
    request: SendMessageToWXReq,
    completion block: SharingCompletion?
  ) {
    WeChat.shared.begin(.sharing(completion: block))

    switch target {
    case .session:
      request.scene = Int32(WXSceneSession.rawValue)
    case .timeline:
      request.scene = Int32(WXSceneTimeline.rawValue)
    case .favorites:
      request.scene = Int32(WXSceneFavorite.rawValue)
    }

    let success = WXApi.send(request)
    if !success {
      let error = SocialError.send(reason: """
        Calling `WXApi.send` method returned false, possible reason:
          - Image data size exceeds 10M
          - Preview image data size exceeds 32K
        """)
      end(with: .sharing(error: error))
    } else {
      // Caution:
      //   As of v1.8.2, when user deny to open WeChat app, `WXapi.send` call
      //   return true immediately.
      jack.verbose("""
        Calling `WApi.send` method returned true. As of WeChatSDK v1.8.2, \
        when user denied to open WeChat app, the method just return true, with \
        the completion block being uncleaned.
        """)
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
    to target: SharingTarget = .session,
    text: String, completion
    block: SharingCompletion?
  ) {
    WeChat.shared._share(
      to: target,
      text: text,
      completion: block
    )
  }

  private func _share(
    to target: SharingTarget = .session,
    text: String,
    completion block: SharingCompletion?
  ) {
    let request = SendMessageToWXReq()
    request.bText = true
    request.text = text

    send(
      to: target,
      request: request,
      completion: block
    )
  }

  // MARK: - Share an Image

  /// Share a local image.
  ///
  /// - Parameters:
  ///   - target: Sharing target.
  ///   - imageData: Image data size should not exceeds __10M__.
  ///   - previewImage: Preview mage data size should not exceeds __32K__.
  ///   - title: title.
  ///   - description: description.
  ///   - block: completion block.
  public static func share(
    to target: SharingTarget = .session,
    image: Data,
    previewImage: Data? = nil,
    title: String,
    description: String? = nil,
    completion block: SharingCompletion?
  ) {
    WeChat.shared._share(
      to: target,
      image: image,
      previewImage: previewImage,
      title: title,
      description: description,
      completion: block
    )
  }

  private func _share(
    to target: SharingTarget = .session,
    image: Data,
    previewImage: Data? = nil,
    title: String,
    description: String? = nil,
    completion block: SharingCompletion?
  ) {
    guard _checkImageSizeNotExceeds10M(image, completion: block) else { return }
    guard _checkPreviewImageSizeNotExceeds32K(previewImage, completion: block) else { return }

    let imageObject = WXImageObject()
    imageObject.imageData = image

    let message = WXMediaMessage()
    message.title = title
    message.description = description
    message.thumbData = previewImage
    message.mediaObject = imageObject

    let request = SendMessageToWXReq()
    request.bText = false
    request.message = message

    send(
      to: target,
      request: request,
      completion: block
    )
  }

  // MARK: - Share a Link

  /// Share a local image.
  ///
  /// - Parameters:
  ///   - target: Sharing target.
  ///   - url: link address.
  ///   - previewImage: Preview mage data, not bigger than __32K__.
  ///   - title: title.
  ///   - description: description.
  ///   - block: completion block.
  public static func share(
    to target: SharingTarget = .session,
    link url: URL,
    previewImage: Data,
    title: String,
    description: String? = nil,
    completion block: SharingCompletion?
  ) {
    WeChat.shared._share(
      to: target,
      link: url,
      previewImage: previewImage,
      title: title,
      description: description,
      completion: block
    )
  }

  private func _share(
    to target: SharingTarget = .session,
    link url: URL,
    previewImage: Data? = nil,
    title: String,
    description: String? = nil,
    completion block: SharingCompletion?
  ) {
    guard _checkPreviewImageSizeNotExceeds32K(previewImage, completion: block) else { return }

    let linkObject = WXWebpageObject()
    linkObject.webpageUrl = url.absoluteString

    let message = WXMediaMessage()
    message.title = title
    message.description = description
    message.thumbData = previewImage
    message.mediaObject = linkObject

    let request = SendMessageToWXReq()
    request.bText = false
    request.message = message

    send(
      to: target,
      request: request,
      completion: block
    )
  }

}

// MARK: - WXApiDelegate

extension WeChat: WXApiDelegate {
  public func onResp(_ response: BaseResp!) {
    let error: SocialError?

    switch response.errCode {
    case WXSuccess.rawValue:
      error = nil
    case WXErrCodeUserCancel.rawValue:
      error = .canceled(reason: response.errStr)
    case WXErrCodeSentFail.rawValue:
      error = .send(reason: response.errStr)
    case WXErrCodeAuthDeny.rawValue:
      error = .authorization
    case WXErrCodeUnsupport.rawValue:
      error = .app(reason: "installed WeChat app does not support SDK")
    default:
      error = .other(reason: nil)
    }

    end(with: .sharing(error: error))
  }

  public func onReq(_ baseRequest: BaseReq!) {
    jack.warn("This callback is currently unhandled, argument `baseRequest`: \(baseRequest)")

  }
}