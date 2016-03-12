//
//  MKDirectionsRequest+SimpleDirections.h
//  En Route
//
//  Created by Tanner on 3/12/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <MapKit/MapKit.h>


@interface MKDirectionsRequest (SimpleDirections)

+ (void)getDirectionsFrom:(MKPlacemark *)start to:(MKPlacemark *)end completion:(MKDirectionsHandler)handler;

@end
