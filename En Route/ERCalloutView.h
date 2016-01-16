//
//  ERCalloutButton.h
//  En Route
//
//  Created by London Steele on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

@import MapKit;


@interface ERCalloutView : UIView

+ (instancetype)viewForAnnotation:(MKPinAnnotationView *)pin;

@property (nonatomic) UIColor *leftColor;
@property (nonatomic) UIColor *rightColor;

@end
