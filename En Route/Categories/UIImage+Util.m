//
//  UIImage+Util.m
//  En Route
//
//  Created by Tanner on 1/17/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "UIImage+Util.h"

@implementation UIImage (foo)

- (UIImage *)tintedImageWithColor:(UIColor *)tintColor {
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    UIRectFill(bounds);
    
    [self drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0];
    
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}

@end
