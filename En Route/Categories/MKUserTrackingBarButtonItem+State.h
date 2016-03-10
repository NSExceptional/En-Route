//
//  MKUserTrackingBarButtonItem+State.h
//  En Route
//
//  Created by Tanner on 3/9/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <MapKit/MapKit.h>

typedef NS_ENUM(NSUInteger, MKUserTrackingState)
{
    MKUserTrackingStateNone,
    MKUserTrackingStateLocating,
    MKUserTrackingStateLocated,
    MKUserTrackingStateFollowing
};

@interface MKUserTrackingBarButtonItem (State)

@property (nonatomic, readonly) MKUserTrackingState state;
@property (nonatomic, readonly) BOOL located;

@end
