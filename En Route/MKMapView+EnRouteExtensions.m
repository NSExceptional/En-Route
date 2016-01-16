//
//  MKMapView+EnRouteExtensions.m
//  En Route
//
//  Created by Tanner on 1/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "MKMapView+EnRouteExtensions.h"

@implementation MKMapView (EnRouteExtensions)

- (void)dropPinsAtLocations:(NSArray *)locations {
    
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self];
    CLLocationCoordinate2D touchMapCoordinate = [self convertPoint:touchPoint toCoordinateFromView:self];
    
    MKPointAnnotation *point = [MKPointAnnotation new];
    point.coordinate = touchMapCoordinate;
    
    // Remove other pins
    NSArray *toRemove = [self.annotations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return ![evaluatedObject isKindOfClass:[MKUserLocation class]];
    }]];
    [self removeAnnotations:toRemove];
    
    // Add new pin
    [self addAnnotation:point];
}

@end
