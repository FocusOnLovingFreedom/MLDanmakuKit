//
//  MLDanmakuEngine.m
//  MLDanmaKuKit
//
//  Created by Mountain on 2020/11/11.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import "MLDanmakuEngine.h"
#import "MLDanmakuConfiguration.h"
#import "MLDanmakuSource.h"

#if OS_OBJECT_USE_OBJC
#define MLDispatchQueueRelease(__v)
#else
#define MLDispatchQueueRelease(__v) (dispatch_release(__v));
#endif

@interface MLDanmakuEngine ()
@property (nonatomic, strong) MLDanmakuConfiguration *configuration;
@property (nonatomic, strong) dispatch_queue_t renderQueue;
/// 使用信号量作安全锁，兼顾性能与安全
@property (nonatomic, strong) dispatch_semaphore_t reuseLock;
@property (nonatomic, assign) NSUInteger toleranceCount;

@property (nonatomic, strong) MLDanmakuSource *danmakuSource;
@property (nonatomic, strong) NSOperationQueue *sourceQueue;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) MLDanmakuTime playTime;

@property (atomic, assign) BOOL isPrepared;
@property (atomic, assign) BOOL isPlaying;

/// 预取队列
@property (nonatomic, strong) NSMutableArray <MLDanmakuAgent *> *fetchDanmakus;
/// 渲染排队队列
@property (nonatomic, strong) NSMutableArray <MLDanmakuAgent *> *danmakuQueuePool;
/// 渲染队列
@property (nonatomic, strong) NSMutableArray <MLDanmakuAgent *> *renderingDanmakus;


@property (nonatomic, weak) MLDanmakuAgent *selectDanmakuAgent;
@property (nonatomic, assign) MLDanmakuTime playTimeAtRange;

@end

@implementation MLDanmakuEngine
- (instancetype)initConfiguration:(MLDanmakuConfiguration *)configuration {
    self = [super init];
    if (self) {
        self.configuration = configuration;
        self.toleranceCount = (NSUInteger)(fabs(self.configuration.tolerance) / gMLFrameInterval);
        self.toleranceCount = MAX(self.toleranceCount, 1);
        self.fetchDanmakus = [NSMutableArray array];
        self.danmakuQueuePool = [NSMutableArray array];
        self.renderingDanmakus = [NSMutableArray array];

        self.danmakuSource = [MLDanmakuSource danmakuSourceWithMode:configuration.danmakuMode];
        self.sourceQueue = [NSOperationQueue new];
        self.sourceQueue.name = @"com.MountainLi.danmaku.sourceQueue";
        self.sourceQueue.maxConcurrentOperationCount = 1;
        
        self.reuseLock = dispatch_semaphore_create(1);;
        self.renderQueue = dispatch_queue_create("com.mountainli.danmaku.renderQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.renderQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    }
    return self;
}
#pragma mark - handle
- (void)prepare {
    self.isPrepared = YES;
    [self stop];
}

- (void)play {
    if (!self.configuration || ![self checkConfigurationValid]) {
        return;
    }
    if (!self.isPrepared) {
        return;
    }
    if (self.isPlaying) {
        return;
    }
    self.isPlaying = YES;
    [self resumeDisplayingDanmakus];
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
        self.displayLink.frameInterval = 60.0 * gMLFrameInterval;
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    self.displayLink.paused = NO;
}

- (void)pause {
    if (!self.isPlaying) {
        return;
    }
    self.isPlaying = NO;
    self.displayLink.paused = YES;
    [self pauseDisplayingDanmakus];
}

- (void)stop {
    self.isPlaying = NO;
    [self.displayLink invalidate];
    self.displayLink = nil;
    self.playTime = (MLDanmakuTime){0, gMLFrameInterval};
    dispatch_async(self.renderQueue, ^{
        [self.danmakuQueuePool removeAllObjects];
        [self.renderingDanmakus removeAllObjects];
    });
}

- (void)cleanAllEngine {
    self.displayLink.paused = YES;
    NSMutableArray *renderingDanmakus = [[self visibleDanmakuAgents] mutableCopy];
    [self.sourceQueue cancelAllOperations];
    [renderingDanmakus addObjectsFromArray:self.danmakuQueuePool];
    dispatch_async(self.renderQueue, ^{
        [self.danmakuQueuePool removeAllObjects];
        [self.renderingDanmakus removeAllObjects];
    });
    dispatch_suspend(self.renderQueue);
    __weak typeof(self) weakSelf = self;
    if ([self.delegate respondsToSelector:@selector(danmakuEngine:recycleDanmakuAgents:completion:)]) {
        [self.delegate danmakuEngine:self recycleDanmakuAgents:renderingDanmakus completion:^{
            dispatch_resume(weakSelf.renderQueue);
            if (weakSelf.isPlaying) {
                weakSelf.displayLink.paused = NO;
            }
        }];
    }
}

- (void)reset {
    [self.danmakuSource reset];
    self.isPrepared = NO;
}

- (void)pauseDisplayingDanmakus {
    NSArray *danmakuAgents = [self visibleDanmakuAgents];
    onMainThreadAsync(^{
        for (MLDanmakuAgent *danmakuAgent in danmakuAgents) {
            if (danmakuAgent.danmakuModel.danmakuType == MLDanmakuTypeRLFT || danmakuAgent.danmakuModel.danmakuType == MLDanmakuTypeRLFB) {
                [danmakuAgent pauseAnimation];
            }
        }
    });
}

- (void)resumeDisplayingDanmakus {
    NSArray *danmakuAgents = [self visibleDanmakuAgents];
    onMainThreadAsync(^{
        for (MLDanmakuAgent *danmakuAgent in danmakuAgents) {
            if (danmakuAgent.danmakuModel.danmakuType == MLDanmakuTypeRLFT || danmakuAgent.danmakuModel.danmakuType == MLDanmakuTypeRLFB) {
                [danmakuAgent playAnimation];
            }
        }
    });
}

- (BOOL)checkConfigurationValid {
    for (NSNumber *danmakuType in self.configuration.congfigItems.allKeys) {
        if ([self.configuration.congfigItems objectForKey:danmakuType].duration <= 0) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - render
- (void)update {
    MLDanmakuTime time = {0, gMLFrameInterval};
    if ([self.dataSource respondsToSelector:@selector(playTimeWithEngine:)]) {
        time.time = [self.dataSource playTimeWithEngine:self];
        if (fabs(self.playTime.time - time.time) <= gMLFrameInterval) {
            time.time = MLMaxTime(self.playTime);
        }
    }
    if (self.configuration.danmakuMode == MLDanmakuModeVideo && time.time <= 0) {
        return;
    }
    BOOL isBuffering = NO;
    if ([self.dataSource respondsToSelector:@selector(bufferingWithEngine:)]) {
        isBuffering = [self.dataSource bufferingWithEngine:self];
    }
    if (!isBuffering) {
        [self loadDanmakusFromSourceForTime:time];
    }
    [self renderDanmakusForTime:time buffering:isBuffering];
    [self clearOldDataForTime:time];
}

- (void)clearOldDataForTime:(MLDanmakuTime)time {
    if (self.configuration.danmakuMode == MLDanmakuModelive) {
        return;
    }
    if (![self.dataSource respondsToSelector:@selector(timeIntervalForEachDataCleaning)]) {
        return;
    }
    NSInteger cleanDataTimeInterval = [self.dataSource timeIntervalForEachDataCleaning];
    if (cleanDataTimeInterval == 0) {
        return;
    }
    NSInteger location = ((NSInteger)(time.time / cleanDataTimeInterval)) * cleanDataTimeInterval;
    if (MLMaxTime(self.playTimeAtRange) == 0) {
        self.playTimeAtRange = (MLDanmakuTime){location, cleanDataTimeInterval};
    }
    double result = self.playTimeAtRange.time - cleanDataTimeInterval;
    BOOL quickBack = time.time < result;
    BOOL quickForward = time.time > self.playTimeAtRange.time + self.playTimeAtRange.interval + cleanDataTimeInterval;
    if (quickBack || quickForward) { // 快退 或 快进
        MLDanmakuTime deleteTime = {0, MLMaxTime(self.playTimeAtRange)};
        [self.danmakuSource removeDanmakuAgentsAtTimeRange:deleteTime completion:nil];
        self.playTimeAtRange = (MLDanmakuTime){location, cleanDataTimeInterval};
    } else if (time.time > MLMaxTime(self.playTimeAtRange) && time.time <  MLMaxTime(self.playTimeAtRange) + cleanDataTimeInterval) { // 正常播放
        MLDanmakuTime deleteTime = {0, self.playTimeAtRange.time};
        [self.danmakuSource removeDanmakuAgentsAtTimeRange:deleteTime completion:nil];
        self.playTimeAtRange = (MLDanmakuTime){location, cleanDataTimeInterval};
    }
}

- (void)loadDanmakusFromSourceForTime:(MLDanmakuTime)time {
    __weak typeof(self) weakSelf = self;
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSArray <MLDanmakuAgent *> *danmakuAgents = [strongSelf.danmakuSource fetchDanmakuAgentsForTime:time];
        danmakuAgents = [danmakuAgents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"remainingTime <= 0"]];
        for (MLDanmakuAgent *danmakuAgent in danmakuAgents) {
            danmakuAgent.duration = [strongSelf.configuration configItemWithType:danmakuAgent.danmakuModel.danmakuType].duration;
            danmakuAgent.delayTime = danmakuAgent.danmakuModel.time - time.time;
            danmakuAgent.remainingTime = danmakuAgent.duration + danmakuAgent.delayTime;
            danmakuAgent.toleranceCount = strongSelf.toleranceCount;
        }
        [strongSelf.fetchDanmakus removeAllObjects];
        [strongSelf.fetchDanmakus addObjectsFromArray:danmakuAgents];
    }];
    operation.completionBlock = ^{
        dispatch_resume(weakSelf.renderQueue);
    };
    dispatch_suspend(self.renderQueue);
    [self.sourceQueue cancelAllOperations];
    [self.sourceQueue addOperation:operation];
}

- (void)renderDanmakusForTime:(MLDanmakuTime)time buffering:(BOOL)isBuffering {
    dispatch_async(self.renderQueue, ^{
        [self renderDisplayingDanmakusForTime:time];
        if (!isBuffering) {
            [self addFetchDanmakusForTime:time];
            [self renderNewDanmakusForTime:time];
        }
        [self removeExpiredDanmakusForTime:time];
    });
}

- (void)renderDisplayingDanmakusForTime:(MLDanmakuTime)time {
    NSMutableArray *disappearDanmakuAgents = [NSMutableArray arrayWithCapacity:self.renderingDanmakus.count];
    [self.renderingDanmakus enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(MLDanmakuAgent *danmakuAgent, NSUInteger idx, BOOL *stop) {
        [danmakuAgent updateRemainingTime:time.interval];
        if (danmakuAgent.remainingTime <= 0) {
            [disappearDanmakuAgents addObject:danmakuAgent];
        }
    }];
    [self.renderingDanmakus removeObjectsInArray:disappearDanmakuAgents];
    if ([self.delegate respondsToSelector:@selector(danmakuEngine:recycleDanmakuAgents:completion:)]) {
        [self.delegate danmakuEngine:self recycleDanmakuAgents:disappearDanmakuAgents completion:^{
                    
        }];
    }

}

- (void)removeExpiredDanmakusForTime:(MLDanmakuTime)time {
    [self.danmakuQueuePool removeObjectsInArray:self.renderingDanmakus];
    [self.danmakuQueuePool enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(MLDanmakuAgent *danmakuAgent, NSUInteger idx, BOOL *stop) {
        danmakuAgent.toleranceCount --;
        if (danmakuAgent.toleranceCount <= 0) {
            [self.danmakuQueuePool removeObjectAtIndex:idx];
        }
    }];
}

- (void)addFetchDanmakusForTime:(MLDanmakuTime)time {
    NSArray *danmakuAgents = [NSArray arrayWithArray:self.fetchDanmakus];
    if (time.time < self.playTime.time || time.time > MLMaxTime(self.playTime) + self.configuration.tolerance) { // 快进或快退
        [self.danmakuQueuePool removeAllObjects];
    }
    NSArray *danmakuQueuePool = [self.danmakuQueuePool copy];
    for (MLDanmakuAgent *danmakuAgent in danmakuQueuePool) {
        danmakuAgent.duration = [self.configuration configItemWithType:danmakuAgent.danmakuModel.danmakuType].duration;
        danmakuAgent.delayTime = danmakuAgent.danmakuModel.time - time.time;
        danmakuAgent.remainingTime = danmakuAgent.duration + danmakuAgent.delayTime;
    }
    if (danmakuAgents.count > 0) {
        [self.danmakuQueuePool insertObjects:danmakuAgents atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, danmakuAgents.count)]];
    }
    self.playTime = time;
}

- (void)renderNewDanmakusForTime:(MLDanmakuTime)time {
    NSUInteger maxShowCount = self.configuration.maxShowCount > 0 ? self.configuration.maxShowCount : NSUIntegerMax;
    NSMutableDictionary *renderResult = [NSMutableDictionary dictionary];
    NSArray *danmakuQueuePool = [self.danmakuQueuePool copy];
    for (MLDanmakuAgent *danmakuAgent in danmakuQueuePool) {
        NSNumber *retainKey = @(danmakuAgent.danmakuModel.danmakuType);
        if (!danmakuAgent.force) {
            if (self.renderingDanmakus.count > maxShowCount) {
                break;
            }
            __block BOOL isStopRender = YES;
            NSArray<NSNumber *> *supportRenderDanmukuTypes = [self.dataSource supportedRenderDanmakuType];
            [supportRenderDanmukuTypes enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![renderResult[obj] boolValue]) {
                    isStopRender = NO;
                    *stop = YES;
                }
            }];
            if (isStopRender) {
                break;
            }
            if (renderResult[retainKey]) {
                continue;
            }
        }
        BOOL shouldRender = YES;
        if ([self.delegate respondsToSelector:@selector(danmakuEngine:shouldRenderDanmaku:)]) {
            shouldRender = [self.delegate danmakuEngine:self shouldRenderDanmaku:danmakuAgent.danmakuModel];
        }
        if (!shouldRender) {
            continue;
        }
        if (![self.delegate renderNewDanmaku:danmakuAgent forTime:time]) {
            renderResult[retainKey] = @(YES);
        } else {
            danmakuAgent.toleranceCount = 0;
            [self.renderingDanmakus addObject:danmakuAgent];
            onMainThreadAsync(^{
                if ([self.delegate respondsToSelector:@selector(danmakuEngine:renderDanmakuAgent:)]) {
                    [self.delegate danmakuEngine:self renderDanmakuAgent:danmakuAgent];
                }
            });
        }
    }
}

- (void)hideVisibleDanmakusWithBlock:(MLDanmakuEngineHideBlock)conditionDealBlock {
    dispatch_async(self.renderQueue, ^{
        NSMutableArray *disappearDanmakuAgents = [NSMutableArray arrayWithCapacity:self.renderingDanmakus.count];
        NSArray *renderingDanmakus = [self.renderingDanmakus copy];
        [renderingDanmakus enumerateObjectsUsingBlock:^(MLDanmakuAgent *danmakuAgent, NSUInteger idx, BOOL * _Nonnull stop) {
            if (conditionDealBlock && conditionDealBlock(danmakuAgent)) {
                [disappearDanmakuAgents addObject:danmakuAgent];
            }
        }];
        [self.renderingDanmakus removeObjectsInArray:disappearDanmakuAgents];
        if ([self.delegate respondsToSelector:@selector(danmakuEngine:recycleDanmakuAgents:completion:)]) {
            [self.delegate danmakuEngine:self recycleDanmakuAgents:disappearDanmakuAgents completion:nil];
        }
    });
}

- (NSArray *)visibleDanmakuAgents {
    if ([self isRenderQueue]) {
        NSAssert(NO, @"线程死锁了！！！");
        return nil;
    }
    __block NSArray *renderingDanmakus = nil;
    dispatch_sync(self.renderQueue, ^{
        renderingDanmakus = [NSArray arrayWithArray:self.renderingDanmakus];
    });
    return renderingDanmakus;
}

static const char * renderIdentifier;
static dispatch_once_t gOnceToken;
- (BOOL)isRenderQueue {
    dispatch_once(&gOnceToken, ^{
        renderIdentifier = dispatch_queue_get_label(self.renderQueue);
    });
    
    const char *identifier = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
    return strcmp(identifier, renderIdentifier) == 0;
}

- (void)dealloc {
    MLDispatchQueueRelease(self.renderQueue);
    gOnceToken = 0;
}

- (void)clear {
    [self.displayLink invalidate];
    _displayLink = nil;
    dispatch_async(self.renderQueue, ^{
        [self.fetchDanmakus removeAllObjects];
        [self.danmakuQueuePool removeAllObjects];
        [self.renderingDanmakus removeAllObjects];
    });
}
@end
