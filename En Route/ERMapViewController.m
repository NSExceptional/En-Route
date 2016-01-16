//
//  ERMapViewController.m
//  En Route
//
//  Created by Tanner on 1/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERMapViewController.h"

@interface ERMapViewController () <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;

@end


@implementation ERMapViewController


- (void)loadView {
    self.view = [[MKMapView alloc] initWithFrame:[UIScreen mainScreen].bounds];
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
    self.toolbarItems = @[userTrackingButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.locationManager requestWhenInUseAuthorization];
}

- (void)clearButtonPressed {
    
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    // User granted location access
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    } else {
        // User denied location access
    }
}

@end
