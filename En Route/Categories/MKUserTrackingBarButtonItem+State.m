//
//  MKUserTrackingBarButtonItem+State.m
//  En Route
//
//  Created by Tanner on 3/9/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "MKUserTrackingBarButtonItem+State.h"

@implementation MKUserTrackingBarButtonItem (State)

- (MKUserTrackingState)state {
    id button = [self valueForKey:@"customButton"];
    id controller = [button valueForKey:@"controller"];
    return [[controller valueForKey:@"state"] integerValue];
}

- (BOOL)located {
    return self.state == MKUserTrackingStateLocated;
}

@end
