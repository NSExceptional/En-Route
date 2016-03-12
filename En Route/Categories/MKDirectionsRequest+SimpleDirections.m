//
//  MKDirectionsRequest+SimpleDirections.m
//  En Route
//
//  Created by Tanner on 3/12/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "MKDirectionsRequest+SimpleDirections.h"


@implementation MKDirectionsRequest (SimpleDirections)

+ (void)getDirectionsFrom:(MKPlacemark *)start to:(MKPlacemark *)end completion:(MKDirectionsHandler)handler {
    MKMapItem *startLocation     = [[MKMapItem alloc] initWithPlacemark:start];
    MKMapItem *endLocation       = [[MKMapItem alloc] initWithPlacemark:end];
    
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.source               = startLocation;
    request.destination          = endLocation;
    request.requestsAlternateRoutes = YES;
    
    MKDirections *directions     = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:handler];
}

@end
