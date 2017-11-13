//
// SSOResult.h
// Pods
//
// Created by Mudox on 19/08/2017.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TencentOAuth;
@class WBAuthorizeResponse;

@interface SSOResult : NSObject


//
// Credential
//

@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) NSDate   *expirationDate;

@property (strong, nonatomic) NSDate *_Nullable refreshToken;

// QQ SDK specific
@property (strong, nonatomic) NSString *_Nullable openID;

// Weibo SDK specific
@property (strong, nonatomic) NSString *_Nullable userID;

//
// User Info
//

@property (strong, nonatomic) NSString *_Nullable nickname;
@property (strong, nonatomic) NSURL *_Nullable    avatarImageURL;

@property (strong, nonatomic) NSDictionary *_Nullable originalJSONObject;

/**
 *  the designated initializer
 *
 *  @param token access token
 *  @param date  access token expiration date
 *
 *  @return the new SSOResult instance
 */
- (instancetype)initWithAccessToken: (NSString *)token expirationDate: (NSDate *)date;


- (instancetype)initWithTencentOAuth: (TencentOAuth *)oauth userInfo: (NSDictionary *)userInfo;

- (instancetype)initWithWBAuthorizeResponse: (WBAuthorizeResponse *)response userInfo: (NSDictionary *)userInfo;


@end

NS_ASSUME_NONNULL_END
