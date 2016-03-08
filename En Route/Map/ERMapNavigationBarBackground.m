//
//  ERMapNavigationBar.m
//  En Route
//
//  Created by Tanner on 2/18/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERMapNavigationBarBackground.h"


static const CGFloat kControlViewHeight = 140;
static const CGFloat kTFHeight          = 28;
static const CGFloat kTFSidePadding     = 6;
static const CGFloat kTFSpacing         = kTFSidePadding;
static const CGFloat kTFBottomPadding   = 12;


@interface ERMapNavigationBarBackground ()
@property (nonatomic, readonly) UIVisualEffectView *controlsBackgroundView;
@property (nonatomic, readonly) UIView *hairline;
@end

@implementation ERMapNavigationBarBackground

+ (instancetype)backgroundForBar:(UINavigationBar *)bar {
    CGRect r = bar.bounds;
    r.size.height = kControlViewHeight;
//    r.origin.y = -20;
    return [[self alloc] initWithFrame:r];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    frame.origin.y = 0;
    if (self) {
        CGRect zero = CGRectMake(0, 0, 1, 1);
        
        // Blurred background
        _controlsBackgroundView       = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
        _controlsBackgroundView.frame = frame;
        
        // Place text fields
        _startTextField = [[ERAddressTextField alloc] initWithFrame:zero];
        _endTextField   = [[ERAddressTextField alloc] initWithFrame:zero];
        _startTextField.nameLabel.text = @"Start:";
        _endTextField.nameLabel.text   = @"End:";
        _endTextField.fieldEntryOffset = _startTextField.estimatedFieldEntryOffset;
        
        // Nav bar hairline
        _hairline = [[UIView alloc] initWithFrame:zero];
        _hairline.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.301];
        
        // Add subviews
        [_controlsBackgroundView addSubview:_startTextField];
        [_controlsBackgroundView addSubview:_endTextField];
        [_controlsBackgroundView addSubview:_hairline];
        [self addSubview:_controlsBackgroundView];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat viewHeight = CGRectGetHeight(self.frame);
    CGFloat textFieldWidth = CGRectGetWidth(self.frame) - kTFSidePadding*2;
    CGFloat hairlineHeight = 1.f/[UIScreen mainScreen].scale;
    
    CGRect r = self.frame;
    r.origin.y = 0;
    _controlsBackgroundView.frame = r;
    
    _startTextField.frame = CGRectMake(kTFSidePadding, (viewHeight-kTFBottomPadding) - kTFHeight*2 - kTFSpacing, textFieldWidth, kTFHeight);
    _endTextField.frame   = CGRectMake(kTFSidePadding, (viewHeight-kTFBottomPadding) - kTFHeight, textFieldWidth, kTFHeight);
    _hairline.frame       = CGRectMake(0, viewHeight - hairlineHeight, CGRectGetWidth(self.frame), hairlineHeight);
}

@end


@implementation UINavigationBar (BarBackground)

- (void)hideDefaultBackground {
    self.backgroundColor = [UIColor clearColor];
    self.barTintColor    = [UIColor clearColor];
    self.translucent     = YES;
    self.shadowImage     = [UIImage new];
    [self setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
}

- (void)setBackgroundView_:(UIView *)view {
    [self hideDefaultBackground];
    self.clipsToBounds = NO;
    [self addSubview:view];
}

@end