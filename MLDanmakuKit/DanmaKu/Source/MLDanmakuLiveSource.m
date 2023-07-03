//
//  MLDanmakuLiveSource.m
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/21.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import "MLDanmakuLiveSource.h"
#import "MLDanmakuAgent.h"
@interface MLDanmakuLiveSource ()

@property (nonatomic, weak) MLDanmakuAgent *lastDanmakuAgent;

@end
@implementation MLDanmakuLiveSource

- (void)addDanmakus:(NSArray<MLDanmakuModel *> *)danmakus completion:(void (^)(void))completion {
    onGlobalThreadAsync(^{
        NSMutableArray *danmakuAgents = [NSMutableArray arrayWithCapacity:danmakus.count];
        [danmakus enumerateObjectsUsingBlock:^(MLDanmakuModel *danmaku, NSUInteger idx, BOOL *stop) {
            MLDanmakuAgent *agent = [[MLDanmakuAgent alloc] initWithDanmakuModel:danmaku];
            [danmakuAgents addObject:agent];
        }];
        NSArray *sortDanmakuAgents = [danmakuAgents sortedArrayUsingSelector:@selector(compare:)];
        DanmakuSourceLock();
        [self.danmakuAgents addObjectsFromArray:sortDanmakuAgents];
        DanmakuSourceUnLock();
        if (completion) {
            completion();
        }
    });
}

- (void)removeDanmakuAgentsAtTimeRange:(MLDanmakuTime)time completion:(void (^)(void))completion {
    // 直播每次都是取完就是释放
    if (completion) {
        completion();
    }
}
- (void)sendDanmaku:(MLDanmakuModel *)danmaku forceRender:(BOOL)force {
    MLDanmakuAgent *danmakuAgent = [[MLDanmakuAgent alloc] initWithDanmakuModel:danmaku];
    danmakuAgent.force = force;
    DanmakuSourceLock();
    [self.danmakuAgents addObject:danmakuAgent];
    DanmakuSourceUnLock();
}

- (void)sendDanmakus:(NSArray<MLDanmakuModel *> *)danmakus {
    onGlobalThreadAsync(^{
        u_int interval = 100;
        NSMutableArray *danmakuAgents = [NSMutableArray arrayWithCapacity:interval];
        NSUInteger lastIndex = danmakus.count - 1;
        [danmakus enumerateObjectsUsingBlock:^(MLDanmakuModel *danmaku, NSUInteger idx, BOOL *stop) {
            MLDanmakuAgent *agent = [[MLDanmakuAgent alloc] initWithDanmakuModel:danmaku];
            [danmakuAgents addObject:agent];
            if (idx == lastIndex || danmakuAgents.count % interval == 0) {
                DanmakuSourceLock();
                [self.danmakuAgents addObjectsFromArray:danmakuAgents];
                DanmakuSourceUnLock();
                [danmakuAgents removeAllObjects];
            }
        }];
    });
}

- (NSArray *)fetchDanmakuAgentsForTime:(MLDanmakuTime)time {
    DanmakuSourceLock();
    NSArray *danmakuAgents = [self.danmakuAgents copy];
    [self.danmakuAgents removeAllObjects];
    DanmakuSourceUnLock();
    return danmakuAgents;
}

@end
