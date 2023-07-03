//
//  MLDanmakuAgent.m
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/21.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import "MLDanmakuAgent.h"
#import "MLDanmakuModel.h"
#define DANMAKU_ANIMATION_KEY @"DanmakuAnimationKey"

@implementation MLDanmakuAgent
@synthesize delayTime = _delayTime;

- (instancetype)initWithDanmakuModel:(MLDanmakuModel *)danmakuModel {
    if (self = [super init]) {
        self.danmakuModel = danmakuModel;
        self.yIdx = -1;
    }
    return self;
}

- (CGFloat)delayTime {
    if (_delayTime > 0) {
        return _delayTime;
    }
    return 0;
}

- (void)setDelayTime:(CGFloat)delayTime {
    if (delayTime > 0) {
        _delayTime = delayTime;
    } else {
        _delayTime = 0;
    }
}

- (NSComparisonResult)compare:(MLDanmakuAgent *)otherDanmakuAgent {
    return [@(self.danmakuModel.time) compare:@(otherDanmakuAgent.danmakuModel.time)];
}

- (void)updateRemainingTime:(CGFloat)time {
    self.remainingTime -= time;
}

- (void)updateDuration:(CGFloat)duration {
    if (self.danmakuModel.danmakuType != MLDanmakuTypeRLFT && self.danmakuModel.danmakuType != MLDanmakuTypeRLFB) {
        return;
    }
    if (![self checkValidPoint:[self contentCellLayer].position]) {
        return;
    }
    BOOL isPause = ([self contentCellLayer].speed == 0);
    CALayer *layer = [self contentCellLayer];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    [layer removeAnimationForKey:DANMAKU_ANIMATION_KEY];
    
    CGFloat preDuration = self.duration;
    CGFloat curDuration = duration;
    CGFloat preRemainingTime = self.remainingTime;
    CGFloat preTime = 0;
    if (preDuration >= preRemainingTime) { // 已经在展现过程中
        self.delayTime = 0;
        preTime = preDuration - preRemainingTime;
    } else { // 还未展现
        self.delayTime = preRemainingTime - preDuration;
        preTime = 0;
    }
    CGFloat curTime = preTime * curDuration / preDuration;
    self.duration = duration;
    self.remainingTime = self.duration + self.delayTime - curTime;
    // 不能使用frame,详细原因请查看UIView中关于frame的描述 ：
    // animatable. do not use frame if view is transformed since it will not correctly reflect the actual location of the view. use bounds + center instead.
    CGPoint fromPoint = self.danmakuProtocolCell.center;
    CGFloat width = CGRectGetWidth(self.danmakuProtocolCell.bounds);
    CGPoint toPoint = CGPointMake(-width * 0.5, self.danmakuProtocolCell.center.y);
    CABasicAnimation *anim = [self makeAnimationFromPoint:fromPoint
                                                  toPoint:toPoint
                                                 duration:self.duration
                                                beginTime:CACurrentMediaTime() + self.delayTime - curTime];
    [[self contentCellLayer] addAnimation:anim forKey:DANMAKU_ANIMATION_KEY];

    if (isPause) {
        [self pauseAnimation];
    }
}

- (void)playAnimation {
    if (self.danmakuModel.danmakuType != MLDanmakuTypeRLFT && self.danmakuModel.danmakuType != MLDanmakuTypeRLFB) {
        return;
    }
    if (![self checkValidPoint:[self contentCellLayer].position]) {
        return;
    }
    CAAnimation *anim = [[self contentCellLayer] animationForKey:DANMAKU_ANIMATION_KEY];
    if (anim) {
        [self resumeAnimation];
    } else {
        CGPoint fromPoint = self.danmakuProtocolCell.center;
        CGFloat width = CGRectGetWidth(self.danmakuProtocolCell.bounds);
        CGPoint toPoint = CGPointMake(-width * 0.5, self.danmakuProtocolCell.center.y);
        CABasicAnimation *anim = [self makeAnimationFromPoint:fromPoint
                                                      toPoint:toPoint
                                                     duration:self.duration
                                                    beginTime:CACurrentMediaTime() + self.delayTime];
        [[self contentCellLayer] addAnimation:anim forKey:DANMAKU_ANIMATION_KEY];
    }
}

- (void)resetAnimation {
    if (self.danmakuModel.danmakuType != MLDanmakuTypeRLFT && self.danmakuModel.danmakuType != MLDanmakuTypeRLFB) {
        return;
    }
    if (![self checkValidPoint:[self contentCellLayer].position]) {
        return;
    }
    BOOL isPause = ([self contentCellLayer].speed == 0);
    CALayer *layer = [self contentCellLayer];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    [layer removeAnimationForKey:DANMAKU_ANIMATION_KEY];

    CGFloat curTime = 0;
    if (self.remainingTime > 0 && self.remainingTime < self.duration) { // 展现中
        curTime = self.duration - self.remainingTime;
        self.delayTime = 0;
    } else {
        self.delayTime = self.remainingTime - self.duration;
    }
    CGPoint fromPoint = self.danmakuProtocolCell.center;
    CGFloat width = CGRectGetWidth(self.danmakuProtocolCell.bounds);
    CGPoint toPoint = CGPointMake(-width * 0.5, self.danmakuProtocolCell.center.y);
    CABasicAnimation *anim = [self makeAnimationFromPoint:fromPoint
                                                  toPoint:toPoint
                                                 duration:self.duration
                                                beginTime:CACurrentMediaTime() + self.delayTime - curTime];
    [[self contentCellLayer] addAnimation:anim forKey:DANMAKU_ANIMATION_KEY];
    if (isPause) {
        [self pauseAnimation];
    }
}

- (void)pauseAnimation {
    if (self.danmakuModel.danmakuType != MLDanmakuTypeRLFT && self.danmakuModel.danmakuType != MLDanmakuTypeRLFB) {
        return;
    }
    CALayer *layer = [self contentCellLayer];
    CFTimeInterval pauseTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pauseTime;
}

- (void)resumeAnimation {
    if (self.danmakuModel.danmakuType != MLDanmakuTypeRLFT && self.danmakuModel.danmakuType != MLDanmakuTypeRLFB) {
        return;
    }
    CALayer *layer = [self contentCellLayer];
    CFTimeInterval pauseTime = layer.timeOffset;
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pauseTime;
    layer.beginTime = timeSincePause;
}

- (CABasicAnimation *)makeAnimationFromPoint:(CGPoint)fromPoint
                                     toPoint:(CGPoint)toPoint
                                    duration:(CGFloat)duration
                                   beginTime:(CFTimeInterval)beginTime {
    CABasicAnimation *anim = [CABasicAnimation animation];
    anim.keyPath = @"position";
    anim.fromValue = [NSValue valueWithCGPoint:fromPoint];
    anim.toValue = [NSValue valueWithCGPoint:toPoint];
    anim.duration = duration;
    anim.beginTime = beginTime;
    anim.removedOnCompletion = NO;
    anim.fillMode = kCAFillModeForwards;
    anim.timingFunction =[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    return anim;
}

- (void)stopAnimation {
    CALayer *layer = [self contentCellLayer];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    [layer removeAnimationForKey:DANMAKU_ANIMATION_KEY];
    [self reset];
}

- (void)reset {
    [self.danmakuProtocolCell removeFromSuperContent];
    self.yIdx = -1;
    self.duration = 0;
    self.delayTime = 0;
    self.remainingTime = 0;
}
- (CALayer *)contentCellLayer {
    return [self.danmakuProtocolCell danmakuAnimationLayer];
}
- (BOOL)checkValidPoint:(CGPoint)point {
    if (isnan(point.x)) {
        return NO;
    }
    if (isnan(point.y)) {
        return NO;
    }
    return YES;
}
@end
