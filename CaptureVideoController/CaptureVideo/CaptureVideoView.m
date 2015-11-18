//
//  CaptureVideoView.m
//  CaptureVideoController
//
//  Created by jianting on 15/11/10.
//  Copyright © 2015年 jianting. All rights reserved.
//

#import "CaptureVideoView.h"
#import "UIImage+CaptureImageEffects.h"

#define VideoSize_320x240 (320.0/240.0)
#define MAX_WriteSec 6.0 //6秒视频
#define Button_Width_Rate (200.0/316.5)

NSString *const CaptureVideoURL = @"CaptureVideoURL";
NSString *const CaptureVideoUIMode = @"CaptureVideoUIMode";

UIColor * UIColorWithRGBA (CGFloat red ,CGFloat green , CGFloat blue, CGFloat alpha)
{
    return [UIColor colorWithRed:(red/255.0) green:(green/255.0) blue:(blue/255.0) alpha:alpha];
}

//自定义拍摄按钮
@interface ShootButton : UIImageView

@end

//提示的Label
@interface NoteLabel : UILabel

@property (nonatomic, assign) CGFloat left;

- (void)initZero;
- (void)show;
- (void)showAutoHide;
- (void)hide;

@end

@interface CaptureVideoView ()
{
    UIImageView * _preView;
    UIView * _backgroundView;
    UIImageView * _focusImageView;
    UILabel * _cancelLabel;
    NoteLabel * _noteCancelLabel;
    NoteLabel * _noteResetLabel;
    
    BOOL _isShooting;
    CGFloat _currentVideoDur;
    CaptureVideoMode _videoMode;
    BOOL _bigMode;
    CGFloat _progress;
    
    NSInteger _pinchCount;
}

@property (nonatomic, retain) NSTimer * writeTimer;

@end

@implementation CaptureVideoView

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self stopCapture];
    [_videoController.view removeFromSuperview];
    [_videoController release];_videoController = nil;
    [_writeTimer release];_writeTimer = nil;
    [super dealloc];
}

+ (UIColor *)recoardColr {
    return UIColorWithRGBA(31, 216, 189, 1.0);
}

+ (UIColor *)cancelColor {
    return UIColorWithRGBA(255, 44, 85, 1.0);
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.masksToBounds = YES;
        //拍摄界面
        [self addVideoView];
        //进度条
        [self addSubview:[self progressView]];
        //提示文字
        [self addSubview:[self cancelLabel]];
        [self addSubview:[self noteCancelLabel]];
        [self addSubview:[self noteResetlLabel]];
        //拍摄按钮
        [self addSubview:[self shootButton]];
        //手势
        [self addGestureRecognizer:[self longPressGesture]];
        [self addGestureRecognizer:[self tapGesture]];
        [self addGestureRecognizer:[self doubleTapGesture]];
        
        _isShooting = NO;
        _currentVideoDur = 0.0;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.35 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self startCapture];
        });
    }
    return self;
}

// --------------------------------
// 初始化相关控件
// --------------------------------

- (CaptureVideoController *)videoController {
    if (!_videoController) {
        _videoController = [[CaptureVideoController alloc] init];
        _videoController.delegate = self;
    }
    return _videoController;
}

- (void)addVideoView {
    UIView *backgroundView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.width*(1.0/VideoSize_320x240))] autorelease];
    backgroundView.backgroundColor = [UIColor clearColor];
    backgroundView.layer.masksToBounds = YES;
    [self addSubview:backgroundView];
    
    [backgroundView addSubview:[[self videoController] view]];
    _videoController.view.frame = backgroundView.bounds;
    
    //对焦图
    [backgroundView addSubview:[self focusImageView]];
    _backgroundView = backgroundView;
    
    [backgroundView addSubview:[self preView]];
}

- (UIImageView *)focusImageView {
    if (!_focusImageView) {
        _focusImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)] autorelease];
        _focusImageView.image = [UIImage imageNamed:@"capture_focus"];
        _focusImageView.alpha = 0.f;
    }
    return _focusImageView;
}

- (UIImageView *)preView {
    if (!_preView) {
        UIImageView *backgroundImage = [[[UIImageView alloc] initWithFrame:_backgroundView.bounds] autorelease];
        backgroundImage.image = [[UIImage imageNamed:@"capture_bg"] __applyLightEffect];
        _preView = backgroundImage;
        
        UIImageView *eye = [[[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(_preView.frame)/2-69/2, CGRectGetHeight(_preView.frame)/2-51/2, 69, 51)] autorelease];
        [eye setImage:[UIImage imageNamed:@"capture_startup_eye"]];
        [_preView addSubview:eye];
    }
    return _preView;
}

- (UIView *)progressView {
    if (!_progressView) {
        _progressView = [[[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY([self videoController].view.frame), self.frame.size.width, 3)] autorelease];
        _progressView.backgroundColor = [[self class] recoardColr];
        [self setProgress:0.0];
    }
    return _progressView;
}

- (UILabel *)cancelLabel {
    if (!_cancelLabel) {
        _cancelLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY([self videoController].view.frame)-40, self.frame.size.width, 20)] autorelease];
        _cancelLabel.backgroundColor = [UIColor clearColor];
        _cancelLabel.font = [UIFont systemFontOfSize:13.0];
        _cancelLabel.textAlignment = NSTextAlignmentCenter;
        _cancelLabel.hidden = YES;
    }
    return _cancelLabel;
}

- (NoteLabel *)noteCancelLabel {
    if (!_noteCancelLabel) {
        _noteCancelLabel = [[[NoteLabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY([self videoController].view.frame)-40, 0, 20)] autorelease];
        _noteCancelLabel.text = @"松手取消";
        [_noteCancelLabel sizeToFit];
        _noteCancelLabel.left = self.frame.size.width/2-_noteCancelLabel.frame.size.width/2;
        [_noteCancelLabel initZero];
    }
    return _noteCancelLabel;
}

- (NoteLabel *)noteResetlLabel {
    if (!_noteResetLabel) {
        _noteResetLabel = [[[NoteLabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY([self videoController].view.frame)-40, 0, 20)] autorelease];
        _noteResetLabel.text = @"拍摄时请长按按钮";
        [_noteResetLabel sizeToFit];
        _noteResetLabel.left = self.frame.size.width/2-_noteResetLabel.frame.size.width/2;
        [_noteResetLabel initZero];
    }
    return _noteResetLabel;
}

- (UIView *)shootButton {
    if (!_shootButton) {
        CGFloat maxHeight = CGRectGetHeight(self.frame) - CGRectGetMaxY(_progressView.frame);
        CGFloat width = maxHeight * Button_Width_Rate;
        
        _shootButton = [[[ShootButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.frame)/2-width/2, maxHeight/2-width/2+CGRectGetMaxY(_progressView.frame), width, width)] autorelease];
        _shootButton.backgroundColor = [UIColor clearColor];
        _shootButton.image = [UIImage imageNamed:@"capture_shoot"];
    }
    return _shootButton;
}

- (UILongPressGestureRecognizer *)longPressGesture {
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    recognizer.minimumPressDuration = 0.15;
    recognizer.allowableMovement = 3.0;
    return [recognizer autorelease];
}

- (UITapGestureRecognizer *)tapGesture {
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    return [recognizer autorelease];
}

- (UITapGestureRecognizer *)doubleTapGesture {
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
    recognizer.numberOfTapsRequired = 2;
    return [recognizer autorelease];
}

- (void)longPressAction:(UILongPressGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            if (CGRectContainsPoint(_shootButton.frame, [recognizer locationInView:self])) {
                _isShooting = YES;
                [self startRecording];
            }
        }
            break;
        case UIGestureRecognizerStateChanged:
            if (_isShooting) {
                if (CGRectContainsPoint(_backgroundView.frame, [recognizer locationInView:self])) {
                    [self becomeCancelMode];
                }else {
                    [self becomeRecordMode];
                }
            }
            break;
        case UIGestureRecognizerStateEnded:
            if (_isShooting) {
                _isShooting = NO;
                if (_videoMode == CaptureVideoModeRecording) {
                    _isRecordFinish = YES;
                }
                [self stopRecording];
            }
            break;
        case UIGestureRecognizerStateCancelled:
            _isShooting = NO;
            break;
        default:
            break;
    }
}

- (void)tapAction:(UITapGestureRecognizer *)recognizer {
    if (CGRectContainsPoint(_shootButton.frame, [recognizer locationInView:self])) {
        [_noteResetLabel initZero];
        [_noteResetLabel showAutoHide];
        
    }else if (CGRectContainsPoint(_backgroundView.frame, [recognizer locationInView:self])) {
        [self focusAndExposeAtPoint:[recognizer locationInView:_backgroundView]];
        [_videoController focusAndExposeTap:recognizer];
    }
}

- (void)doubleTapAction:(UITapGestureRecognizer *)recognizer {
    if (CGRectContainsPoint(_backgroundView.frame, [recognizer locationInView:self])) {
        _bigMode = !_bigMode;
        [self performSelector:@selector(pinchVideo) withObject:nil afterDelay:0.025];
    }
}
- (void)pinchVideo {
    if (_pinchCount >= 10) {
        _pinchCount = 0;
        return;
    }
    _pinchCount++;
    CGFloat scale = _bigMode ? 1.0+_pinchCount*0.1 : 2.0-_pinchCount*0.1;
    [_videoController setVideoScale:scale];
    [self performSelector:@selector(pinchVideo) withObject:nil afterDelay:0.025];
}

- (void)startCapture {
    [[self videoController] startCamera];
    
    _videoController.view.transform = CGAffineTransformMakeScale(2.0, 2.0);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [_preView removeFromSuperview];
        [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            _videoController.view.transform = CGAffineTransformIdentity;
        }completion:nil];
    });
}

- (void)stopCapture {
    [[self videoController] stopCamera];
}

//重置界面
- (void)resetUI {
    [self setProgress:0.0];
    _progressView.backgroundColor = [[self class] recoardColr];
    
    _cancelLabel.text = @"上移取消";
    _cancelLabel.textColor = [[self class] recoardColr];
    _cancelLabel.hidden = YES;
    
    [_noteCancelLabel initZero];
    
    _currentVideoDur = 0.0;
    _isShooting = NO;
}

// --------------------------------
// 录制相关的控制操作
// --------------------------------

- (NSURL *)fileURL {
    NSString *filePath = nil;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,  NSUserDomainMask, YES);
    if ([paths count] > 0) {
        NSString * rootPath = [[NSString alloc] initWithFormat:@"%@",[paths objectAtIndex:0]];
        filePath = [rootPath stringByAppendingPathComponent:@"RecordMovie_temp.mp4"];
    }
    return [NSURL fileURLWithPath:filePath];
}

- (void)startRecording {
    [_videoController startRecordingToOutputFileURL:[self fileURL]];
    [self startRecordTimer];
    [self becomeRecordMode];
}

- (void)stopRecording {
    [_videoController stopRecording];
    [self stopRecordTimer];
    [self resetUI];
}

- (void)becomeCancelMode {
    _progressView.backgroundColor = [[self class] cancelColor];
    [_noteCancelLabel show];
    _videoMode = CaptureVideoModeCancelled;
}

- (void)becomeRecordMode {
    _progressView.backgroundColor = [[self class] recoardColr];
    _cancelLabel.textColor = [[self class] recoardColr];
    _cancelLabel.text = @"上移取消";
    _cancelLabel.hidden = NO;
    [_noteCancelLabel hide];
    _videoMode = CaptureVideoModeRecording;
}

- (void)focusAndExposeAtPoint:(CGPoint)point {
    [_focusImageView setCenter:point];
    _focusImageView.transform = CGAffineTransformMakeScale(2.0, 2.0);
    
    [UIView animateWithDuration:0.3f delay:0.f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        _focusImageView.alpha = 1.f;
        _focusImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5f delay:0.5f options:UIViewAnimationOptionAllowUserInteraction animations:^{
            _focusImageView.alpha = 0.f;
        } completion:nil];
    }];
}

// --------------------------------
// 录制计时器
// --------------------------------
- (void)startRecordTimer {
    _currentVideoDur = 0.0;
    [self stopRecordTimer];
    self.writeTimer = [NSTimer scheduledTimerWithTimeInterval:0.033 target:self selector:@selector(recordTime) userInfo:nil repeats:YES];
    [_shootButton setHighlighted:YES];
}

- (void)stopRecordTimer {
    if ([self.writeTimer isValid]) {
        [self.writeTimer invalidate];
        self.writeTimer = nil;
        [_shootButton setHighlighted:NO];
    }
}

- (void)recordTime {
    _currentVideoDur += 0.033;
    CGFloat progress = _currentVideoDur/MAX_WriteSec;
    [self setProgress:progress];
    if (progress >= 1.0) {
        _isRecordFinish = YES;
        [self stopRecording];
    }
}

- (void)setProgress:(CGFloat)progress {
    CGFloat progressWidth = progress * self.frame.size.width;
    _progress = progress;
    
    CGRect rect = _progressView.frame;
    rect.size.width = progressWidth;
    _progressView.frame = rect;
    _progressView.hidden = (progress > 0) ? NO : YES;
}

// --------------------------------
// CaptureVideoControllerDelegate
// --------------------------------

- (void)captureVideoWillStartRecording:(CaptureVideoController *)controller {
    
}

- (void)captureVideoWillStopRecording:(CaptureVideoController *)controller {
    if (_isRecordFinish) {
        NSDictionary *info = @{CaptureVideoURL:[self fileURL],
                               CaptureVideoUIMode:[NSNumber numberWithInteger:_videoMode]};
        if (_delegate && [_delegate respondsToSelector:@selector(captureVideoView:didFinishWithInfo:)]) {
            [_delegate captureVideoView:self didFinishWithInfo:info];
        }
        
    }
    _isRecordFinish = NO;
}

@end

@implementation ShootButton

+ (UIColor *)labelColor {
    return UIColorWithRGBA(31, 216, 189, 1.0);
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        
        UILabel *label = [[[UILabel alloc] initWithFrame:self.bounds] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [[self class] labelColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"按住拍";
        [self addSubview:label];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    for (UIView *v in self.subviews) {
        if ([v isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)v;
            label.frame = self.bounds;
        }
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.alpha = highlighted ? 0.3 : 1.0;
}

@end

@interface NoteLabel ()
{
    CGFloat _height;
    BOOL _animationFinished;
}

@end

@implementation NoteLabel

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.textAlignment = NSTextAlignmentCenter;
        self.font = [UIFont systemFontOfSize:13];
        self.layer.cornerRadius = 3;
        self.layer.masksToBounds = YES;
        self.backgroundColor = [CaptureVideoView cancelColor];
        self.textColor = [UIColor whiteColor];
    }
    return self;
}

- (void)setLeft:(CGFloat)left
{
    CGRect rect = self.frame;
    rect.origin.x = left;
    self.frame = rect;
}

- (CGFloat)left {
    return self.frame.origin.x;
}

- (void)sizeToFit {
    [super sizeToFit];
    
    CGRect rect = self.frame;
    rect.size.width += 20;
    rect.size.height += 10;
    self.frame = rect;
    
    _height = rect.size.height;
}

- (void)initZero {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.alpha = 0.0;
    self.transform = CGAffineTransformIdentity;
    [self.layer removeAllAnimations];
    
    CGRect rect = self.frame;
    rect.origin.y += rect.size.height/2;
    rect.size.height = 0;
    self.frame = rect;
}

- (void)show {
    if (self.alpha <= 0.0) {
        [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            CGRect rect = self.frame;
            rect.origin.y -= _height/2;
            rect.size.height = _height;
            self.frame = rect;
            self.alpha = 1.0;
        }completion:nil];
    }
}

- (void)showAutoHide {
    [self show];
    [self performSelector:@selector(hide) withObject:nil afterDelay:2];
}

- (void)hide {
    if (self.alpha >= 1.0) {
        [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.transform = CGAffineTransformMakeScale(0.1, 0.1);
            self.alpha = 0.0;
        }completion:^(BOOL finished) {
            if (finished) {
                [self initZero];
            }
        }];
    }
}

@end
