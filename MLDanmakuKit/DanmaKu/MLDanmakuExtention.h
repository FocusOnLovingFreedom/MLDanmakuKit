//
//  MLDanmakuExtention.h
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/19.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import <UIKit/UIKit.h>

static const CGFloat gMLFrameInterval = 0.5;  // 渲染时间间隔
static const CGFloat gMLFaultTolerant = 0.1; // 误差精度
static inline void onMainThreadAsync(void (^block)(void)) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

static inline void onGlobalThreadAsync(void (^block)(void)) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

static inline BOOL checkValidFrame(CGRect frame) {
    return !(isnan(frame.origin.x) || isnan(frame.origin.y) || isnan(frame.size.width) || isnan(frame.size.height));
}

static inline BOOL checkValidPoint(CGPoint point){
    return !(isnan(point.x) || isnan(point.y));
}


@interface NSMutableDictionary (MLDanmakuSafe)
- (void)dk_setObject:(id)object forKey:(NSString *)key;
@end


@interface NSMutableArray (MLDanmakuSafe)
- (id)dk_safeObjectAtIndex:(NSInteger)index;
- (void)dk_safeAddObject:(id)object;
@end
