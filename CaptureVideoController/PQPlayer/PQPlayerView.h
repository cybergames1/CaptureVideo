//
//  PQPlayerView.h
//  Player
//
//  Created by jianting on 14-5-15.
//  Copyright (c) 2014年 jianting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "PQPlayerControl.h"
#import "PQPlayerNavBar.h"
#import "PQPlayerDefines.h"
#import "PQActivityIndicatorView.h"

@interface PQPlayerView : UIView

@property (nonatomic, retain) AVPlayer * player;
@property (nonatomic, assign) id<PQPlayerControlDelegate,PQPlayerNavBarDelegate> delegate;

@property (nonatomic, retain) PQPlayerNavBar *playerNavbar;
@property (nonatomic, retain) PQPlayerControl *playerControl;
@property (nonatomic, retain) UIImageView *playIcon;
@property (nonatomic, retain) PQProgressView * progressView;
@property (nonatomic, assign) PQPlayerViewMode viewMode;

//网络异常时，菊花转
@property (nonatomic, retain) PQActivityIndicatorView * indicatorView;

//视频播放成功开始启动隐藏控制条的timer
- (void)openControlTimer;
- (void)closeControlTimer;

- (void)showControl;
- (void)hideControl;

- (void)setIsPause:(BOOL)isPause;

@end
