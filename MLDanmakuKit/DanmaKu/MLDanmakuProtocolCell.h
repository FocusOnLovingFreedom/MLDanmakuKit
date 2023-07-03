//
//  MLDanmakuProtocolCell.h
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/20.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLDanmakuDefines.h"
#import "MLDanmakuModel.h"
NS_ASSUME_NONNULL_BEGIN

@protocol MLDanmakuProtocolCell <NSObject>
//system info
@property(nonatomic) CGRect            frame;
@property(nonatomic) CGRect            bounds;
@property(nonatomic) CGPoint           center;      // layer没有center，需要手动处理
@property(getter=isHidden) BOOL hidden;


@property (nonatomic, readonly) NSString *reuseIdentifier;

@property (nonatomic, assign) MLDanmakuCellSelectionStyle selectionStyle; // default is MLDanmakuCellSelectionStyleNone.
/// 初始化
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;
/// 重用
- (void)prepareForReuse;
/// 容器layer
- (CALayer *)danmakuAnimationLayer;
/// 从父视图移除
- (void)removeFromSuperContent;
/// 内部布局
- (void)layoutSubContent;
/// 填充数据
- (void)configCellWithModel:(MLDanmakuModel *)model;
@end

NS_ASSUME_NONNULL_END
