//
// SneakBackGuard.h
// Pods
//
// Created by Mudox on 27/08/2017.
//
//

#import <Foundation/Foundation.h>

@class SDKBaseManager;

@interface SneakBackGuard : NSObject

@property (strong, nonatomic) id leaveBackgroundObserver;
@property (strong, nonatomic) id becomeActiveObserver;

- (instancetype)initWithSDKManager: (SDKBaseManager *)client;

@end
