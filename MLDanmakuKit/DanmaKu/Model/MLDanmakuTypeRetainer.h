//
//  MLDanmakuTypeRetainer.h
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/22.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLDanmakuDefines.h"
@class MLDanmakuAgent;
@interface MLDanmakuTypeRetainer : NSObject

- (instancetype _Nonnull )initWithOverLayerNum:(NSUInteger)overLayerNum;

- (NSMutableDictionary <NSNumber *, MLDanmakuAgent *> * _Nullable)retainerWithLayerIndex:(NSInteger)layerIndex;

- (void)removeAllObjects;
@end

