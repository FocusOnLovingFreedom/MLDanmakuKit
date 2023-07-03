//
//  MLDanmakuCell.m
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/19.
//  Copyright © 2020年 MountainLi. All rights reserved.
//

#import "MLDanmakuCell.h"

@interface MLDanmakuCell ()

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) NSString *reuseIdentifier;

@end

@implementation MLDanmakuCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [self init]) {
        self.reuseIdentifier = reuseIdentifier;
    }
    return self;
}

- (void)prepareForReuse {
    
}
- (void)layoutSubContent {
    self.textLabel.frame = self.bounds;
}
- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] initWithFrame:self.bounds];
        [self addSubview:_textLabel];
    }
    return _textLabel;
}
- (CALayer *)danmakuAnimationLayer {
    return self.layer;
}
- (void)removeFromSuperContent {
    [self removeFromSuperview];
}
- (void)configCellWithModel:(MLDanmakuModel *)model {
    
}

@synthesize hidden;

@end
