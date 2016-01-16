//
//  ERMapView.h
//  En Route
//
//  Created by Tanner on 1/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

@import MapKit;


@interface ERMapView : MKMapView

@property (nonatomic) MKPointAnnotation *droppedPinAnnotation;
@property (nonatomic, copy) void (^pinAddressLoadHandler)(NSString *address);

@end
