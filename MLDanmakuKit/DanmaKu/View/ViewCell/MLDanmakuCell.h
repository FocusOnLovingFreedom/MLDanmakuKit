//
//  MLDanmakuCell.h
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/19.
//  Copyright © 2020年 MountainLi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MLDanmakuProtocolCell.h"
@interface MLDanmakuCell : UIView <MLDanmakuProtocolCell>

@property (nonatomic) MLDanmakuCellSelectionStyle selectionStyle; // default is MLDanmakuCellSelectionStyleNone.

@property (nonatomic, readonly) UILabel *textLabel;

@property (nonatomic, readonly) NSString *reuseIdentifier;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;

- (void)prepareForReuse;

@end
