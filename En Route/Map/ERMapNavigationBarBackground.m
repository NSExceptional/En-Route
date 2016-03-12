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
@property (nonatomic) BOOL isShrinkingOrGrowing;

@property (nonatomic) UIImageView *startImageView;
@property (nonatomic) UIImageView *endImageView;

@property (nonatomic, readonly) UIImage *defaultStartImage;
@property (nonatomic, readonly) UIImage *defaultendImage;
@end

@implementation ERMapNavigationBarBackground

- (id)init {
    return [self initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, kControlViewHeight)];
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
        _startTextField.returnKeyType = UIReturnKeyNext;
        _endTextField.returnKeyType   = UIReturnKeyRoute;
        _startTextField.enablesReturnKeyAutomatically = YES;
        _endTextField.enablesReturnKeyAutomatically   = YES;
        
        
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
    
    if (self.isShrinkingOrGrowing) return;
    
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

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    // Dispatch because sometimes start text field wasn't captured
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _defaultStartImage = [self.startTextField asImage];
        _defaultendImage = [self.endTextField asImage];
    });
}

- (void)setShrunken:(BOOL)shrunken {
    if (_shrunken == shrunken) return;
    _shrunken = shrunken;
    
    // Add dummy views, hide actual views
    if (shrunken) {
        [self replaceViewsWithImages];
    } else {
        [self updateImageViews];
    }
    
    self.isShrinkingOrGrowing = YES;
    [UIView animateSmoothly:^{
        if (_shrunken)
            [self shrink];
        else
            [self grow];
    } completion:^(BOOL finished) {
        self.isShrinkingOrGrowing = NO;
        
        // Remove dummy views
        if (!shrunken) {
            self.startTextField.hidden = NO;
            self.endTextField.hidden = NO;
            
            [self.startImageView removeFromSuperview];
            [self.endImageView removeFromSuperview];
            
            self.startImageView = nil;
            self.endImageView = nil;
        }
    }];
}

- (void)replaceViewsWithImages {
    self.startImageView = [[UIImageView alloc] initWithImage:[self.startTextField asImage]];
    self.endImageView   = [[UIImageView alloc] initWithImage:[self.endTextField asImage]];
    
    self.startImageView.frame = self.startTextField.frame;
    self.endImageView.frame = self.endTextField.frame;
    
    self.startTextField.hidden = YES;
    self.endTextField.hidden = YES;
    
    [_controlsBackgroundView addSubview:self.startImageView];
    [_controlsBackgroundView addSubview:self.endImageView];
}

- (void)updateImageViews {
    // Go back to the empty image if there's no text in the fields now
    if (!self.startTextField.text.length)
        self.startImageView.image = self.defaultStartImage;
    if (!self.endTextField.text.length)
        self.endImageView.image = self.defaultendImage;
}

- (void)shrink {
    CGFloat viewHeight = 64;
    CGFloat hairlineHeight = 1.f/[UIScreen mainScreen].scale;
    CGFloat tfRatio = CGRectGetWidth(_startTextField.frame) / CGRectGetHeight(_startTextField.frame);
    CGFloat textFieldWidth = tfRatio;
    CGFloat centerX = self.center.x - tfRatio/2.f;
    
    [self setFrameHeight:viewHeight];
    _controlsBackgroundView.frame = self.frame;
    [self.hairline setFrameY:viewHeight - hairlineHeight];
    
    [self.startImageView setFrameSize:CGSizeMake(textFieldWidth, 1)];
    [self.endImageView setFrameSize:CGSizeMake(textFieldWidth, 1)];
    
    [self.startImageView setFrameOrigin:CGPointMake(centerX, viewHeight - kTFSidePadding - kTFBottomPadding - 1)];
    [self.endImageView setFrameOrigin:CGPointMake(centerX, viewHeight - kTFBottomPadding - 1)];
    
    self.startImageView.alpha = 0;
    self.endImageView.alpha = 0;
}

- (void)grow {
    [self setFrameHeight:kControlViewHeight];
    
    CGFloat viewHeight = kControlViewHeight;
    CGFloat hairlineHeight = 1.f/[UIScreen mainScreen].scale;
    
    CGRect r = self.frame;
    r.origin.y = 0;
    _controlsBackgroundView.frame = r;
    
    self.startImageView.frame = self.startTextField.frame;
    self.endImageView.frame   = self.endTextField.frame;
    self.hairline.frame   = CGRectMake(0, viewHeight - hairlineHeight, CGRectGetWidth(self.frame), hairlineHeight);
    
    self.startImageView.alpha = 1;
    self.endImageView.alpha = 1;
}

@end
