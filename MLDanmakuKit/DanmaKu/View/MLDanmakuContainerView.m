//
//  MLDanmakuContainerView.m
//  MLDanmaKuKit
//
//  Created by Mountain on 2020/11/10.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import "MLDanmakuContainerView.h"
#import "MLDanmakuExtention.h"
#import "MLDanmakuTypeRetainer.h"
#import "MLDanmakuAgent.h"
@interface MLDanmakuContainerView ()

@property (nonatomic, strong) MLDanmakuConfiguration *configuration;
@property (nonatomic, assign) MLDanmakuType danmakuType;
@property (nonatomic, strong) MLDanmakuTypeRetainer *retainer;
@property (nonatomic, strong) NSMutableArray<MLDanmakuAgent *> *danmakuAgents;
@end
@implementation MLDanmakuContainerView
- (instancetype)initWithFrame:(CGRect)frame
                  danmakuType:(MLDanmakuType)danmakuType
                configuration:(MLDanmakuConfiguration *)configuration {
    self = [super initWithFrame:frame];
    if (self) {
        self.danmakuType = danmakuType;
        self.configuration = configuration;
        self.renderBounds = self.bounds;
        self.semaphoreLock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)clearScreen {
    dispatch_async(dispatch_get_main_queue(), ^{
        Container_DanmakuSourceLock();
        [self.danmakuAgents removeAllObjects];
        Container_DanmakuSourceUnLock();
        [self.retainer removeAllObjects];
        [self.layer.sublayers enumerateObjectsUsingBlock:^(__kindof CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj conformsToProtocol:@protocol(MLDanmakuProtocolCell)] && [obj respondsToSelector:@selector(removeFromSuperContent)]) {
                [obj removeFromSuperContent];
            }
        }];
        [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj conformsToProtocol:@protocol(MLDanmakuProtocolCell)] && [obj respondsToSelector:@selector(removeFromSuperContent)]) {
                [obj removeFromSuperContent];
            }
        }];
    });
}
- (void)addDanmakuAngent:(MLDanmakuAgent *)danmakuAgent {
    Container_DanmakuSourceLock();
    [self.danmakuAgents dk_safeAddObject:danmakuAgent];
    Container_DanmakuSourceUnLock();
}
- (void)removeDanmakuAngent:(MLDanmakuAgent *)danmakuAgent {
    Container_DanmakuSourceLock();
    [self.danmakuAgents removeObject:danmakuAgent];
    Container_DanmakuSourceUnLock();
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return nil;
}
- (MLDanmakuAgent *)dk_hitTest:(CGPoint)point {
    return [self danmakuAgentAtPoint:point];
    
}
- (MLDanmakuAgent *)danmakuAgentAtPoint:(CGPoint)point {
    for (MLDanmakuAgent *danmakuAgent in self.visibleDanmakuAgents) {
        CGRect rect = danmakuAgent.danmakuProtocolCell.danmakuAnimationLayer.presentationLayer.frame;
        if (CGRectContainsPoint(rect, point)) {
            return danmakuAgent;
        }
    }
    return nil;
}
- (BOOL)layoutNewDanmaku:(MLDanmakuAgent *)danmakuAgent width:(CGFloat)width forTime:(MLDanmakuTime)time {
    return NO;
}

- (CGFloat)pyWithIndex:(NSInteger)index isLayoutFromBottom:(BOOL)isLayoutFromBottom {
    if (isLayoutFromBottom) {
        return CGRectGetHeight(self.renderBounds) - self.configuration.cellHeight * (index + 1);
    } else {
        return self.configuration.cellHeight * index;
    }
}

- (u_int8_t)maxPyIndexWithType:(MLDanmakuType)danmakuType {
    if (danmakuType == MLDanmakuTypeUnKnown) {
        return 0;
    }
    CGFloat displayArea = [self.configuration configItemWithType:danmakuType].displayArea;
    CGFloat numberOfLines = self.configuration.numberOfLines;
    return numberOfLines> 0 ? numberOfLines : (CGRectGetHeight(self.renderBounds) * displayArea / self.configuration.cellHeight);
}
#pragma mark - property
- (MLDanmakuTypeRetainer *)retainer {
    if (!_retainer) {
        NSInteger numOfSameTypeOverLayers = [self.configuration configItemWithType:self.danmakuType].numOfSameTypeOverLayers;
        _retainer = [[MLDanmakuTypeRetainer alloc] initWithOverLayerNum:numOfSameTypeOverLayers];
    }
    return _retainer;
}
- (NSMutableArray<MLDanmakuAgent *> *)danmakuAgents {
    if (!_danmakuAgents) {
        _danmakuAgents = [[NSMutableArray alloc] init];
    }
    return _danmakuAgents;
}
- (NSArray<MLDanmakuAgent *> *)visibleDanmakuAgents {
    Container_DanmakuSourceLock();
    NSArray *visibleDanmakuAgents = [self.danmakuAgents copy];
    Container_DanmakuSourceUnLock();
    return visibleDanmakuAgents;
}
@end
