//
//  CaptureVideoView.h
//  CaptureVideoController
//
//  Created by jianting on 15/11/10.
//  Copyright © 2015年 jianting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CaptureVideoController.h"

/**
 * 拍摄控制界面
 * 包括视频拍摄界面和拍摄按钮等
 */

enum {
    CaptureVideoModeRecording, //正常录制退出模式
    CaptureVideoModeCancelled, //取消状态退出模式
};
typedef NSInteger CaptureVideoMode;

@protocol CaptureVideoViewDelegate;
@class ShootButton;
@interface CaptureVideoView : UIView <CaptureVideoControllerDelegate>
{
    CaptureVideoController * _videoController;
    ShootButton * _shootButton;
    UIView * _progressView;
    BOOL _isRecordFinish;
}

@property (nonatomic, assign) id<CaptureVideoViewDelegate> delegate;

- (void)startCapture;
- (void)stopCapture;

@end

@protocol CaptureVideoViewDelegate <NSObject>
@optional
- (void)captureVideoView:(CaptureVideoView *)videoView didFinishWithInfo:(NSDictionary *)info;
- (void)captureVideoViewDidCancel:(CaptureVideoView *)videoView;

@end

//info dictionary keys
UIKIT_EXTERN NSString *const CaptureVideoURL; //拍摄完成后生成的URL地址
UIKIT_EXTERN NSString *const CaptureVideoUIMode; //拍摄完成时，拍摄所处于的模式，当处于取消模式时，需要弹alert提示




