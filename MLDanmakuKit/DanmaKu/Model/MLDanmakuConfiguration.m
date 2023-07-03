//
//  MLDanmakuConfiguration.m
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/19.
//  Copyright © 2020年 MountainLi. All rights reserved.
//

#import "MLDanmakuConfiguration.h"

@interface MLDanmakuConfigItem ()
@property (nonatomic, assign) MLDanmakuType danmakuType;
@end

@interface MLDanmakuConfiguration ()

@property (nonatomic) MLDanmakuMode danmakuMode;
@property (nonatomic, copy) NSDictionary<NSNumber *, MLDanmakuConfigItem *> *congfigItems;
@end

@implementation MLDanmakuConfiguration

- (instancetype)init {
    return [self initWithDanmakuMode:MLDanmakuModeVideo configItems:nil];
}

- (instancetype)initWithDanmakuMode:(MLDanmakuMode)danmakuMode
                        configItems:(NSDictionary<NSNumber *, MLDanmakuConfigItem *> *)congfigItems{
    if (self = [super init]) {
        self.danmakuMode = danmakuMode;
        self.tolerance = 1.0f;
        self.cellHeight = 30.0f;
        self.minSpacing = 0.0f;
        self.congfigItems = congfigItems;
        self.autoLayoutWhenTransformed = YES;
    }
    return self;
}

- (void)setCellHeight:(CGFloat)cellHeight {
    _cellHeight = cellHeight;
    if (cellHeight <= 0) {
        NSAssert(0, @"弹幕cell高度不能小于等于0");
    }
}

- (MLDanmakuConfigItem *)configItemWithType:(MLDanmakuType)danmakuType {
    return (MLDanmakuConfigItem *)[self.congfigItems objectForKey:@(danmakuType)];
}
@end

@implementation MLDanmakuConfigItem
- (instancetype)init{
    return [self initWithDanmakuType:MLDanmakuTypeUnKnown];
}
- (instancetype)initWithDanmakuType:(MLDanmakuType)danmakuType {
    if (self = [super init]) {
        self.danmakuType = danmakuType;
        self.duration = 5;
        self.numOfSameTypeOverLayers = 1;
        self.displayArea = 1.0;
    }
    return self;
}
- (void)setDisplayArea:(CGFloat)displayArea {
    if (![self checkDisplayAreaValueValid:displayArea]) {
        return;
    }
    _displayArea = displayArea;
}

- (BOOL)checkDisplayAreaValueValid:(CGFloat)displayArea {
    if (displayArea >=0  && displayArea <= 1) {
        return YES;
    }
    return NO;
}

- (void)setNumOfSameTypeOverLayers:(NSUInteger)numOfSameTypeOverLayers {
    if (numOfSameTypeOverLayers < 1) {
        return;
    }
    _numOfSameTypeOverLayers = numOfSameTypeOverLayers;
}
@end
