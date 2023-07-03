//
//  MLRLDanmakuContainerView.m
//  MLDanmaKuKit
//
//  Created by Mountain on 2020/11/10.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import "MLRLDanmakuContainerView.h"
#import "MLDanmakuTypeRetainer.h"
#import "MLDanmakuAgent.h"
#import "MLDanmakuExtention.h"
@implementation MLRLDanmakuContainerView
- (instancetype)initWithFrame:(CGRect)frame danmakuType:(MLDanmakuType)danmakuType configuration:(MLDanmakuConfiguration *)configuration {
    self = [super initWithFrame:frame danmakuType:danmakuType configuration:configuration];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect preRenderBounds = self.renderBounds;
    CGRect currentRenderBounds = self.bounds;
    if (CGRectEqualToRect(preRenderBounds, currentRenderBounds)) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self relayoutSubContent];
    });
}

- (void)relayoutSubContent {
    NSArray *danmakuAgents = [self visibleDanmakuAgents];
    self.renderBounds = self.bounds;
    CGFloat height = CGRectGetHeight(self.renderBounds);
    for (MLDanmakuAgent *danmakuAgent in danmakuAgents) {
        CGFloat currentRate = 1;
        if (danmakuAgent.duration !=0 && danmakuAgent.remainingTime <= danmakuAgent.duration) {
            currentRate = danmakuAgent.remainingTime * 1.0 / danmakuAgent.duration;
        }
        CGFloat currentRenderW = CGRectGetWidth(self.renderBounds);
        CGFloat newX = currentRate * (currentRenderW + danmakuAgent.size.width) - danmakuAgent.size.width;
        CGFloat newY = danmakuAgent.danmakuProtocolCell.frame.origin.y;
        if (danmakuAgent.danmakuModel.danmakuType == MLDanmakuTypeRLFB) {
            newY = height - self.configuration.cellHeight * (danmakuAgent.yIdx + 1);
        }
        CGRect newFrame = (CGRect){CGPointMake(newX, newY), danmakuAgent.size};
        if (!checkValidFrame(newFrame)) {
            return;
        }
        [CATransaction begin];
        [CATransaction setDisableActions: YES];
        danmakuAgent.danmakuProtocolCell.frame = newFrame;
        [danmakuAgent resetAnimation];
        [CATransaction commit];
        danmakuAgent.danmakuProtocolCell.hidden = danmakuAgent.yIdx >= [self maxPyIndexWithType:danmakuAgent.danmakuModel.danmakuType];
    }
    
    
}

- (BOOL)layoutNewDanmaku:(MLDanmakuAgent *)danmakuAgent width:(CGFloat)width forTime:(MLDanmakuTime)time {
    danmakuAgent.size = CGSizeMake(width, self.configuration.cellHeight);
    CGFloat py = [self layoutPyWithDanmaku:danmakuAgent forTime:time layerIndex:0];
    if (py < 0) {
        return NO;
    }
    danmakuAgent.py = py;
    danmakuAgent.px = CGRectGetWidth(self.renderBounds);
    return YES;
}

- (CGFloat)layoutPyWithDanmaku:(MLDanmakuAgent *)danmakuAgent forTime:(MLDanmakuTime)time layerIndex:(NSUInteger)layerIndex {
    if (layerIndex >= [self.configuration configItemWithType:self.danmakuType].numOfSameTypeOverLayers) {
        return -1;
    }
    u_int8_t maxPyIndex = [self maxPyIndexWithType:self.danmakuType];
    NSMutableDictionary *retainer = [self.retainer retainerWithLayerIndex:layerIndex];
    for (u_int8_t index = 0; index < maxPyIndex; index++) {
        NSNumber *key = @(index);
        MLDanmakuAgent *tempAgent = retainer[key];
        if (!tempAgent || tempAgent.yIdx != index) {
            danmakuAgent.yIdx = index;
            retainer[key] = danmakuAgent;
            return [self pyWithIndex:index isLayoutFromBottom:[self isFromBottom]];
        }
        if (![self isRLWillHitWithPreDanmaku:tempAgent danmaku:danmakuAgent]) {
            danmakuAgent.yIdx = index;
            retainer[key] = danmakuAgent;
            return [self pyWithIndex:index isLayoutFromBottom:[self isFromBottom]];
        }
    }
    if (danmakuAgent.force) {
        u_int8_t index = arc4random() % maxPyIndex;
        danmakuAgent.yIdx = index;
        retainer[@(index)] = danmakuAgent;
        return [self pyWithIndex:index isLayoutFromBottom:[self isFromBottom]];
    }
    layerIndex ++;
    return [self layoutPyWithDanmaku:danmakuAgent forTime:time layerIndex:layerIndex];
}

- (BOOL)isFromBottom {
    if (self.danmakuType == MLDanmakuTypeRLFB) {
        return YES;
    }
    return NO;
}


- (BOOL)isRLWillHitWithPreDanmaku:(MLDanmakuAgent *)preDanmakuAgent danmaku:(MLDanmakuAgent *)danmakuAgent {
    if (preDanmakuAgent.remainingTime <= 0) {
        return NO;
    }
    CGFloat width = CGRectGetWidth(self.renderBounds);
    CGFloat preDanmakuSpeed = (width + preDanmakuAgent.size.width) / preDanmakuAgent.duration;
    CGFloat finalSpace = preDanmakuSpeed * (preDanmakuAgent.duration - preDanmakuAgent.remainingTime + danmakuAgent.delayTime);
    CGFloat minSpace = preDanmakuAgent.size.width + self.configuration.minSpacing;
    // 已经展现过程中的弹幕
    if (finalSpace < minSpace) {
        return YES;
    }
    CGFloat curDanmakuSpeed = (width + danmakuAgent.size.width) / danmakuAgent.duration;
    CGFloat chaseSpace = curDanmakuSpeed * (preDanmakuAgent.remainingTime - danmakuAgent.delayTime);
    CGFloat maxChaseSpace = width - self.configuration.minSpacing;
    // 都在队列中的弹幕
    if (chaseSpace > maxChaseSpace) {
        return YES;
    }
    return NO;
}
@end
