//
//  UIApplication+Design.m
//  En Route
//
//  Created by Tanner on 2/6/18.
//Copyright © 2018 Tanner Bennett. All rights reserved.
//

#import "UIApplication+Design.h"
#define iOS11 @available(iOS 11, *)
#define iPhoneX ([UIApplication sharedApplication].keyWindow.safeAreaInsets.top > 0.0)

@implementation UIApplication (Design)

+ (CGFloat)statusBarHeight {
    if (iOS11) {
        if (iPhoneX) {
            return 44.f;
        }
    }

    return 20.f;
}

+ (CGFloat)navigationBarHeight {
    return 44.f;
}

+ (CGFloat)navigationBarMaxY {
    return [self statusBarHeight] + [self navigationBarHeight];
}

@end
