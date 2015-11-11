//
//  CaptureVideoSheetView.m
//  CaptureVideoController
//
//  Created by jianting on 15/11/11.
//  Copyright © 2015年 jianting. All rights reserved.
//

#import "CaptureVideoSheetView.h"

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
    }
    return self;
}

@end
