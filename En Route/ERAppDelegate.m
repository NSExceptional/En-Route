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

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>


@implementation ERAppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Crashlytics
    [Fabric with:@[[Crashlytics class]]];
    
    
    // Register default preferences
    NSString *defaults = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:defaults]];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.tintColor = [UIColor colorWithRed:0.973 green:0.271 blue:0.298 alpha:1.000];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ERMapViewController new]];
    
    [self.window makeKeyAndVisible];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:[FLEXManager sharedManager] action:@selector(showExplorer)];
    tap.numberOfTouchesRequired = 3;
    [self.window addGestureRecognizer:tap];
    
    [self potentiallyResetPrompts];
    
#if TARGET_IPHONE_SIMULATOR
    [[FLEXManager sharedManager] showExplorer];
#endif
    
    return YES;
}

- (void)potentiallyResetPrompts {
    // Location
    CLAuthorizationStatus locStatus = [CLLocationManager authorizationStatus];
    if (locStatus != [[NSUserDefaults standardUserDefaults] integerForKey:kPref_lastLocationAccessStatus]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPref_locationDontAskAgain];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPref_didShowRestrictedLocationAccessPrompt];
    }
    
    // Contacts
    CNAuthorizationStatus contactsStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (contactsStatus != [[NSUserDefaults standardUserDefaults] integerForKey:kPref_lastContactsAccessStatus]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPref_contactsDontAskAgain];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPref_didShowRestrictedContactAccessPrompt];
    }
}


@end
