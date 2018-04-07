#import "SDKBaseManager.h"
#import "SneakBackGuard.h"
#import "Types.h"
#import "SSError.h"

#import "WeiboSDKManager.h"

@import JacKit;

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif


@interface SDKBaseManager ()

@property (strong, nonatomic) SneakBackGuard *guard;

@end


@implementation SDKBaseManager

- (instancetype)init
{
  if (nil == (self = [super init]))
    return nil;

  _stage     = SSStageSuccess;
  _lastError = nil;

  return self;
}

#pragma mark Stage mangement

- (void)setStage: (SSStage)newStage {

  const SSStage from = _stage;
  const SSStage to   = newStage;

  JackDebug(@"stage transition: %@ -> %@", NSStringFromSSStage(_stage), NSStringFromSSStage(newStage));
  _stage = newStage;

  //
  // state transition rule #1: can not reset
  //

  if (to == from)
  {
    JackWarn(@"reset the same stage (%@)", NSStringFromSSStage(_stage));
    return;
  }

  //
  // state transition rule #2: abey the rules
  //

  static NSDictionary *rules;
  if (rules == nil)
  {
    rules = @{

      @(SSStageSuccess): @[
        @(SSSSOStageDidLaunchOperation),
        @(SSSharingStageDidLaunchOperation),
      ],

      @(SSStageFaillure): @[
        @(SSSSOStageDidLaunchOperation),
        @(SSSharingStageDidLaunchOperation),
      ],

      //
      // SSO
      //

      @(SSSSOStageDidLaunchOperation): @[
        @(SSStageFaillure),
        @(SSStageSuccess),  // SSO in SDK built-in web view, no app switch
        @(SSSSOStageDidEnterInactiveFromBackground),
      ],
      
      @(SSSSOStageDidEnterInactiveFromBackground): @[
        @(SSStageFaillure),
        @(SSSSOStageDidHandleOpenURL),
      ],

      @(SSSSOStageDidHandleOpenURL): @[
        @(SSStageFaillure),
        @(SSStageSuccess),
      ],

      //
      // Share
      //

      @(SSSharingStageDidLaunchOperation): @[
        @(SSStageFaillure),
        @(SSStageSuccess),  // share in SDK built-in web view, no app switch
        @(SSSharingStageDidEnterInactiveFromBackground),
      ],

      @(SSSharingStageDidEnterInactiveFromBackground): @[
        @(SSStageFaillure),
        @(SSStageSuccess), // different from SSO, sharing is one step operation, it may succeed during the run of handleOpenURL method
        @(SSSharingStageDidHandleOpenURL),
      ],

      @(SSSharingStageDidHandleOpenURL): @[
        @(SSStageFaillure),
        @(SSStageSuccess),
      ],

    };
  }

  if (![rules[@(from)] containsObject:@(to)])
  {
    JackError("transition is invalid");
  }

}

- (BOOL)isIdle
{
  return [@[
            @(SSStageSuccess),
            @(SSStageFaillure),
          ] containsObject: @(self.stage)];
}

- (BOOL)isSSOing
{
  return [@[
            @(SSSSOStageDidLaunchOperation),
            @(SSSSOStageDidEnterInactiveFromBackground),
            @(SSSSOStageDidHandleOpenURL),
          ] containsObject: @(self.stage)];
}

- (BOOL)isSharing
{
  return [@[
            @(SSSharingStageDidLaunchOperation),
            @(SSSharingStageDidEnterInactiveFromBackground),
            @(SSSharingStageDidHandleOpenURL),
          ] containsObject: @(self.stage)];
}

- (NSError *)checkInternalState
{
    switch (self.stage)
    {
      case SSStageSuccess:
        if( self.lastError != nil) {
          NSString *errorMessage = [NSString stringWithFormat:@"self.lastError should be nil on stage SSStageSuccess"];
          SSError *error        = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage }];
          JackError(@"%@", errorMessage);
          return error;
        }
        break;
      
      case SSStageFaillure:
          if (self.lastError == nil) {
            NSString *errorMessage = [NSString stringWithFormat:@"self.lastError should be nil on stage SSStageSuccess"];
            SSError *error        = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage }];
            JackError(@"%@", errorMessage);
            return error;
          }
        break;
    
    case SSSSOStageDidLaunchOperation:
    case SSSSOStageDidEnterInactiveFromBackground:
    case SSSSOStageDidHandleOpenURL:

      //
      // on SSO stages, ssoCompletionBlock must be non-nil, while the sharingCompletionBlock must be nil
      //

      if (self.ssoCompletionBlock == nil)
      {
        NSString *errorMessage = [NSString stringWithFormat:@"SSO completion blocks should not be nil on SSO stages (%@)", NSStringFromSSStage(self.stage)];
        SSError *error        = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage }];
       
        JackError(@"%@", errorMessage);
        return error;
      }

      if (self.sharingCompletionBlock != nil)
      {
        NSString *errorMessage = [NSString stringWithFormat:@"sharing completion blocks should be nil on SSO stages (%@)", NSStringFromSSStage(self.stage)];
        SSError *error        = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage}];

        JackError(@"%@", errorMessage);
        return error;
      }

      break;

    case SSSharingStageDidLaunchOperation:
    case SSSharingStageDidEnterInactiveFromBackground:
    case SSSharingStageDidHandleOpenURL:

      //
      // on sharing stages, ssoCompletionBlock must be nil, while the sharingCompletionBlock must be non-nil
      //

      if (self.ssoCompletionBlock != nil)
      {
        NSString *errorMessage = [NSString stringWithFormat:@"SSO completion blocks should be nil on sharing stages (%@)", NSStringFromSSStage(self.stage)];
        SSError *error        = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage}];
        JackError(@"%@", errorMessage);
        return error;
      }

      if (self.sharingCompletionBlock == nil)
      {
        NSString *errorMessage = [NSString stringWithFormat:@"sharing completion blocks should not be nil on sharing stages (%@)", NSStringFromSSStage(self.stage)];
        SSError *error        = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage}];
        JackError(@"%@", errorMessage);
        return error;
      }
    }

  if(self.isIdle) {

    //
    // on idle stage, both blocks must be nil
    //

    if (self.ssoCompletionBlock != nil)
    {
      NSString *errorMessage = @"SSO completion blocks is NOT nil on idle stage";
      SSError *error        = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage}];

      [self completeSSOWithError:error];
      JackError(@"%@", errorMessage);
      return error;
    }

    if (self.sharingCompletionBlock != nil)
    {
      NSString *errorMessage = @"sharing completion blocks is NOT nil on idle stage";
      SSError *error        = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage}];

      [self completeSSOWithError:error];
      JackError(@"%@", errorMessage);
      return error;
    }
  }

  return nil;
}

#pragma mark SSO

- (void)startSSOWithCompletion: (SSSSOCompletionBlock)block {

  //
  // save block
  //

  if (self.ssoCompletionBlock != nil)
  {
    JackError(@"previous SSO block remains, override it");
  }

  self.ssoCompletionBlock = block;

  //
  // install sneak back guard
  //

  if (self.guard != nil)
  {
    JackError(@"previous sneak back guard remains, override it");
  }

  self.guard = [[SneakBackGuard alloc] initWithSDKManager:self];

  //
  // set stage
  //

  self.stage = SSSSOStageDidLaunchOperation;
}

- (void)completeSSOWithSSOResult: (SSOResult *)ssoResult error: (NSError *)error
{
  if (self.isSharing)
  {
    JackError(@"SSO completion block is invoked in sharing process");
    return;
  }

  //
  // always clear sneak back guards
  //

  self.guard = nil;

  // precondition: completion block must not be nil
  if (self.ssoCompletionBlock == nil)
  {
    JackError(@"SSO completion block should not be nil");

    self.stage     = SSStageFaillure;
    self.lastError = error;

    return;
  }

  //
  // precondition: the 2 argument must not be nil or non-nil at the same time
  //

  if (ssoResult == nil && error == nil)
  {
    NSString *errorMessage = @"argument `result` and `error` should not be nil at the same time";
    JackError("%@", errorMessage);
    SSError *error = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage }];
    self.ssoCompletionBlock(nil, error);

    self.stage     = SSStageFaillure;
    self.lastError = error;

    return;
  }

  if (ssoResult != nil && error != nil)
  {
    NSString *errorMessage = @"argument `result` and `error` should not be non-nil at the same time";
    JackError("%@", errorMessage);
    SSError *error = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage }];
    self.ssoCompletionBlock(nil, error);

    self.stage     = SSStageFaillure;
    self.lastError = error;

    return;
  }

  //
  // invoke block & set final stage value
  //


  if (error != nil)
  {
    self.stage     = SSStageFaillure;
    self.lastError = error;
  }
  else
  {
    self.stage     = SSStageSuccess;
    self.lastError = nil;
  }

  self.ssoCompletionBlock(ssoResult, error);
  self.ssoCompletionBlock = nil;
}

/**
 *  Conventient method
 */
- (void)completeSSOWithSSOResult: (SSOResult *)ssoResult
{
  if (ssoResult == nil)
  {
    JackError(@"needs a non-nil `ssoResult` argument");
  }
  else
  {
    JackDebug(@"%@", ssoResult);
  }
  [self completeSSOWithSSOResult:ssoResult error:nil];
}

/**
 *  Conventient method
 */
- (void)completeSSOWithError: (NSError *)error
{
  if (error == nil)
  {
    JackError(@"needs a non-nil `error` argument");
  }
  else
  {
    JackDebug(@"%@", error);
  }
  [self completeSSOWithSSOResult:nil error:error];
}

#pragma mark Sharing

- (void)startSharingWithCompletion: (SSSharingCompletionBlock)block {

  //
  // save block
  //

  if (self.sharingCompletionBlock != nil)
  {
    JackError(@"previous sharing block remains, override it");
  }

  self.sharingCompletionBlock = block;

  //
  // install sneak back guard
  //

  if (self.guard != nil)
  {
    JackError(@"previous sneak back guard remains, override it");
  }

  self.guard = [[SneakBackGuard alloc] initWithSDKManager:self];

  //
  // set stage
  //

  self.stage = SSSharingStageDidLaunchOperation;
}

- (void)completeSharingWithError: (NSError *)error
{
  if (error != nil)
  {
    JackDebug(@"%@", error);
  }

  if (self.isSSOing)
  {
    JackError(@"sharing completion block is invoked in SSO process");
  }

  //
  // always clear sneak back guards
  //

  self.guard = nil;

  //
  // preconditoin: completion block must not be nil
  //

  if (self.sharingCompletionBlock == nil)
  {
    JackError(@"sharing completion block should not be nil");

    self.stage     = SSStageFaillure;
    self.lastError = error;

    return;
  }

  //
  // invoke block & set final stage value
  //


  if (error != nil)
  {
    self.stage     = SSStageFaillure;
    self.lastError = error;
  }
  else
  {
    self.stage     = SSStageSuccess;
    self.lastError = nil;
  }

  self.sharingCompletionBlock(error);
  self.sharingCompletionBlock = nil;
}

@end
