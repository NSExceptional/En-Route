//
//  ERListItemCell.m
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERListItemCell.h"
#import "UIImage+Util.h"


@implementation ERListItemCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.layoutMargins = UIEdgeInsetsZero;
    self.chevron.image = [[UIImage imageNamed:@"chevron"] tintedImageWithColor:[UIColor lightGrayColor]];
}

- (void)setFlipped:(BOOL)flipped {
    if (_flipped == flipped) return;
    if (_flipped) {
        self.chevron.transform = CGAffineTransformMakeRotation(0);
        self.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0);
    } else {
        self.chevron.transform = CGAffineTransformMakeRotation(M_PI);
        self.separatorInset = UIEdgeInsetsZero;
    }
    
    _flipped = flipped;
}

- (void)flipChevron {
    BOOL flipped = self.flipped;
    _flipped = !_flipped;
    
    [UIView animateSmoothly:^{
        if (flipped) {
            self.chevron.transform = CGAffineTransformMakeRotation(0);
            self.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0);
        } else {
            self.chevron.transform = CGAffineTransformMakeRotation(M_PI);
            self.separatorInset = UIEdgeInsetsZero;
        }
    }];
}

@end




