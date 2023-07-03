//
//  MLDanmakuTypeRetainer.m
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/22.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import "MLDanmakuTypeRetainer.h"
#import "MLDanmakuExtention.h"
#import "MLDanmakuAgent.h"
@interface MLDanmakuTypeRetainer ()
@property (nonatomic, strong) NSMutableArray<NSMutableDictionary <NSNumber *, MLDanmakuAgent *> *> *retainers;
@end
@implementation MLDanmakuTypeRetainer
- (instancetype)initWithOverLayerNum:(NSUInteger)overLayerNum {
    self = [super init];
    if (self) {
        self.retainers = [[NSMutableArray alloc] init];
    }
    return self;
}
- (NSMutableDictionary <NSNumber *, MLDanmakuAgent *> * _Nullable )retainerWithLayerIndex:(NSInteger)layerIndex {
    NSMutableDictionary *retainerDict = [self.retainers dk_safeObjectAtIndex:layerIndex];
    if (!retainerDict) {
        retainerDict = [NSMutableDictionary dictionary];
        [self.retainers addObject:retainerDict];
    }
    return retainerDict;
}
- (void)removeAllObjects {
    [self.retainers removeAllObjects];
}
@end
