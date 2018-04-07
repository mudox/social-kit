#import "WXApi.h"
#import "WXApiObject.h"

#import "SSError.h"
#import "WeChatSDKManager.h"


@import JacKit;

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif

@interface WeChatSDKManager () <WXApiDelegate>

// privatize init method
- (instancetype)init;

@end

@implementation WeChatSDKManager

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

  BOOL ret = [WXApi registerApp:appKey enableMTA:NO];
  if (!ret)
  {
    JackError(@"Registering WeChat App ID [%@] failed:", appKey);
    return nil;
  }

  UInt64 typeFlag =
    MMAPP_SUPPORT_TEXT     |
    MMAPP_SUPPORT_PICTURE  |
    MMAPP_SUPPORT_LOCATION |
    MMAPP_SUPPORT_VIDEO    |
    MMAPP_SUPPORT_AUDIO    |
    MMAPP_SUPPORT_WEBPAGE  |
    MMAPP_SUPPORT_DOC      |
    MMAPP_SUPPORT_DOCX     |
    MMAPP_SUPPORT_PPT      |
    MMAPP_SUPPORT_PPTX     |
    MMAPP_SUPPORT_XLS      |
    MMAPP_SUPPORT_XLSX     |
    MMAPP_SUPPORT_PDF;

  [WXApi registerAppSupportContentFlag:typeFlag];
  return self;
}

static WeChatSDKManager *sharedClient;

+ (WeChatSDKManager *)sharedClient
{
  return sharedClient;
}

#pragma mark SDK initialization

+ (BOOL)initSDKWithAppKey: (NSString *)appKey
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedClient = [[WeChatSDKManager alloc] initWithAppKey:appKey];
  });

  [sharedClient greet];
  return sharedClient != nil;
}

- (BOOL)handleOpenURL: (NSURL *)url
{
  if (self.stage == SSStageFaillure)
  {
    JackVerbose(@"operation already terminated");
    return NO;
  }
  
  BOOL handled = [WXApi handleOpenURL:url delegate:self];
  
  if (!handled) {
    return handled;
  }
  
  switch (self.stage)
  {
    case SSSSOStageDidEnterInactiveFromBackground:
      self.stage = SSSSOStageDidHandleOpenURL;
      break;
      
    case SSSharingStageDidEnterInactiveFromBackground:
      self.stage = SSSharingStageDidHandleOpenURL;
      break;
      
    case SSStageFaillure:
    case SSStageSuccess:
      JackVerbose(@"operation already terminated");
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
      @"WeChatSDKManager] initialized",
      @">>    SDK version: %@",
      @">>     WeChat App: %@",
      @"\n",
    ] componentsJoinedByString: @"\n"];

  NSString *version = [NSString stringWithFormat:@"%@", [WXApi getApiVersion]];

  NSString *appLine;
  if ([WXApi isWXAppInstalled])
  {
    NSString *appSupportAPI = BOOLSYMBOL([WXApi isWXAppSupportApi]);
    appLine = [NSString stringWithFormat:@"installed, support API %@", appSupportAPI];
  }
  else
  {
    appLine = @"Not installed";
  }

  DDLogInfo(lines, version, appLine);
}

#pragma mark Share

-(void)sendRequest: (SendMessageToWXReq *)request to: (WXxSharingTarget)target {
  switch(target)
  {
  case WXxSharingTargetSession:
    request.scene = WXSceneSession;
    break;

  case WXxSharingTargetTimeline:
    request.scene = WXSceneTimeline;
    break;

  case WXxSharingTargetFavorites:
    request.scene = WXSceneFavorite;
  }

  [WXApi sendReq:request];
}

-(void)shareTo: (WXxSharingTarget)target
   withRequest: (SendMessageToWXReq *)request
    completion: (SSSharingCompletionBlock)block
{
  [self startSharingWithCompletion:block];
  [self sendRequest:request to:target];
}

-(void)    shareTo: (WXxSharingTarget)target
         withTitle: (NSString *)title
              text: (NSString *)text
               url: (NSURL *)url
  previewImageData: (NSData *)previewImageData
        completion: (SSSharingCompletionBlock)block
{
  [self startSharingWithCompletion:block];

  // webpage media object
  WXWebpageObject *webpage = [WXWebpageObject object];
  webpage.webpageUrl = url.absoluteString;

  // message object
  WXMediaMessage *message = [WXMediaMessage message];
  message.title       = title;
  message.description = text;
  message.thumbData   = previewImageData;
  message.mediaObject = webpage;

  // request object
  SendMessageToWXReq *request = [SendMessageToWXReq new];
  request.bText   = NO;
  request.message = message;

  [self sendRequest:request to:target];
}

#pragma mark WxApiDelegate

- (void)onReq: (BaseReq *)req {
  JackDebug(@"%@", req);
}

- (void)onResp: (BaseResp *)resp
{
  if (self.stage == SSStageFaillure)
  {
    JackVerbose(@"operation already terminated");
    return;
  }

  if ([self handleSharingResponse:resp])
  {
    return;
  }

  JackWarn(@"response is not handled: %@", resp);
}

- (BOOL)handleSharingResponse: (BaseResp *)response
{
  if (![response isKindOfClass:[SendMessageToWXResp class]])
  {
    return NO;
  }

  [self completeSharingWithError:[SSError errorWithWXBaseResp:response]];
  return YES;
}

@end
