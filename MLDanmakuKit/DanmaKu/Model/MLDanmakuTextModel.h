//
//  MLDanmakuTextModel.h
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/19.
//  Copyright © 2018年 com.baidu. All rights reserved.
//

#import "MLDanmakuModel.h"

@interface MLDanmakuTextModel : MLDanmakuModel

@property (nonatomic, assign) BOOL selfFlag;

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIFont *textFont;

@end
