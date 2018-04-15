import Foundation

import JacKit
fileprivate let jack = Jack.with(levelOfThisFile: .verbose)

extension Weibo {

//  func _checkImageSizeNotExceeds10M(_ data: Data, completion block: SharingCompletion?) -> Bool {
//    if data.count > 10 * 1024 * 1024 {
//      let error = SocialError.api(reason: "Image data size (\(data.count)) exceeds 10M")
//      begin(.sharing(completion: block))
//      end(with: .sharing(error: error)) // invoke default completion block is user pass a nil block.
//      return false
//    } else {
//      return true
//    }
//  }
//
//  func _checkPreviewImageSizeNotExceeds32K(_ data: Data?, completion block: SharingCompletion?) -> Bool {
//    if let data = data, data.count > 32 * 1024 {
//      let error = SocialError.api(reason: "Preview image size (\(data.count)) exceeds 32K")
//      begin(.sharing(completion: block))
//      end(with: .sharing(error: error)) // invoke default completion block is user pass a nil block.
//      return false
//    } else {
//      return true
//    }
//  }
//

  /// Base method of sharing, the more convenient `shareXXX` methods is prefered.
  ///
  /// - Parameters:
  ///   - target: Sharing target.
  ///   - object: The message content object.
  ///   - block: completion block.
  public func send(
    to target: SharingTarget,
    message: WBMessageObject,
    completion block: SharingCompletion?
  ) {
    Weibo.shared.begin(.sharing(completion: block))

    switch target {
    case .timeline:
      message.imageObject?.isShareToStory = false
      message.videoObject?.isShareToStory = false
    case .story:
      message.imageObject?.isShareToStory = true
      message.videoObject?.isShareToStory = true
    }

    guard let request = WBSendMessageToWeiboRequest.request(
      withMessage: message,
      authInfo: authorizationRequest,
      access_token: nil
    ) as? WBSendMessageToWeiboRequest else {
      end(with: .sharing(error: .api(reason: "Creating `WBSendMessageToWeiboRequest` instance failed")))
      return
    }

    let success = WeiboSDK.send(request)
    if !success {
      end(with: .sharing(error: .send(reason: "call `WeiboSDK.send` returned false")))

    }
  }

  // MARK: - Share a Text Message

  /// Share a local image.
  ///
  /// - Note: text (as well as media) can not be shared to story (SharintTarget.story).
  ///
  /// - Parameters:
  ///   - target: Sharing target.
  ///   - text: The text content to share.
  ///   - block: completion block.
  public static func share(
    to target: SharingTarget = .timeline,
    text: String, completion
    block: SharingCompletion?
  ) {
    Weibo.shared._share(
      to: target,
      text: text,
      completion: block
    )
  }

  private func _share(
    to target: SharingTarget,
    text: String,
    completion block: SharingCompletion?
  ) {
    let message = WBMessageObject()
    message.text = text
    send(to: target, message: message, completion: block)
  }

  // MARK: - Share a Single Image

  /// Share an of images.
  ///
  /// - Parameters:
  ///   - target: Sharing target.
  ///   - image: Image data to share, must not exceeds __10M__.
  ///   - title: title.
  ///   - block: completion block.
  public static func share(
    to target: SharingTarget = .timeline,
    image: Data,
    title: String,
    completion block: SharingCompletion?
  ) {
    Weibo.shared._share(
      to: target,
      image: image,
      title: title,
      completion: block
    )
  }

  private func _share(
    to target: SharingTarget,
    image: Data,
    title: String,
    completion block: SharingCompletion?
  ) {
    guard image.count < 10 * 1024 * 1024 else {
      begin(.sharing(completion: block))
      end(with: .sharing(error: .api(reason: "image data size exceeds 10M")))
      return
    }

    let imageObject = WBImageObject()
    imageObject.imageData = image

    let message = WBMessageObject()
    message.text = title
    message.imageObject = imageObject

    send(to: target, message: message, completion: block)
  }

  // MARK: - Share an Group of Images
  
  /// Share an Gorup of Images.
  ///
  /// - Parameters:
  ///   - target: Sharing target.
  ///   - image: Image data to share, must not exceeds __10M__.
  ///   - title: title.
  ///   - block: completion block.
//  public static func share(
//    to target: SharingTarget = .timeline,
//    images: [UIImage],
//    title: String,
//    completion block: SharingCompletion?
//    ) {
//    Weibo.shared._share(
//      to: target,
//      images: images,
//      title: title,
//      completion: block
//    )
//  }
//
//  private func _share(
//    to target: SharingTarget,
//    images: [UIImage],
//    title: String,
//    completion block: SharingCompletion?
//    ) {
//    guard !images.isEmpty else {
//      begin(.sharing(completion: block))
//      end(with: .sharing(error: .api(reason: "image array to share is empty")))
//      return
//    }
//
//    let imageObject = WBImageObject()
//    imageObject.delegate = self
//    imageObject.add(images)
//
//    let message = WBMessageObject()
//    message.text = title
//    message.imageObject = imageObject
//
//    send(to: target, message: message, completion: block)
//  }
  
  
}
