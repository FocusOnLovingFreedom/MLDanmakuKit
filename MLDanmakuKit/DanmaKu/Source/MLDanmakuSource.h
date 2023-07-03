//
//  MLDanmakuSource.h
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/21.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLDanmakuExtention.h"

#import "MLDanmakuModel.h"
#import <libkern/OSAtomic.h>
#import <os/lock.h>
@class MLDanmakuAgent;
NS_ASSUME_NONNULL_BEGIN

#define DanmakuSourceLock() dispatch_semaphore_wait(self.semaphoreLock, DISPATCH_TIME_FOREVER)
#define DanmakuSourceUnLock() dispatch_semaphore_signal(self.semaphoreLock)
@interface MLDanmakuSource : NSObject
@property (nonatomic, strong) dispatch_semaphore_t semaphoreLock;
@property (nonatomic, strong) NSMutableArray <MLDanmakuAgent *> *danmakuAgents;

/// 弹幕处理池类型
+ (MLDanmakuSource *)danmakuSourceWithMode:(MLDanmakuMode)mode;

/// 添加弹幕
- (void)addDanmakus:(NSArray<MLDanmakuModel *> *)danmakus completion:(void (^)(void))completion;

/// 发单个弹幕，forceRender 触发强制重绘
- (void)sendDanmaku:(MLDanmakuModel *)danmaku forceRender:(BOOL)force;

/// 发组弹幕
- (void)sendDanmakus:(NSArray<MLDanmakuModel *> *)danmakus;

/// 获取指定时间范围内的弹幕
- (NSArray *)fetchDanmakuAgentsForTime:(MLDanmakuTime)time;

/// 数据重置
- (void)reset;

/// 移除指定时间范围内的数据
- (void)removeDanmakuAgentsAtTimeRange:(MLDanmakuTime)time completion:(nullable  void (^)(void))completion;

/// 获取当前弹幕数据，线程安全
- (NSArray<MLDanmakuAgent *> *)currentDanmakuAgents;
@end


NS_ASSUME_NONNULL_END
