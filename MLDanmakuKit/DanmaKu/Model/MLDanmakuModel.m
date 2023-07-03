//
//  MLDanmakuModel.m
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/19.
//  Copyright © 2020年 MountainLi. All rights reserved.
//

#import "MLDanmakuModel.h"

@interface MLDanmakuModel ()

@property (nonatomic) MLDanmakuType danmakuType;

@end

@implementation MLDanmakuModel

-(instancetype)init {
    return [self initWithType:MLDanmakuTypeRLFT];
}

-(instancetype)initWithType:(MLDanmakuType)danmakuType {
    if (self = [super init]) {
        self.danmakuType = danmakuType;
    }
    return self;
}

@end
