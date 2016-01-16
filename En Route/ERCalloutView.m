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
        self.tintColor  = [UIColor whiteColor];
        UIButton *start = [UIButton buttonWithType:UIButtonTypeSystem];
        UIButton *end   = [UIButton buttonWithType:UIButtonTypeSystem];
        start.frame     = CGRectMake(0, 0, 52, CGRectGetHeight(frame));
        end.frame       = CGRectMake(52, 0, 52, CGRectGetHeight(frame));
        start.backgroundColor = [UIColor colorWithRed:0.200 green:0.400 blue:1.000 alpha:1.000];
        end.backgroundColor   = [UIColor colorWithRed:0.600 green:0.000 blue:1.000 alpha:1.000];
        [start setTitle:@"Start" forState:UIControlStateNormal];
        [end setTitle:@"End" forState:UIControlStateNormal];
        start.titleEdgeInsets = end.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 5, 0);
        
        [self addSubview:start];
        [self addSubview:end];
    }
    
    return self;
}

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

@end
