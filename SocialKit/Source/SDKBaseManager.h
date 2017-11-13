//
// SDKBaseManager.h
// Pods
//
// Created by Mudox on 22/04/2017.
//
//

@import Foundation;

#import "Types.h"
#import "SSOResult.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSInteger, SSStage) {
  //
  // The 2 final stages
  //
  // they can only be set by completeWith methods
  //

  // `lastError` must be nil when set
  SSStageSuccess,

  // `lastError` must be non-nil when set
  SSStageFaillure,

  //
  // SSO stages
  //

  SSSSOStageDidLaunchOperation = 10,
  SSSSOStageDidEnterInactiveFromBackground,
  SSSSOStageDidHandleOpenURL,

  //
  // Sharing stages
  //

  SSSharingStageDidLaunchOperation = 100,
  SSSharingStageDidEnterInactiveFromBackground,
  SSSharingStageDidHandleOpenURL,

};

extern NSString *NSStringFromSSStage(SSStage stage);

@interface SDKBaseManager : NSObject

#pragma mark Internal states

/**
 *  Internal flag tracking progress of asynchronous / cross-apps operations
 */
@property (assign, nonatomic) SSStage stage;

/**
 *  stage is `.success` or `.failure`
 */
@property (assign, readonly, nonatomic) BOOL isIdle;

/**
 *  is in the process of SSO
 */
@property (assign, readonly, nonatomic) BOOL isSSOing;

/**
 *  is in the process of sharing
 */
@property (assign, readonly, nonatomic) BOOL isSharing;

/**
 *  When `stage` turns into `SSStageFailure`, the associated error object is
 *  stored into this property for debug use.
 *
 *  @note This property can only be set with the 2 `completeWith...` methods.
 */
@property (strong, nonatomic) NSError *_Nullable lastError;

#pragma mark Completion blocks

@property (strong, nonatomic) SSSSOCompletionBlock _Nullable    ssoCompletionBlock;
@property (strong, nonatomic) SSSharingCompletionBlock _Nullable sharingCompletionBlock;

#pragma mark Helper methods

- (NSError *)checkInternalState;

#pragma mark SSO

/**
 *  It prepares the manager state for new SSO operation
 *
 *  - Save the argumetn completion block for later invocation
 *
 *  - Install sneak back guard
 *
 *  - Change `stage` to `didLaunchOperation`
 *
 *  @note Subclasses's SSO method must call this method first
 *
 *  @param block SSO completion block
 */
- (void)startSSOWithCompletion: (SSSSOCompletionBlock)block;
- (void)completeSSOWithSSOResult: (SSOResult *)ssoResult;
- (void)completeSSOWithError: (NSError *)error;

#pragma mark Share

/**
 *  It prepares the manager state for new sharing operation
 *
 *  - Save the argumetn completion block for later invocation
 *
 *  - Install sneak back guard
 *
 *  - Change `stage` to `didLaunchOperation`
 *
 *  @note Subclasses's sharing method must call this method first
 *
 *  @param block sharing completion block
 */
- (void)startSharingWithCompletion: (SSSharingCompletionBlock)block;
- (void)completeSharingWithError: (NSError *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
