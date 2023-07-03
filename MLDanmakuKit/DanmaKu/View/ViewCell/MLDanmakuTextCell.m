//
//  MLDanmakuTextCell.m
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/19.
//  Copyright © 2018年 com.baidu. All rights reserved.
//

#import "MLDanmakuTextCell.h"

@implementation MLDanmakuTextCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.textLabel.layer.borderWidth = 0;
    self.textLabel.layer.cornerRadius = 0;
}

- (void)configCellWithModel:(MLDanmakuTextModel *)model {
    self.textLabel.font = model.textFont;
    self.textLabel.textColor = model.textColor;
    self.textLabel.text = model.text;
    self.textLabel.textAlignment = NSTextAlignmentCenter;
}

@end
