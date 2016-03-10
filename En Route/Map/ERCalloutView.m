//
//  ERCalloutButton.m
//  En Route
//
//  Created by London Steele on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERCalloutView.h"


static CGFloat dx = 5;
static CGFloat dy = 10;
static CGFloat kCalloutWidth = 52;

@interface ERCalloutView ()
@property (nonatomic) UIButton *button;
@end

@implementation ERCalloutView

+ (instancetype)viewForAnnotation:(MKAnnotationView *)pin {
    return [[self alloc] initWithFrame:CGRectMake(-dx, -dy, kCalloutWidth + dx, CGRectGetHeight(pin.frame)+dy)];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.tintColor          = [UIColor whiteColor];
        _button                 = [UIButton buttonWithType:UIButtonTypeSystem];
        _button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _button.backgroundColor = [UIColor colorWithRed:0.600 green:0.000 blue:1.000 alpha:1.000];
        [_button setTitle:@"Start" forState:UIControlStateNormal];
        
        
        _buttonTitleYOffset = 5;
        _button.titleEdgeInsets = UIEdgeInsetsMake(0, 0, _buttonTitleYOffset, 0);
        
        
        [self addSubview:_button];
        
        [_button addTarget:self action:@selector(didTapButton) forControlEvents:UIControlEventTouchUpInside];
        self.useDestinationButton = self.useDestinationButton;
    }
    
    return self;
}

- (void)setFrame:(CGRect)frame {
    super.frame   = frame;
    _button.frame = frame;
}

- (void)setUseDestinationButton:(BOOL)useDestinationButton {
    _useDestinationButton = useDestinationButton;
    
    if (useDestinationButton) {
        [_button setTitle:@"End" forState:UIControlStateNormal];
        self.buttonColor = [[UIApplication sharedApplication].delegate window].tintColor;
    } else {
        [_button setTitle:@"Start" forState:UIControlStateNormal];
        self.buttonColor = [UIColor colorWithRed:0.263 green:0.835 blue:0.318 alpha:1.000];
    }
}

- (void)setButtonTitleYOffset:(CGFloat)buttonTitleYOffset {
    _buttonTitleYOffset = buttonTitleYOffset;
    _button.titleEdgeInsets = UIEdgeInsetsMake(0, 0, _buttonTitleYOffset, 0);
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    // Fix weird alignment of callout views on 6s+
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.superview.backgroundColor = self.button.backgroundColor;
        self.superview.clipsToBounds = NO;
    });
}

#pragma mark - Colors

- (void)setButtonColor:(UIColor *)buttonColor {
    _button.backgroundColor = buttonColor;
}

- (UIColor *)buttonColor {
    return _button.backgroundColor;
}

#pragma mark - Actions

- (void)didTapButton {
    if (self.buttonTapHandler)
        self.buttonTapHandler();
}

@end
