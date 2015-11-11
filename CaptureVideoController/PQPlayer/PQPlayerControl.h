//
//  PQPlayerControl.h
//  Player
//
//  Created by jianting on 14-5-15.
//  Copyright (c) 2014年 jianting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PQPlayerPlayback.h"
#import "PQProgressView.h"

@interface PQSlider : UISlider

@end

enum {
    PQPlayerViewModeWindow      =   2,
    PQPlayerViewModeFullscreen  =   3,
};
typedef NSInteger PQPlayerViewMode;

@interface PQPlayerControl : UIView

@property (nonatomic, assign) id<PQPlayerControlDelegate> delegate;

/** 缓冲进度 **/
@property (nonatomic, retain) PQProgressView * progressView;
/** 拖动条 **/
@property (nonatomic, retain) PQSlider * progressSlider;
/** 有渐变色的拖动进度条 **/
@property (nonatomic, retain) PQProgressView * playProgressView;
/** 全屏时的播放按钮 **/
@property (nonatomic, retain) UIButton * playButton;
/** 全屏按钮 **/
@property (nonatomic, retain) UIButton * controlStyleButton;
/** 时间Label **/
@property (nonatomic, retain) UILabel * currentTimeLabel;
/** 总时长Label **/
@property (nonatomic, retain) UILabel * totalTimeLabel;
/** 全屏时的时长显示Label **/
@property (nonatomic, retain) UILabel * fullTimeLabel;
 

@property (nonatomic, assign) PQPlayerViewMode viewMode;

@end