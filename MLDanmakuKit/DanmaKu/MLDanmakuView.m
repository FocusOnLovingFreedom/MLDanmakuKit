//
//  MLDanmakuView.m
//  MLDanmakuKit
//
//  Created by Mountain on 2020/10/19.
//  Copyright © 2020年 MountainLi. All rights reserved.
//

#import "MLDanmakuView.h"
#import "MLDanmakuExtention.h"
#import "MLDanmakuAgent.h"
#import "MLDanmakuTypeRetainer.h"
#import "MLDanmakuContainerView.h"
#import "MLDanmakuEngine.h"
#import "MLRLDanmakuContainerView.h"
#import "MLTBDanmakuContainerView.h"
#pragma mark - MLDanmakuView
//_______________________________________________________________________________________________________________


@interface MLDanmakuView ()<MLDanmakuEngineDelegate, MLDanmakuEngineDataSource>

@property (nonatomic, strong) MLDanmakuConfiguration *configuration;
@property (nonatomic, strong) dispatch_semaphore_t reuseLock;

@property (nonatomic, strong) NSMutableDictionary *cellClassInfo;
@property (nonatomic, strong) NSMutableDictionary *cellReusePool;

@property (nonatomic, weak) MLDanmakuAgent *selectDanmakuAgent;
@property (nonatomic, assign) BOOL changeCellHeightLock;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MLDanmakuContainerView *> *danmakuContainers;
@property (nonatomic, strong) MLDanmakuEngine *engine;
@end

@implementation MLDanmakuView

- (instancetype)initWithFrame:(CGRect)frame configuration:(MLDanmakuConfiguration *)configuration {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.engine = [[MLDanmakuEngine alloc] initConfiguration:configuration];
        self.engine.dataSource = self;
        self.engine.delegate = self;
        self.configuration = configuration;
        self.cellClassInfo = [NSMutableDictionary dictionary];
        self.cellReusePool = [NSMutableDictionary dictionary];
        [[self danmakuLayoutSortArray] enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self containerViewWithType:obj.intValue];
        }];
        self.reuseLock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)resetWithNewConfiguration:(MLDanmakuConfiguration *)configuration {
    [self reset];
    self.engine = [[MLDanmakuEngine alloc] initConfiguration:configuration];
    self.engine.dataSource = self;
    self.engine.delegate = self;
    self.configuration = configuration;
}

- (MLDanmakuContainerView *)containerViewWithType:(MLDanmakuType)danmakuType {
    if (danmakuType == MLDanmakuTypeUnKnown) {
        return nil;
    }
    if (!self.danmakuContainers) {
        self.danmakuContainers = [[NSMutableDictionary alloc] init];
    }
    MLDanmakuContainerView *containerView = [self.danmakuContainers objectForKey:@(danmakuType)];
    if (!containerView) {
        containerView = [[[[self danmakuContainerClassWithType:danmakuType] class] alloc] initWithFrame:self.bounds
                                                                                            danmakuType:danmakuType
                                                                                          configuration:self.configuration];
        [self.danmakuContainers setObject:containerView forKey:@(danmakuType)];
        NSInteger index = [[self danmakuLayoutSortArray] indexOfObject:@(danmakuType)];
        [self insertSubview:containerView atIndex:index];
    }
    return containerView;
}

- (Class)danmakuContainerClassWithType:(MLDanmakuType)danmakuType {
    return [[self containerViewClassMap] objectForKey:@(danmakuType)];
}

- (NSDictionary<NSNumber *, Class> *)containerViewClassMap {
    return @{
        @(MLDanmakuTypeRLFT) : [MLRLDanmakuContainerView class],
        @(MLDanmakuTypeRLFB) : [MLRLDanmakuContainerView class],
        @(MLDanmakuTypeFixFT) : [MLTBDanmakuContainerView class],
        @(MLDanmakuTypeFixFB) : [MLTBDanmakuContainerView class]
    };
}

- (NSArray<NSNumber *> *)danmakuLayoutSortArray {
    return @[
        @(MLDanmakuTypeRLFT),
        @(MLDanmakuTypeRLFB),
        @(MLDanmakuTypeFixFT),
        @(MLDanmakuTypeFixFB)
    ];
}
#pragma mark - public
- (BOOL)isPlaying {
    return self.engine.isPlaying;
}
- (BOOL)isPrepared {
    return self.engine.isPrepared;
}

#pragma mark - reusePool
- (void)registerClass:(Class)cellClass forCellReuseIdentifier:(NSString *)identifier {
    if (!identifier) {
        return;
    }
    self.cellClassInfo[identifier] = cellClass;
}

/// 弹幕复用池
- (id<MLDanmakuProtocolCell>)dequeueReusableCellWithIdentifier:(NSString *)identifier {
    if (!identifier) {
        return nil;
    }
    NSMutableArray *cells = self.cellReusePool[identifier];
    if (cells.count == 0) {
        Class cellClass = self.cellClassInfo[identifier];
        return cellClass ? [[cellClass alloc] initWithReuseIdentifier:identifier]: nil;
    }
    id<MLDanmakuProtocolCell>cell = cells.lastObject;
    [cells removeLastObject];
    [cell prepareForReuse];
    return cell;
}

- (void)recycleCellToReusePool:(id<MLDanmakuProtocolCell>)danmakuCell {
    NSString *identifier = danmakuCell.reuseIdentifier;
    if (!identifier) {
        return;
    }
    NSMutableArray *cells = self.cellReusePool[identifier];
    if (!cells) {
        cells = [NSMutableArray array];
        self.cellReusePool[identifier] = cells;
    }
    [cells addObject:danmakuCell];
}
#pragma mark -

- (void)prepareToShowDanmaKu {
    [self.engine prepare];
    onMainThreadAsync(^{
        if ([self.delegate respondsToSelector:@selector(prepareCompletedWithDanmakuView:)]) {
            [self.delegate prepareCompletedWithDanmakuView:self];
        }
    });
}

- (void)play {
    [self.engine play];
}

- (void)pause {
    [self.engine pause];
}

- (void)stop {
    [self.engine stop];
    [self clearScreen];
}

// 改变不同类型的弹幕的速度
- (void)changeDanmakuType:(MLDanmakuType)danmakuType duration:(CGFloat)duration {
    if (!self.isPrepared) {
        return;
    }
    if ([self.configuration configItemWithType:danmakuType].duration == duration) {
        return;
    }
    [self.configuration configItemWithType:danmakuType].duration = duration;
    NSArray *danmakuAgents = [self visibleDanmakuAgents];
    onMainThreadAsync(^{
        for (MLDanmakuAgent *danmakuAgent in danmakuAgents) {
            if (danmakuAgent.danmakuModel.danmakuType == MLDanmakuTypeRLFT || danmakuAgent.danmakuModel.danmakuType == MLDanmakuTypeRLFB) {
                [danmakuAgent updateDuration:[self.configuration configItemWithType:danmakuAgent.danmakuModel.danmakuType].duration];
            }
        }
    });
}

- (void)changeDanmakuType:(MLDanmakuType)danmakuType displayArea:(CGFloat)displayArea {
    if (!self.isPrepared) {
        return;
    }
    [self.configuration configItemWithType:danmakuType].displayArea = displayArea;
}

- (void)changeDanmakuType:(MLDanmakuType)danmakuType numOfSameTypeOverLayers:(NSUInteger)numOfSameTypeOverLayers {
    if (!self.isPrepared) {
        return;
    }
    [self.configuration configItemWithType:danmakuType].numOfSameTypeOverLayers = numOfSameTypeOverLayers;
}

// 改变轨道高度
- (void)changeCellHeight:(CGFloat)cellHeight {
    if (!self.isPrepared) {
        return;
    }
    if (self.configuration.cellHeight == cellHeight) {
        return;
    }
    self.configuration.cellHeight = cellHeight;
    if (self.changeCellHeightLock) {
        return;
    }
    self.changeCellHeightLock = YES;
    [self.engine cleanAllEngine];
    [self clearScreen];
}

- (void)reset {
    [self stop];
    [self.engine reset];
}

- (void)clearScreen {
    [self.danmakuContainers.allValues enumerateObjectsUsingBlock:^(MLDanmakuContainerView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj clearScreen];
    }];
}

- (void)hideVisibleDanmakusWithBlock:(MLDanmakuForbitConditionDealBlock)conditionDealBlock {
    __weak typeof(self) weakSelf = self;
    [self.engine hideVisibleDanmakusWithBlock:^BOOL(MLDanmakuAgent *danmakuAgent) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (conditionDealBlock && conditionDealBlock(danmakuAgent.danmakuModel)) {
            MLDanmakuContainerView *containerView = [strongSelf containerViewWithType:danmakuAgent.danmakuModel.danmakuType];
            [containerView removeDanmakuAngent:danmakuAgent];
            return YES;
        }
        return NO;
    }];
}

- (void)resetVisibleCellsUIWithBlock:(MLDanmakuResetVisibleCellUIWithBlock)resetUIBlock {
    if (!resetUIBlock) {
        return;
    }
    NSArray *danmakuAgents = [self visibleDanmakuAgents];
    onMainThreadAsync(^{
        for (MLDanmakuAgent *danmakuAgent in danmakuAgents) {
            resetUIBlock(danmakuAgent.danmakuModel, danmakuAgent.danmakuProtocolCell);
        }
    });
}

- (NSSet<MLDanmakuModel *> *)allDanmuModels {
    NSArray<MLDanmakuAgent *> *currentDanmakuAgents = self.engine.danmakuSource.currentDanmakuAgents;
    if (currentDanmakuAgents.count <= 0) {
        return nil;
    }
    NSMutableSet *allDanmuModels = [NSMutableSet setWithCapacity:currentDanmakuAgents.count];
    [currentDanmakuAgents enumerateObjectsUsingBlock:^(MLDanmakuAgent *obj, NSUInteger idx, BOOL *stop) {
        [allDanmuModels addObject:obj.danmakuModel];
    }];
    return [allDanmuModels copy];
}

#pragma mark - MLDanmakuEngineDataSource
- (double)playTimeWithEngine:(MLDanmakuEngine *)danmakuEngine {
    if ([self.dataSource respondsToSelector:@selector(playTimeWithDanmakuView:)]) {
        return [self.dataSource playTimeWithDanmakuView:self];
    }
    return 0;
}

- (BOOL)bufferingWithEngine:(MLDanmakuEngine *)danmakuEngine {
    if ([self.dataSource respondsToSelector:@selector(bufferingWithDanmakuView:)]) {
        return [self.dataSource bufferingWithDanmakuView:self];
    }
    return NO;
}

- (NSInteger)timeIntervalForEachDataCleaning {
    if ([self.dataSource respondsToSelector:@selector(timeIntervalForEachDataCleaning)]) {
        return [self.dataSource timeIntervalForEachDataCleaning];
    }
    return 0;
}
- (NSArray<NSNumber *> *)supportedRenderDanmakuType {
    return [self danmakuLayoutSortArray];
}

#pragma mark - MLDanmakuEngineDelegate
- (void)danmakuEngine:(MLDanmakuEngine *)danmakuEngine didEndDisplayDanmakus:(NSArray<MLDanmakuAgent *> *)disapearDanmakuAgents {
    [self recycleDanmakuAgents:disapearDanmakuAgents completion:nil];
}
- (void)danmakuEngine:(MLDanmakuEngine *)danmakuEngine renderDanmakuAgent:(MLDanmakuAgent *)danmakuAgent {
    danmakuAgent.danmakuProtocolCell = ({
        // 去除复用时的隐式动画
        [CATransaction begin];
        [CATransaction setDisableActions: YES];
        id<MLDanmakuProtocolCell>cell = [self.dataSource danmakuView:self cellForDanmaku:danmakuAgent.danmakuModel];
        if (![cell isKindOfClass:[UIView class]] && ![cell isKindOfClass:[CALayer class]]) {
            NSAssert(NO, @"cellClass must be UIView Class or CALayer Class");
            return;
        }
        if (self.configuration.isUseLayerReplaceView && [cell isKindOfClass:[UIView class]]) {
            NSAssert(NO, @"cellClass is not kind of CALayer Class, please reset 'useLayerReplaceView' value in MLDanmakuConfiguration");
            return;
        }
        if (!self.configuration.isUseLayerReplaceView && [cell isKindOfClass:[CALayer class]]) {
            NSAssert(NO, @"cellClass is not kind of UIView Class, please reset 'useLayerReplaceView' value in MLDanmakuConfiguration");
            return;
        }
        cell.frame = (CGRect){CGPointMake(danmakuAgent.px, danmakuAgent.py), danmakuAgent.size};
        [cell layoutSubContent];
        cell.hidden = NO;
        [CATransaction commit];
        cell;
    });
    if ([self.delegate respondsToSelector:@selector(danmakuView:willDisplayCell:danmaku:)]) {
        [self.delegate danmakuView:self
                   willDisplayCell:danmakuAgent.danmakuProtocolCell
                           danmaku:danmakuAgent.danmakuModel];
    }
    MLDanmakuContainerView *danmakuContainerView = [self containerViewWithType:danmakuAgent.danmakuModel.danmakuType];
    if (self.configuration.isUseLayerReplaceView) {
        CALayer *layer = danmakuContainerView.layer;
        [layer addSublayer:(CALayer *)danmakuAgent.danmakuProtocolCell];
    } else {
        UIView *view = danmakuContainerView;
        [view addSubview:(UIView *)danmakuAgent.danmakuProtocolCell];
    }
    [danmakuContainerView addDanmakuAngent:danmakuAgent];
    [danmakuAgent playAnimation];
    
}
- (void)danmakuEngine:(MLDanmakuEngine *)danmakuEngine
 recycleDanmakuAgents:(NSArray<MLDanmakuAgent *> *)recycleDanmakuAgents
           completion:(void (^)(void))completion{
    __weak typeof(self) weakSelf = self;
    [self recycleDanmakuAgents:recycleDanmakuAgents completion:^{
        if (completion) {
            completion();
        }
        weakSelf.changeCellHeightLock = NO;
    }];
}

- (void)recycleDanmakuAgents:(NSArray *)danmakuAgents completion:(void (^)(void))completion {
    if (danmakuAgents.count == 0) {
        if (completion) {
            completion();
        }
        return;
    }
    onMainThreadAsync(^{
        for (MLDanmakuAgent *danmakuAgent in danmakuAgents) {
            [danmakuAgent stopAnimation];
            [[self containerViewWithType:danmakuAgent.danmakuModel.danmakuType] removeDanmakuAngent:danmakuAgent];
            [self recycleCellToReusePool:danmakuAgent.danmakuProtocolCell];
            if ([self.delegate respondsToSelector:@selector(danmakuView:didEndDisplayCell:danmaku:)]) {
                [self.delegate danmakuView:self
                         didEndDisplayCell:danmakuAgent.danmakuProtocolCell
                                   danmaku:danmakuAgent.danmakuModel];
            }
        }
        if (completion) {
            completion();
        }
    });
}


- (BOOL)renderNewDanmaku:(MLDanmakuAgent *)danmakuAgent forTime:(MLDanmakuTime)time {
    if (![self layoutNewDanmaku:danmakuAgent forTime:time]) {
        return NO;
    }
    return YES;
}
// called before render. return NO will ignore danmaku
- (BOOL)danmakuEngine:(MLDanmakuEngine *)danmakuEngine shouldRenderDanmaku:(MLDanmakuModel *)danmaku {
    if ([self.delegate respondsToSelector:@selector(danmakuView:shouldRenderDanmaku:)]) {
        return [self.delegate danmakuView:self shouldRenderDanmaku:danmaku];
    }
    return YES;
}
#pragma mark - layout
- (BOOL)layoutNewDanmaku:(MLDanmakuAgent *)danmakuAgent forTime:(MLDanmakuTime)time {
    CGFloat width = [self.dataSource danmakuView:self widthForDanmaku:danmakuAgent.danmakuModel];
    if (width <= 0) {
        NSAssert(NO, @"danmaku width should not be zero!!!");
        return NO;
    }
    MLDanmakuContainerView *containerView = [self containerViewWithType:danmakuAgent.danmakuModel.danmakuType];
    return [containerView layoutNewDanmaku:danmakuAgent
                                     width:width
                                   forTime:time];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.configuration.autoLayoutWhenTransformed) {
        return;
    }
    [self.danmakuContainers.allValues enumerateObjectsUsingBlock:^(MLDanmakuContainerView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.frame = self.bounds;
    }];
}
#pragma mark - Touch

- (MLDanmakuAgent *)danmakuAgentAtPoint:(CGPoint)point {
    __block MLDanmakuAgent *danmakuAgent = nil;
    [[self danmakuLayoutSortArray] enumerateObjectsWithOptions:NSEnumerationReverse
                                                    usingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MLDanmakuType danmakuType = [obj intValue];
        MLDanmakuContainerView *containerView = [self containerViewWithType:danmakuType];
        danmakuAgent = [containerView dk_hitTest:point];
        if (danmakuAgent) {
            *stop = YES;
        }
    }];
    return danmakuAgent;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.isUserInteractionEnabled) {
        return [super hitTest:point withEvent:event];
    }
    
    if ([_delegate respondsToSelector:@selector(danmakuView:hitTestSubviewAtPoint:withEvent:)]) {
        UIView *subview = [_delegate danmakuView:self hitTestSubviewAtPoint:point withEvent:event];
        if (subview) {
            return subview;
        }
    }
    
    self.selectDanmakuAgent = nil;
    MLDanmakuAgent *danmakuAgent = [self danmakuAgentAtPoint:point];
    if (danmakuAgent) {
        if (danmakuAgent.danmakuProtocolCell.selectionStyle == MLDanmakuCellSelectionStyleDefault) {
            self.selectDanmakuAgent = danmakuAgent;
            return self;
        }
        if (!self.configuration.isUseLayerReplaceView) {
            CGPoint cellPoint = [self convertPoint:point toView:(UIView *)danmakuAgent.danmakuProtocolCell];
            return [(UIView *)danmakuAgent.danmakuProtocolCell hitTest:cellPoint withEvent:event];
        }
    }
    return self.traverseTouches ? nil: [super hitTest:point withEvent:event];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if (self.selectDanmakuAgent) {
        if ([self.delegate respondsToSelector:@selector(danmakuView:shouldSelectCell:danmaku:)]) {
            BOOL shouldSelect = [self.delegate danmakuView:self shouldSelectCell:self.selectDanmakuAgent.danmakuProtocolCell
                                                   danmaku:self.selectDanmakuAgent.danmakuModel];
            if (!shouldSelect) {
                self.selectDanmakuAgent = nil;
                return;
            }
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if (self.selectDanmakuAgent) {
        CGRect rect = self.selectDanmakuAgent.danmakuProtocolCell.danmakuAnimationLayer.presentationLayer.frame;
        CGPoint touchPoint = [[touches anyObject] locationInView:self];
        if (!CGRectContainsPoint(rect, touchPoint)) {
            self.selectDanmakuAgent = nil;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (self.selectDanmakuAgent) {
        CGRect rect = self.selectDanmakuAgent.danmakuProtocolCell.danmakuAnimationLayer.presentationLayer.frame;
        CGPoint touchPoint = [[touches anyObject] locationInView:self];
        if (CGRectContainsPoint(rect, touchPoint)) {
            if ([self.delegate respondsToSelector:@selector(danmakuView:didSelectCell:danmaku:)]) {
                [self.delegate danmakuView:self
                             didSelectCell:self.selectDanmakuAgent.danmakuProtocolCell
                                   danmaku:self.selectDanmakuAgent.danmakuModel];
            }
            self.selectDanmakuAgent = nil;
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.selectDanmakuAgent = nil;
}

#pragma mark - action

- (void)sendDanmaku:(MLDanmakuModel *)danmaku forceRender:(BOOL)force {
    if (!danmaku) {
        return;
    }
    [self.engine.danmakuSource sendDanmaku:danmaku forceRender:force];
}

- (void)sendDanmakus:(NSArray<MLDanmakuModel *> *)danmakus {
    if (danmakus.count == 0) {
        return;
    }
    [self.engine.danmakuSource sendDanmakus:danmakus];
}

- (void)addDanmakus:(NSArray<MLDanmakuModel *> *)danmakus completion:(void (^)(void))completion {
    if (danmakus.count == 0) {
        return;
    }
    if (!self.isPrepared) {
        [self.engine prepare];
    }
    [self.engine.danmakuSource addDanmakus:danmakus completion:completion];
}

- (MLDanmakuModel *)danmakuForVisibleCell:(id<MLDanmakuProtocolCell>)danmakuCell {
    if (!danmakuCell) {
        return nil;
    }
    NSArray *danmakuAgents = [self visibleDanmakuAgents];
    for (MLDanmakuAgent *danmakuAgent in danmakuAgents) {
        if (danmakuAgent.danmakuProtocolCell == danmakuCell) {
            return danmakuAgent.danmakuModel;
        }
    }
    return nil;
}

- (NSArray *)visibleCells {
    __block NSMutableArray *visibleCells = [NSMutableArray array];
    NSArray<MLDanmakuAgent *> *visibleDanmakuAgents = [self visibleDanmakuAgents];
    [visibleDanmakuAgents enumerateObjectsUsingBlock:^(MLDanmakuAgent * _Nonnull danmakuAgent, NSUInteger idx, BOOL * _Nonnull stop) {
        id<MLDanmakuProtocolCell>cell = danmakuAgent.danmakuProtocolCell;
        if (cell) {
            [visibleCells addObject:cell];
        }
    }];
    return visibleCells;
}

- (NSArray *)visibleDanmakuAgents {
    return self.engine.visibleDanmakuAgents;
}
- (void)dealloc {
#if DEBUG
    NSLog(@"%@ dealloc", NSStringFromClass([self class]));
#endif
    [self clearScreen];
    [_engine clear];
}
@end
