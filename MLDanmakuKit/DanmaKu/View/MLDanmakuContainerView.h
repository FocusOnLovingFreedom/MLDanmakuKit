//
//  MLDanmakuContainerView.h
//  MLDanmaKuKit
//
//  Created by Mountain on 2020/11/10.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MLDanmakuConfiguration.h"
@class MLDanmakuTypeRetainer;
@class MLDanmakuAgent;
NS_ASSUME_NONNULL_BEGIN

#define Container_DanmakuSourceLock() dispatch_semaphore_wait(self.semaphoreLock, DISPATCH_TIME_FOREVER)
#define Container_DanmakuSourceUnLock() dispatch_semaphore_signal(self.semaphoreLock)

@interface MLDanmakuContainerView : UIView
@property (nonatomic, strong) dispatch_semaphore_t semaphoreLock;
@property (nonatomic, assign, readonly) MLDanmakuType danmakuType;
@property (nonatomic, strong, readonly) MLDanmakuConfiguration *configuration;
@property (nonatomic, strong, readonly) MLDanmakuTypeRetainer *retainer;
@property (nonatomic, assign) CGRect renderBounds;

@property (nonatomic, strong, readonly) NSArray<MLDanmakuAgent *> *visibleDanmakuAgents;

- (void)clearScreen;

- (void)addDanmakuAngent:(MLDanmakuAgent *)danmakuAgent;

- (void)removeDanmakuAngent:(MLDanmakuAgent *)danmakuAgent;

- (MLDanmakuAgent *)dk_hitTest:(CGPoint)point;
- (instancetype)initWithFrame:(CGRect)frame
                  danmakuType:(MLDanmakuType)danmakuType
                configuration:(MLDanmakuConfiguration *)configuration;

- (u_int8_t)maxPyIndexWithType:(MLDanmakuType)danmakuType;

- (BOOL)layoutNewDanmaku:(MLDanmakuAgent *)danmakuAgent
                   width:(CGFloat)width
                 forTime:(MLDanmakuTime)time;

/// 根据index返回y，默认从顶往下
/// @param index index
/// @param isLayoutFromBottom 是否从底网上布局
- (CGFloat)pyWithIndex:(NSInteger)index isLayoutFromBottom:(BOOL)isLayoutFromBottom;

@end

NS_ASSUME_NONNULL_END
