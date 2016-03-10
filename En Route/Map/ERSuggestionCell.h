//
//  ERSuggestionCell.h
//  En Route
//
//  Created by Tanner on 3/9/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ERSuggestionCell : UITableViewCell

@property (nonatomic, readonly) UILabel *nameLabel;
@property (nonatomic, readonly) UILabel *addressLabel;

@property (nonatomic, readonly) UIImageView *iconImageView;

+ (UIColor *)secondaryColor;

@end
