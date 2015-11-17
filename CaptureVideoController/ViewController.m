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
#import "PQMoviePlayerController.h"

@interface ViewController () <CaptureVideoViewDelegate>


@property (nonatomic,retain) PQMoviePlayerController * moviePlayer;

@end

@implementation ViewController

- (void)dealloc
{
    [self stopPlayer];
    [super dealloc];
}

- (void)stopPlayer {
    if (_moviePlayer) {
        [_moviePlayer stop];
        [_moviePlayer.view removeFromSuperview];
        [_moviePlayer release];_moviePlayer = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"小视频";
    self.view.backgroundColor = [UIColor whiteColor];
    
}

//CaptureVideoViewDelegate

- (void)captureVideoViewDidCancel:(CaptureVideoView *)videoView {
    
}

- (void)captureVideoView:(CaptureVideoView *)videoView didFinishWithInfo:(NSDictionary *)info {
    CaptureVideoMode mode = [[info objectForKey:CaptureVideoUIMode] integerValue];
    if (mode == CaptureVideoModeRecording) {

        NSURL *fileURL = [info objectForKey:CaptureVideoURL];
        if (fileURL) {
            PQMoviePlayerController *moviePlayer = [[[PQMoviePlayerController alloc] initWithContentURL:fileURL] autorelease];
            moviePlayer.view.frame = self.view.bounds;
            moviePlayer.controlStyle = PQMovieControlStyleNone;
            moviePlayer.repeatMode = PQMovieRepeatModeLoop;
            [self.view addSubview:moviePlayer.view];
            self.moviePlayer = moviePlayer;
            
            [self.moviePlayer play];
        }
    }else {
        UIAlertView *aler = [[UIAlertView alloc] initWithTitle:nil message:@"是否继续发送" delegate:nil cancelButtonTitle:@"否" otherButtonTitles:@"是", nil];
        [aler show];
        [aler release];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self showVideoView];
}

- (void)showVideoView {
    [self stopPlayer];
    CaptureVideoSheetView *videoView = [[CaptureVideoSheetView alloc] init];
    videoView.delegate = self;
    [videoView show];
    [videoView release];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
