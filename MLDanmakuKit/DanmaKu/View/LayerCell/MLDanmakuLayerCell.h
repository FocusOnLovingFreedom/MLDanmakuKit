//
//  MLDanmakuLayerCell.h
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/20.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MLDanmakuProtocolCell.h"

@interface MLDanmakuLayerCell : CALayer <MLDanmakuProtocolCell>


@property (nonatomic) MLDanmakuCellSelectionStyle selectionStyle; // default is MLDanmakuCellSelectionStyleNone.

@property (nonatomic, readonly) CALayer *richContentLayer;

@property (nonatomic, readonly) NSString *reuseIdentifier;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;

- (void)prepareForReuse;

@end


