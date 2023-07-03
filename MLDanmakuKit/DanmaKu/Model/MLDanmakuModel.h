//
//  MLDanmakuModel.h
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/19.
//  Copyright © 2020年 MountainLi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MLDanmakuDefines.h"

@interface MLDanmakuModel : NSObject

@property (readonly) MLDanmakuType danmakuType;

// 单位秒，直播可传 0
@property (nonatomic) double time;

- (instancetype)initWithType:(MLDanmakuType)danmakuType NS_DESIGNATED_INITIALIZER;

@end
