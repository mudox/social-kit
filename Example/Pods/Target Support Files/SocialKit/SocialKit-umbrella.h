#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SSError.h"
#import "SSOResult.h"
#import "Types.h"
#import "QQApiInterface.h"
#import "QQApiInterfaceObject.h"
#import "sdkdef.h"
#import "TencentApiInterface.h"
#import "TencentMessageObject.h"
#import "TencentOAuth.h"
#import "TencentOAuthObject.h"
#import "WechatAuthSDK.h"
#import "WXApi.h"
#import "WXApiObject.h"
#import "WBHttpRequest.h"
#import "WeiboSDK.h"

FOUNDATION_EXPORT double SocialKitVersionNumber;
FOUNDATION_EXPORT const unsigned char SocialKitVersionString[];

