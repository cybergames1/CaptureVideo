//
//  BViewController.m
//  CaptureVideoController
//
//  Created by jianting on 15/11/10.
//  Copyright © 2015年 jianting. All rights reserved.
//

#import "BViewController.h"
#import "PQMoviePlayerController.h"

@interface BViewController ()

@property (nonatomic,retain) PQMoviePlayerController * moviePlayer;

@end

@implementation BViewController

- (void)dealloc
{
    [_fileURL release];_fileURL = nil;
    if (_moviePlayer) {
        [_moviePlayer stop];
        [_moviePlayer release];_moviePlayer = nil;
    }
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"预览";
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSLog(@"fileurl:%@",_fileURL);
    PQMoviePlayerController *moviePlayer = [[[PQMoviePlayerController alloc] initWithContentURL:_fileURL] autorelease];
    moviePlayer.view.frame = self.view.bounds;
    moviePlayer.controlStyle = PQMovieControlStyleNone;
    moviePlayer.repeatMode = PQMovieRepeatModeLoop;
    [self.view addSubview:moviePlayer.view];
    self.moviePlayer = moviePlayer;
    
    [self.moviePlayer play];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
