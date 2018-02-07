//
//  ERCalloutButton.h
//  En Route
//
//  Created by London Steele on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

@import MapKit;


@interface ERCalloutView : UIView

+ (instancetype)viewForAnnotation:(MKAnnotationView *)pin;

@property (nonatomic) UIColor *buttonColor;
@property (nonatomic, copy) void (^buttonTapHandler)(void);
@property (nonatomic) CGFloat buttonTitleYOffset;

@property (nonatomic) BOOL useDestinationButton;

@end
