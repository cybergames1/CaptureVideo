//
//  CaptureVideoSheetView.m
//  CaptureVideoController
//
//  Created by jianting on 15/11/11.
//  Copyright © 2015年 jianting. All rights reserved.
//

#import "CaptureVideoSheetView.h"

#define Button_Width_Rate (200.0/316.5)

@interface CaptureVideoSheetView ()
{
    UIView * _recoardingView;
    UIButton * _backButton;
    UIView * _backgroundView;
}

@end

@implementation CaptureVideoSheetView

- (instancetype)init
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(window.frame), 400);
    self = [self initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:(4.0/255.0) green:(4.0/255.0) blue:(14.0/255.0) alpha:1.0];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:(4.0/255.0) green:(4.0/255.0) blue:(14.0/255.0) alpha:1.0];
        for (UIView *v in self.subviews) {
            CGRect rect = v.frame;
            rect.origin.y += 20;
            v.frame = rect;
        }
       
        CGFloat maxHeight = CGRectGetHeight(self.frame) - CGRectGetMaxY(_progressView.frame);
        CGFloat width = maxHeight * Button_Width_Rate;
        [_shootButton setFrame:CGRectMake(CGRectGetMaxX(self.frame)/2-width/2, maxHeight/2-width/2+CGRectGetMaxY(_progressView.frame), width, width)];
        
        [self addSubview:[self recoardingView]];
        [self addSubview:[self backButton]];
    }
    return self;
}

- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[[UIView alloc] init] autorelease];
        _backgroundView.backgroundColor = [UIColor blackColor];
        _backgroundView.alpha = 0.0;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backTap:)];
        [_backgroundView addGestureRecognizer:tap];
        [tap release];
    }
    return _backgroundView;
}

- (void)show {
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    [window addSubview:[self backgroundView]];
    [window addSubview:self];
    
    _backgroundView.frame = window.bounds;
    self.frame = CGRectMake(0, CGRectGetHeight(window.frame), CGRectGetWidth(window.frame), 400);
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _backgroundView.alpha = 0.6;
        CGRect rect = self.frame;
        rect.origin.y -= rect.size.height;
        self.frame = rect;
    }completion:nil];
}

- (void)hide {
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        CGRect rect = self.frame;
        rect.origin.y += rect.size.height;
        self.frame = rect;
        _backgroundView.alpha = 0.0;
    }completion:^(BOOL finished) {
        [super captureVideoWillStopRecording:_videoController];
        [self removeFromSuperview];
        [_backgroundView removeFromSuperview];
    }];
}

- (UIView *)recoardingView {
    if (!_recoardingView) {
        _recoardingView = [[[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.frame)/2-8/2, 20/2-8/2, 8, 8)] autorelease];
        _recoardingView.backgroundColor = [UIColor colorWithRed:1.0 green:(44.0/255.0) blue:(85.0/255.0) alpha:1.0];
        _recoardingView.layer.cornerRadius = CGRectGetWidth(_recoardingView.bounds)/2;
        _recoardingView.layer.masksToBounds = YES;
        _recoardingView.alpha = 0.0;
    }
    return _recoardingView;
}

- (UIButton *)backButton {
    if (!_backButton) {
        UIImage *image = [UIImage imageNamed:@"capture_back"];
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:image forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
        
        CGFloat maxHeight = CGRectGetHeight(self.frame) - CGRectGetMaxY(_progressView.frame);
        [_backButton setFrame:CGRectMake(15, maxHeight/2-image.size.height/2+CGRectGetMaxY(_progressView.frame), image.size.width, image.size.height)];
    }
    return _backButton;
}

- (void)backAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(captureVideoViewDidCancel:)]) {
        [self.delegate captureVideoViewDidCancel:self];
    }
    [self hide];
}

- (void)backTap:(UITapGestureRecognizer *)recognizer {
    [self backAction];
}

// --------------------------------
// CaptureVideoControllerDelegate
// --------------------------------

- (void)captureVideoWillStartRecording:(CaptureVideoController *)controller {
    [super captureVideoWillStartRecording:controller];
    _recoardingView.alpha = 1.0;
    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionRepeat animations:^{
        _recoardingView.alpha = 0.0;
    }completion:nil];
}

- (void)captureVideoWillStopRecording:(CaptureVideoController *)controller {
    [_recoardingView.layer removeAllAnimations];
    if (_isRecordFinish) {
        [self hide];
    }
}


@end
