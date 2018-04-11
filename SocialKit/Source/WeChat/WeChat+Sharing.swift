import Foundation

import JacKit
fileprivate let jack = Jack.with(levelOfThisFile: .verbose)

extension WeChat {

  public enum SharingTarget {
    case session
    case timeline
    case favorites
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
    var error: SocialError? = nil
    WeChat.shared.begin(.sharing(completion: block))
    

    switch target {
    case .session:
      request.scene = Int32(WXSceneSession.rawValue)
    case .timeline:
      request.scene = Int32(WXSceneTimeline.rawValue)
    case .favorites:
      request.scene = Int32(WXSceneFavorite.rawValue)
    }

    if !WXApi.send(request) {
      error = SocialError.send(reason: "calling `WXApi.send` method returned false")
    }
    
    end(with: .sharing(error: error))
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
  ///   - imageData: Image data, not bigger than __5M__.
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
    previewImage data: Data,
    title: String,
    description: String? = nil,
    completion block: SharingCompletion?
  ) {
    WeChat.shared._share(
      to: target,
      link: url,
      previewImage: data,
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
