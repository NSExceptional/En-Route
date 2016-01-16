//
//  ERMapView.m
//  En Route
//
//  Created by Tanner on 1/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERMapView.h"

@implementation ERMapView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 0.2;
        [self addGestureRecognizer:longPress];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Adjust compass position
    UIView *compass = self.compassView_;
    CGRect frame = compass.frame;
    frame.origin.y = kControlViewHeight + 5;
    frame.origin.x = CGRectGetWidth([UIScreen mainScreen].bounds) - (5 + CGRectGetWidth(frame));
    compass.frame = frame;
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self];
    CLLocationCoordinate2D coords = [self convertPoint:touchPoint toCoordinateFromView:self];
    
    // Create pin
    MKPointAnnotation *point = [MKPointAnnotation new];
    point.coordinate = coords;
    point.title = @"Dropped Pin";
    
    // Remove other pin
    if (self.droppedPinAnnotation)
        [self removeAnnotation:self.droppedPinAnnotation];
    
    // Add new pin
    [self addAnnotation:point];
    [self selectAnnotation:point animated:YES];
    self.droppedPinAnnotation = point;
    
    // Get subtitle for location
    CLGeocoder *ceo = [CLGeocoder new];
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:coords.latitude longitude:coords.longitude];
    
    [ceo reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = placemarks[0];
        NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
        self.droppedPinAnnotation.subtitle = locatedAt;
        // Pass address to view
        if (self.pinAddressLoadHandler) self.pinAddressLoadHandler(locatedAt);
    }];
}

- (UIView *)compassView_ {
    return [self valueForKey:@"_compassView"];
}

@end
