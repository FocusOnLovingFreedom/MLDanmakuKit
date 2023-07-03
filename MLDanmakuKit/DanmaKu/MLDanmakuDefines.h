//
//  MLDanmakuDefines.h
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/19.
//  Copyright © 2020年 MountainLi. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef MLDanmakuDefines_h
#define MLDanmakuDefines_h

typedef NS_ENUM (NSUInteger, MLDanmakuMode) {
    MLDanmakuModeVideo,
    MLDanmakuModelive
};

typedef NS_ENUM (int, MLDanmakuType) {
    MLDanmakuTypeRLFT = 0,              // 从右往左滚动, 从顶往底排布
    MLDanmakuTypeRLFB,              // 从右往左滚动，从底往顶排布
    MLDanmakuTypeFixFT,             // 固定位置，从顶往底排布
    MLDanmakuTypeFixFB,              // 固定位置，从底往顶排布
    MLDanmakuTypeUnKnown
};

typedef struct {
    double time;  // 出现时间
    CGFloat interval;   // 展示时长
} MLDanmakuTime;

NS_INLINE CGFloat MLMaxTime(MLDanmakuTime time) {
    return time.time + time.interval;
}

typedef NS_ENUM(NSInteger, MLDanmakuCellSelectionStyle) { // cell可选中态
    MLDanmakuCellSelectionStyleNone,     // no select.
    MLDanmakuCellSelectionStyleDefault,
};
#endif /* MLDanmakuDefines_h */
