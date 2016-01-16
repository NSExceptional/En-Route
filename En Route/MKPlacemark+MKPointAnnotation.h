//
//  MKPlacemark+MKPointAnnotation.h
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

@import MapKit;


@interface CLPlacemark (MKPointAnnotation)

@property (nonatomic, readonly) NSString *formattedAddress;
@property (nonatomic, readonly) MKPointAnnotation *pointAnnotation;

@end
