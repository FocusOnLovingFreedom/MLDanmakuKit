//
//  MLDanmakuEngine.h
//  MLDanmaKuKit
//
//  Created by Mountain on 2020/11/11.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLDanmakuAgent.h"
#import "MLDanmakuSource.h"
#import "MLDanmakuConfiguration.h"

typedef BOOL(^MLDanmakuEngineHideBlock)(MLDanmakuAgent *danmakuAgent);
@class MLDanmakuEngine;
@protocol MLDanmakuEngineDataSource <NSObject>
/// 当前的运行时间节点，用于和弹幕和视频内容的匹配
- (double)playTimeWithEngine:(MLDanmakuEngine *)danmakuEngine;

/// 正否正处于视频的加载loading中，会暂停新弹幕的渲染
- (BOOL)bufferingWithEngine:(MLDanmakuEngine *)danmakuEngine;

/// 每隔多长间隔清理一下旧弹幕
- (NSInteger)timeIntervalForEachDataCleaning;

/// 支持的弹幕种类
- (NSArray<NSNumber *> *)supportedRenderDanmakuType;
@end

@protocol MLDanmakuEngineDelegate <NSObject>
@required
/// 是否渲染新的弹幕， 用于布局和碰撞监测等内部判断
- (BOOL)renderNewDanmaku:(MLDanmakuAgent *)danmakuAgent forTime:(MLDanmakuTime)time;

/// 弹幕渲染条件判断通过，回调用于cell和数据的绑定
- (void)danmakuEngine:(MLDanmakuEngine *)danmakuEngine renderDanmakuAgent:(MLDanmakuAgent *)danmakuAgent;

@optional
///  在弹幕正式渲染前回调，用于业务场景, return NO ,则不会渲染该弹幕
- (BOOL)danmakuEngine:(MLDanmakuEngine *)danmakuEngine shouldRenderDanmaku:(MLDanmakuModel *)danmaku;

/// 弹幕回收
- (void)danmakuEngine:(MLDanmakuEngine *)danmakuEngine
 recycleDanmakuAgents:(NSArray<MLDanmakuAgent *> *)recycleDanmakuAgents
           completion:(void (^)(void))completion;
@end


@interface MLDanmakuEngine : NSObject

- (instancetype)initConfiguration:(MLDanmakuConfiguration *)configuration;
@property (nonatomic, strong, readonly) MLDanmakuSource *danmakuSource;
@property (nonatomic, weak) id<MLDanmakuEngineDataSource> dataSource;
@property (nonatomic, weak) id<MLDanmakuEngineDelegate> delegate;
@property (readonly) BOOL isPrepared;
@property (readonly) BOOL isPlaying;
- (void)prepare;
- (void)play;
- (void)pause;
- (void)stop;
/// 将正在展现过程中的弹幕清空
- (void)cleanAllEngine;
/// 引擎重置
- (void)reset;
/// 隐藏已经渲染好的弹幕
- (void)hideVisibleDanmakusWithBlock:(MLDanmakuEngineHideBlock)conditionDealBlock;
/// 目前正在展现的弹幕
- (NSArray *)visibleDanmakuAgents;
/// 清除引擎中的弹幕数据，但仍会保留数据池中的数据
- (void)clear;
@end

