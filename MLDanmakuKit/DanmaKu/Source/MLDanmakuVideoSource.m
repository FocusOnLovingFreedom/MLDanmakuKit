//
//  MLDanmakuVideoSource.m
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/21.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import "MLDanmakuVideoSource.h"
#import "MLDanmakuAgent.h"
@interface MLDanmakuVideoSource ()

@property (nonatomic, weak) MLDanmakuAgent *lastDanmakuAgent;

@end
@implementation MLDanmakuVideoSource

- (void)removeDanmakuAgentsAtTimeRange:(MLDanmakuTime)time completion:(void (^)(void))completion {
    onGlobalThreadAsync(^{
        double minTime = floor(time.time * 10) / 10.0f - gMLFaultTolerant;
        double maxTime = MLMaxTime(time) + gMLFaultTolerant;
        DanmakuSourceLock();
        NSIndexSet *indexSet = [self.danmakuAgents indexesOfObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.danmakuAgents.count)]
                                                                     options:NSEnumerationConcurrent
                                                                 passingTest:^BOOL(MLDanmakuAgent *danmakuAgent, NSUInteger idx, BOOL *stop) {
            if (danmakuAgent.danmakuModel.time > maxTime) {
                *stop = YES;
            }
            return danmakuAgent.remainingTime <= 0 && danmakuAgent.danmakuModel.time >= minTime && danmakuAgent.danmakuModel.time < maxTime;
        }];
        if (indexSet.count == 0) {
            DanmakuSourceUnLock();
            if (completion) {
                completion();
            }
            return;
        }
        [self.danmakuAgents removeObjectsAtIndexes:indexSet];
        DanmakuSourceUnLock();
        if (completion) {
            completion();
        }
    });
}

- (void)addDanmakus:(NSArray<MLDanmakuModel *> *)danmakus completion:(void (^)(void))completion {
    onGlobalThreadAsync(^{
        NSMutableArray *danmakuAgents = [NSMutableArray arrayWithCapacity:danmakus.count];
        [danmakus enumerateObjectsUsingBlock:^(MLDanmakuModel *danmaku, NSUInteger idx, BOOL *stop) {
            MLDanmakuAgent *agent = [[MLDanmakuAgent alloc] initWithDanmakuModel:danmaku];
            [danmakuAgents addObject:agent];
        }];
        NSArray *sortDanmakuAgents = [danmakuAgents sortedArrayUsingSelector:@selector(compare:)];
        MLDanmakuAgent *sortFirstDanmakuAgent = sortDanmakuAgents.firstObject;
        DanmakuSourceLock();
        MLDanmakuAgent *currentLastAgent = self.danmakuAgents.lastObject;
        DanmakuSourceUnLock();
        // 正常的时间排序
        if (!currentLastAgent || currentLastAgent.danmakuModel.time <= sortFirstDanmakuAgent.danmakuModel.time) {
            DanmakuSourceLock();
            [self.danmakuAgents addObjectsFromArray:sortDanmakuAgents];
            DanmakuSourceUnLock();
        } else { // 因为清理部分数据，导致数据混乱，重新排序
            DanmakuSourceLock();
            NSMutableArray *danmakuAgentsCopyArray = [self.danmakuAgents mutableCopy];
            DanmakuSourceUnLock();
            
            [danmakuAgentsCopyArray addObjectsFromArray:sortDanmakuAgents];
            NSArray *finalSortArray = [danmakuAgentsCopyArray sortedArrayUsingSelector:@selector(compare:)];
            
            DanmakuSourceLock();
            self.danmakuAgents = [finalSortArray mutableCopy];
            DanmakuSourceUnLock();
        }
        if (completion) {
            completion();
        }
    });
}


- (void)sendDanmaku:(MLDanmakuModel *)danmaku forceRender:(BOOL)force {
    MLDanmakuAgent *danmakuAgent = [[MLDanmakuAgent alloc] initWithDanmakuModel:danmaku];
    danmakuAgent.force = force;
    DanmakuSourceLock();
    NSUInteger index = [self indexOfDanmakuAgent:danmakuAgent];
    [self.danmakuAgents insertObject:danmakuAgent atIndex:index];
    DanmakuSourceUnLock();
}

- (NSUInteger)indexOfDanmakuAgent:(MLDanmakuAgent *)danmakuAgent {
    NSUInteger count = self.danmakuAgents.count;
    if (count == 0) {
        return 0;
    }
    NSUInteger index = [self.danmakuAgents indexOfObjectPassingTest:^BOOL(MLDanmakuAgent *tempDanmakuAgent, NSUInteger idx, BOOL *stop) {
        return danmakuAgent.danmakuModel.time <= tempDanmakuAgent.danmakuModel.time;
    }];
    if (index == NSNotFound) {
        return count;
    }
    return index;
}

- (void)sendDanmakus:(NSArray<MLDanmakuModel *> *)danmakus {
    onGlobalThreadAsync(^{
        DanmakuSourceLock();
        NSMutableArray *danmakuAgents = [NSMutableArray arrayWithArray:self.danmakuAgents];
        DanmakuSourceUnLock();
        [danmakus enumerateObjectsUsingBlock:^(MLDanmakuModel *danmaku, NSUInteger idx, BOOL *stop) {
            MLDanmakuAgent *danmakuAgent = [[MLDanmakuAgent alloc] initWithDanmakuModel:danmaku];
            [danmakuAgents addObject:danmakuAgent];
        }];
        NSArray *sortDanmakuAgents = [danmakuAgents sortedArrayUsingSelector:@selector(compare:)];
        DanmakuSourceLock();
        [self.danmakuAgents addObjectsFromArray:sortDanmakuAgents];
        DanmakuSourceUnLock();
    });
}

- (NSArray *)fetchDanmakuAgentsForTime:(MLDanmakuTime)time {
    DanmakuSourceLock();
    if (self.danmakuAgents.count <= 0) {
        DanmakuSourceUnLock();
        return nil;
    }
    NSUInteger lastIndex = [self indexOfDanmakuAgent:self.lastDanmakuAgent];
    MLDanmakuAgent *lastDanmakuAgent = self.lastDanmakuAgent;
    if (!lastDanmakuAgent || time.time < lastDanmakuAgent.danmakuModel.time) {
        lastIndex = 0;
    }
    double minTime = floor(time.time * 10) / 10.0f - gMLFaultTolerant;
    double maxTime = MLMaxTime(time) + gMLFaultTolerant;
    NSIndexSet *indexSet = [self.danmakuAgents indexesOfObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(lastIndex, self.danmakuAgents.count - lastIndex)]
                                                                 options:NSEnumerationConcurrent
                                                             passingTest:^BOOL(MLDanmakuAgent *danmakuAgent, NSUInteger idx, BOOL *stop) {
        if (danmakuAgent.danmakuModel.time > maxTime) {
            *stop = YES;
        }
        return danmakuAgent.remainingTime <= 0 && danmakuAgent.danmakuModel.time >= minTime && danmakuAgent.danmakuModel.time < maxTime;
    }];
    if (indexSet.count == 0) {
        self.lastDanmakuAgent = nil;
        DanmakuSourceUnLock();
        return nil;
    }
    NSArray *danmakuAgents = [self.danmakuAgents objectsAtIndexes:indexSet];
    self.lastDanmakuAgent = danmakuAgents.firstObject;
    DanmakuSourceUnLock();
    return danmakuAgents;
}

- (void)reset {
    [super reset];
    self.lastDanmakuAgent = nil;
}

@end
