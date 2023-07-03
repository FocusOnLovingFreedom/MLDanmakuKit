//
//  MLDanmakuLayerCell.m
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/20.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import "MLDanmakuLayerCell.h"
@interface MLDanmakuLayerCell ()

@property (nonatomic, strong) NSString *reuseIdentifier;
@property (nonatomic, strong) CALayer *richContentLayer;

@end

@implementation MLDanmakuLayerCell
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [self init]) {
        self.reuseIdentifier = reuseIdentifier;
    }
    return self;
}
- (CGPoint)center {
    return CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
}
- (void)setCenter:(CGPoint)center {
    CGRect oldFrame = self.frame;
    CGFloat x = center.x - CGRectGetWidth(self.frame) * 0.5;
    CGFloat y = center.y - CGRectGetHeight(self.frame) * 0.5;
    self.frame = CGRectMake(x, y, CGRectGetWidth(oldFrame), CGRectGetHeight(oldFrame));
}
- (void)layoutSubContent {
    self.richContentLayer.frame = self.bounds;
}
- (void)prepareForReuse {
    
}
- (CALayer *)richContentLayer {
    if (!_richContentLayer) {
        _richContentLayer = [[CALayer alloc] init];
        [self addSublayer:_richContentLayer];
    }
    return _richContentLayer;
}
- (CALayer *)danmakuAnimationLayer {
    return self;
}
- (void)removeFromSuperContent {
    [self removeFromSuperlayer];
}
- (void)configCellWithModel:(MLDanmakuModel *)model {
    
}
@end
