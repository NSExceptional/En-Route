//
//  MKMapView+EnRouteExtensions.h
//  En Route
//
//  Created by Tanner on 1/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKMapView (EnRouteExtensions)

- (void)dropPinsAtLocations:(NSArray *)locations;
- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer;

@end
