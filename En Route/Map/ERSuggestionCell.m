//
//  ERSuggestionCell.m
//  En Route
//
//  Created by Tanner on 3/9/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERSuggestionCell.h"
#import "Masonry.h"


@implementation ERSuggestionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        _addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        _iconImageView = [[UIImageView alloc] initWithImage:nil];
        
        _addressLabel.font = [UIFont systemFontOfSize:14];
        _addressLabel.textColor = [UIColor colorWithWhite:0.500 alpha:1.000];
        
        [self awakeFromNib];
    }
    
    return self;
}

- (void)updateConstraints {
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).with.offset(24);
        make.centerY.equalTo(self.mas_centerY);
    }];
    
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.iconImageView.mas_right).with.offset(12);
        make.top.equalTo(self.mas_top).with.offset(12);
        make.right.equalTo(self.mas_right).with.offset(15);
    }];
    
    [self.addressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.iconImageView.mas_right).with.offset(12);
        make.top.equalTo(self.nameLabel.mas_bottom).with.offset(6);
        make.right.equalTo(self.mas_right).with.offset(15);
        make.bottom.equalTo(self.mas_bottom).with.offset(12);
    }];
    
    [super updateConstraints];
}

+ (UIColor *)secondaryColor { return [UIColor colorWithWhite:0.500 alpha:1.000]; }

@end
