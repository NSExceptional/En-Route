//
//  ERCalloutButton.m
//  En Route
//
//  Created by London Steele on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERCalloutView.h"


@interface ERCalloutView ()
@property (nonatomic) UIButton *button;
@end

@implementation ERCalloutView

+ (instancetype)viewForAnnotation:(MKAnnotationView *)pin {
    return [[self alloc] initWithFrame:CGRectMake(0, 0, 52, CGRectGetHeight(pin.frame)+10)];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.tintColor          = [UIColor whiteColor];
        _button                 = [UIButton buttonWithType:UIButtonTypeSystem];
        _button.frame           = CGRectMake(0, 0, 52, CGRectGetHeight(frame));
        _button.backgroundColor = [UIColor colorWithRed:0.600 green:0.000 blue:1.000 alpha:1.000];
        [_button setTitle:@"Start" forState:UIControlStateNormal];
        
        _buttonTitleYOffset = 5;
        _button.titleEdgeInsets = UIEdgeInsetsMake(0, 0, _buttonTitleYOffset, 0);
        
        
        [self addSubview:_button];
        
        [_button addTarget:self action:@selector(didTapButton) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return self;
}

- (void)setUseDestinationButton:(BOOL)useDestinationButton {
    if (_useDestinationButton == useDestinationButton) return;
    _useDestinationButton = useDestinationButton;
    
    if (useDestinationButton)
        [_button setTitle:@"End" forState:UIControlStateNormal];
    else
        [_button setTitle:@"Start" forState:UIControlStateNormal];
}

- (void)setButtonTitleYOffset:(CGFloat)buttonTitleYOffset {
    _buttonTitleYOffset = buttonTitleYOffset;
    _button.titleEdgeInsets = UIEdgeInsetsMake(0, 0, _buttonTitleYOffset, 0);
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
