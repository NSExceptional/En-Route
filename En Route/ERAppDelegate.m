//
//  AppDelegate.m
//  En Route
//
//  Created by Tanner on 1/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERAppDelegate.h"
#import "ERMapViewController.h"
#import "FLEXManager.h"

@interface ERAppDelegate ()
@end

@implementation ERAppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.tintColor = [UIColor colorWithRed:0.973 green:0.271 blue:0.298 alpha:1.000];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ERMapViewController new]];
    
    [self.window makeKeyAndVisible];
    
    [[FLEXManager sharedManager] showExplorer];
    
    return YES;
}


@end
