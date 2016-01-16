//
//  ERListItemCell.m
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERListItemCell.h"


@interface UIImage (foo)
- (UIImage *)tintedImageWithColor:(UIColor *)tintColor;
@end

@implementation ERListItemCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.chevron.image = [[UIImage imageNamed:@"chevron"] tintedImageWithColor:[UIColor lightGrayColor]];
    self.chevron.layer.affineTransform = CGAffineTransformMakeRotation(M_PI);
}

@end




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