//
//  CaptureVideoView.m
//  CaptureVideoController
//
//  Created by jianting on 15/11/10.
//  Copyright © 2015年 jianting. All rights reserved.
//

#import "CaptureVideoView.h"
#import "CaptureVideoController.h"

#define VideoSize_320x240 (320.0/240.0)
#define MAX_WriteSec 6.0 //6秒视频
#define Button_Width_Rate (200.0/316.5)

NSString *const CaptureVideoURL = @"CaptureVideoURL";
NSString *const CaptureVideoUIMode = @"CaptureVideoUIMode";

@interface CaptureVideoView () <CaptureVideoControllerDelegate>
{
    CaptureVideoController * _videoController;
    UIView * _progressView;
    UILabel * _cancelLabel;
    UIView * _shootButton;
    
    BOOL _isShooting;
    CGFloat _currentVideoDur;
    CaptureVideoMode _videoMode;
    BOOL _isRecordFinish;
}

@property (nonatomic, retain) NSTimer * writeTimer;

@end

@implementation CaptureVideoView

- (void)dealloc
{
    [_videoController.view removeFromSuperview];
    [_videoController release];_videoController = nil;
    [_writeTimer release];_writeTimer = nil;
    [super dealloc];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:[[self videoController] view]];
        [self addSubview:[self progressView]];
        [self addSubview:[self cancelLabel]];
        [self addSubview:[self shootButton]];
        [self addGestureRecognizer:[self longPressGesture]];
        
        _isShooting = NO;
        _currentVideoDur = 0.0;
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
        _videoController.view.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.width*(1.0/VideoSize_320x240));
    }
    return _videoController;
}

- (UIView *)progressView {
    if (!_progressView) {
        _progressView = [[[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY([self videoController].view.frame), self.frame.size.width, 5)] autorelease];
        _progressView.backgroundColor = [UIColor greenColor];
    }
    return _progressView;
}

- (UILabel *)cancelLabel {
    if (!_cancelLabel) {
        _cancelLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY([self videoController].view.frame)-40, self.frame.size.width, 20)] autorelease];
        _cancelLabel.backgroundColor = [UIColor clearColor];
        _cancelLabel.font = [UIFont systemFontOfSize:15.0];
        _cancelLabel.textAlignment = NSTextAlignmentCenter;
        _cancelLabel.textColor = [UIColor greenColor];
        _cancelLabel.text = @"上移取消";
    }
    return _cancelLabel;
}

- (UIView *)shootButton {
    if (!_shootButton) {
        CGFloat maxHeight = CGRectGetHeight(self.frame) - CGRectGetMaxY(_progressView.frame);
        CGFloat width = maxHeight * Button_Width_Rate;
        NSLog(@"maxheight:%f",maxHeight);
        
        _shootButton = [[[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.frame)/2-width/2, maxHeight/2-width/2+CGRectGetMaxY(_progressView.frame), width, width)] autorelease];
        _shootButton.backgroundColor = [UIColor greenColor];
        _shootButton.layer.cornerRadius = _shootButton.frame.size.width/2;
        _shootButton.layer.masksToBounds = YES;
    }
    return _shootButton;
}

- (UILongPressGestureRecognizer *)longPressGesture {
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    recognizer.minimumPressDuration = 0.25;
    recognizer.allowableMovement = 3.0;
    return [recognizer autorelease];
}

- (void)longPressAction:(UILongPressGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            if (CGRectContainsPoint(_shootButton.frame, [recognizer locationInView:self])) {
                _isShooting = YES;
                [self startRecording];
                NSLog(@"shooting");
            }else {
                NSLog(@"not shoot");
            }
        }
            break;
        case UIGestureRecognizerStateChanged:
            if (_isShooting) {
                if (CGRectContainsPoint(_videoController.view.frame, [recognizer locationInView:self])) {
                    NSLog(@"cancell");
                    [self becomeCancelMode];
                }else {
                    NSLog(@"contune");
                    [self becomeRecordMode];
                }
            }
            break;
        case UIGestureRecognizerStateEnded:
            _isShooting = NO;
            if (_videoMode == CaptureVideoModeRecording) {
                _isRecordFinish = YES;
            }
            [self stopRecording];
            break;
        case UIGestureRecognizerStateCancelled:
            _isShooting = NO;
            break;
        default:
            break;
    }
}

- (void)startCapture {
    [[self videoController] startCamera];
}

- (void)stopCapture {
    [[self videoController] stopCamera];
}

//重置界面
- (void)resetUI {
    [self setProgress:0.0];
    _progressView.backgroundColor = [UIColor greenColor];
    
    _cancelLabel.text = @"上移取消";
    _cancelLabel.textColor = [UIColor greenColor];
    
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
}

- (void)stopRecording {
    [_videoController stopRecording];
    [self stopRecordTimer];
    [self resetUI];
}

- (void)becomeCancelMode {
    _progressView.backgroundColor = [UIColor redColor];
    _cancelLabel.textColor = [UIColor redColor];
    _cancelLabel.text = @"松手取消";
    _videoMode = CaptureVideoModeCancelled;
}

- (void)becomeRecordMode {
    _progressView.backgroundColor = [UIColor greenColor];
    _cancelLabel.textColor = [UIColor greenColor];
    _cancelLabel.text = @"上移取消";
    _videoMode = CaptureVideoModeRecording;
}

// --------------------------------
// 录制计时器
// --------------------------------
- (void)startRecordTimer {
    [self stopRecordTimer];
    self.writeTimer = [NSTimer scheduledTimerWithTimeInterval:0.033 target:self selector:@selector(recordTime) userInfo:nil repeats:YES];
}

- (void)stopRecordTimer {
    if ([self.writeTimer isValid]) {
        [self.writeTimer invalidate];
        self.writeTimer = nil;
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
    
    CGRect rect = _progressView.frame;
    rect.origin.x = progressWidth/2;
    rect.size.width = self.frame.size.width - progressWidth;
    _progressView.frame = rect;
}

// --------------------------------
// CaptureVideoControllerDelegate
// --------------------------------

- (void)captureVideoDidStartRecording:(CaptureVideoController *)controller {
    
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
