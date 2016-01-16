//
//  TBTimeInterval.m
//  BU Eats
//
//  Created by Tanner on 4/24/15.
//  Copyright (c) 2015 Tanner Bennett. All rights reserved.
//

#import "TBTimer.h"

@implementation TBTimer

#pragma mark Timer

+ (instancetype)timer {
    static TBTimer *sharedTimeInterval = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTimeInterval = [self new];
    });
    
    return sharedTimeInterval;
}

+ (void)startTimer {
    //    if (true) return;
    TBTimer *timer = [self timer];
    NSLog(@"Timer: started\n");
    timer->_startTime = [NSDate date];
    timer->_endTime   = nil;
}

+ (double)lap {
    //    if (true) return;
    TBTimer *timer = self.timer;
    timer->_endTime       = [NSDate date];
    NSLog(@"Timer: elapsed %f\n", [timer.endTime timeIntervalSinceDate:timer.startTime]);
    
    return [timer.endTime timeIntervalSinceDate:timer.startTime];
}

@end
