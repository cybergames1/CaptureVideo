//
//  CaptureVideoPreView.m
//  CaptureVideoController
//
//  Created by jianting on 15/11/10.
//  Copyright © 2015年 jianting. All rights reserved.
//

#import "CaptureVideoPreView.h"

@interface CaptureVideoPreView ()
{
    UIImageView * _focusImageView;
}

@end
@implementation CaptureVideoPreView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)captureSession {
    return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setCaptureSession:(AVCaptureSession *)captureSession {
    return [(AVCaptureVideoPreviewLayer *)[self layer] setSession:captureSession];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _focusImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)] autorelease];
        _focusImageView.image = [UIImage imageNamed:@"capture_focus"];
        _focusImageView.alpha = 0.f;
        [self addSubview:_focusImageView];
    }
    return self;
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

@end
