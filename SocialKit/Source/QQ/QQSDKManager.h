//
// QQSDKManager.h
//
// Created by Mudox on 28/02/2017.
// Copyright © 2017 Mudox. All rights reserved.
//

@import Foundation;

#import "SDKBaseManager.h"

@class SendMessageToQQReq;

typedef NS_ENUM (NSInteger, QQxSharingTarget) {
  // QQ 好友对话
  QQxSharingTargetFriend = 0,

  // QQ 空间
  QQxSharingTargetQZone,

  // QQ 群
  // 好像这个已经不支持了，使用上面的发送到好友对话，会在 QQ 显示选择对象界面，里面包括了好友和群
  QQxSharingTargetGroup,

};

@interface QQSDKManager : SDKBaseManager <SSSDKManager>

@property (class, strong, readonly, nonatomic) QQSDKManager *sharedClient;

#pragma mark SDK initialization

+ (BOOL)initSDKWithAppKey: (NSString *)appKey;

- (BOOL)handleOpenURL: (NSURL *)url;

#pragma mark SSO

- (void)ssoWithCompletion: (SSSSOCompletionBlock)block;

#pragma mark Share

/**
 *  Give user the flexibility to construct the underlying request & message objects
 *
 *  @note For most of the time, user should use the more convenient method
 *  `-shareTo:withTile:text:url:previewImageData:completion:` method
 *
 *  @param target  Sharing target [friend | qzone | group]
 *  @param request The custom request object
 *  @param block   Completion block
 */
- (void)shareTo: (QQxSharingTarget)target
    withRequest: (SendMessageToQQReq *)request
     completion: (SSSharingCompletionBlock)block;

- (void)   shareTo: (QQxSharingTarget)target
         withTitle: (NSString *)title
              text: (NSString *)text
               url: (NSURL *)url
  previewImageData: (NSData *)previewImageData
        completion: (SSSharingCompletionBlock)block;

@end

