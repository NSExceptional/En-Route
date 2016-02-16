//
//  ERMapView.h
//  En Route
//
//  Created by Tanner on 1/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

@import MapKit;


static const CGFloat kControlViewHeight = 140;


@interface ERMapView : MKMapView

@property (nonatomic, readonly, getter=_panningGestureRecognizer) UIPanGestureRecognizer *panningGestureRecognizer;

@property (nonatomic) MKPointAnnotation *droppedPinAnnotation;
@property (nonatomic, readonly) NSArray *resultAnnotations;
@property (nonatomic, copy) void (^pinAddressLoadHandler)(NSString *address);

@property (readonly, nonatomic) UIView *compassView_;

@end
