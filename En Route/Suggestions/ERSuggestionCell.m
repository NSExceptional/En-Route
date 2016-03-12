//
//  ERSuggestionCell.m
//  En Route
//
//  Created by Tanner on 3/9/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERSuggestionCell.h"
#import "Masonry.h"


@interface ERSuggestionCell ()
@property (nonatomic, readonly) UIImageView *iconImageView;
@end

@implementation ERSuggestionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        _addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        _iconImageView = [[UIImageView alloc] initWithImage:nil];
        
        _addressLabel.font = [UIFont systemFontOfSize:14];
        _addressLabel.textColor = [[self class] secondaryColor];
        
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        
        [self.contentView addSubview:_nameLabel];
        [self.contentView addSubview:_addressLabel];
        [self.contentView addSubview:_iconImageView];
        
        self.clipsToBounds = YES;
    }
    
    return self;
}

+ (BOOL)requiresConstraintBasedLayout { return YES; }

- (void)updateConstraints {
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@24);
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.top.greaterThanOrEqualTo(@8);
        make.bottom.lessThanOrEqualTo(self.contentView.mas_bottom).with.offset(-8);
    }];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.greaterThanOrEqualTo(@12);
        make.left.equalTo(self.iconImageView.mas_right).with.offset(12);
        make.right.equalTo(self.contentView.mas_right).with.offset(-15);
    }];
    [self.addressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).with.offset(4);
        make.bottom.lessThanOrEqualTo(self.contentView.mas_bottom).with.offset(-12);
        make.left.equalTo(self.nameLabel.mas_left);
        make.right.equalTo(self.nameLabel.mas_right);
    }];
    
    // Do not compress image view
    [self.iconImageView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.iconImageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    [super updateConstraints];
}

- (void)setIcon:(UIImage *)icon {
    self.iconImageView.image = icon;
    self.nameLabel.preferredMaxLayoutWidth = CGRectGetMaxX(self.iconImageView.frame) + 12 - 15;
    self.addressLabel.preferredMaxLayoutWidth = self.nameLabel.preferredMaxLayoutWidth;
}

+ (UIColor *)secondaryColor { return [UIColor colorWithWhite:0.500 alpha:1.000]; }

@end
