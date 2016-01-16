//
//  ERAdressTextField.m
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERAddressTextField.h"


static const CGFloat kLabelToFieldPadding = 8;

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation ERAddressTextField

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.borderStyle = UITextBorderStyleNone;
        self.layer.cornerRadius = 5;
        self.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.060];
        self.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        self.textColor = [UIColor blackColor];
        
        _nameLabel           = [[UILabel alloc] initWithFrame:CGRectMake(6, 0, 1, 1)];
        _nameLabel.text      = @"Text:";
        _nameLabel.font      = self.font;
        _nameLabel.textColor = [UIColor colorWithWhite:0.000 alpha:0.562];
        [self addSubview:_nameLabel];
    }
    
    return self;
}

- (void)layoutSubviews {
    
    [self.nameLabel sizeToFit];
    CGRect frame = _nameLabel.frame;
    frame.origin.x = 6;
    frame.origin.y = (self.frame.size.height - frame.size.height) / 2.f;
    _nameLabel.frame = frame;
    
    // Calculate new offset or use existing offset
    CGFloat offset = CGRectGetMaxX(frame) + kLabelToFieldPadding;
    _fieldEntryOffset = MAX(_fieldEntryOffset, offset);
    [super layoutSubviews];
}

#pragma mark - Positioning subviews

- (void)setFieldEntryOffset:(CGFloat)fieldEntryOffset {
    _fieldEntryOffset = fieldEntryOffset;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (CGFloat)estimatedFieldEntryOffset {
    [_nameLabel sizeToFit];
    return MAX(CGRectGetMaxX(_nameLabel.frame) + kLabelToFieldPadding, _fieldEntryOffset);
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    // Workaround to a weird bug where `bounds` was {0, 0, 100, 100)
    // which causes CGRectInset to return a null rect in some cases.
    if (bounds.size.width == 100)
        return [super textRectForBounds:bounds];
    return CGRectInset(bounds, _fieldEntryOffset, 0);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, _fieldEntryOffset, 0);
}

#pragma mark - Parent overrides

- (void)setText:(NSString *)text {
    [super setText:text];
    self.drawsAsAtom = [text isEqualToString:@"Current location"];
}

@end
