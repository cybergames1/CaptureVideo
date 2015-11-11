//
//  PQPlayerView.m
//  Player
//
//  Created by jianting on 14-5-15.
//  Copyright (c) 2014年 jianting. All rights reserved.
//

#import "PQPlayerView.h"
#import "PQPlayerControl.h"

#define Control_Height 60 //控制条的高度

@interface PQPlayerView ()
{
    BOOL _isPause;
}

@property (nonatomic, retain) NSTimer *playControlTimer;

@end

@implementation PQPlayerView

@synthesize player = _player;
@synthesize playerControl = _playerControl;
@synthesize playerNavbar = _playerNavbar;
@synthesize indicatorView = _indicatorView;

- (void)dealloc
{
    [_player           release];
    [_playerControl    release];
    [_indicatorView    release];
    [_playerNavbar     release];
    [_playIcon         release];
    [_progressView     release];
    [_playControlTimer release];
    _player             =   nil;
    _playerControl      =   nil;
    _indicatorView      =   nil;
    _playerNavbar       =   nil;
    _playIcon           =   nil;
    _progressView       =   nil;
    _playControlTimer   =   nil;
    
    [super dealloc];
}

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayer*)player
{
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player
{
    return[(AVPlayerLayer *)[self layer] setPlayer:player];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.autoresizesSubviews = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _isPause = NO;

        _indicatorView = [[PQActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        _indicatorView.center = CGPointMake(frame.size.width / 2, frame.size.height / 2);
        _indicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [_indicatorView startAnimating];
        [self addSubview:_indicatorView];
        
        _playerNavbar = [[PQPlayerNavBar alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 64)];
        _playerNavbar.hidden = YES;
        [_playerNavbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self addSubview:_playerNavbar];
        
        _playerControl = [[PQPlayerControl alloc] initWithFrame:CGRectMake(0, self.frame.size.height - Control_Height, self.frame.size.width, Control_Height)];
        _playerControl.alpha = 0.0;
        _playerControl.hidden = YES;
        [_playerControl setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin)];
        [self addSubview:_playerControl];
        
        UIImage *image = [UIImage imageNamed:@"videoPlayer_play"];
        _playIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
        _playIcon.center = _indicatorView.center;
        _playIcon.autoresizingMask = _indicatorView.autoresizingMask;
        _playIcon.image = image;
        _playIcon.hidden = YES;
        [self addSubview:_playIcon];
        
        //播放进度条
        _progressView = [[PQProgressView alloc] initWithFrame:CGRectMake(0, self.frame.size.height-3, self.frame.size.width, 3)];
        [_progressView setTrackColor:[UIColor colorWithRed:(170.0/255.0) green:(170.0/255.0) blue:(170.0/255.0) alpha:1.0]];
        [_progressView setProgressColor:[UIColor colorWithRed:(57.0/155.0) green:(192.0/255.0) blue:(65.0/255.0) alpha:1.0]];
        [_progressView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
        [self addSubview:_progressView];        
    }
    return self;
}

- (void)setViewMode:(PQPlayerViewMode)viewMode {
    [_playerControl setViewMode:viewMode];
    
    if (_viewMode != viewMode) {
        _viewMode = viewMode;
        
        if (viewMode == PQPlayerViewModeFullscreen) {
            _progressView.hidden = YES;
            _playIcon.alpha = 0.0;
        }else {
            _progressView.hidden = NO;
            _playIcon.alpha = 1.0;
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)setDelegate:(id<PQPlayerControlDelegate,PQPlayerNavBarDelegate>)delegate
{
    _delegate = delegate;
    [_playerControl setDelegate:delegate];
    [_playerNavbar setDelegate:delegate];
}

- (void)setIsPause:(BOOL)isPause {
    _isPause = isPause;
}

- (void)singleTap:(UITapGestureRecognizer *)recognizer
{
    if (_playerControl.hidden)
    {
        [self showControl];
        [self openControlTimer];
    }
    else
    {
        [self hideControl];
        [self closeControlTimer];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_viewMode == PQPlayerViewModeFullscreen) {
        /* 全屏模式
         * 点击弹出control，开启timer
         * 再点击，隐藏control，停止timer
         */
        [self singleTap:nil];
    }else {
        /* 窗口模式
         * 点击暂停，弹出control，隐藏progress，停止timer
         * 再点击，继续播放，开启timer，4秒后隐藏control，弹出progress
         */
        _isPause = !_isPause;
        if (_isPause) {
            if (_delegate && [_delegate respondsToSelector:@selector(pause)]) {
                [_delegate pause];
            }
        }else {
            if (_delegate && [_delegate respondsToSelector:@selector(play)]) {
                [_delegate play];
            }
        }
    }
}

// --------------------------------------------
// Private Methods
// --------------------------------------------

- (void)showControl
{
    [self closeControlTimer];
    _playerControl.hidden = NO;
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^
     {
         _playerNavbar.alpha = 1.0;
         _playerControl.alpha = 1.0;
         _progressView.alpha = 0.0;
     }
                     completion:^(BOOL finished)
     {
         //
     }];
}

- (void)hideControl
{
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^
     {
         _playerNavbar.alpha = 0.0;
         _playerControl.alpha = 0.0;
         _progressView.alpha = 1.0;
     }
                     completion:^(BOOL finished)
     {
         _playerControl.hidden = YES;
     }];
}

// ------------------------------------------------------
// 定时器
// ------------------------------------------------------

- (void)openControlTimer
{
    if (self.playControlTimer && [self.playControlTimer isValid])
    {
        [self.playControlTimer invalidate];
    }
    
    self.playControlTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(autoHidePlayControl) userInfo:nil repeats:NO];
}

- (void)closeControlTimer
{
    [self.playControlTimer invalidate];
    self.playControlTimer = nil;
}

- (void)autoHidePlayControl
{
    [self hideControl];
}

@end
