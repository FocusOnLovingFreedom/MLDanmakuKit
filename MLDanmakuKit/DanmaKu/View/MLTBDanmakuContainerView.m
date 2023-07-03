//
//  MLTBDanmakuContainerView.m
//  MLDanmaKuKit
//
//  Created by Mountain on 2020/11/10.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import "MLTBDanmakuContainerView.h"
#import "MLDanmakuTypeRetainer.h"
#import "MLDanmakuAgent.h"
#import "MLDanmakuExtention.h"

@implementation MLTBDanmakuContainerView

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
    CGFloat midX = CGRectGetMidX(self.renderBounds);
    CGFloat height = CGRectGetHeight(self.renderBounds);
    for (MLDanmakuAgent *danmakuAgent in danmakuAgents) {
        CGPoint centerPoint = danmakuAgent.danmakuProtocolCell.center;
        centerPoint.x = midX;
        danmakuAgent.danmakuProtocolCell.center = centerPoint;
        if (danmakuAgent.danmakuModel.danmakuType == MLDanmakuTypeFixFB) {
            CGRect rect = danmakuAgent.danmakuProtocolCell.frame;
            rect.origin.y = height - self.configuration.cellHeight * (danmakuAgent.yIdx + 1);
            if (!checkValidFrame(rect)) {
                return;
            }
            danmakuAgent.danmakuProtocolCell.frame = rect;
        }
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
    danmakuAgent.px = CGRectGetMidX(self.renderBounds) - danmakuAgent.size.width / 2;
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
        if (!tempAgent) {
            danmakuAgent.yIdx = index;
            retainer[key] = danmakuAgent;
            return [self pyWithIndex:index isLayoutFromBottom:[self isFromBottom]];
        }
        if (![self isTBWillHitWithPreDanmaku:tempAgent danmaku:danmakuAgent]) {
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
    if (self.danmakuType == MLDanmakuTypeFixFB) {
        return YES;
    }
    return NO;
}

- (BOOL)isTBWillHitWithPreDanmaku:(MLDanmakuAgent *)preDanmakuAgent danmaku:(MLDanmakuAgent *)danmakuAgent {
    if (preDanmakuAgent.remainingTime <= 0) {
        return NO;
    }
    return YES;
}


@end
