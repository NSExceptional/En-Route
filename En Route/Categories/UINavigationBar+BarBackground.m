//
//  UINavigationBar+BarBackground.m
//  En Route
//
//  Created by Tanner on 3/12/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "UINavigationBar+BarBackground.h"


@implementation UINavigationBar (BarBackground)

- (void)hideDefaultBackground {
    self.backgroundColor = [UIColor clearColor];
    self.barTintColor    = [UIColor clearColor];
    self.shadowImage     = [UIImage new];
    [self setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
}

- (void)showDefaultBackground {
    self.backgroundColor = nil;
    self.barTintColor    = nil;
    self.shadowImage     = nil;
    [self setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
}

@end
