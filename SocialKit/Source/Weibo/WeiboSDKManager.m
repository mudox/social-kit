//
// WeiboSDKManager.m
// ChangShou
//
// Created by Mudox on 28/02/2017.
// Copyright © 2017 Mudox. All rights reserved.
//

#import "Types.h"
#import "WeiboSDKManager.h"
#import "SSOResult.h"

#import "WeiboSDK.h"

@import JacKit;

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif

#define WeiboRedirectURI @"https://api.weibo.com/oauth2/default.html"

@interface WeiboSDKManager () <WeiboSDKDelegate>

/**
 *  use this to initiate a authorization process
 */
@property (strong, readonly, nonatomic) WBAuthorizeRequest *authorizeRequest;

/**
 *  keep authorized information, e.g. user ID, access token
 */
@property (strong, nonatomic) WBAuthorizeResponse *authorizeResponse;

// privatize init method
- (instancetype)init;

@end

@implementation WeiboSDKManager

#pragma mark Only use the singleton

- (instancetype)init
{
  NSAssert(NO, @"call initWithAppKey: instead");
  return [super init];
}

- (instancetype)initWithAppKey: (NSString *)appKey
{
  if (nil == (self = [super init]))
    return nil;

#ifdef DEBUG
  [WeiboSDK enableDebugMode:YES];
#endif

  BOOL success = [WeiboSDK registerApp:appKey];
  if (!success)
  {
    JackError(@"Registering app key [%@] failed:", appKey);
    return nil;
  }

  return self;
}

static WeiboSDKManager *sharedClient;

+ (WeiboSDKManager *)sharedClient
{
  return sharedClient;
}

#pragma mark SDK initialization

+ (BOOL)initSDKWithAppKey: (NSString *)appKey
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedClient = [[WeiboSDKManager alloc] initWithAppKey:appKey];
  });

  [WeiboSDKManager.sharedClient greet];

  return sharedClient != nil;
}

- (BOOL)handleOpenURL: (NSURL *)url
{
  if (self.stage == SSStageFaillure)
  {
    JackVerbose(@"operation already terminated");
    return NO;
  }

  BOOL handled = [WeiboSDK handleOpenURL:url delegate:self];
  JackDebug(@"[%@] WeiboSDK", BOOLSYMBOL(handled));

  if (!handled)
  {
    return handled;
  }

  switch (self.stage)
  {
    case SSStageFaillure:
    case SSStageSuccess:
      JackVerbose(@"operation already terminated");
      break;
      
    case SSSSOStageDidLaunchOperation:
      JackDebug(@"SSO'ed in SDK built-in web view");
      break;
      
    case SSSSOStageDidEnterInactiveFromBackground:
      self.stage = SSSSOStageDidHandleOpenURL;
      break;
      
    case SSSharingStageDidLaunchOperation:
      JackDebug(@"shared in SDK built-in web view");
      break;
      
    case SSSharingStageDidEnterInactiveFromBackground:
      self.stage = SSSharingStageDidHandleOpenURL;
      break;

    default:
    {
      NSString *errorMessage = [NSString stringWithFormat:
                                @"invalid pre-stage `%@`, expecting:"
                                @"\n>> - `SS[SSO|Sharing]DidEnterInactiveFromBackground`"
                                @"\n>> - `SSStage[Failure|Success]`",
                                NSStringFromSSStage(self.stage)
                                ];
      SSError *error = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage }];
      JackError(@"%@", errorMessage);
      [self completeSSOWithError:error];
    }
  }
  return handled;
}

#pragma mark Common utilities

- (void)greet
{
  NSString *lines = [
    @[
      @"WeiboSDKManager] SDK initialized",
      @">>    SDK version: %@",
      @">>      Weibo App: %@",
      @"\n",
    ] componentsJoinedByString: @"\n"];
  NSString *appLine;
  if ([WeiboSDK isWeiboAppInstalled])
  {
    NSString *supportSSO     = BOOLSYMBOL([WeiboSDK isCanSSOInWeiboApp]);
    NSString *supportSharing = BOOLSYMBOL([WeiboSDK isCanShareInWeiboAPP]);
    appLine = [NSString stringWithFormat:@"installed (SSO %@ | Sharing %@)", supportSSO, supportSharing];
  }
  else
  {
    appLine = BOOLSYMBOL(NO);
  }

  DDLogInfo(lines, [WeiboSDK getSDKVersion], appLine);
}

#pragma mark SSO

- (WBAuthorizeRequest *)authorizationRequest
{
  WBAuthorizeRequest *request = [WBAuthorizeRequest request];
  request.redirectURI                                 = WeiboRedirectURI;
  request.scope                                       = @"all";
  request.shouldShowWebViewForAuthIfCannotSSO         = YES;
  request.shouldOpenWeiboAppInstallPageIfNotInstalled = YES;

  return request;
}

- (void)ssoWithCompletion: (SSSSOCompletionBlock)block
{
  [self startSSOWithCompletion:block];
  [WeiboSDK sendRequest:self.authorizationRequest];
}

/**
 *  Weibo SDK does not provide method to fetch user info, we can rely on only open API.
 *
 *  @param block Completion block.
 */
- (void)getUserInfoWithCompletion: (void (^)(NSDictionary *resultJSON, NSError *error))block
{
  NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession             * session       = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];

  NSString *baseURLString = @"https://api.weibo.com/2/users/show.json";
  NSString *queryString   = [NSString stringWithFormat:@"access_token=%@&uid=%@",
                             [self.authorizeResponse.accessToken stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],
                             [self.authorizeResponse.userID stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]
                            ];
  NSURL        *url     = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", baseURLString, queryString]];
  NSURLRequest* request = [NSURLRequest requestWithURL:url];

  /* Start a new Task */
  NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                {
                                  if (error != nil)
                                  {
                                    block(nil, error);
                                    return;
                                  }

                                  NSError *jsonError;
                                  NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                  if (jsonError != nil)
                                  {
                                    block(nil, error);
                                    return;
                                  }

                                  block(json, nil);
                                }];
  [task resume];
  [session finishTasksAndInvalidate];
}
#pragma mark Share

- (void)sendRequest: (WBBaseRequest *)request {
  [WeiboSDK sendRequest:request];
}

- (void)shareWithRequest: (WBBaseRequest *)request completion: (SSSharingCompletionBlock)block
{
  [self startSharingWithCompletion:block];
  [self sendRequest:request];
}

- (void)shareWithTitle: (NSString *)title
                  text: (NSString *)text
                   url: (NSURL *)url
      previewImageData: (NSData *)previewImageData
            completion: (SSSharingCompletionBlock)block
{
  [self startSharingWithCompletion:block];

  //
  // construct sharing request object
  //

  WBMessageObject *message = [WBMessageObject message];
  message.text = text;

  WBWebpageObject *webpage = [WBWebpageObject object];
  webpage.objectID      = [[NSProcessInfo processInfo] globallyUniqueString];
  webpage.webpageUrl    = url.absoluteString;
  webpage.title         = title;
  webpage.description   = text;
  webpage.thumbnailData = previewImageData;

  message.mediaObject = webpage;

  WBSendMessageToWeiboRequest * request = [WBSendMessageToWeiboRequest requestWithMessage:message authInfo:self.authorizeRequest access_token:nil];
  request.shouldOpenWeiboAppInstallPageIfNotInstalled = YES;

  [self sendRequest:request];
}

#pragma - mark WeiboSDKDelegate

- (void)didReceiveWeiboRequest: (WBBaseRequest *)request
{
  JackDebug(@"%@", request);
}

- (void)didReceiveWeiboResponse: (WBBaseResponse *)response
{
  if (self.stage == SSStageFaillure)
  {
    JackVerbose(@"operation already terminated");
    return;
  }

  if ([self handleSharingResponse:response])
  {
    return;
  }

  if ([self handleSSOResponse:response])
  {
    return;
  }

  JackWarn(@"response is not handled: %@", response);
}

- (BOOL)handleSharingResponse: (WBBaseResponse *)response
{
  if (![response isKindOfClass:WBSendMessageToWeiboResponse.class])
  {
    return NO;
  }

  [self completeSharingWithError:[SSError errorWithWBBaseResponse:response]];
  return YES;
}

- (BOOL)handleSSOResponse: (WBBaseResponse *)response
{
  if (![response isKindOfClass:WBAuthorizeResponse.class])
  {
    return NO;
  }

  SSError *error = [SSError errorWithWBBaseResponse:response];
  if (error != nil)
  {
    [self completeSSOWithError:error];
    return YES;
  }

  self.authorizeResponse = (WBAuthorizeResponse *)response;

  [self getUserInfoWithCompletion:^(NSDictionary *resultJSON, NSError *error) {
     if (error != nil)
     {
       [self completeSSOWithError:error];
       return;
     }

     SSOResult *result = [[SSOResult alloc] initWithWBAuthorizeResponse:self.authorizeResponse userInfo:resultJSON];
     if (result == nil)
     {
       SSError *error = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: @"failed to initialize SSOResult instance" }];
       [self completeSSOWithError:error];
     }
     else
     {
       [self completeSSOWithSSOResult:result];
     }
   }];

  return YES;
}

@end
