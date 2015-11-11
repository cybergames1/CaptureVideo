//
//  PQMoviePlayerController.m
//  Player
//
//  Created by jianting on 14-5-15.
//  Copyright (c) 2014年 jianting. All rights reserved.
//

#import "PQMoviePlayerController.h"
#import <MobileCoreServices/MobileCoreServices.h>
/* Notifications */
NSString *const PQMoviePlayerPlaybackDidFinishNotification = @"PQMoviePlayerPlaybackDidFinishNotification";
NSString *const PQMoviePlayerPlaybackStateDidChangeNotification = @"PQMoviePlayerPlaybackStateDidChangeNotification";
NSString *const PQMoviePlayerLoadStateDidChangeNotification = @"PQMoviePlayerLoadStateDidChangeNotification";

NSString *const PQMoviePlayerWillFullscreenNotification = @"PQMoviePlayerWillFullscreenNotification";
NSString *const PQMoviePlayerDidFullscreenNotification = @"PQMoviePlayerDidFullscreenNotification";
NSString *const PQMoviePlayerWillWindowNotification = @"PQMoviePlayerWillWindowNotification";
NSString *const PQMoviePlayerDidWindowNotification = @"PQMoviePlayerDidWindowNotification";

NSString *const PQMoviePlayerPlaybackProgressNotification = @"PQMoviePlayerPlaybackProgressNotification";
NSString *const PQMoviePlayerPlaybackDidPlayToEndNotification = @"PQMoviePlayerPlaybackDidPlayToEndNotification";

NSString *const PQMoviePlayerDidStopNotifcation = @"PQMoviePlayerDidStopNotifcation";

/* AVPlayerItem Keys */
NSString * const kPlayerItemStatusKey = @"status";
NSString * const kPlayerItemLoadedTimeRangesKey = @"loadedTimeRanges";

/* AVPlayer Keys */
NSString * const kPlayerRateKey = @"rate";

static void *AVPlayerPlaybackStatusObservationContext = &AVPlayerPlaybackStatusObservationContext;
static void *AVPlayerLoadedTimeRangesObservationContext = &AVPlayerLoadedTimeRangesObservationContext;
static void *AVPlayerRateObservationContext = &AVPlayerRateObservationContext;

/* Notification type */
enum{
    PQMoviePlayerNotificationLoadStateDidChange,
    PQMoviePlayerNotificationPlaybackStateDidChange,
    PQMoviePlayerNotificationplaybackDidFinish,
    PQMoviePlayerNotificationplaybackDidPlayToEnd,
    
    PQMoviePlayerNotificationWillFullscreen,
    PQMoviePlayerNotificationDidFullscreen,
    PQMoviePlayerNotificationWillWindow,
    PQMoviePlayerNotificationDidWindow,
    
    PQMoviePlayerNotificationplaybackProgress,
};
typedef NSInteger PQMoviePlayerNotificationType;

@interface PQMoviePlayerController ()<UIAlertViewDelegate>
{
    PQPlayerView * _playerView;
    CGRect _fixFrame;
    
    UIView * _backgroundView;
    
    id _playbackTimeObserver;
    
    NSTimeInterval _duration;
    NSTimeInterval _playableDuration;
    
    //记录下device的方向，用于player当device是平放的时候来按照之前的方向转
    UIDeviceOrientation _remarkDeviceOrientation;
    
    BOOL _isLoadingMovie;
    
    //用于控制一次循环播放
    BOOL _isRepeat;
    
    //网络延时计数，当网络出问题时开始计数，超过20秒则任务视频播放失败
    NSInteger _playerStalledCount;
    
    BOOL _deviceNotificationIsWork;
    
    CGSize _videoSize;
    
    BOOL _autoFixVideoSize;
    BOOL _openDeviceOrientationChange;
    BOOL _loadIndicatorBeforePlay;
    
    //拖动进度条时，进度条不随播放进度变化而变化
    BOOL _isSeeking;
}

@property (nonatomic) CGRect identifyFrame;
@property (nonatomic, retain) UIView * identifyView;

@property (nonatomic, retain) NSTimer *playbackStalledTimer;

@property (nonatomic, assign) CMTimeRange clipRange;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) AVPlayerItem * playerItem;

@end

@implementation PQMoviePlayerController

@synthesize currentPlaybackTime = _currentPlaybackTime;
@synthesize identifyView = _identifyView;

+ (CGRect)fixRect:(CGRect)originalRect fromView:(UIView *)view
{
    UIView * referenceView = view.superview;
    while ((referenceView != nil) && ![referenceView isKindOfClass:[UIWindow class]]){
        referenceView = referenceView.superview;
    }
    
    CGRect newRect = originalRect;
    if ([referenceView isKindOfClass:[UIWindow class]])
    {
        UIWindow * myWindow = (UIWindow*)referenceView;
        newRect = [view convertRect:newRect toView:myWindow];
    }
    
    return newRect;
}

+ (NSString *)convertDuration:(CGFloat)duration
{
    int newDuration = (int)(duration + 0.5);
    
    if (duration <= 0.0) return @"00:00";
    
    int h = newDuration / 3600;
    int m = (newDuration % 3600) / 60;
    int s = newDuration % 60;
    
    if (h > 0)
    {
        return [NSString stringWithFormat:@"%@:%@:%@",[self convertNumber:h],[self convertNumber:m],[self convertNumber:s]];
    }
    
    return [NSString stringWithFormat:@"%@:%@",[self convertNumber:m],[self convertNumber:s]];
}

+ (NSString *)convertNumber:(NSInteger)number
{
    if (number < 10)
    {
        return [NSString stringWithFormat:@"0%ld",(long)number];
    }
    
    return [NSString stringWithFormat:@"%ld",(long)number];
}

+ (BOOL)systemVersionLowIOS8
{
    if (NSOrderedAscending == [[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch])
        return YES;
    else
        return NO;
}

+ (AVAssetTrack *)videoTrackWithAsset:(AVAsset *)asset
{
    AVAssetTrack *videoTrack = nil;
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if ([videoTracks count]){
        videoTrack = [videoTracks objectAtIndex:0];
    }
    return videoTrack;
}

+ (CGSize)videoSizeWithAsset:(AVAsset *)asset
{
    CGSize videoSize = CGSizeZero;
    
    AVAssetTrack *videoTrack = nil;
    
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if ([videoTracks count])
    {
        videoTrack = [videoTracks objectAtIndex:0];
    }
    
    if (videoTrack){
        CGAffineTransform assetTransform = videoTrack.preferredTransform;
        CGSize realSize = CGSizeApplyAffineTransform(videoTrack.naturalSize, assetTransform);
        videoSize = CGSizeMake(fabs(realSize.width), fabs(realSize.height));
    }
    return videoSize;
}

- (void)dealloc
{
    if (_playbackTimeObserver)
    {
        [self stop];
    }
    
    [_playerView           release];
    [_backgroundView       release];
    [_identifyView         release];
    [_playbackStalledTimer release];
    [_playerItem           release];
    _playerView             =   nil;
    _backgroundView         =   nil;
    _identifyView           =   nil;
    _playbackStalledTimer   =   nil;
    _playerItem             =   nil;
    
    [super dealloc];
}

- (void)removePlayerObserver
{
    if (_openDeviceOrientationChange)
    {
        [self stopDeviceOrientationChangeNotification];
    }
    
    if (_playbackTimeObserver)
    {
        [_playerView.player removeTimeObserver:_playbackTimeObserver];
        _playbackTimeObserver = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:_playerView.player.currentItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerView.player.currentItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if (_playerItem)
    {
        [_playerItem removeObserver:self forKeyPath:kPlayerItemLoadedTimeRangesKey context:AVPlayerLoadedTimeRangesObservationContext];
        [_playerItem removeObserver:self forKeyPath:kPlayerItemStatusKey context:AVPlayerPlaybackStatusObservationContext];
    }
    
    [_playerView.player removeObserver:self forKeyPath:kPlayerRateKey context:AVPlayerRateObservationContext];
}

- (id)initWithContentURL:(NSURL *)url
{
    return [self initWithContentURL:url timeRange:kCMTimeRangeZero];
}

- (id)initWithContentURL:(NSURL *)url timeRange:(CMTimeRange)timeRange
{
    self = [super init];
    
    if (self)
    {
        self.url = url;
        _playerView = [[PQPlayerView alloc] init];
        [_playerView setDelegate:self];
        [_playerView setContentMode:UIViewContentModeScaleAspectFit];
        if (url == nil || url.absoluteString.length == 0)
        {
            [self showURLErrorAlert];
            return self;
        }
        
        _videoSize = [PQMoviePlayerController videoSizeWithAsset:[AVURLAsset URLAssetWithURL:url options:nil]];
        
        AVPlayerItem *playerItem = [self playerItemWithURL:url timeRange:timeRange];
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
        self.playerItem = playerItem;
        
        [_playerItem addObserver:self forKeyPath:kPlayerItemStatusKey options:NSKeyValueObservingOptionNew context:AVPlayerPlaybackStatusObservationContext];
        [_playerItem addObserver:self forKeyPath:kPlayerItemLoadedTimeRangesKey options:NSKeyValueObservingOptionNew context:AVPlayerLoadedTimeRangesObservationContext];
        [player addObserver:self forKeyPath:kPlayerRateKey options:NSKeyValueObservingOptionNew context:AVPlayerRateObservationContext];
        
        [_playerView setPlayer:player];
        [[_playerView player] setAllowsExternalPlayback:YES];
        [(AVPlayerLayer *)[_playerView layer] setVideoGravity:AVLayerVideoGravityResizeAspect];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemStalled:) name:AVPlayerItemPlaybackStalledNotification object:playerItem];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        self.controlStyle = PQMovieControlStyleDefault;
        
        _currentPlaybackTime = 0.0;
        _duration = 0.0;
        _playableDuration = 0.0;
        _remarkDeviceOrientation = UIDeviceOrientationPortrait;
        _loadState = PQMovieLoadStateUnknown;
        _repeatMode = PQMovieRepeatModeNone;
        _isRepeat = NO;
        _playerStalledCount = 0;
        _deviceNotificationIsWork = NO;
        _autoFixVideoSize = NO;
        _openDeviceOrientationChange = YES;
        _loadIndicatorBeforePlay = YES;
    }
    
    return self;
}

- (AVPlayerItem *)playerItemWithURL:(NSURL *)url timeRange:(CMTimeRange)timeRange
{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
    self.clipRange = timeRange;
    if (!CMTimeRangeEqual(kCMTimeRangeZero, timeRange)) {
        [playerItem seekToTime:timeRange.start toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        playerItem.forwardPlaybackEndTime = CMTimeAdd(timeRange.start, timeRange.duration);
    }
    return playerItem;
}

- (void)seekToTime:(NSTimeInterval)seekTime
{
    [self seekToTime:seekTime completionHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)seekTime completionHandler:(void (^)(BOOL finished))completionHandler
{
    if (_playerView.player.currentItem.status == AVPlayerItemStatusReadyToPlay)
    {
        [self notifyIndicatorViewIsLoading:YES];
        
        int32_t timeScale = _playerView.player.currentItem.asset.duration.timescale;
        [_playerView.player seekToTime: CMTimeMakeWithSeconds(seekTime, timeScale)
                       toleranceBefore: kCMTimeZero
                        toleranceAfter: kCMTimeZero
                     completionHandler: ^(BOOL finshed)
         {
             [self notifyIndicatorViewIsLoading:NO];
             if (completionHandler) {
                 completionHandler(finshed);
             }
         }];
    }
}

// ------------------------------------------------------
// 更新播放器的currentTime
// ------------------------------------------------------

- (void)addPeriodicTimeObserver
{
    if (_playbackTimeObserver != nil) return;
    
    _playbackTimeObserver = [_playerView.player addPeriodicTimeObserverForInterval:CMTimeMake(33, 1000) queue:NULL usingBlock:^(CMTime time)
     {
         _currentPlaybackTime = CMTimeGetSeconds(_playerView.player.currentItem.currentTime);
         [self notifyProgressSlider];
         [self sendNotificationWithType:PQMoviePlayerNotificationplaybackProgress];
         
         //只在当播放状态是AVPlayerStatusReadyToPlay时，发出load状态的通知
         if (_isLoadingMovie)
         {
             _isLoadingMovie = NO;
             [self setLoadState:PQMovieLoadStateStartPlay];
         }
     }];
}

// ------------------------------------------------------
// AVPlayer通知
// ------------------------------------------------------

- (void)playerItemStalled:(NSNotification *)notification
{
    [self setLoadState:PQMovieLoadStateStalled];
    
    //网络出现问题时，循环，等到缓存大于当前播放的进度，才开始播放
    [self openStalledTimer];
}

- (void)playerItemDidEnd:(NSNotification *)notification
{
    [self sendNotificationWithType:PQMoviePlayerNotificationplaybackDidPlayToEnd];
    if (_repeatMode == PQMovieRepeatModeOne)
    {
        if (!_isRepeat)
        {
            _isRepeat = !_isRepeat;
            [self seekToTime:CMTimeGetSeconds(self.clipRange.start) completionHandler:^(BOOL finished) {
               [self play];
            }];
        }
        else
        {
            [self sendNotificationWithType:PQMoviePlayerNotificationplaybackDidFinish];
        }
    }
    else if (_repeatMode == PQMovieRepeatModeLoop)
    {
        [self seekToTime:CMTimeGetSeconds(self.clipRange.start) completionHandler:^(BOOL finished) {
            [self play];
        }];
    }
    else
    {
        [self sendNotificationWithType:PQMoviePlayerNotificationplaybackDidFinish];
    }
    
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self pause];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
//    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
//    if (_controlStyle == PQMovieControlStyleFullscreen && ![PQMoviePlayerController systemVersionLowIOS8])
//    {
//        [self rotatePlayViewOrientation:orientation animated:YES];
//    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AVPlayerPlaybackStatusObservationContext)
    {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        
        switch (playerItem.status)
        {
            case AVPlayerStatusUnknown:
                
                break;
                
            case AVPlayerStatusReadyToPlay:
            {
                CMTime totalTime = playerItem.duration;
                _duration = CMTimeGetSeconds(totalTime);
                
                [self addPeriodicTimeObserver];
                [self notifyEnablePlayButton];
                [self notifyProgressView];
                
                if (_openDeviceOrientationChange && !_deviceNotificationIsWork)
                {
                    _deviceNotificationIsWork = YES;
                    [self startDeviceOrientationChangeNotification];
                }
                
                _isLoadingMovie = YES;
            }
                break;
                
            case AVPlayerStatusFailed:
                
                [_playerItem removeObserver:self forKeyPath:kPlayerItemLoadedTimeRangesKey context:AVPlayerLoadedTimeRangesObservationContext];
                [_playerItem removeObserver:self forKeyPath:kPlayerItemStatusKey context:AVPlayerPlaybackStatusObservationContext];
                self.playerItem = nil;
                
                [self showErrorVideoAlert];
                
                break;
                
            default:
                break;
        }        
    }
    else if (context == AVPlayerLoadedTimeRangesObservationContext)
    {
        NSArray *loadedTimeRanges = [[_playerView.player currentItem] loadedTimeRanges];
        
        if ([loadedTimeRanges count] > 0)
        {
            CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
            float startSeconds = CMTimeGetSeconds(timeRange.start);
            float durationSeconds = CMTimeGetSeconds(timeRange.duration);
            
            _playableDuration = startSeconds + durationSeconds;
        }
        
        [self notifyProgressView];
    }
    else if (context == AVPlayerRateObservationContext)
    {
        _isPlaying = _playerView.player.rate;
        [self notifyPauseOrPlayButton];
        [self sendNotificationWithType:PQMoviePlayerNotificationPlaybackStateDidChange];
    }
    else
    {
        //
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (UIView *)view
{
    return _playerView;
}

- (void)showErrorVideoAlert
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"无法播放此视频" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
    [alertView show];
    [alertView release];
    ;
}

- (void)showURLErrorAlert
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"无法播放此视频" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
    [alertView show];
    [alertView release];
}

- (void)showPlayErrorAlert
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"播放出错" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
    [alertView show];
    [alertView release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[UIPasteboard generalPasteboard] setValue:[self.url absoluteString] forPasteboardType:(NSString *)kUTTypeText];
}
// ------------------------------------------------------
// 定时器
// ------------------------------------------------------

- (void)openStalledTimer
{
    if (self.playbackStalledTimer && [self.playbackStalledTimer isValid])
    {
        [self.playbackStalledTimer invalidate];
    }
    
    self.playbackStalledTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkPlayableIsEnoughToPlay) userInfo:nil repeats:YES];
}

- (void)cloaseStalledTimer
{
    _playerStalledCount = 0;
    [self.playbackStalledTimer invalidate];
    self.playbackStalledTimer = nil;
}

- (void)checkPlayableIsEnoughToPlay
{
    _playerStalledCount ++;
    
    if (_playerStalledCount >= 20)
    {
        [self cloaseStalledTimer];
        [self showPlayErrorAlert];
        
        return;
    }
    
    if (_playableDuration > _currentPlaybackTime)
    {
        [self play];
        [self setLoadState:PQMovieLoadStatePlayable];
        [self cloaseStalledTimer];
    }
}

#pragma mark -
#pragma mark Network Of Movie Player

- (void)setLoadState:(PQMovieLoadState)loadState
{
    _loadState = loadState;
    
    if (_loadState == PQMovieLoadStatePlayable || _loadState == PQMovieLoadStateStartPlay)
    {
        _playerView.backgroundColor = [UIColor blackColor];
        _playerView.playerControl.controlStyleButton.enabled = YES;
        _playerView.playerControl.progressSlider.enabled = YES;
        _playerView.playerControl.progressSlider.userInteractionEnabled = YES;
        [self notifyIndicatorViewIsLoading:NO];
    }
    else
    {
        _playerView.playerControl.controlStyleButton.enabled = NO;
        _playerView.playerControl.progressSlider.enabled = NO;
        _playerView.playerControl.progressSlider.userInteractionEnabled = NO;
        [self notifyIndicatorViewIsLoading:YES];
    }
    
    [self sendNotificationWithType:PQMoviePlayerNotificationLoadStateDidChange];
}

#pragma mark -
#pragma mark PlayView Orientation

- (void)addPlayViewToWindow
{
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    [window addSubview:_backgroundView];
    [window addSubview:_playerView];
}

- (void)createBackgroundView
{
    if (!_backgroundView)
    {
        _backgroundView = [[UIView alloc] initWithFrame:_playerView.frame];
        _backgroundView.backgroundColor = [UIColor blackColor];
    }
}

- (void)removeBackgroundView
{
    [_backgroundView removeFromSuperview];
    [_backgroundView release];
    _backgroundView = nil;
}

//通过设备转向来判断导航条的转向
- (UIInterfaceOrientation)statusBarOrientationWithDeviceOrientation:(UIDeviceOrientation)orientation
{
    if (orientation == UIDeviceOrientationLandscapeLeft)
    {
        return UIInterfaceOrientationLandscapeRight;
    }
    else if (orientation == UIDeviceOrientationLandscapeRight)
    {
        return UIInterfaceOrientationLandscapeLeft;
    }
    else if (orientation == UIDeviceOrientationPortrait)
    {
        return UIInterfaceOrientationPortrait;
    }
    else
    {
        return UIInterfaceOrientationPortrait;
    }
}

//通过设备方向判断playView要转的角度
- (CGAffineTransform)playViewTransformWithOrientation:(UIDeviceOrientation)orientation
{
    if (orientation == UIDeviceOrientationLandscapeLeft)
    {
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    else if (orientation == UIDeviceOrientationLandscapeRight)
    {
        return CGAffineTransformMakeRotation(-M_PI_2);
    }
    else if (orientation == UIDeviceOrientationPortrait)
    {
        return CGAffineTransformMakeRotation(0);
    }
    else
    {
        return CGAffineTransformIdentity;
    }
}

//通过视频的size来得到全屏时视频默认的方向
- (UIDeviceOrientation)defaultFullScreenOrientation
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if (_autoFixVideoSize)
    {
        if (_videoSize.width <= _videoSize.height)
        {
            orientation = UIDeviceOrientationPortrait;
        }
        else
        {
            if (orientation != UIDeviceOrientationLandscapeRight){
                orientation = UIDeviceOrientationLandscapeLeft;
            }
        }
    }
    
    return orientation;
}

- (void)rotatePlayViewOrientation:(UIDeviceOrientation)orientation animated:(BOOL)animated
{
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown)
    {
        orientation = _remarkDeviceOrientation;
    }
    
    _remarkDeviceOrientation = orientation;
    
    [self sendNotificationWithType:PQMoviePlayerNotificationWillFullscreen];
    //[[UIDevice currentDevice] setValue: [NSNumber numberWithInteger: orientation] forKey:@"orientation"];
    //[[UIApplication sharedApplication] setStatusBarOrientation:[self statusBarOrientationWithDeviceOrientation:orientation] animated:animated];
    
    if (animated)
    {
        [UIView animateWithDuration:0.3 animations:^
         {
             _playerView.transform = [self playViewTransformWithOrientation:orientation];
             _playerView.frame = CGRectMake(0, 0, KDefaultScreenWidth, kDefaultScreenHeight);
         } completion:^(BOOL finished)
         {
             [self createBackgroundView];
             [self addPlayViewToWindow];
             [self sendNotificationWithType:PQMoviePlayerNotificationDidFullscreen];
         }];
    }
    else
    {
        _playerView.transform = [self playViewTransformWithOrientation:orientation];
        _playerView.frame = CGRectMake(0, 0, KDefaultScreenWidth, kDefaultScreenHeight);
        [self createBackgroundView];
        [self addPlayViewToWindow];
        [self sendNotificationWithType:PQMoviePlayerNotificationDidFullscreen];
    }
}

- (void)setControlStyle:(PQMovieControlStyle)controlStyle
{
    _controlStyle = controlStyle;
    
    [self notifyControlStyle:_controlStyle];
    
    if (_controlStyle == PQMovieControlStyleWindow)
    {
        [self sendNotificationWithType:PQMoviePlayerNotificationWillWindow];
        [self removeBackgroundView];
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
        
            [UIView animateWithDuration:0.3 animations:^
             {
                 _playerView.transform = CGAffineTransformMakeRotation(0);
                 _playerView.frame = _fixFrame;
             } completion:^(BOOL finished)
             {
                 _playerView.frame = _identifyFrame;
                 [_identifyView addSubview:_playerView];
                 [self sendNotificationWithType:PQMoviePlayerNotificationDidWindow];
             }];
    }
    else if (_controlStyle == PQMovieControlStyleFullscreen)
    {
        
        self.identifyFrame = _playerView.frame;
        self.identifyView = _playerView.superview;
        
        _fixFrame = [PQMoviePlayerController fixRect:_identifyFrame fromView:_identifyView];
        self.view.frame = _fixFrame;
        
        [self addPlayViewToWindow];
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
        
        UIDeviceOrientation orientation = [self defaultFullScreenOrientation];
        [self rotatePlayViewOrientation:orientation animated:YES];
    }
    else if (_controlStyle == PQMovieControlStyleNone)
    {
        for (UIView *v in self.view.subviews)
        {
            [v removeFromSuperview];
        }
    }
    else
    {
        //
    }
}

// ------------------------------------------------------
// deviceOrientationChange Notification
// ------------------------------------------------------

- (void)startDeviceOrientationChangeNotification
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)stopDeviceOrientationChangeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)deviceOrientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (_controlStyle == PQMovieControlStyleFullscreen)
    {
        [self rotatePlayViewOrientation:orientation animated:YES];
    }
}

#pragma mark -
#pragma mark PQPlayerPlayback

- (void)play
{
    [_playerView.player play];
}

- (void)pause
{
    [_playerView.player pause];
}

- (void)stop
{
    [self pause];
    [self removePlayerObserver];
}

#pragma mark -
#pragma mark Notifications

- (void)sendNotificationWithType:(PQMoviePlayerNotificationType)notificationType
{
    NSString *postName = nil;
    
    switch (notificationType)
    {
        case PQMoviePlayerNotificationWillFullscreen:
            
            postName = PQMoviePlayerWillFullscreenNotification;
            
            break;
            
        case PQMoviePlayerNotificationDidFullscreen:
            
            postName = PQMoviePlayerDidFullscreenNotification;
            
            break;
            
        case PQMoviePlayerNotificationWillWindow:
            
            postName = PQMoviePlayerWillWindowNotification;
            
            break;
            
        case PQMoviePlayerNotificationDidWindow:
            
            postName = PQMoviePlayerDidWindowNotification;
            
            break;
            
        case PQMoviePlayerNotificationLoadStateDidChange:
            
            postName = PQMoviePlayerLoadStateDidChangeNotification;
            
            break;
        
        case PQMoviePlayerNotificationPlaybackStateDidChange:
            
            postName = PQMoviePlayerPlaybackStateDidChangeNotification;
            
            break;
            
        case PQMoviePlayerNotificationplaybackDidFinish:
            
            postName = PQMoviePlayerPlaybackDidFinishNotification;
            
            break;
            
        case PQMoviePlayerNotificationplaybackProgress:
            
            postName = PQMoviePlayerPlaybackProgressNotification;
            
            break;
        case PQMoviePlayerNotificationplaybackDidPlayToEnd:

            postName = PQMoviePlayerPlaybackDidPlayToEndNotification;
            
            break;
        default:
            break;
    }
    
    if (postName)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:postName object:self];
        });
    }
}

#pragma mark -
#pragma mark PQPlayerStateToNotifyView

- (void)notifyProgressSlider
{
    if (_duration > 0.0 && !_isSeeking)
    {
        NSString *currentTime = [PQMoviePlayerController convertDuration:_currentPlaybackTime];
        NSString *totalTime = [PQMoviePlayerController convertDuration:_duration];
        [self updateTimeLabel:currentTime totalTime:totalTime];
        
        CGFloat progress = _currentPlaybackTime / _duration;
        _playerView.playerControl.progressSlider.value = progress;
        _playerView.playerControl.playProgressView.progress = progress;
        _playerView.progressView.progress = progress;
    }
}

- (void)updateTimeLabel:(NSString *)currentTime totalTime:(NSString *)totalTime
{
    _playerView.playerControl.currentTimeLabel.text = currentTime;
    _playerView.playerControl.totalTimeLabel.text = totalTime;
    _playerView.playerControl.fullTimeLabel.text = [NSString stringWithFormat:@"%@/%@",currentTime,totalTime];
}

- (void)notifyProgressView
{
    if (_duration > 0.0)
    {
        CGFloat progress= _playableDuration / _duration;
        if (progress > 0.85) progress = 1.0;
        
        _playerView.playerControl.progressView.progress = progress;
    }
}

- (void)notifyPauseOrPlayButton
{    
    _playerView.playerControl.playButton.selected = !_isPlaying;
    _playerView.playIcon.hidden = _isPlaying;
    [_playerView setIsPause:!_isPlaying];
    if (!_isPlaying) {
        [_playerView showControl];
        [_playerView closeControlTimer];
    }else {
        [_playerView openControlTimer];
    }
}

- (void)notifyEnablePlayButton
{
    _playerView.playerControl.playButton.enabled = YES;
}

- (void)notifyControlStyle:(PQMovieControlStyle)controlStyle
{
    [_playerView.playerControl.controlStyleButton setSelected:(controlStyle == PQMovieControlStyleFullscreen)];
    [_playerView.playerNavbar setHidden:!(controlStyle == PQMovieControlStyleFullscreen)];
    [_playerView setViewMode:controlStyle];
}

- (void)notifyIndicatorViewIsLoading:(BOOL)isLoading
{
    if (isLoading)
    {
        [_playerView.indicatorView startAnimating];
    }
    else
    {
        [_playerView.indicatorView stopAnimating];
    }
}

#pragma mark -
#pragma mark PQPlayerControl Delegate

- (void)startSeek
{
    _isSeeking = YES;
    [_playerView closeControlTimer];
}

- (void)setSeekingValue:(CGFloat)seekingValue
{
    NSString *currentTime = [PQMoviePlayerController convertDuration:seekingValue*_duration];
    NSString *totalTime = [PQMoviePlayerController convertDuration:_duration];
    [self updateTimeLabel:currentTime totalTime:totalTime];
}

- (void)endSeekAtValue:(CGFloat)seekValue {
    [self seekToTime:seekValue * _duration completionHandler:^(BOOL finished){
        _isSeeking = NO;
    }];
}

- (void)playerViewToFullStyle
{
    self.controlStyle = PQMovieControlStyleFullscreen;
}

- (void)playerViewToWindowStyle
{
    self.controlStyle = PQMovieControlStyleWindow;
}

#pragma mark -
#pragma mark PQPlayerNavBar Delegate

- (void)PQPlayerNavBarGoback:(PQPlayerNavBar *)navbar
{
    self.controlStyle = PQMovieControlStyleWindow;
}

#pragma mark -
#pragma mark PQMovieProperties

- (NSTimeInterval)duration
{
    return _duration;
}

- (NSTimeInterval)playableDuration
{
    return _playableDuration;
}

- (NSTimeInterval) currentPlaybackTime
{
    return _currentPlaybackTime;
}
#pragma mark -
#pragma mark PQMovieOrientation

- (UIDeviceOrientation)orientation
{
    return _remarkDeviceOrientation;
}

#pragma mark -
#pragma mark PQMovieFullScreen

- (void)setAutoFixVideoSize:(BOOL)autoFixVideoSize
{
    _autoFixVideoSize = autoFixVideoSize;
}

- (BOOL)autoFixVideoSize
{
    return _autoFixVideoSize;
}

- (void)setOpenDeviceOrientationChange:(BOOL)openDeviceOrientationChange
{
    _openDeviceOrientationChange = openDeviceOrientationChange;
}

- (BOOL)openDeviceOrientationChange
{
    return _openDeviceOrientationChange;
}

#pragma mark -
#pragma mark PQMovieIndicator

- (void)setLoadIndicatorBeforePlay:(BOOL)loadIndicatorBeforePlay {
    if (_loadIndicatorBeforePlay != loadIndicatorBeforePlay) {
        _loadIndicatorBeforePlay = loadIndicatorBeforePlay;
        
        if (!loadIndicatorBeforePlay) {
            [_playerView.indicatorView stopAnimating];
        }
    }
}

- (BOOL)loadIndicatorBeforePlay {
    return _loadIndicatorBeforePlay;
}

@end
