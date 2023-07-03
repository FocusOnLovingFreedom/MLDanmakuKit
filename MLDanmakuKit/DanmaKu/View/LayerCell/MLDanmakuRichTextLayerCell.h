//
//  MLDanmakuRichTextLayerCell.h
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/20.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import "MLDanmakuLayerCell.h"
#import "MLDanmakuTextModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface MLDanmakuRichTextLayerCell : MLDanmakuLayerCell
- (void)configCellWithModel:(MLDanmakuTextModel *)model;
@end

NS_ASSUME_NONNULL_END
