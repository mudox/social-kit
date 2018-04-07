#import "TencentOAuth.h"
#import "TencentApiInterface.h"
#import "QQApiInterface.h"

#import "SSError.h"
#import "QQSDKManager.h"
#import "SSOResult.h"
#import "Types.h"

@import JacKit;

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif

@interface QQSDKManager () <TencentSessionDelegate, QQApiInterfaceDelegate>

@property (strong, nonatomic) NSString *appKey;

@property (strong, nonatomic) TencentOAuth        *oauth;
@property (strong, nonatomic) NSArray<NSString *> *scope;

// privatize init method
- (instancetype)init;

@end

@implementation QQSDKManager

#pragma mark Only use the singleton

// only for privatize init method
- (instancetype)init
{
  return [super init];
}

- (instancetype)initWithAppKey: (NSString *)appKey
{
  if (nil == (self = [super init]))
    return nil;

  self.oauth = [[TencentOAuth alloc] initWithAppId:appKey andDelegate:self];
  if (self.oauth == nil)
  {
    JackError(@"Registering QQ SDK app key [%@] failed", self.appKey);
    return nil;
  }

  // default permission scopes
  self.scope = @[
    kOPEN_PERMISSION_GET_USER_INFO,
    kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
    kOPEN_PERMISSION_GET_INFO,
    kOPEN_PERMISSION_ADD_SHARE,
  ];

  return self;
}

static QQSDKManager *sharedClient;

+ (QQSDKManager *)sharedClient
{
  return sharedClient;
}

#pragma mark SDK initialization

+ (BOOL)initSDKWithAppKey: (NSString *)appKey
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedClient = [[QQSDKManager alloc] initWithAppKey:appKey];
  });

  [QQSDKManager.sharedClient greet];

  return YES;
}

- (BOOL)handleOpenURL: (NSURL *)url
{
  if (self.stage == SSStageFaillure)
  {
    JackVerbose(@"operation already terminated");
    return NO;
  }

  BOOL handledByTencentOAuth   = [TencentOAuth HandleOpenURL:url];
  BOOL handledByQQApiInterface = [QQApiInterface handleOpenURL:url delegate:self];

  JackDebug(@"[%@] TencentOAuth   [%@] QQApiInterface",
            BOOLSYMBOL(handledByTencentOAuth),
            BOOLSYMBOL(handledByQQApiInterface)
            );

  BOOL handled = handledByTencentOAuth || handledByQQApiInterface;

  if (handled)
  {
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
  }

  return handled;
}

#pragma mark Common utilities

- (void)greet
{
  NSString *lines = [
    @[
      @"QQSDKManager] initialized",
      @">>    SDK version: %@",
      @">>         QQ App: %@",
      @">>        TIM App: %@",
      @">>      QZone App: %@",
      @"\n",
    ] componentsJoinedByString: @"\n"];

  NSString *sdkVersion    = [NSString stringWithFormat:@"%@-%@", [TencentOAuth sdkVersion], [TencentOAuth sdkSubVersion]];
  NSString *isLiteVersion = [TencentOAuth isLiteSDK] ? @"lite version" : @"full version";
  NSString *sdkLine       = [NSString stringWithFormat:@"%@ (%@)", sdkVersion, isLiteVersion];

  NSString *qqLine;
  if ([QQApiInterface isQQInstalled])
  {
    NSString *qqSupportSSO   = BOOLSYMBOL([TencentOAuth iphoneQQSupportSSOLogin]);
    NSString *qqSupportQQAPI = BOOLSYMBOL([QQApiInterface isQQSupportApi]);
    qqLine = [NSString stringWithFormat:@"SSO %@ | QQAPI %@", qqSupportSSO, qqSupportQQAPI];
  }
  else
  {
    qqLine = BOOLSYMBOL(NO);
  }

  NSString *timLine;
  if ([QQApiInterface isTIMInstalled])
  {
    NSString *timSupportSSO   = BOOLSYMBOL([TencentOAuth iphoneTIMSupportSSOLogin]);
    NSString *timSupportQQAPI = BOOLSYMBOL([QQApiInterface isTIMSupportApi]);
    timLine = [NSString stringWithFormat:@"%@ SSO | %@ QQApiInterface", timSupportSSO, timSupportQQAPI];
  }
  else
  {
    timLine = BOOLSYMBOL(NO);
  }

  NSString *qzoneLine;
  if ([QQApiInterface isTIMInstalled])
  {
    NSString *qzoneSupportSSO = [TencentOAuth iphoneQZoneSupportSSOLogin] ? @"supports" : @"NOT supports";
    qzoneLine = [NSString stringWithFormat:@"%@ SSO", qzoneSupportSSO];
  }
  else
  {
    qzoneLine = BOOLSYMBOL(NO);
  }

  DDLogInfo(
    lines,
    sdkLine,
    qqLine,
    timLine,
    qzoneLine
    );
}

/**
 *  Check if QQ or TIM app is installed and is updated.
 *
 *  @note It is only called immediately after the 2 `start[SSO|Sharing]WithCompletion` methods is called.
 *
 *  @param error If found any issue, upon return contins a NSKErrorCanceled describing the issue details
 *
 *  @return A ShareTargetType wrapeed in NSNumber if it found any client app is fully available for sharing,
 *          returns nil is no client app can be used.
 */
- (NSNumber *)shareDestTypeForSharing: (NSError *_Nullable *)error
{

  NSString *qqState = nil;

  if (![QQApiInterface isQQInstalled])
  {
    qqState = @"QQ app is not installed";
  }
  else if (![QQApiInterface isQQSupportApi])
  {
    qqState = @"QQ app is outdated";
  }

  NSString *timState = nil;

  if (![QQApiInterface isTIMInstalled])
  {
    timState = @"TIM app is not installed";
  }
  else if (![QQApiInterface isTIMSupportApi])
  {
    timState = @"TIM app is outdated";
  }

  if (qqState == nil)
  {
    return @(ShareDestTypeQQ);
  }
  else if (timState == nil)
  {
    return @(ShareDestTypeTIM);
  }

  qqState  = (qqState != nil) ? qqState : @"QQ app is avaible";
  timState = (timState != nil) ? timState : @"TIM app is avaible";

  NSString *errorMessage = [NSString stringWithFormat:@"%@, %@", qqState, timState];

  SSError *mskError = [SSError errorCanceledWithUserInfo:@{NSLocalizedDescriptionKey: errorMessage}];
  *error = mskError;
  return nil;
}

- (void)presentClientInstallOrUpdateActionSheet
{
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:@"客户端没有安装，或者版本过低" preferredStyle:UIAlertControllerStyleActionSheet];

  UIAlertAction *qqAction = [UIAlertAction actionWithTitle:@"安装或者更新 QQ" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                               NSURL *appURL = [NSURL URLWithString:[QQApiInterface getQQInstallUrl]];
    if (@available(iOS 10.0, *)) {
      [UIApplication.sharedApplication openURL:appURL options:@{} completionHandler:nil];
    } else {
      // Fallback on earlier versions
    }
                             }];
  UIAlertAction *timAction = [UIAlertAction actionWithTitle:@"安装或者更新 TIM" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                NSURL *appURL = [NSURL URLWithString:[QQApiInterface getTIMInstallUrl]];
    if (@available(iOS 10.0, *)) {
      [UIApplication.sharedApplication openURL:appURL options:@{} completionHandler:nil];
    } else {
      // Fallback on earlier versions
    }
                              }];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];

  [alert addAction:qqAction];
  [alert addAction:timAction];
  [alert addAction:cancelAction];

  [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)handleSendResultCode: (QQApiSendResultCode)code
{
  if (code == EQQAPISENDSUCESS)
  {
    JackDebug(@"request sent out, waiting for response ...");
  }
  else if (code == EQQAPIAPPSHAREASYNC)
  {
    JackDebug(@"sharing operation proceeds asynchronouly");
  }
  else
  {
    [self completeSharingWithError:[SSError errorWithQQApiSendResultCode:code]];
  }
}

#pragma mark SSO

- (void)ssoWithCompletion: (SSSSOCompletionBlock)block
{
  [self startSSOWithCompletion:block];

  BOOL ret = [self.oauth authorize:self.scope];
  if (!ret)
  {
    NSString *message = [NSString stringWithFormat:@"`TencentOAuth -authorize` invocation failed with %@", [TencentOAuth getLastErrorMsg]];
    JackError(@"%@", message);
    NSError *error = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: message }];
    [self completeSSOWithError:error];
  }
}

/**
 *  Capture errors related to client apps before passing to copletion block,
 *  prompt user to install / update app
 *
 *  @param error The error object
 */
- (void)completeSSOWithError: (NSError *)error {
  if ([error isKindOfClass:[SSError class]])
  {
    SSError *mskError = (SSError *)error;
    switch (mskError.code)
    {
    case SSErrorClientAppNotInstalled:
    case SSErrorClientAppOutdated:
      [self presentClientInstallOrUpdateActionSheet];
      break;
    }
  }

  [super completeSSOWithError:error];
}

#pragma mark Share

- (void)sendSharingRequest: (SendMessageToQQReq *)request
                        to: (QQxSharingTarget)target
{
  switch (target)
  {
  case QQxSharingTargetFriend:
    [self handleSendResultCode:[QQApiInterface sendReq:request]];
    break;

  case QQxSharingTargetQZone:
    [self handleSendResultCode:[QQApiInterface SendReqToQZone:request]];
    break;

  case QQxSharingTargetGroup:
    JackWarn(@"sending to QQ group seems to be deprecated (incurs API not suppported error)"
             @", instead send to QQ friend which will prompt you to select target including"
             @"QQ group as well as QQ friends");
    [self handleSendResultCode:[QQApiInterface SendReqToQQGroupTribe:request]];
    break;
  }
}

- (void)shareTo: (QQxSharingTarget)target
    withRequest: (SendMessageToQQReq *)request
     completion: (SSSharingCompletionBlock)block
{
  [self startSharingWithCompletion:block];
  [self sendSharingRequest:request to:target];
}

- (void)   shareTo: (QQxSharingTarget)target
         withTitle: (NSString *)title text: (NSString *)text
               url: (NSURL *)url
  previewImageData: (NSData *)previewImageData
        completion: (SSSharingCompletionBlock)block
{
  [self startSharingWithCompletion:block];

  //
  // choose sharing destination client app
  // prompt user to install / update client apps if failed
  //

  NSError  *error;
  NSNumber *destTypeOrNil = [self shareDestTypeForSharing:&error];
  if (error != nil)
  {
    [self presentClientInstallOrUpdateActionSheet];
    [self completeSSOWithError:self.lastError];
    return;
  }

  //
  // construct sharing request object
  //

  QQApiNewsObject *newsObject = [QQApiNewsObject objectWithURL:url title:title description:text previewImageData:previewImageData];
  newsObject.shareDestType = (int)destTypeOrNil.integerValue;

  SendMessageToQQReq *request = [SendMessageToQQReq reqWithContent:newsObject];

  [self sendSharingRequest:request to:target];
}

/**
 *  Capture errors related to client apps before passing to super method,
 *  prompt user to install / update app
 *
 *  @param error The error object
 */
- (void)completeSharingWithError: (NSError *)error {
  if ([error isKindOfClass:[SSError class]])
  {
    SSError *mskError = (SSError *)error;
    switch (mskError.code)
    {
    case SSErrorClientAppNotInstalled:
    case SSErrorClientAppOutdated:
      [self presentClientInstallOrUpdateActionSheet];
      break;
    }
  }

  [super completeSharingWithError:error];
}

#pragma mark - TencentLoginDelegate

/**
 * 登录成功后的回调
 */
- (void)tencentDidLogin
{
  if (self.stage == SSStageFaillure)
  {
    JackVerbose(@"operation already terminated");
    return;
  }

  //
  // get user info
  //

  BOOL ret = [self.oauth getUserInfo];
  if (!ret)
  {
    NSString *message = [NSString stringWithFormat:
                         @"`TencentOAuth -getUserInfo` invocation failed with error message: %@",
                         [TencentOAuth getLastErrorMsg]
                        ];
    JackError(@"%@", message);
    NSError *error = [SSError errorInternalWithUserInfo:@{
                        NSLocalizedDescriptionKey: message,
                      }];
    [self completeSSOWithError:error];
  }
}

/**
 * 登录失败后的回调
 *
 * @param cancelled 代表用户是否主动退出登录
 */
- (void)tencentDidNotLogin: (BOOL)cancelled
{
  if (self.stage == SSStageFaillure)
  {
    JackVerbose(@"operation already terminated");
    return;
  }

  if (cancelled)
  {
    // SSO is canceled
    SSError *error = [SSError errorCanceled];
    [self completeSSOWithError:error];
    JackWarn(@"SSO is canceled");
  }
  else       // unknown error
  {
    NSString *errorMessage = [TencentOAuth getLastErrorMsg];
    SSError  *error        = [SSError errorOtherWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage } ];
    [self completeSSOWithError:error];
    JackError(@"SSO failed with error: %@", errorMessage);
  }
}

/**
 * 登录时网络有问题的回调
 */
- (void)tencentDidNotNetWork
{
  if (self.stage == SSStageFaillure)
  {
    JackVerbose(@"operation already terminated");
    return;
  }

  NSString *errorMessage = [TencentOAuth getLastErrorMsg];
  SSError  *error        = [SSError errorNetworkWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage } ];
  [self completeSSOWithError:error];
  JackError(@"SSO failed with network error: %@", errorMessage);
}

/**
 * 登录时权限信息的获得
 */
- (NSArray *)getAuthorizedPermissions: (NSArray *)permissions withExtraParams: (NSDictionary *)extraParams
{
  JackVerbose("permisssions:\n%@extra params:\n%@", permissions, extraParams);
  return nil;
}

/**
 * unionID获得
 */
- (void)didGetUnionID
{
  JackVerbose("▣");
}


/**
 * TencentSessionDelegate iOS Open SDK 1.3 API回调协议
 *
 * 第三方应用需要实现每条需要调用的API的回调协议
 */
#pragma mark TencentSessionDelegate
/**
 * 退出登录的回调
 */
- (void)tencentDidLogout
{
  JackVerbose("▣");
}

/**
 * 因用户未授予相应权限而需要执行增量授权。在用户调用某个api接口时，如果服务器返回操作未被授权，
 * 则触发该回调协议接口，由第三方决定是否跳转到增量授权页面，让用户重新授权。
 *
 * @param tencentOAuth 登录授权对象。
 * @param permissions 需增量授权的权限列表。
 * @return 是否仍然回调返回原始的api请求结果。
 * @note 不实现该协议接口则默认为不开启增量授权流程。若需要增量授权请调用 [TencentOAuth incrAuthWithPermissions:]
         注意：增量授权时用户可能会修改登录的帐号
 */
- (BOOL)tencentNeedPerformIncrAuth: (TencentOAuth *)tencentOAuth withPermissions: (NSArray *)permissions
{
  JackVerbose("▣");
  return YES;
}

/**
 * [该逻辑未实现]因token失效而需要执行重新登录授权。在用户调用某个api接口时，如果服务器返回token失效，则触发该回调协议接口，由第三方决定是否跳转到登录授权页面，让用户重新授权。
 *
 * @param tencentOAuth 登录授权对象。
 * @return 是否仍然回调返回原始的api请求结果。
 * @note 不实现该协议接口则默认为不开启重新登录授权流程。若需要重新登录授权请调用 [TencentOAuth reauthorizeWithPermissions:]
 *       注意：重新登录授权时用户可能会修改登录的帐号
 */
- (BOOL)tencentNeedPerformReAuth: (TencentOAuth *)tencentOAuth
{
  JackVerbose("▣");
  return YES;
}

/**
 * 用户通过增量授权流程重新授权登录，token及有效期限等信息已被更新。
 *
 * @param tencentOAuth token及有效期限等信息更新后的授权实例对象
 * @note 第三方应用需更新已保存的token及有效期限等信息。
 */
- (void)tencentDidUpdate: (TencentOAuth *)tencentOAuth
{
  JackVerbose("▣");
}

/**
 * 用户增量授权过程中因取消或网络问题导致授权失败
 *
 * @param reason 授权失败原因，具体失败原因参见sdkdef.h文件中 UpdateFailType
 */
- (void)tencentFailedUpdate: (UpdateFailType)reason
{
  JackVerbose("▣");

  NSString *errorDescription;
  switch (reason)
  {
  case kUpdateFailNetwork:
    errorDescription = @"network error";
    break;

  case kUpdateFailUserCancel:
    errorDescription = @"canceled by user";
    break;

  default:
    errorDescription = @"unknown error";
  }

  JackDebug(@"reason: %@",             errorDescription);
  JackDebug(@"last error message: %@", [TencentOAuth getLastErrorMsg]);
}
/**
 * 获取用户个人信息回调
 *
 * @param response API返回结果，具体定义参见sdkdef.h文件中\ref APIResponse
 * @remarks 正确返回示例: \snippet example/getUserInfoResponse.exp success
 *          错误返回示例: \snippet example/getUserInfoResponse.exp fail
 */
- (void)getUserInfoResponse: (APIResponse*)response
{
  switch (self.stage) {
    case SSStageFaillure:
      JackVerbose(@"operation already terminated");
      return;
    
    case SSSSOStageDidLaunchOperation:
    case SSSSOStageDidHandleOpenURL:
    {
      if (response.errorMsg != nil)
      {
        JackError(@"failed with error message: %@", response.errorMsg);
        SSError *error = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: response.errorMsg }];
        [self completeSSOWithError:error];
      }
      
      JackInfo(@"user info:\n%@", response.jsonResponse);
      SSOResult *result = [[SSOResult alloc] initWithTencentOAuth:self.oauth userInfo:response.jsonResponse];
      if (result == nil)
      {
        SSError *error = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: @"failed to initialize SSOResult instance" }];
        [self completeSSOWithError:error];
      }
      else
      {
        [self completeSSOWithSSOResult:result];
      }
    }
      break;
      
    default:
    {
      NSString *errorMessage = [NSString stringWithFormat:@"invalid pre-stage (%@), expecting"
                                @"\n>> - `SSSSODidLaunchOperation`"
                                @"\n>> - `SSSSODidHandleOpenURL`",
                                NSStringFromSSStage(self.stage)];
      SSError *error = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage }];
      [self completeSSOWithError:error];
    }
  }
}

//
// ---------- need to add comments from definition source file -------------
//

- (void)addShareResponse: (APIResponse *)response
{
  JackDebug(@"did share to QZone");
}

- (void)addOneBlogResponse: (APIResponse *)response
{
  JackDebug(@"did add diary into QZone");
}

- (void)addTopicResponse: (APIResponse *)response
{
  JackDebug(@"did add talking into QZone");
}

- (void)setUserHeadpicResponse: (APIResponse *)response
{
  JackDebug(@"did update user avatar");
}

- (void)uploadPicResponse: (APIResponse *)response
{
  JackDebug(@"did add photo into QZone photo album");
}

- (void)getListAlbumResponse: (APIResponse *)response
{
  JackDebug(@"did receive QQ photo album list");
}

- (void)getListPhotoResponse: (APIResponse *)response
{
  JackDebug(@"did receive QZone photo album list");
}

- (void)checkPageFansResponse: (APIResponse *)response
{
  JackDebug(@"did receive fans info from QZone");
}

- (void)addAlbumResponse: (APIResponse *)response
{
  JackDebug(@"did add album into QQ photo album");
}

- (void)getVipInfoResponse: (APIResponse *)response
{
  JackDebug(@"did receive QQ VIP user info");
}

- (void)getVipRichInfoResponse: (APIResponse *)response
{
  JackDebug(@"did receive QQ VIP user defailed info");
}

#pragma mark Other

// union response receving interface for SendStory, AppInvitation, AppChallenge, AppGiftRequest
- (void)responseDidReceived: (APIResponse *)response forMessage: (NSString *)message
{
  JackDebug(@"did receive response for message: %@", message);
}

// upload progress reporting
- (void)       tencentOAuth: (TencentOAuth *)tencentOAuth
            didSendBodyData: (NSInteger)bytesWritten
          totalBytesWritten: (NSInteger)totalBytesWritten
  totalBytesExpectedToWrite: (NSInteger)totalBytesExpectedToWrite
                   userData: (id)userData {}

- (void)tencentOAuth: (TencentOAuth *)tencentOAuth doCloseViewController: (UIViewController *)viewController
{
  JackDebug(@"");
}

#pragma mark - TencentWebViewDelegate

//- (BOOL)tencentWebViewShouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
//{
//  JackDebug(@"returning YES");
//  return YES;
//}
//
//- (NSUInteger)tencentWebViewSupportedInterfaceOrientationsWithWebkit
//{
//  JackDebug(@"returning portrait");
//  return UIInterfaceOrientationMaskPortrait;
//}
//
//- (BOOL)tencentWebViewShouldAutorotateWithWebkit
//{
//  JackDebug(@"returning YES");
//  return YES;
//}

#pragma mark - QQApiInterfaceDelegate

- (void)onReq: (QQBaseReq *)req
{
  JackDebug(@"%@", req);
}

- (void)onResp: (QQBaseResp *)resp
{
  if (self.stage == SSStageFaillure)
  {
    JackVerbose(@"operation already terminated");
    return;
  }

  switch (resp.type)
  {

  case ESENDMESSAGETOQQRESPTYPE:
  {
    SendMessageToQQResp* sendResp = (SendMessageToQQResp*)resp;
    if (sendResp.errorDescription == nil)
    {
      [self completeSharingWithError:nil];
    }
    else
    {
      SSError *error = [SSError errorOtherWithUserInfo:@{NSLocalizedDescriptionKey: sendResp.errorDescription}];
      [self completeSharingWithError:error];
    }
    break;
  }

  default:
    JackWarn(@"handling logic of this kind of response is not implemented\n%@", resp);
  }
}

- (void)isOnlineResponse: (NSDictionary *)info
{
  JackDebug(@"%@", info);
}

@end
