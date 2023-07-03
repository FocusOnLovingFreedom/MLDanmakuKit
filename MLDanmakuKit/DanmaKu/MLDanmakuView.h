//
//  MLDanmakuView.h
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/19.
//  Copyright © 2020 MountainLi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MLDanmakuConfiguration.h"
#import "MLDanmakuModel.h"
#import "MLDanmakuProtocolCell.h"

@class MLDanmakuView;
@class MLDanmakuModel;
@class MLDanmakuProtocolCell;
typedef BOOL(^MLDanmakuForbitConditionDealBlock)(MLDanmakuModel *danmakuModel);
typedef void(^MLDanmakuResetVisibleCellUIWithBlock)(MLDanmakuModel *danmakuModel,id<MLDanmakuProtocolCell> cell);
//_______________________________________________________________________________________________________________

@protocol MLDanmakuViewDateSource <NSObject>

@required

/// 返回计算好的弹幕宽度
- (CGFloat)danmakuView:(MLDanmakuView *)danmakuView widthForDanmaku:(MLDanmakuModel *)danmaku;

/// 返回cell实例。 实现改方法  应当调用 MLDanmakuView的  dequeueReusableCellWithIdentifier
- (id<MLDanmakuProtocolCell>)danmakuView:(MLDanmakuView *)danmakuView cellForDanmaku:(MLDanmakuModel *)danmaku;

@optional

/// 当前的播放时间，以秒为单位
- (double)playTimeWithDanmakuView:(MLDanmakuView *)danmakuView;

/// 正否正处于视频的加载loading中，返回YES,  会暂停新弹幕的渲染
- (BOOL)bufferingWithDanmakuView:(MLDanmakuView *)danmakuView;

/// 旧弹幕的清理时间间隔
- (NSInteger)timeIntervalForEachDataCleaning;

@end

@protocol MLDanmakuViewDelegate <NSObject>

@optional

/// 弹幕引擎准备完成， 可在该方法回调 启动弹幕引擎
- (void)prepareCompletedWithDanmakuView:(MLDanmakuView *)danmakuView;

/// 渲染前调用， returen NO 会略过该弹幕的渲染
- (BOOL)danmakuView:(MLDanmakuView *)danmakuView shouldRenderDanmaku:(MLDanmakuModel *)danmaku;

/// 弹幕展现时机回调
- (void)danmakuView:(MLDanmakuView *)danmakuView willDisplayCell:(id<MLDanmakuProtocolCell>)cell danmaku:(MLDanmakuModel *)danmaku;
- (void)danmakuView:(MLDanmakuView *)danmakuView didEndDisplayCell:(id<MLDanmakuProtocolCell>)cell danmaku:(MLDanmakuModel *)danmaku;

/// 弹幕选中时机回调
- (BOOL)danmakuView:(MLDanmakuView *)danmakuView shouldSelectCell:(id<MLDanmakuProtocolCell>)cell danmaku:(MLDanmakuModel *)danmaku;
- (void)danmakuView:(MLDanmakuView *)danmakuView didSelectCell:(id<MLDanmakuProtocolCell>)cell danmaku:(MLDanmakuModel *)danmaku;

/// 点击事件回传，便于业务侧处理业务
- (UIView *)danmakuView:(MLDanmakuView *)danmakuView hitTestSubviewAtPoint:(CGPoint)point withEvent:(UIEvent *)event;
@end

//_______________________________________________________________________________________________________________

@protocol MLDanmakuViewDateSource;
@interface MLDanmakuView : UIView

@property (nonatomic, weak) id <MLDanmakuViewDateSource> dataSource;
@property (nonatomic, weak) id <MLDanmakuViewDelegate> delegate;

@property (readonly) MLDanmakuConfiguration *configuration;
@property (readonly) BOOL isPrepared;
@property (readonly) BOOL isPlaying;

// 弹幕点击是否可穿透
@property (nonatomic, assign) BOOL traverseTouches;

- (instancetype)initWithFrame:(CGRect)frame configuration:(MLDanmakuConfiguration *)configuration;

/// 弹幕配置重置， 在调用之前请先确认 prepareToShowDanmaKu 已经被调用
- (void)resetWithNewConfiguration:(MLDanmakuConfiguration *)configuration;

/// 注册cell
- (void)registerClass:(Class)cellClass forCellReuseIdentifier:(NSString *)identifier;
- (__kindof id<MLDanmakuProtocolCell>)dequeueReusableCellWithIdentifier:(NSString *)identifier;

- (__kindof MLDanmakuModel *)danmakuForVisibleCell:(id<MLDanmakuProtocolCell>)danmakuCell; // returns nil if cell is not visible
@property (nonatomic, readonly) NSArray<__kindof id<MLDanmakuProtocolCell>> *visibleCells;

- (void)prepareToShowDanmaKu;

/// 调用前，请确认prepareToShowDanmaKu 已被调用，不然不会有任何响应
- (void)play;
- (void)pause;
- (void)stop;

// 改变弹幕速度
- (void)changeDanmakuType:(MLDanmakuType)danmakuType duration:(CGFloat)duration;

// 改变弹幕显示区域
- (void)changeDanmakuType:(MLDanmakuType)danmakuType displayArea:(CGFloat)displayArea;

/// 改变同种弹幕重叠层数
- (void)changeDanmakuType:(MLDanmakuType)danmakuType numOfSameTypeOverLayers:(NSUInteger)numOfSameTypeOverLayers;

/// 改变弹幕高度
- (void)changeCellHeight:(CGFloat)cellHeight;

/// 重置所有弹幕，  再次播放之前 请确认 prepareToShowDanmaKu 已被调用
- (void)reset;
- (void)clearScreen;

/* 强制渲染弹幕，调用该方法后会忽略各种限制，强制渲染。 一般用于渲染自己发送的本地弹幕
   远端的弹幕 最好使用 sendDanmakus 方法
 */
- (void)sendDanmaku:(MLDanmakuModel *)danmaku forceRender:(BOOL)force;
- (void)sendDanmakus:(NSArray<MLDanmakuModel *> *)danmakus;

- (void)addDanmakus:(NSArray<MLDanmakuModel *> *)danmakus completion:(void (^)(void))completion;

/// 隐藏正在展现过程中的弹幕，  block 可能会回调很多次
- (void)hideVisibleDanmakusWithBlock:(MLDanmakuForbitConditionDealBlock)conditionDealBlock;

// 重置可见弹幕的UI, 但最好别修改该弹幕的尺寸
- (void)resetVisibleCellsUIWithBlock:(MLDanmakuResetVisibleCellUIWithBlock)resetUIBlock;

/// 数据池中所有的弹幕数据
- (NSSet<MLDanmakuModel *> *)allDanmuModels;
@end
