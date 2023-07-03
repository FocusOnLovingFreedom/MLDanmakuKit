//
//  MLDanmakuConfiguration.h
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/19.
//  Copyright © 2020年 MountainLi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MLDanmakuDefines.h"


@interface MLDanmakuConfigItem : NSObject

@property (nonatomic, assign, readonly) MLDanmakuType danmakuType;

// 弹幕显示区域，默认1.0，全局显示
@property (nonatomic, assign) CGFloat displayArea;

// 同种弹幕重叠层数，默认1
@property (nonatomic, assign) NSUInteger numOfSameTypeOverLayers;

// 弹幕速度，默认5s
@property (nonatomic, assign) CGFloat duration;

- (instancetype)initWithDanmakuType:(MLDanmakuType)danmakuType NS_DESIGNATED_INITIALIZER;
@end


@interface MLDanmakuConfiguration : NSObject

@property (readonly) MLDanmakuMode danmakuMode;

@property (nonatomic, copy, readonly) NSDictionary<NSNumber *, MLDanmakuConfigItem *> *congfigItems;

// 弹幕渲染精度，默认1s 误差
@property (nonatomic) CGFloat tolerance;

// 弹幕渲染轨道书， 默认 0 ，全屏渲染
@property (nonatomic) NSInteger numberOfLines;

// 单行弹幕高度， 默认  30.0f
@property (nonatomic) CGFloat cellHeight;

/// 同行弹幕最小间距， 默认 0.f
@property (nonatomic) CGFloat minSpacing;

/// 弹幕最大展现个人，默认 0 ，不限制
@property (nonatomic) NSUInteger maxShowCount;

/// 在容器size发生变化时，是否自适应布局
@property (nonatomic, assign) BOOL autoLayoutWhenTransformed;

/// 使用layer代替view来渲染， 可获得更高的性能，默认NO
@property (nonatomic, assign, getter=isUseLayerReplaceView) BOOL useLayerReplaceView;

- (instancetype)initWithDanmakuMode:(MLDanmakuMode)danmakuMode
                        configItems:(NSDictionary<NSNumber *, MLDanmakuConfigItem *> *)congfigItems NS_DESIGNATED_INITIALIZER;

- (MLDanmakuConfigItem *)configItemWithType:(MLDanmakuType)danmakuType;
@end
