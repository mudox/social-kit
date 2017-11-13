//
// SSOResult.m
// Pods
//
// Created by Mudox on 19/08/2017.
//
//

#import "SSOResult.h"
#import "TencentOAuth.h"
#import "WeiboSDK.h"

@import Jack;

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif

@implementation SSOResult

- (instancetype)initWithAccessToken: (NSString *)token expirationDate: (NSDate *)date {
  if (nil == (self = [super init]))
  {
    return nil;
  }

  if (token == nil || date == nil)
  {
    return nil;
  }

  _accessToken    = token;
  _expirationDate = date;

  return self;
}

- (instancetype)initWithTencentOAuth: (TencentOAuth *)oauth userInfo: (NSDictionary *)userInfo {
  if (nil == (self = [self initWithAccessToken:oauth.accessToken expirationDate:oauth.expirationDate ]))
  {
    return nil;
  }

  if (oauth.openId == nil)
  {
    JackError(@"oauth.openID should not be nil");
    return nil;
  }

  _openID             = oauth.openId;
  _nickname           = userInfo[@"nickname"];
  _avatarImageURL     = [NSURL URLWithString:userInfo[@"figureurl_qq_2"]];
  _originalJSONObject = userInfo;

  return self;
}

- (instancetype)initWithWBAuthorizeResponse: (WBAuthorizeResponse *)response userInfo: (NSDictionary *)userInfo {
  if (nil == (self = [self initWithAccessToken:response.accessToken expirationDate:response.expirationDate ]))
  {
    return nil;
  }

  if (response.userID == nil)
  {
    JackError(@"authorizeResponse.userID should not be nil");
    return nil;
  }

  _userID = response.userID;

  NSString *screenName = userInfo[@"screen_name"];
  NSString *name       = userInfo[@"name"];

  if (screenName != nil && screenName.length > 0)
  {
    _nickname = screenName;
  }
  else if (name != nil && name.length > 0)
  {
    _nickname = name;
  }
  else
  {
    _nickname = nil;
  }

  _avatarImageURL     = [NSURL URLWithString:userInfo[@"avatar_hd"]];
  _originalJSONObject = userInfo;

  return self;
}

- (NSString *)description
{
  NSString *lines =
    [@[ @"SSOResult",
        @">> --- SSO Credential",
        [NSString stringWithFormat:@">>    Access Token: %@", self.accessToken],
        [NSString stringWithFormat:@">>         Open ID: %@", self.openID],
        [NSString stringWithFormat:@">>         User ID: %@", self.userID],
        [NSString stringWithFormat:@">> Expiration Date: %@", self.expirationDate],
        @">> --- User Info",
        [NSString stringWithFormat:@">>        Nickname: %@", self.nickname],
        [NSString stringWithFormat:@">>      Avatar URL: %@", self.avatarImageURL],
     ] componentsJoinedByString: @"\n"];
  return lines;
}

@end
