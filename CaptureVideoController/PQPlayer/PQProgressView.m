//
//  PQProgressView.m
//  PaPaQi
//
//  Created by jianting on 14-2-19.
//  Copyright (c) 2014年 iQiYi. All rights reserved.
//

#import "PQProgressView.h"


@implementation ProgressView

- (void)dealloc {
    [_imageView release];_imageView = nil;
    [super dealloc];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *imageView = [[[UIImageView alloc] initWithFrame:self.bounds] autorelease];
        [self addSubview:imageView];
        self.imageView = imageView;
    }
    return self;
}

//- (void)drawRect:(CGRect)rect {
//    if (!self.imageView.image) {
//        [self drawGradientColor:UIGraphicsGetCurrentContext() rect:self.bounds point:CGPointMake(self.frame.size.width-60, 0) point:CGPointMake(self.frame.size.width, 0) options:kCGGradientDrawsBeforeStartLocation startColor:[UIColor colorWithRed:(69.0/255.0) green:(176.0/255.0) blue:0.0 alpha:1.0] endColor:[UIColor colorWithRed:(93.0/255.0) green:(238.0/255.0) blue:0.0 alpha:1.0]];
//    }
//    [super drawRect:rect];
//}

- (void)drawGradientColor:(CGContextRef)context
                     rect:(CGRect)clipRect
                    point:(CGPoint) startPoint
                    point:(CGPoint) endPoint
                  options:(CGGradientDrawingOptions) options
               startColor:(UIColor*)startColor
                 endColor:(UIColor*)endColor
{
    UIColor* colors [2] = {startColor,endColor};
    CGColorSpaceRef rgb =CGColorSpaceCreateDeviceRGB();
    CGFloat colorComponents[8];
    
    for (int i = 0; i < 2; i++) {
        UIColor *color = colors[i];
        CGColorRef temcolorRef = color.CGColor;
        
        const CGFloat *components = CGColorGetComponents(temcolorRef);
        for (int j = 0; j < 4; j++) {
            colorComponents[i *4 + j] = components[j];
        }
    }
    
    CGGradientRef gradient = CGGradientCreateWithColorComponents(rgb, colorComponents,NULL, 2);
    
    CGColorSpaceRelease(rgb);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, options);
    CGGradientRelease(gradient);
}

@end

@implementation PQProgressView

- (void)dealloc
{
    [_progressImageView release];
    [_trackImageView release];
    [_progressImage release];
    [_progressColor release];
    [_trackImage    release];
    [_trackColor    release];
    
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.backgroundColor = [UIColor clearColor];
        
        UIImageView *trackImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _trackImageView = trackImageView;
        
        ProgressView *progressImageView = [[ProgressView alloc] initWithFrame:self.bounds];
        progressImageView.hidden = YES;
        progressImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        _progressImageView = progressImageView;
        
        [self addSubview:_trackImageView];
        [self addSubview:_progressImageView];
        
        self.progress = 0.0;
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    _trackImageView.frame = self.bounds;
    _progressImageView.frame = self.bounds;
}

- (void)setTrackImage:(UIImage *)trackImage
{
    if (_trackImage != trackImage)
    {
        [_trackImage release];
        _trackImage = [trackImage retain];
        
        _trackImageView.image = _trackImage;
    }
}

- (void)setProgressImage:(UIImage *)progressImage
{
    if (_progressImage != progressImage)
    {
        [_progressImage release];
        _progressImage = [progressImage retain];
        
        _progressImageView.imageView.image = _progressImage;
    }
}

- (void)setTrackColor:(UIColor *)trackColor
{
    if (_trackColor != trackColor)
    {
        [_trackColor release];
        _trackColor = [trackColor retain];
        
        _trackImageView.backgroundColor = _trackColor;
    }
}

- (void)setProgressColor:(UIColor *)progressColor
{
    if (_progressColor != progressColor)
    {
        [_progressColor release];
        _progressColor = [progressColor retain];
        
        _progressImageView.backgroundColor = _progressColor;
    }
}

- (void)setProgress:(CGFloat)progress
{
//    if (_progress != progress)
//    {
        _progress = progress;
        
        if (_progress <= 0.0)
        {
            _progressImageView.hidden = YES;
            
            CGRect rect = _progressImageView.frame;
            rect.size.width = 0.0;
            _progressImageView.frame = rect;
        }
        else if (_progress >= 1.0)
        {
            _progressImageView.hidden = NO;
            
            CGRect rect = _progressImageView.frame;
            rect.size.width = self.frame.size.width;
            _progressImageView.frame = rect;
        }
        else
        {
            _progressImageView.hidden = NO;
            
            CGRect rect = _progressImageView.frame;
            rect.size.width = self.frame.size.width * progress;
            _progressImageView.frame = rect;
        }
//    }
    
    [_progressImageView setNeedsDisplay];
}

@end
