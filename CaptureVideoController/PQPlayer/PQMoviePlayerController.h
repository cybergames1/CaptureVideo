//
//  PQMoviePlayerController.h
//  Player
//
//  Created by jianting on 14-5-15.
//  Copyright (c) 2014年 jianting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PQPlayerPlayback.h"
#import "PQPlayerView.h"
#import "PQPlayerControl.h"

enum {
    PQMovieControlStyleDefault,
    PQMovieControlStyleNone, //该模式，不显示本事的view，可以自定义view
    PQMovieControlStyleWindow       =   PQPlayerViewModeWindow,
    PQMovieControlStyleFullscreen   =   PQPlayerViewModeFullscreen,
};
typedef NSInteger PQMovieControlStyle;

enum {
    PQMovieLoadStateUnknown     = 0,
    PQMovieLoadStatePlayable    = 1 << 0,
    PQMovieLoadStateStalled     = 1 << 1, //网络出现异常，导致播放暂停
    PQMovieLoadStateStartPlay   = 1 << 2, //刚开始播放
};
typedef NSInteger PQMovieLoadState;

enum {
    PQMovieRepeatModeNone,
    PQMovieRepeatModeOne,
    PQMovieRepeatModeLoop,
};
typedef NSInteger PQMovieRepeatMode;


@interface PQMoviePlayerController : NSObject <PQPlayerControlDelegate,PQPlayerNavBarDelegate>

- (id)initWithContentURL:(NSURL *)url;

//播放timeRange内的视频
- (id)initWithContentURL:(NSURL *)url timeRange:(CMTimeRange)timeRange;

- (void)seekToTime:(NSTimeInterval)seekTime;
- (void)seekToTime:(NSTimeInterval)seekTime completionHandler:(void (^)(BOOL finished))completionHandler;

//播放器所在的view，包括控制条
@property (nonatomic, readonly) UIView *view;

/**
 * 就是全屏还是窗口，默认是PQMovieControlStyleNone
 * 全屏模式是加在UIWindow上的
 */
@property (nonatomic) PQMovieControlStyle controlStyle;

//播放器网络load状态
@property (nonatomic, readonly) PQMovieLoadState loadState;

//循环模式,默认是不循环播放
@property (nonatomic) PQMovieRepeatMode repeatMode;

@property (nonatomic, readonly) BOOL isPlaying;

@end

@interface PQMoviePlayerController (PQMovieProperties)

//视频时长，默认未知时为0.0
@property (nonatomic, readonly) NSTimeInterval duration;

//可播放的时长，一般用于进度下载
@property (nonatomic, readonly) NSTimeInterval playableDuration;

@end

@interface PQMoviePlayerController (PQMovieOrientation)

@property (nonatomic, readonly) UIDeviceOrientation orientation;

@end

@interface PQMoviePlayerController (PQMovieFullScreen)

//是否依据视频尺寸全屏，横屏视频自动横，竖屏视频自动竖
@property (nonatomic) BOOL autoFixVideoSize;

//全屏后是否打开横竖屏旋转
@property (nonatomic) BOOL openDeviceOrientationChange;

@end

@interface PQMoviePlayerController (PQMovieIndicator)

/** 正式播放之前是否展示菊花转,默认是YES **/
@property (nonatomic) BOOL loadIndicatorBeforePlay;

@end

// --------------------------------------------------------------
// Notifications

PQ_EXTERN NSString *const PQMoviePlayerPlaybackDidFinishNotification;
PQ_EXTERN NSString *const PQMoviePlayerPlaybackStateDidChangeNotification;
PQ_EXTERN NSString *const PQMoviePlayerLoadStateDidChangeNotification;

PQ_EXTERN NSString *const PQMoviePlayerWillFullscreenNotification;
PQ_EXTERN NSString *const PQMoviePlayerDidFullscreenNotification;
PQ_EXTERN NSString *const PQMoviePlayerWillWindowNotification;
PQ_EXTERN NSString *const PQMoviePlayerDidWindowNotification;

PQ_EXTERN NSString *const PQMoviePlayerPlaybackProgressNotification;
PQ_EXTERN NSString *const PQMoviePlayerPlaybackDidPlayToEndNotification;

PQ_EXTERN NSString *const PQMoviePlayerDidStopNotifcation;
