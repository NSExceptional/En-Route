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
    
    self.chevron.image = [[UIImage imageNamed:@"chevron"] tintedImageWithColor:[UIColor lightGrayColor]];
}

- (void)flipChevron {
    self.chevron.layer.affineTransform = CGAffineTransformMakeRotation(M_PI);
}

@end




