

#import <UIKit/UIKit.h>

@interface UIImage (__CaptureImageEffectss)

- (UIImage *)__applyLightEffect;
- (UIImage *)__applyExtraLightEffect;
- (UIImage *)__applyDarkEffect;
- (UIImage *)__applyTintEffectWithColor:(UIColor *)tintColor;

- (UIImage *)__applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage;

@end
