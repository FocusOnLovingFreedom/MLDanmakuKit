//
//  MLDanmakuExtention.m
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/19.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import "MLDanmakuExtention.h"

@implementation NSMutableDictionary (MLDanmakuSafe)
- (void)dk_setObject:(id)object forKey:(NSString *)key {
    if (object == nil || ([key isKindOfClass:[NSString class]] && key.length <= 0)) {
        return;
    }
    [self setObject:object forKey:key];
}
@end

@implementation NSMutableArray (MLDanmakuSafe)

- (id)dk_safeObjectAtIndex:(NSInteger)index {
    if (index >= self.count) {
        return nil;
    }
    return [self objectAtIndex:index];
}
- (void)dk_safeAddObject:(id)object {
    if (object == nil) {
        return;
    }
    [self addObject:object];
}
@end
