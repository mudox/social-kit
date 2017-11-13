//
// SocialShare.h
// Pods
//
// Created by Mudox on 11/04/2017.
//
//

@import Foundation;

#import "Types.h"

NS_ASSUME_NONNULL_BEGIN

@interface SocialShare : NSObject

#pragma mark Service initialization

+ (BOOL)initQQSDKWithAppKey: (NSString *)appKey;

+ (BOOL)initWeChatSDKWithAppKey: (NSString *)appKey;

+ (BOOL)initWeiboSDKWithAppKey: (NSString *)appKey;

+ (BOOL)handleOpenURL: (NSURL *)url;

#pragma mark SSO

+ (void)ssoTo: (SSPlatform)platform completion: (SSSSOCompletionBlock)block NS_REFINED_FOR_SWIFT;

#pragma mark Share

+ (void)        to: (SSTarget)target
         withTitle: (NSString *)title
              text: (NSString *)text
               url: (NSURL *)url
  previewImageData: (NSData *)previewImageData
        completion: (SSSharingCompletionBlock)block NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
