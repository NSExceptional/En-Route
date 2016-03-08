//
//  ERMapNavigationBar.h
//  En Route
//
//  Created by Tanner on 2/18/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ERAddressTextField.h"


@interface ERMapNavigationBarBackground : UIView

+ (instancetype)backgroundForBar:(UINavigationBar *)bar;

@property (nonatomic) BOOL shrunken;

@property (nonatomic, readonly) ERAddressTextField *startTextField;
@property (nonatomic, readonly) ERAddressTextField *endTextField;

@end


@interface UINavigationBar (BarBackground)
- (void)hideDefaultBackground;
- (void)setBackgroundView_:(UIView *)view;
- (void)showDefaultBackground;
@end