//
//  ERTextFieldCell.m
//  En Route
//
//  Created by Tanner on 3/12/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERTextFieldCell.h"
#import "Masonry.h"


@interface ERTextFieldCell () <UITextFieldDelegate>
@property (nonatomic, readonly) UITextField *textField;
@end

@implementation ERTextFieldCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        [self.contentView addSubview:self.textField];
        
        [self awakeFromNib];
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.textField.font                     = [UIFont systemFontOfSize:17];
    self.textField.delegate                 = self;
    self.textField.leftViewMode             = UITextFieldViewModeAlways;
    self.textField.returnKeyType            = UIReturnKeyDone;
    self.textField.autocorrectionType       = UITextAutocorrectionTypeNo;
    self.textField.autocapitalizationType   = UITextAutocapitalizationTypeNone;
    self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
}

+ (BOOL)requiresConstraintBasedLayout { return YES; }

- (void)updateConstraints {
    [self.textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.left.equalTo(@15);
        make.right.equalTo(self.contentView);
    }];
    
    [super updateConstraints];
}

- (void)setText:(NSString *)text {
    self.textField.text = text;
}

- (NSString *)text {
    return self.textField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

@end
