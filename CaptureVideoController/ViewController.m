//
//  ViewController.m
//  CaptureVideoController
//
//  Created by jianting on 15/11/10.
//  Copyright © 2015年 jianting. All rights reserved.
//

#import "ViewController.h"
#import "CaptureVideoView.h"
#import "BViewController.h"
#import "CaptureVideoSheetView.h"

@interface ViewController () <CaptureVideoViewDelegate>
{
    BOOL _start;
    UIView * _videoSuperView;
    CaptureVideoView * _videoView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"小视频";
    self.view.backgroundColor = [UIColor whiteColor];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CaptureVideoView *videoView = [[CaptureVideoView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height-64)];
    videoView.delegate = self;
    [self.view addSubview:videoView];
    [videoView release];
    _videoView = videoView;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_videoView) {
        [_videoView stopCapture];
        [_videoView removeFromSuperview];
    }
}

- (void)captureVideoView:(CaptureVideoView *)videoView didFinishWithInfo:(NSDictionary *)info {
    CaptureVideoMode mode = [[info objectForKey:CaptureVideoUIMode] integerValue];
    if (mode == CaptureVideoModeRecording) {
        BViewController *controller = [[BViewController alloc] init];
        controller.fileURL = [info objectForKey:CaptureVideoURL];
        [self.navigationController pushViewController:controller animated:YES];
        [controller release];
    }else {
        UIAlertView *aler = [[UIAlertView alloc] initWithTitle:nil message:@"是否继续发送" delegate:nil cancelButtonTitle:@"否" otherButtonTitles:@"是", nil];
        [aler show];
        [aler release];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _start = !_start;
    
//    if (_start) {
//        [self showVideoView];
//    }else {
//        [self hideVideoView];
//    }
}

- (void)showVideoView {
    _videoSuperView = [[[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.height, 400)] autorelease];
    _videoSuperView.userInteractionEnabled = YES;
    [self.view addSubview:_videoSuperView];
    
    CaptureVideoView *videoView = [[CaptureVideoView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 400)];
    videoView.delegate = self;
    [_videoSuperView addSubview:videoView];
    [videoView release];
    _videoView = videoView;
    
//    [UIView animateWithDuration:0.25 animations:^{
//        CGRect rect = _videoSuperView.frame;
//        rect.origin.y -= rect.size.height;
//        _videoSuperView.frame = rect;
//    }completion:^(BOOL finished) {
//        //
//    }];
}

- (void)hideVideoView {
    [UIView animateWithDuration:0.25 animations:^{
        CGRect rect = _videoSuperView.frame;
        rect.origin.y += rect.size.height;
        _videoSuperView.frame = rect;
    }completion:^(BOOL finished) {
        [_videoSuperView removeFromSuperview];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
