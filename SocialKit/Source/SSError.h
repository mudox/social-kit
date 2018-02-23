//
// SSError.h
// Pods
//
// Created by Mudox on 13/04/2017.
//
//

#import <Foundation/Foundation.h>

#import "TencentOAuth.h"
#import "TencentApiInterface.h"
#import "QQApiInterface.h"
#import "WeiboSDK.h"
#import "WXApi.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark Domain & error codes

// domain
#define kSSErrorDomain @"com.mudox.SocialKit.ErrorDomain"

// error code
typedef NS_ENUM (NSInteger, SSErrorCode) {
  // Client app related
  SSErrorClientAppNotInstalled,
  SSErrorClientAppOutdated,
  SSErrorSDKIncompatbile,
  
  // General errors
  SSErrorCanceled,
  SSErrorNetwork,
  
  SSErrorSSO,
  
  SSErrorPayment,

  /**
     SDK internal error that should be contained within the framework during development

     For example:
     - not register app key
     - not specifying sharing to QQ or TIM
     - invalid message type, content, missing required message part ...
     - invalid stage transition
     - unknown SDK error
     - ...
   */
  SSErrorInternal,

  /**
     Other errors
   */
  SSErrorOther,

};

@interface SSError : NSError

#pragma mark - Standard class factory methods

/**
   Each error has 2 class factory methods, the short one invoke the long one with default user info dictionary.
 */

+ (instancetype)errorSSOWithUserInfo: (NSDictionary *)userInfo;
+ (instancetype)errorSSO;

+ (instancetype)errorClientAppNotInstalledWithUserInfo: (NSDictionary *)userInfo;
+ (instancetype)errorClientAppNotInstalled;

+ (instancetype)errorSDKIncompatibleWithUserInfo: (NSDictionary *)userInfo;
+ (instancetype)errorSDKIncompatible;

+ (instancetype)errorCanceledWithUserInfo: (NSDictionary *)userInfo;
+ (instancetype)errorCanceled;

+ (instancetype)errorNetworkWithUserInfo: (NSDictionary *)userInfo;
+ (instancetype)errorNetwork;

+ (instancetype)errorPaymentWithUserInfo: (NSDictionary *)userInfo;
+ (instancetype)errorPayment;

+ (instancetype)errorInternalWithUserInfo: (NSDictionary *)userInfo;

+ (instancetype)errorOtherWithUserInfo: (NSDictionary *)userInfo;


#pragma mark - Translate SDK specific error into SSError

/**
   Parse the response object info, translate SDK specific error into SSError

   @param resultCode The QQApiInterface `QQApiSendResultCode` value that convey the result of operation

   Note: unlike status code from other SDKs, QQApiSendResultCode may be returned synchronously by `QQApiInterface -sendReqXXX` methods

   @return nil if operation succeeded
 */
+ (instancetype _Nullable)errorWithQQApiSendResultCode: (QQApiSendResultCode)resultCode;

/**
   Parse the response object info, translate SDK specific error into SSError

   @param response The WeiboSDK `WBBaseResponse` object that convey the result of operation

   @return nil if operation succeeded
 */
+ (instancetype _Nullable)errorWithWBBaseResponse: (WBBaseResponse *)response;

/**
   Parse the response object info, translate SDK specific error into SSError

   @param response The WXApi `BaseResp` object that convey the result of operation

   @return nil if operation succeeded
 */
+ (instancetype _Nullable)errorWithWXBaseResp: (BaseResp *)response;
@end

NS_ASSUME_NONNULL_END
