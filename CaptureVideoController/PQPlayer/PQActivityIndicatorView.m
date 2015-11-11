//
//  PQActivityIndicatorView.m
//  Papaqi
//
//  Created by jianting on 15/8/13.
//  Copyright (c) 2015年 PPQ. All rights reserved.
//

#import "PQActivityIndicatorView.h"

@implementation PQActivityIndicatorView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.image = [UIImage imageNamed:@"videoPlayer_loading"];
        self.bounds = CGRectMake(0, 0, self.image.size.width, self.image.size.height);
    }
    return self;
}

- (void)startAnimating {
    self.hidden = NO;
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: -M_PI * 2.0 ];
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    rotationAnimation.duration = 2;
    rotationAnimation.repeatCount = 1000;
    rotationAnimation.cumulative = NO;
    rotationAnimation.removedOnCompletion = NO;
    rotationAnimation.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:rotationAnimation forKey:@"Rotation"];
}

- (void)stopAnimating {
    [self.layer removeAnimationForKey:@"Rotation"];
    self.hidden = YES;
}

@end
