//
// SneakBackGuard.m
// Pods
//
// Created by Mudox on 27/08/2017.
//
//

#import "SneakBackGuard.h"
#import "SDKBaseManager.h"

@import Jack;

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif

@implementation SneakBackGuard

static NSString * uniquingToken = nil;

- (void)dealloc
{
  if (self.leaveBackgroundObserver != nil)
  {
    [NSNotificationCenter.defaultCenter removeObserver:self.leaveBackgroundObserver];
    self.leaveBackgroundObserver = nil;
    JackVerbose(@"disposed leaveBackgroundObserver");
  }

  if (self.becomeActiveObserver != nil)
  {
    [NSNotificationCenter.defaultCenter removeObserver:self.becomeActiveObserver];
    self.becomeActiveObserver = nil;
    JackVerbose(@"disposed becomeActiveObserver");
  }
}

- (instancetype)initWithSDKManager: (SDKBaseManager *)client {
  if (nil == (self = [super init]))
    return nil;

  // captured by observer block
  NSString *thisUniquingToken = [NSProcessInfo.processInfo globallyUniqueString];
  uniquingToken = thisUniquingToken;

  __weak typeof(client)weakClient = client;
  __weak typeof(self)weakSelf     = self;

  __block id leaveBackgroundObserver =
    [NSNotificationCenter.defaultCenter
     addObserverForName:UIApplicationWillEnterForegroundNotification
                 object:nil
                  queue:NSOperationQueue.mainQueue
             usingBlock:^(NSNotification * _Nonnull notify)
     {
       // one time off
       [NSNotificationCenter.defaultCenter removeObserver:leaveBackgroundObserver];

       if (![thisUniquingToken isEqualToString:uniquingToken])
       {
         JackError(@"uniquing tokenes do not match, return");
         return;
       }

       if (weakClient == nil)
       {
         JackWarn("becomeActiveObserver: weakly captured client instance is released");
         return;
       }
       __strong typeof(weakClient)trappedClient = weakClient;

       if (weakSelf == nil)
       {
         JackWarn("becomeActiveObserver: weakly captured self instance is released");
         return;
       }
       __strong typeof(weakSelf)trappedSelf = weakSelf;

       trappedSelf.leaveBackgroundObserver = nil;

       //
       // check trappedClient state integrity
       //

       NSError *error = [trappedClient checkInternalState];
       if (error != nil)
       {
         [trappedClient completeSSOWithError:error];
         return;
       }

       // transition state
       if (trappedClient.stage == SSSSOStageDidLaunchOperation)
       {
         trappedClient.stage = SSSSOStageDidEnterInactiveFromBackground;
       }
       else if (trappedClient.stage == SSSharingStageDidLaunchOperation)
       {
         trappedClient.stage = SSSharingStageDidEnterInactiveFromBackground;
       }
       else
       {
         NSString *errorMessage = [NSString
                                   stringWithFormat:@"leaveBackgroundObserver: invalid pre-stage (%@), "
                                   @"expecting SS[SSO|Sharing]DidLaunchOperation",
                                   NSStringFromSSStage(trappedClient.stage)
                                  ];
         SSError *error = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage }];
         [trappedClient completeSSOWithError:error];
       }

     }      // observer block
    ];

  self.leaveBackgroundObserver = leaveBackgroundObserver;

  __block id becomeActiveObserver =
    [NSNotificationCenter.defaultCenter
     addObserverForName:UIApplicationDidBecomeActiveNotification
                 object:nil
                  queue:NSOperationQueue.mainQueue
             usingBlock:^(NSNotification * _Nonnull notify)
     {
       // one time off
       [NSNotificationCenter.defaultCenter removeObserver:becomeActiveObserver];

       if (weakClient == nil)
       {
         JackWarn("becomeActiveObserver: weakly captured client instance is released");
         return;
       }
       __strong typeof(weakClient)trappedClient = weakClient;

       if (weakSelf == nil)
       {
         JackWarn("becomeActiveObserver: weakly captured self instance is released");
         return;
       }
       __strong typeof(weakSelf)trappedSelf = weakSelf;

       trappedSelf.becomeActiveObserver = nil;

       //
       // check client state integrity
       //

       NSError *checkError = [trappedClient checkInternalState];
       if (checkError != nil)
       {
         [trappedClient completeSSOWithError:checkError];
         return;
       }

       if (trappedClient.stage == SSStageSuccess || trappedClient.stage == SSStageFaillure)
       {
         JackVerbose(@"becomeActiveObserver: operation already terminated before becoming active");
         return;
       }

       if (trappedClient.stage == SSSSOStageDidHandleOpenURL || trappedClient.stage == SSSharingStageDidHandleOpenURL)
       {
         JackDebug(@"becomeActiveObserver: open url request is handled, but not terminated");
         return;
       }

       // transition state
       if (trappedClient.stage == SSSSOStageDidEnterInactiveFromBackground)
       {
         NSString *errorMessage = @"user snuck back, operation cancelled";
         SSError *error = [SSError errorCanceledWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage }];
         [trappedClient completeSSOWithError:error];
         return;
       }

       if (trappedClient.stage == SSSharingStageDidEnterInactiveFromBackground)
       {
         NSString *errorMessage = @"user snuck back, operation cancelled";
         SSError *error = [SSError errorCanceledWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage }];
         [trappedClient completeSharingWithError:error];
         return;
       }

       NSString *errorMessage = [NSString stringWithFormat:@"becomeActiveObserver: invalid pre-stage (%@), "
                                 @"expecting SS[SSO|Sharing][DidEnterInactiveFromBackground|DidHandleOpenURL]",
                                 NSStringFromSSStage(trappedClient.stage)
                                ];
       SSError *error = [SSError errorInternalWithUserInfo:@{ NSLocalizedDescriptionKey: errorMessage }];
       [trappedClient completeSSOWithError:error];

     }      // observer block
    ];

  self.becomeActiveObserver = becomeActiveObserver;


  return self;
}

@end
