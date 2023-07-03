//
//  MLDanmakuRichTextLayerCell.m
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/20.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import "MLDanmakuRichTextLayerCell.h"

@interface MLDanmakuRichTextLayerCell ()
@property (nonatomic, strong) CATextLayer *richTextlayer;
@end
@implementation MLDanmakuRichTextLayerCell
- (void)prepareForReuse {
}
- (void)configCellWithModel:(MLDanmakuTextModel *)model {
    self.richTextlayer.string = model.text;
    self.richTextlayer.fontSize = model.textFont.lineHeight;
    self.richTextlayer.foregroundColor = model.textColor.CGColor;
}
- (CATextLayer *)richTextlayer {
    if (!_richTextlayer) {
        _richTextlayer = [[CATextLayer alloc] init];
        [self addSublayer:_richTextlayer];
    }
    return _richTextlayer;
}
- (CALayer *)richContentLayer {
    return self.richTextlayer;
}


@end
