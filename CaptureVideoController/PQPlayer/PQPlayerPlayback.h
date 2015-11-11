//
//  PQPlayerPlayback.h
//  Player
//
//  Created by jianting on 14-5-15.
//  Copyright (c) 2014年 jianting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PQPlayerDefines.h"
#import <UIKit/UIKit.h>

@protocol PQPlayerPlayback <NSObject>

- (void)play;
- (void)pause;
- (void)stop;

@property (nonatomic) NSTimeInterval currentPlaybackTime;

@end

@protocol PQPlayerControlDelegate <PQPlayerPlayback>

/**
 * 拖动进度条的时候视频不暂停，时间显示随拖动的进度显示
 * 拖动结束后，时间显示恢复正常，随视频播放的进度
 */

- (void)startSeek;
/**
 * 结束的时候的位置
 */
- (void)endSeekAtValue:(CGFloat)seekValue;
/*
 * 用于控制播放进度的协议
 * seekingValue一般指UISlider等的value值
 */
- (void)setSeekingValue:(CGFloat)seekingValue;

//全屏和退出全屏的协议
- (void)playerViewToFullStyle;
- (void)playerViewToWindowStyle;

@end

