//
//  Helpers.m
//  Pods
//
//  Created by Mudox on 22/08/2017.
//
//

@import Foundation;

#import "SDKBaseManager.h"
#import "SocialKit.h"

NSString *NSStringFromSSStage(SSStage stage)
{
#define _es(e) @(e) : @#e
  return @{
           _es(SSStageSuccess),
           _es(SSStageFaillure),
           _es(SSSSOStageDidLaunchOperation),
           _es(SSSSOStageDidEnterInactiveFromBackground),
           _es(SSSSOStageDidHandleOpenURL),
           _es(SSSharingStageDidLaunchOperation),
           _es(SSSharingStageDidEnterInactiveFromBackground),
           _es(SSSharingStageDidHandleOpenURL),
           }[@(stage)];
#undef _es
}

NSString *NSStringFromSSTarget(SSTarget target)
{
#define _es(e) @(e) : @#e
  return @{
           _es(SSTargetQQ),
           _es(SSTargetQZone),
           
           _es(SSTargetWeibo),
           
           _es(SSTargetWeChat),
           _es(SSTargetWeChatTimeline),
           }[@(target)];
#undef _es
}
