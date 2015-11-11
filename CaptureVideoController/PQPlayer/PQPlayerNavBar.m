//
//  PQPlayerNavBar.m
//  Player
//
//  Created by jianting on 14-5-21.
//  Copyright (c) 2014年 jianting. All rights reserved.
//

#import "PQPlayerNavBar.h"

@interface PQPlayerNavBar ()
{
    UIView *_backgroundView;
}

@end

@implementation PQPlayerNavBar

@synthesize titleLabel = _titleLabel;

- (void)dealloc
{
    [_titleLabel release];
    _titleLabel   =   nil;
    
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
//        _backgroundView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
//        _backgroundView.backgroundColor = [UIColor grayColor];
//        _backgroundView.alpha = 0.5;
//        [self addSubview:_backgroundView];
        
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [backButton setFrame:CGRectMake(10, 44/2-20/2, 12, 20)];
        [backButton setImage:[UIImage imageNamed:@"camera_share_back"] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(backAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:backButton];
        
        UIButton *backBigButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [backBigButton setFrame:CGRectMake(0, 0, 100, 100)];
        [backBigButton addTarget:self action:@selector(backAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:backBigButton];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(52, (44 - 20) / 2 + 20, frame.size.width - 104, 20)];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_titleLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    _backgroundView.frame = self.bounds;
    _titleLabel.frame = CGRectMake(52, (44 - 20) / 2 + 20, self.frame.size.width - 62, 20);
}

- (void)backAction:(UIButton *)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(PQPlayerNavBarGoback:)])
    {
        [_delegate PQPlayerNavBarGoback:self];
    }
}

/** 阻断touch事件向上传 **/
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
}


@end
