//
//  ERMapView.m
//  En Route
//
//  Created by Tanner on 1/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERMapView.h"
#import "MKPlacemark+MKPointAnnotation.h"


@interface ERMapView ()

@property (nonatomic) UIView *dimmingView;
@property (nonatomic, copy) VoidBlock dimmingViewTapAction;

@end

@implementation ERMapView
@dynamic panningGestureRecognizer;

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
        self.droppedPinAnnotation.subtitle = placemark.formattedAddress;
        
        // Pass address to view
        if (self.pinAddressLoadHandler)
            self.pinAddressLoadHandler(self.droppedPinAnnotation.subtitle);
    }];
}

- (UIView *)compassView_ {
    return [self valueForKey:@"_compassView"];
}

- (NSArray *)resultAnnotations {
    if (!self.droppedPinAnnotation) return self.annotations;
    
    NSMutableArray *results = self.annotations.mutableCopy;
    [results removeObject:self.droppedPinAnnotation];
    return results;
}

- (void)dim:(VoidBlock)tapAction {
    self.dimmingViewTapAction = tapAction;
    
    _dimmingView = ({
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        view.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.500];
        view.alpha = 0;
        
        [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dimmingViewTapped)]];
        view;
    });
    
    [self addSubview:_dimmingView];
    [UIView animateWithDuration:kAnimationDuration/2 animations:^{
        _dimmingView.alpha = 1;
    }];
}

- (void)unDim {
    [UIView animateWithDuration:kAnimationDuration/2 animations:^{
        _dimmingView.alpha = 0;
    } completion:^(BOOL finished) {
        [_dimmingView removeFromSuperview];
        _dimmingView = nil;
    }];
}

- (void)dimmingViewTapped {
    if (self.dimmingViewTapAction) self.dimmingViewTapAction();
}

@end
