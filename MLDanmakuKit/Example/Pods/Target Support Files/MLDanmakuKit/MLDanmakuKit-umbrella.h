#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "MLDanmaku.h"
#import "MLDanmakuDefines.h"
#import "MLDanmakuEngine.h"
#import "MLDanmakuExtention.h"
#import "MLDanmakuProtocolCell.h"
#import "MLDanmakuView.h"
#import "MLDanmakuAgent.h"
#import "MLDanmakuConfiguration.h"
#import "MLDanmakuModel.h"
#import "MLDanmakuTextModel.h"
#import "MLDanmakuTypeRetainer.h"
#import "MLDanmakuLiveSource.h"
#import "MLDanmakuSource.h"
#import "MLDanmakuVideoSource.h"
#import "MLDanmakuLayerCell.h"
#import "MLDanmakuRichTextLayerCell.h"
#import "MLDanmakuContainerView.h"
#import "MLRLDanmakuContainerView.h"
#import "MLTBDanmakuContainerView.h"
#import "MLDanmakuCell.h"
#import "MLDanmakuTextCell.h"

FOUNDATION_EXPORT double MLDanmakuKitVersionNumber;
FOUNDATION_EXPORT const unsigned char MLDanmakuKitVersionString[];

