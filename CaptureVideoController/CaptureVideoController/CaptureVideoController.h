//
//  CaptureVideoController.h
//  CaptureVideoController
//
//  Created by jianting on 15/11/10.
//  Copyright © 2015年 jianting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CaptureVideoPreView.h"

@protocol CaptureVideoControllerDelegate;

@interface CaptureVideoController : NSObject

@property (nonatomic, readonly) CaptureVideoPreView * view;

@property (nonatomic, readonly) NSURL * outputURL;

@property (nonatomic, assign) id<CaptureVideoControllerDelegate> delegate;

/** 开启和关闭相机 **/
- (void)startCamera;
- (void)stopCamera;

/** 录制视频的相关操作 **/
- (void)startRecordingToOutputFileURL:(NSURL *)fileURL;
- (void)stopRecording;

@end

@protocol CaptureVideoControllerDelegate <NSObject>

@optional

/** 录制的回调 **/
- (void)captureVideoWillStartRecording:(CaptureVideoController *)controller;
- (void)captureVideoDidStartRecording:(CaptureVideoController *)controller;
- (void)captureVideoWillStopRecording:(CaptureVideoController *)controller;
- (void)captureVideoDidStopRecording:(CaptureVideoController *)controller;

@end
