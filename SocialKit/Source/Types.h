//
// SSTypes.h
// Pods
//
// Created by Mudox on 13/04/2017.
//
//

#import "SSError.h"
#import "SSOResult.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark Social sharing platforms

typedef NS_ENUM (NSInteger, SSPlatform) {
  SSPlatformQQ     NS_SWIFT_NAME(qq),
  SSPlatformWeChat NS_SWIFT_NAME(wechat),
  SSPlatformWeibo  NS_SWIFT_NAME(weibo),

};

#pragma mark - Social sharing targets

typedef NS_ENUM (NSInteger, SSTarget)
{
  //
  // QQ
  //

  // 发送给 QQ 好友

  SSTargetQQ       NS_SWIFT_NAME(qq)       = 0,
  SSTargetQQFriend NS_SWIFT_NAME(qqFriend) = SSTargetQQ,

  // 发布在 QZone 主界面
  SSTargetQZone NS_SWIFT_NAME(qzone),

  //
  // WeChat
  //

  // 发送给微信好友
  SSTargetWeChat,
  SSTargetWeChatFriend = SSTargetWeChat,

  // 发布在微信朋友圈
  SSTargetWeChatTimeline,

  //
  // Weibo
  //

  // 发布在微博主界面
  SSTargetWeibo,

};

extern NSString *NSStringFromSSTarget(SSTarget target);

#pragma mark - Completion blocks

/**
   Completion block for sharing operation

   @param error   nil if sharing completed successfully, non-nil if failed
 */
typedef void (^SSSharingCompletionBlock) (NSError *_Nullable error);

/**
   Completion block for SSO login

   @param ssoResult object wrap sso fetched informations
   @param error   not nil if sharing failed
 */
typedef void (^SSSSOCompletionBlock) (SSOResult *_Nullable ssoResult, NSError *_Nullable error);

#pragma mark - SSSDKManager protocol

@protocol SSSDKManager <NSObject>

@required

@property (class, readonly, strong, nonatomic) id<SSSDKManager> sharedClient NS_SWIFT_NAME(shared);

- (void)greet;

+ (BOOL)initSDKWithAppKey: (NSString *)appkey;

- (BOOL)handleOpenURL: (NSURL *)url;

@end

NS_ASSUME_NONNULL_END
