//
//  PQProgressView.h
//  PaPaQi
//
//  Created by jianting on 14-2-19.
//  Copyright (c) 2014年 iQiYi. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * 支持渐变的进度条
 */
@interface ProgressView : UIView

@property (nonatomic, retain) UIImageView * imageView;

@end

@interface PQProgressView : UIView

@property (nonatomic, retain) ProgressView * progressImageView;
@property (nonatomic, retain) UIImageView * trackImageView;

@property (nonatomic, retain) UIImage * progressImage;
@property (nonatomic, retain) UIImage * trackImage;

@property (nonatomic, retain) UIColor * progressColor;
@property (nonatomic, retain) UIColor * trackColor;

@property (nonatomic, assign) CGFloat progress;

@end
