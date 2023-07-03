//
//  MLDanmakuSource.m
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/21.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import "MLDanmakuSource.h"


@implementation MLDanmakuSource

+ (MLDanmakuSource *)danmakuSourceWithMode:(MLDanmakuMode)mode {
    Class class = mode == MLDanmakuModeVideo ? NSClassFromString(@"MLDanmakuVideoSource"): NSClassFromString(@"MLDanmakuLiveSource");
    return [class new];
}

- (instancetype)init {
    if (self = [super init]) {
        _semaphoreLock = dispatch_semaphore_create(1);
        self.danmakuAgents = [NSMutableArray array];
    }
    return self;
}

- (void)removeDanmakuAgentsAtTimeRange:(MLDanmakuTime)time completion:(void (^)(void))completion {
    NSAssert(NO, @"subClass implementation");
}
- (void)addDanmakus:(NSArray<MLDanmakuModel *> *)danmakus completion:(void (^)(void))completion {
    NSAssert(NO, @"subClass implementation");
}

- (void)sendDanmaku:(MLDanmakuModel *)danmaku forceRender:(BOOL)force {
    NSAssert(NO, @"subClass implementation");
}

- (void)sendDanmakus:(NSArray<MLDanmakuModel *> *)danmakus {
    NSAssert(NO, @"subClass implementation");
}

- (NSArray *)fetchDanmakuAgentsForTime:(MLDanmakuTime)time {
    NSAssert(NO, @"subClass implementation");
    return nil;
}

- (void)reset {
    DanmakuSourceLock();
    self.danmakuAgents = [NSMutableArray array];
    DanmakuSourceUnLock();
}

- (NSArray<MLDanmakuAgent *> *)currentDanmakuAgents {
    NSArray<MLDanmakuAgent *> *currentDanmakuAgents = nil;
    DanmakuSourceLock();
    currentDanmakuAgents = [_danmakuAgents copy];
    DanmakuSourceUnLock();
    return currentDanmakuAgents;
}

@end
