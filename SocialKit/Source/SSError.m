//
// SSError.m
// Pods
//
// Created by Mudox on 13/04/2017.
//
//


#import "SSError.h"

@implementation SSError

- (instancetype)initWithDomain: (NSErrorDomain)domain code: (NSInteger)code userInfo: (NSDictionary *)dict
{
  self = [super initWithDomain:domain code:code userInfo:dict];
  if (self == nil)
    return nil;
  return self;
}

#pragma mark - Standard class factory methods

+ (instancetype)errorClientAppNotInstalledWithUserInfo: (NSDictionary *)userInfo
{
  NSInteger errorCode = SSErrorClientAppNotInstalled;
  return [[SSError alloc] initWithDomain:kSSErrorDomain code:errorCode userInfo:userInfo];
}

+ (instancetype)errorClientAppNotInstalled
{
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey: @"Client app is not installed"
  };
  return [SSError errorClientAppNotInstalledWithUserInfo:userInfo];
}

+ (instancetype)errorClientAppOutdatedWithUserInfo: (NSDictionary *)userInfo
{
  NSInteger errorCode = SSErrorClientAppOutdated;
  return [[SSError alloc] initWithDomain:kSSErrorDomain code:errorCode userInfo:userInfo];
}

+ (instancetype)errorClientAppOutdated
{
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey: @"Client app is not installed"
  };
  return [SSError errorClientAppOutdatedWithUserInfo:userInfo];
}

+ (instancetype)errorSDKIncompatibleWithUserInfo: (NSDictionary *)userInfo
{
  NSInteger errorCode = SSErrorSDKIncompatbile;
  return [[SSError alloc] initWithDomain:kSSErrorDomain code:errorCode userInfo:userInfo];
}

+ (instancetype)errorSDKIncompatible
{
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey: @"SDK version is incompatible with the target client app"
  };
  return [SSError errorSDKIncompatibleWithUserInfo:userInfo];
}

+ (instancetype)errorCanceledWithUserInfo: (NSDictionary *)userInfo
{
  NSInteger errorCode = SSErrorCanceled;
  return [[SSError alloc] initWithDomain:kSSErrorDomain code:errorCode userInfo:userInfo];
}

+ (instancetype)errorCanceled
{
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey: @"Operation is canceled"
  };
  return [SSError errorCanceledWithUserInfo:userInfo];
}

+ (instancetype)errorNetworkWithUserInfo: (NSDictionary *)userInfo
{
  NSInteger errorCode = SSErrorNetwork;
  return [[SSError alloc] initWithDomain:kSSErrorDomain code:errorCode userInfo:userInfo];
}

+ (instancetype)errorNetwork
{
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey: @"Network error"
  };
  return [SSError errorNetworkWithUserInfo:userInfo];
}

+ (instancetype)errorSSOWithUserInfo: (NSDictionary *)userInfo
{
  NSInteger errorCode = SSErrorSSO;
  return [[SSError alloc] initWithDomain:kSSErrorDomain code:errorCode userInfo:userInfo];
}

+ (instancetype)errorSSO
{
  NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"SSO error" };
  return [SSError errorSSOWithUserInfo:userInfo];
}

+ (instancetype)errorPaymentWithUserInfo: (NSDictionary *)userInfo
{
  NSInteger errorCode = SSErrorPayment;
  return [[SSError alloc] initWithDomain:kSSErrorDomain code:errorCode userInfo:userInfo];
}

+ (instancetype)errorPayment
{
  NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Payment error" };
  return [SSError errorPaymentWithUserInfo:userInfo];
}
+ (instancetype)errorInternalWithUserInfo: (NSDictionary *)userInfo
{
  NSInteger errorCode = SSErrorInternal;
  return [[SSError alloc] initWithDomain:kSSErrorDomain code:errorCode userInfo:userInfo];
}

+ (instancetype)errorOtherWithUserInfo: (NSDictionary *)userInfo
{
  NSInteger errorCode = SSErrorOther;
  return [[SSError alloc] initWithDomain:kSSErrorDomain code:errorCode userInfo:userInfo];
}

#pragma mark - Translate SDK specific error into SSError

#define RETURN_SSERROR(eName, desc)   \
  NSDictionary *userInfo = @{          \
    NSLocalizedDescriptionKey: @#desc, \
  };                                   \
  return [SSError eName ## WithUserInfo:userInfo];


+ (instancetype _Nullable)errorWithQQApiSendResultCode: (QQApiSendResultCode)resultCode
{

  switch (resultCode)
  {
  case EQQAPISENDSUCESS:
    return nil;

  /******************************************************************************************************
     QQ app related error
     Should capture it within the framework by checking app availability before start any operation
   */

  case EQQAPIQQNOTINSTALLED:
  {
    RETURN_SSERROR(errorClientAppNotInstalled, The QQ app is not installed)
  }

  case EQQAPIQQNOTSUPPORTAPI:
  {
    RETURN_SSERROR(errorSDKIncompatible, The API is not supported by the installed QQ app (maybe the QQ SDK version is too low))
  }

  case EQQAPIVERSIONNEEDUPDATE:
  {
    RETURN_SSERROR(errorClientAppOutdated, The QQ app verions is too low)
  }

  /******************************************************************************************************
     TIM app related error
     Should capture it within the framework by checking app availability before start any operation
   */

  case EQQAPITIMNOTINSTALLED:
  {
    RETURN_SSERROR(errorClientAppNotInstalled, The TIM app is not installed)
  }

  case EQQAPITIMNOTSUPPORTAPI:
  {
    RETURN_SSERROR(errorSDKIncompatible, The API is not supported by the installed TIM app (maybe the QQ SDK version is too low))
  }

  case ETIMAPIVERSIONNEEDUPDATE:
  {
    RETURN_SSERROR(errorSDKIncompatible, The TIM verions is too low)
  }

  /******************************************************************************************************
     SDK using related error
     Often caused by using the SDK interface incorrectly
     This kind of error should NOT be leaked to outside
   */

  case EQQAPIAPPNOTREGISTED:
  {
    RETURN_SSERROR(errorInternal, The app key is not registered)
  }

  case EQQAPISHAREDESTUNKNOWN:
  {
    RETURN_SSERROR(errorInternal, Sharing target(QQApiObject.shareDestType: QQ or TIM) is not specified)
  }

  case EQQAPIMESSAGETYPEINVALID:
  {
    RETURN_SSERROR(errorInternal, Invalid QQ message objet type)
  }

  case EQQAPIMESSAGECONTENTNULL:
  {
    RETURN_SSERROR(errorInternal, The required message part is empty)
  }

  case EQQAPIMESSAGECONTENTINVALID:
  {
    RETURN_SSERROR(errorInternal, The message content is invalid)
  }

  case EQQAPIQZONENOTSUPPORTTEXT:
  {
    RETURN_SSERROR(errorInternal, Text message is not supported by QZone)
  }

  case EQQAPIQZONENOTSUPPORTIMAGE:
  {
    RETURN_SSERROR(errorInternal, Image message is not supported by QZone)
  }

  /******************************************************************************************************
     Other error without knowing the cause
   */

  case EQQAPISENDFAILD:
  {
    RETURN_SSERROR(errorOther, Fail to send message)
  }

  case EQQAPIQQNOTSUPPORTAPI_WITH_ERRORSHOW:
  {
    RETURN_SSERROR(errorInternal, Error code: EQQAPIQQNOTSUPPORTAPI_WITH_ERRORSHOW)
  }

  default:
  {
    NSDictionary *userInfo = @{
      NSLocalizedDescriptionKey: [NSString stringWithFormat:@"unhandled QQApi.QQApiSendResultCode: %ld", (long)resultCode],
    };
    return [SSError errorInternalWithUserInfo:userInfo];
  }

  } // switch (resultCode)

}

+ (instancetype _Nullable)errorWithWBBaseResponse: (WBBaseResponse *)response
{
  switch (response.statusCode)
  {

  case WeiboSDKResponseStatusCodeSuccess:
    return nil;

  case WeiboSDKResponseStatusCodeUserCancel:
  {
    RETURN_SSERROR(errorCanceled, Sharing is canceled)
  }

  case WeiboSDKResponseStatusCodeSentFail:
  {
    RETURN_SSERROR(errorOther, Fail to send message)
  }

  case WeiboSDKResponseStatusCodeAuthDeny:
  {
    RETURN_SSERROR(errorInternal, Not authorized)
  }

  case WeiboSDKResponseStatusCodeUserCancelInstall:
  {
    RETURN_SSERROR(errorCanceled, User canceled Weibo app installation)
  }

  case WeiboSDKResponseStatusCodePayFail:
  {
    RETURN_SSERROR(errorPayment, Weibo Payment failed)
  }

  case WeiboSDKResponseStatusCodeShareInSDKFailed:
  {
    NSDictionary *userInfo = @{
      NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed with SDK error: %@", response.userInfo],
    };

    return [SSError errorInternalWithUserInfo:userInfo];
  }

  case WeiboSDKResponseStatusCodeUnsupport:
  {
    RETURN_SSERROR(errorInternal, Invalid request type)
  }

  case WeiboSDKResponseStatusCodeUnknown:
  {
    RETURN_SSERROR(errorOther, Failed with unknown error)
  }

  default:
  {
    NSDictionary *userInfo = @{
      NSLocalizedDescriptionKey: [NSString stringWithFormat:@"unhandled WeiboSDK.WBBaseResponse.statusCode: %ld", (long)response.statusCode],
    };
    return [SSError errorInternalWithUserInfo:userInfo];
  }

    {
      RETURN_SSERROR(errorInternal, unhandled WeiboSDK WBBaseResponse status code)
    }

  } // switch (statusCode)
}

+ (instancetype _Nullable)errorWithWXBaseResp: (BaseResp *)response
{

  switch (response.errCode)
  {
  case WXSuccess:
    return nil;

  case WXErrCodeCommon:
  {
    RETURN_SSERROR(errorOther, Failed with unknown error)
  }

  case WXErrCodeUserCancel:
  {
    RETURN_SSERROR(errorCanceled, User cancled operation)
  }

  case WXErrCodeSentFail:
  {
    RETURN_SSERROR(errorOther, Sending failed with unknown error)
  }

  case WXErrCodeAuthDeny:
  {
    RETURN_SSERROR(errorSSO, WeChat Authorization denied)
  }

  case WXErrCodeUnsupport:
  {
    RETURN_SSERROR(errorInternal, WeChat client app does not support the SDK)
  }

  default:
  {
    NSDictionary *userInfo = @{
      NSLocalizedDescriptionKey: [NSString stringWithFormat:@"unhandled WXApi.BaseResp.errCode: %ld", (long)response.errCode],
    };
    return [SSError errorInternalWithUserInfo:userInfo];
  }

  } // switch(response.errCode)
}

@end
