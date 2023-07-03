//
//  MLDanmakuAgent.h
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/21.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLDanmakuModel.h"
#import "MLDanmakuProtocolCell.h"

NS_ASSUME_NONNULL_BEGIN


@interface MLDanmakuAgent : NSObject

@property (nonatomic, strong) MLDanmakuModel *danmakuModel;
@property (nonatomic, strong) id<MLDanmakuProtocolCell> danmakuProtocolCell;

@property (nonatomic, assign) BOOL force;

@property (nonatomic, assign) NSInteger toleranceCount;

/// 动画执行时间，速度
@property (nonatomic, assign) CGFloat duration;
/// 延迟时间
@property (nonatomic, assign) CGFloat delayTime;
/// 存活时间
@property (nonatomic, assign) CGFloat remainingTime;

@property (nonatomic, assign) CGFloat px;
@property (nonatomic, assign) CGFloat py;
@property (nonatomic, assign) CGSize size;

// y轴位置，默认-1
@property (nonatomic, assign) NSInteger yIdx;

- (instancetype)initWithDanmakuModel:(MLDanmakuModel *)danmakuModel;

- (NSComparisonResult)compare:(MLDanmakuAgent *)otherDanmakuAgent;

- (void)updateRemainingTime:(CGFloat)time;

- (void)updateDuration:(CGFloat)duration;

- (void)resetAnimation;

- (void)playAnimation;

- (void)pauseAnimation;

- (void)stopAnimation;

@end

NS_ASSUME_NONNULL_END
