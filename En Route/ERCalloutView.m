//
//  ERCalloutButton.m
//  En Route
//
//  Created by London Steele on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERCalloutView.h"


@interface ERCalloutView ()
@property (nonatomic) UIButton *leftButton;
@property (nonatomic) UIButton *rightButton;
@end

@implementation ERCalloutView

+ (instancetype)viewForAnnotation:(MKPinAnnotationView *)pin {
    return [[self alloc] initWithFrame:CGRectMake(0, 0, 104, CGRectGetHeight(pin.frame)+10)];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.tintColor               = [UIColor whiteColor];
        _leftButton                  = [UIButton buttonWithType:UIButtonTypeSystem];
        _rightButton                 = [UIButton buttonWithType:UIButtonTypeSystem];
        _leftButton.frame            = CGRectMake(0, 0, 52, CGRectGetHeight(frame));
        _rightButton.frame           = CGRectMake(52, 0, 52, CGRectGetHeight(frame));
        _leftButton.backgroundColor  = [UIColor colorWithRed:0.200 green:0.400 blue:1.000 alpha:1.000];
        _rightButton.backgroundColor = [UIColor colorWithRed:0.600 green:0.000 blue:1.000 alpha:1.000];
        [_leftButton setTitle:@"Start" forState:UIControlStateNormal];
        [_rightButton setTitle:@"End" forState:UIControlStateNormal];
        _leftButton.titleEdgeInsets  = _rightButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 5, 0);
        
        [self addSubview:_leftButton];
        [self addSubview:_rightButton];
        
        [_leftButton addTarget:self action:@selector(didTapLeftButton) forControlEvents:UIControlEventTouchUpInside];
        [_rightButton addTarget:self action:@selector(didTapRightButton) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return self;
}

#pragma mark - Colors

- (void)setLeftColor:(UIColor *)leftColor {
    self.leftButton.backgroundColor = leftColor;
}

- (UIColor *)leftColor {
    return self.leftButton.backgroundColor;
}

- (void)setRightColor:(UIColor *)rightColor {
    self.leftButton.backgroundColor = rightColor;
}

- (UIColor *)rightColor {
    return self.rightButton.backgroundColor;
}

#pragma mark - Actions

- (void)didTapLeftButton {
    if (self.tapLeftHandler) self.tapLeftHandler();
}

- (void)didTapRightButton {
    if (self.tapRightHandler) self.tapRightHandler();
}

@end
