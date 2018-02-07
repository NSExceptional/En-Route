//
//  ERListActivityCell.m
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERListActivityCell.h"

@implementation ERListActivityCell

- (void)awakeFromNib {
    [super awakeFromNib];

    self.layoutMargins = UIEdgeInsetsZero;
    
    self.backgroundColor = nil;
    self.contentView.backgroundColor = nil;
    self.icon.layer.cornerRadius = 7;
    self.icon.layer.masksToBounds = YES;
}

@end
