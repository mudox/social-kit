//
// WeChatSDKManager.h
// ChangShou
//
// Created by Mudox on 28/02/2017.
// Copyright © 2017 Mudox. All rights reserved.
//

@import Foundation;

#import "Types.h"
#import "SDKBaseManager.h"

typedef NS_ENUM (NSInteger, WXxSharingTarget) {
  WXxSharingTargetSession = 0,
  WXxSharingTargetTimeline,
  WXxSharingTargetFavorites,

};

@interface WeChatSDKManager : SDKBaseManager <SSSDKManager>

@property (class, strong, readonly, nonatomic) WeChatSDKManager *sharedClient;

#pragma mark SDK initialization

+ (BOOL)initSDKWithAppKey: (NSString *)appKey;

- (BOOL)handleOpenURL: (NSURL *)url;

#pragma mark Share

/**
   All other convenience method just construct specific message & request object accordingly, and then call this method.

   @param request The request object which carry the message object
   @param block   Completion block
 */
- (void)shareTo: (WXxSharingTarget)target
    withRequest: (SendMessageToQQReq *)request
     completion: (SSSharingCompletionBlock)block;

/**
   Convenient interafce, should use this publicly.

   @param target           send to which component (session, timeline, favorites)
   @param title            title
   @param text             message text
   @param url              url link
   @param previewImageData thumbnail
   @param block            completion block
 */
- (void)   shareTo: (WXxSharingTarget)target
         withTitle: (NSString *)title
              text: (NSString *)text
               url: (NSURL *)url
  previewImageData: (NSData *)previewImageData
        completion: (SSSharingCompletionBlock)block;

@end

