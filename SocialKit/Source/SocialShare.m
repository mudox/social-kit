//
// SocialShare.m
// Pods
//
// Created by Mudox on 11/04/2017.
//
//

#import "SocialShare.h"

#import "QQ/QQSDKManager.h"
#import "WeChat/WeChatSDKManager.h"
#import "Weibo/WeiboSDKManager.h"

@import Jack;

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif

typedef NS_OPTIONS (NSUInteger, SSSDKFlag) {
  SSSDKNone     = 0,
  SSSDKQQ       = 1 << 0,
    SSSDKWeChat = 1 << 1,
    SSSDKWeibo  = 1 << 2,

};

SSSDKFlag activeSDKSet = 0;

@implementation SocialShare

#pragma mark Prepare SDKs

+ (BOOL)initQQSDKWithAppKey: (NSString *)appKey
{
  activeSDKSet |= SSSDKQQ;
  return [QQSDKManager initSDKWithAppKey:appKey];
}

+ (BOOL)initWeChatSDKWithAppKey: (NSString *)appKey
{
  activeSDKSet |= SSSDKWeChat;
  return [WeChatSDKManager initSDKWithAppKey:appKey];
}

+ (BOOL)initWeiboSDKWithAppKey: (NSString *)appKey
{
  activeSDKSet |= SSSDKWeibo;
  return [WeiboSDKManager initSDKWithAppKey:appKey];
}

+ (BOOL)handleOpenURL: (NSURL *)url
{
  JackDebug(@"%@", url);

  if (activeSDKSet & SSSDKQQ)
  {
    BOOL handled = [QQSDKManager.sharedClient handleOpenURL:url];
    if (handled)
    {
      JackDebug(@"handled by QQSDK");
      return YES;
    }
  }

  if (activeSDKSet & SSSDKWeChat)
  {
    BOOL handled = [WeChatSDKManager.sharedClient handleOpenURL:url];
    if (handled)
    {
      JackDebug(@"handled by WeChatSDK");
      return YES;
    }
  }

  if (activeSDKSet & SSSDKWeibo)
  {
    BOOL handled = [WeiboSDKManager.sharedClient handleOpenURL:url];
    if (handled)
    {
      JackDebug(@"handled by WeiboSDK");
      return YES;
    }
  }

  JackDebug(@"unhandled URL: %@", url);
  return NO;
}

#pragma mark SSO


+ (void)ssoTo: (SSPlatform)platform completion: (SSSSOCompletionBlock)block {
  switch (platform)
  {
  case SSPlatformQQ:
    [QQSDKManager.sharedClient ssoWithCompletion:block];
    break;

  case SSPlatformWeibo:
    [WeiboSDKManager.sharedClient ssoWithCompletion:block];
    break;
      
    default:
      JackError(@"Not implemented yet");
  }
}


#pragma mark Share

+ (void)        to: (SSTarget)target
         withTitle: (NSString *)title
              text: (NSString *)text
               url: (NSURL *)url
  previewImageData: (NSData *)previewImageData
        completion: (SSSharingCompletionBlock)block
{
  switch (target)
  {

  case SSTargetQQ:
    [QQSDKManager.sharedClient shareTo:QQxSharingTargetFriend withTitle:title text:text url:url previewImageData:previewImageData completion:block];
    break;

  case SSTargetQZone:
    [QQSDKManager.sharedClient shareTo:QQxSharingTargetQZone withTitle:title text:text url:url previewImageData:previewImageData completion:block];
    break;

  case SSTargetWeibo:
    [WeiboSDKManager.sharedClient shareWithTitle:title text:text url:url previewImageData:previewImageData completion:block];
    break;

  case SSTargetWeChat:
    [WeChatSDKManager.sharedClient shareTo:WXxSharingTargetSession withTitle:title text:text url:url previewImageData:previewImageData completion:block];
    break;

  case SSTargetWeChatTimeline:
    [WeChatSDKManager.sharedClient shareTo:WXxSharingTargetTimeline withTitle:title text:text url:url previewImageData:previewImageData completion:block];
    break;

  default:
    JackWarn(@"sharing target %@ is not implemented yet", NSStringFromSSTarget(target));
  }

}

@end
