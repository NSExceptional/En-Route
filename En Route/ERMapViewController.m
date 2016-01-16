//
//  ERMapViewController.m
//  En Route
//
//  Created by Tanner on 1/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERMapViewController.h"


@interface ERMapViewController () <CLLocationManagerDelegate, MKMapViewDelegate>
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSMutableArray *POIs; //points of interest
@end


@implementation ERMapViewController


- (void)loadView {
    self.view = [[ERMapView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.mapView.delegate = self;
}

- (MKMapView *)mapView {
    return (id)self.view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Locaiton manager is used to get location permissions
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearButtonPressed)]; //targets self bc clear button
    self.navigationItem.leftBarButtonItem = button; //clear button
    
    self.navigationController.toolbarHidden = NO;
    self.title = @"En Route";
    
    MKUserTrackingBarButtonItem *userTrackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    UIBarButtonItem *list = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"list"] style:UIBarButtonItemStylePlain target:self action:@selector(showList)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[userTrackingButton, spacer, list];
    
    //    self.navigationController.hidesBarsOnTap = YES;
    
    [self setupTextFields];
}


//shows routes
- (void)showRoutesForStart:(MKPlacemark *)start end:(MKPlacemark *)end {
    MKMapItem *startLocation = [[MKMapItem alloc] initWithPlacemark:start];
    MKMapItem *endLocation = [[MKMapItem alloc] initWithPlacemark:end];
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.source = startLocation;
    request.destination = destination;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse * _Nullable response, NSError * _Nullable error) {
        self.mapView; //to display map
        
        //look in mapview.response
        //look for different routes as well
        
    }];
}


//local searches for restaurants
- (void)searchWithCoord:(CLLocation *)location{
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"noms";
    request.region = MKCoordinateRegionMakeWithDistance(location.coordinate, 800, 800);
    
    [[[MKLocalSearch alloc] initWithRequest:request] startWithCompletionHandler:^(MKLocalSearchResponse * response, NSError * error) {
        [self.POIs addObjectsFromArray:response.mapItems];
        
    }];
}



- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.locationManager requestWhenInUseAuthorization];
}

#pragma mark View customization

- (void)setupTextFields {
    // Make navigation bar transparent
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.barTintColor    = [UIColor clearColor];
    self.navigationController.navigationBar.translucent     = YES;
    self.navigationController.navigationBar.shadowImage     = [UIImage new];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    
 
}

#pragma mark - Actions

- (void)clearButtonPressed {
}
- (void)showList {
}

#pragma mark - CLLocationManagerDelegate, MKMapViewDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    // User granted location access
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    } else {
        // User denied location access
    }
}

// Left this in this class because putting it in ERMapView caused the drop animation to disappear
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(nonnull id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return [self.mapView viewForAnnotation:annotation];
    } else {
        MKPinAnnotationView *pin = [MKPinAnnotationView new];
        pin.animatesDrop = YES;
        pin.pinColor = MKPinAnnotationColorPurple;
        pin.canShowCallout = YES;
        pin.calloutOffset = CGPointMake(5, 0);
        return pin;
    }
}

@end
