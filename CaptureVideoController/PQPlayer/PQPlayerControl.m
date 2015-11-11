//
//  PQPlayerControl.m
//  Player
//
//  Created by jianting on 14-5-15.
//  Copyright (c) 2014年 jianting. All rights reserved.
//

#import "PQPlayerControl.h"
#import "PQMoviePlayerController.h"

@implementation PQSlider

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    return CGRectMake(0, bounds.size.height / 2 - 1, bounds.size.width, 3);
}

@end

@interface PQPlayerControl ()
{
    UIView * _backgroundView;
}

@end

@implementation PQPlayerControl

- (void)dealloc
{
    [_playButton         release];
    [_progressSlider     release];
    [_progressView       release];
    [_playProgressView   release];
    [_controlStyleButton release];
    [_currentTimeLabel   release];
    [_totalTimeLabel     release];
    [_fullTimeLabel release];
    _playButton           =   nil;
    _progressSlider       =   nil;
    _progressView         =   nil;
    _playProgressView     =   nil;
    _controlStyleButton   =   nil;
    _currentTimeLabel     =   nil;
    _totalTimeLabel       =   nil;
    _fullTimeLabel = nil;
    
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        _viewMode = PQPlayerViewModeWindow;
        
        _backgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
        _backgroundView.backgroundColor = [UIColor grayColor];
        _backgroundView.userInteractionEnabled = YES;
        _backgroundView.alpha = 0.5;
        [self addSubview:_backgroundView];
        
        //播放暂停按钮
        _playButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [_playButton setFrame:CGRectZero];
        [_playButton setImage:[UIImage imageNamed:@"videoDetailPlayer_button_pause"] forState:UIControlStateNormal];
        [_playButton setImage:[UIImage imageNamed:@"videoDetailPlayer_button_play"] forState:UIControlStateSelected];
        [_playButton addTarget:self action:@selector(playOrPause:) forControlEvents:UIControlEventTouchUpInside];
        [_playButton setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
        [_playButton setEnabled:NO];
        
        //缓冲进度条
        _progressView = [[PQProgressView alloc] initWithFrame:CGRectZero];
        //[_progressView setProgressImage:[UIImage imageNamed:@"videoDetailPlayer_progress_cache"]];
        [_progressView setTrackColor:[UIColor colorWithRed:(170.0/255.0) green:(170.0/255.0) blue:(170.0/255.0) alpha:1.0]];
        [_progressView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        //播放进度条
        _playProgressView = [[PQProgressView alloc] initWithFrame:CGRectZero];
        [_playProgressView setTrackColor:[UIColor colorWithRed:(170.0/255.0) green:(170.0/255.0) blue:(170.0/255.0) alpha:1.0]];
        [_playProgressView setProgressColor:[UIColor colorWithRed:(57.0/155.0) green:(192.0/255.0) blue:(65.0/255.0) alpha:1.0]];
        [_playProgressView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        //slider
        _progressSlider = [[PQSlider alloc] initWithFrame:CGRectZero];
        [_progressSlider setThumbImage:[UIImage imageNamed:@"videoDetailPlayer_progress_thumb"] forState:UIControlStateNormal];
        [_progressSlider setMaximumTrackImage:[self queueImage] forState:UIControlStateNormal];
        [_progressSlider setMinimumTrackImage:[self queueImage] forState:UIControlStateNormal];
        [_progressSlider addTarget:self action:@selector(willSlider:) forControlEvents:UIControlEventTouchDown];
        [_progressSlider addTarget:self action:@selector(didSlider:) forControlEvents:UIControlEventValueChanged];
        [_progressSlider addTarget:self action:@selector(endSlider:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
        [_progressSlider setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        //播放时长
        _currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_currentTimeLabel setBackgroundColor:[UIColor clearColor]];
        [_currentTimeLabel setFont:[UIFont systemFontOfSize:11]];
        [_currentTimeLabel setTextAlignment:NSTextAlignmentCenter];
        [_currentTimeLabel setTextColor:[UIColor whiteColor]];
        [_currentTimeLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        
        //总时长
        _totalTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_totalTimeLabel setBackgroundColor:[UIColor clearColor]];
        [_totalTimeLabel setFont:[UIFont systemFontOfSize:11]];
        [_totalTimeLabel setTextAlignment:NSTextAlignmentCenter];
        [_totalTimeLabel setTextColor:[UIColor whiteColor]];
        [_totalTimeLabel setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
        
        //全屏显示的时长
        _fullTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_fullTimeLabel setBackgroundColor:[UIColor clearColor]];
        [_fullTimeLabel setFont:[UIFont systemFontOfSize:11]];
        [_fullTimeLabel setTextAlignment:NSTextAlignmentLeft];
        [_fullTimeLabel setTextColor:[UIColor whiteColor]];
        [_fullTimeLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        
        
        //全屏按钮
        _controlStyleButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [_controlStyleButton setFrame:CGRectZero];
        [_controlStyleButton setImage:[UIImage imageNamed:@"videoDetailPlayer_button_fullScreen"] forState:UIControlStateNormal];
        [_controlStyleButton setImage:[UIImage imageNamed:@"videoDetailPlayer_button_close"] forState:UIControlStateSelected];
        [_controlStyleButton addTarget:self action:@selector(changeStyle:) forControlEvents:UIControlEventTouchUpInside];
        [_controlStyleButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        [_controlStyleButton setEnabled:NO];
        
        [self addSubview:_progressView];
        [self addSubview:_playProgressView];
        [self addSubview:_progressSlider];
        [self addSubview:_currentTimeLabel];
        [self addSubview:_totalTimeLabel];
        [self addSubview:_controlStyleButton];
        [self addSubview:_playButton];
        [self addSubview:_fullTimeLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _backgroundView.frame = CGRectMake(0, 10, self.frame.size.width, self.frame.size.height-10);
    _playButton.frame = CGRectMake(10, (_backgroundView.frame.size.height - 40) / 2+10, 40, 40);
    _fullTimeLabel.frame = CGRectMake(CGRectGetMaxX(_playButton.frame)+10, (_backgroundView.frame.size.height - 18) / 2+3+10, self.frame.size.width-50, 12);
    _currentTimeLabel.frame = CGRectMake(0, (_backgroundView.frame.size.height - 18) / 2+3+10, 40, 12);
    _totalTimeLabel.frame = CGRectMake(self.frame.size.width-32-40, CGRectGetMinY(_currentTimeLabel.frame), 40, 12);
    _controlStyleButton.frame = CGRectMake(self.frame.size.width - 45, (_backgroundView.frame.size.height - 45) / 2+10, 45, 45);
    
    if (_viewMode == PQPlayerViewModeFullscreen) {
        _playButton.hidden = NO;
        _fullTimeLabel.hidden = NO;
        _currentTimeLabel.hidden = YES;
        _totalTimeLabel.hidden = YES;
        
        _progressView.frame = CGRectMake(0, 8, self.frame.size.width, 3);
        _progressSlider.frame = CGRectMake(0, 0, self.frame.size.width, 18);
        _playProgressView.frame = _progressView.frame;
        _playProgressView.progress = _playProgressView.progress;
    }else {
        _playButton.hidden = YES;
        _fullTimeLabel.hidden = YES;
        _currentTimeLabel.hidden = NO;
        _totalTimeLabel.hidden = NO;
        
        _progressView.frame = CGRectMake(40, (_backgroundView.frame.size.height - 18) / 2 + 8+10, self.frame.size.width - 80 - 32, 3);
        _progressSlider.frame = CGRectMake(40, (_backgroundView.frame.size.height - 18) / 2+10, self.frame.size.width - 80 - 32, 18);
        _playProgressView.frame = _progressView.frame;
        _playProgressView.progress = _playProgressView.progress;
    }
    
}

- (UIImage *)queueImage
{
    UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
    UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return transparentImage;
}

- (void)playOrPause:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    if (sender.selected)
    {
        if (_delegate && [_delegate respondsToSelector:@selector(pause)])
        {
            [_delegate pause];
        }
    }
    else
    {
        if (_delegate && [_delegate respondsToSelector:@selector(play)])
        {
            [_delegate play];
        }
    }
}

- (void)changeStyle:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    if (sender.selected)
    {
        if (_delegate && [_delegate respondsToSelector:@selector(playerViewToFullStyle)])
        {
            [_delegate playerViewToFullStyle];
        }
    }
    else
    {
        if (_delegate && [_delegate respondsToSelector:@selector(playerViewToWindowStyle)])
        {
            [_delegate playerViewToWindowStyle];
        }
    }
}

- (void)willSlider:(UISlider *)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(startSeek)])
    {
        [_delegate startSeek];
    }
}

- (void)didSlider:(UISlider *)sender
{
    _playProgressView.progress = sender.value;
    if (_delegate && [_delegate respondsToSelector:@selector(setSeekingValue:)])
    {
        [_delegate setSeekingValue:sender.value];
    }
}

- (void)endSlider:(UISlider *)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(endSeekAtValue:)])
    {
        [_delegate endSeekAtValue:sender.value];
    }
}

- (void)setViewMode:(PQPlayerViewMode)viewMode {
    if (_viewMode != viewMode) {
        _viewMode = viewMode;
        [self setNeedsLayout];
    }
}

/** 阻断touch事件向上传 **/
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

@end
