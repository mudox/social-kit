@import Foundation;

#import "WeiboSDK.h"

#import "SDKBaseManager.h"

@interface WeiboSDKManager : SDKBaseManager <SSSDKManager>

@property (class, strong, readonly, nonatomic) WeiboSDKManager *sharedClient;

#pragma mark SDK initialization

+ (BOOL)initSDKWithAppKey: (NSString *)appKey;

- (BOOL)handleOpenURL: (NSURL *)url;

#pragma mark SSO

- (void)ssoWithCompletion: (SSSSOCompletionBlock)block;

#pragma mark Share

- (void)shareWithRequest: (WBBaseRequest *)request
              completion: (SSSharingCompletionBlock)block;

- (void)shareWithTitle: (NSString *)title
                  text: (NSString *)text
                   url: (NSURL *)url
      previewImageData: (NSData *)previewImageData
            completion: (SSSharingCompletionBlock)block;


@end
