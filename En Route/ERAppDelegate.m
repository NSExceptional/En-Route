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
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ERMapViewController new]];
    
    [self.window makeKeyAndVisible];
    
    [[FLEXManager sharedManager] showExplorer];
    
    return YES;
}


@end
