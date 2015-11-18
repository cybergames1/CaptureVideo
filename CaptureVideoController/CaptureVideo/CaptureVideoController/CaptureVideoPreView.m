//
//  CaptureVideoPreView.m
//  CaptureVideoController
//
//  Created by jianting on 15/11/10.
//  Copyright © 2015年 jianting. All rights reserved.
//

#import "CaptureVideoPreView.h"

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

@end
