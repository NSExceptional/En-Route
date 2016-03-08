//
//  MKPlacemark+MKPointAnnotation.h
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

@import MapKit;
@class CNPostalAddress;

@interface CLPlacemark (MKPointAnnotation)

- (NSString *)vCardStringForLocationWithName:(NSString *)name;

@property (nonatomic, readonly) NSString *formattedAddress;
@property (nonatomic, readonly) MKPointAnnotation *pointAnnotation;
@property (nonatomic, readonly) CNPostalAddress *postalAddress;

@end
