//
//  CaptureVideoSheetView.m
//  CaptureVideoController
//
//  Created by jianting on 15/11/11.
//  Copyright © 2015年 jianting. All rights reserved.
//

#import "CaptureVideoSheetView.h"

#define Button_Width_Rate (200.0/316.5)

@implementation CaptureVideoSheetView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        for (UIView *v in self.subviews) {
            CGRect rect = v.frame;
            rect.origin.y += 20;
            v.frame = rect;
        }
       
        CGFloat maxHeight = CGRectGetHeight(self.frame) - CGRectGetMaxY(_progressView.frame);
        CGFloat width = maxHeight * Button_Width_Rate;
        [_shootButton setFrame:CGRectMake(CGRectGetMaxX(self.frame)/2-width/2, maxHeight/2-width/2+CGRectGetMaxY(_progressView.frame), width, width)];
    }
    return self;
}

@end
