//
//  AppDelegate.m
//  En Route
//
//  Created by Tanner on 1/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERAppDelegate.h"
#import "ERMapViewController.h"

#import <MapKit/MKPolylineRenderer.h>


@implementation ERAppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.tintColor = [UIColor colorWithRed:0.973 green:0.271 blue:0.298 alpha:1.000];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ERMapViewController new]];
    
    [self.window makeKeyAndVisible];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:[FLEXManager sharedManager] action:@selector(showExplorer)];
    tap.numberOfTouchesRequired = 3;
    [self.window addGestureRecognizer:tap];
    
    //    MKMethod *applystroke = [MKMethod methodForSelector:@selector(applyStrokePropertiesToContext:atZoomScale:) class:[MKPolylineRenderer class]];
    //    IMP oldImp = applystroke.implementation;
    //    applystroke.implementation = imp_implementationWithBlock(^(MKPolylineRenderer *me, CGContextRef context, MKZoomScale scale) {
    //        ((void(*)(id, SEL, CGContextRef, MKZoomScale))oldImp)(me, @selector(applyStrokePropertiesToContext:atZoomScale:), context, scale);
    //        CGContextSetLineWidth(context, me.lineWidth/scale);
    //        NSLog(@"\n\n============= Applying stroke =============\n\n");
    //    });
    
    return YES;
}


@end
