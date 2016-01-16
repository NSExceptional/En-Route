//
//  ERMapViewController.m
//  En Route
//
//  Created by Tanner on 1/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERMapViewController.h"
#import "TBAlertController.h"
#import "ERCalloutView.h"

@interface ERMapViewController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property (nonatomic) CLLocationManager *locationManager;

@property (nonatomic, readonly) UIVisualEffectView *controlsBackgroundView;
@property (nonatomic, readonly) UITextField *startTextField;
@property (nonatomic, readonly) UITextField *endTextField;

@property (nonatomic) NSMutableArray *POIs; //points of interest
@end


@implementation ERMapViewController


- (void)loadView {
    self.view = [[ERMapView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.mapView.delegate = self;
    
    _controlsBackgroundView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    
}

- (ERMapView *)mapView {
    return (id)self.view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"En Route";
    
    // Locaiton manager is used to get location permissions
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearButtonPressed)];
    self.navigationController.toolbarHidden = NO;
    
    MKUserTrackingBarButtonItem *userTrackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    UIBarButtonItem *list = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"list"] style:UIBarButtonItemStylePlain target:self action:@selector(showList)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[userTrackingButton, spacer, list];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Go" style:UIBarButtonItemStyleDone target:self action:@selector(beginRouting)];
    
    //    [self setupTextFields];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.locationManager requestWhenInUseAuthorization];
}

#pragma mark - View customization

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

- (void)beginRouting {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    __block MKPlacemark *start = nil, *end = nil;
    
    CLGeocoder *geocoder = [CLGeocoder new];
    // Get starting address
    [geocoder geocodeAddressString:self.startTextField.text completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks && placemarks.count) {
            start = [[MKPlacemark alloc] initWithPlacemark:placemarks[0]];
            // Get destination address
            [geocoder geocodeAddressString:self.endTextField.text completionHandler:^(NSArray *placemarks, NSError *error) {
                if (placemarks && placemarks.count) {
                    end = [[MKPlacemark alloc] initWithPlacemark:placemarks[0]];
                    // Show routes
                    [self showRoutesForStart:start end:end];
                } else {
                    [[TBAlertController simpleOKAlertWithTitle:@"Oops" message:@"Could not locate destination address"] showFromViewController:self];
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                }
            }];
        } else {
            [[TBAlertController simpleOKAlertWithTitle:@"Oops" message:@"Could not locate starting address"] showFromViewController:self];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }
    }];
}

#pragma mark - POI processing

- (NSArray<CLLocation*> *)coordinatesAlongRoute:(MKRoute *)route {
    NSMutableArray *points = [NSMutableArray array];
    for (NSInteger i = 0; i < route.polyline.pointCount; i++) {
        CLLocationCoordinate2D coord = MKCoordinateForMapPoint(route.polyline.points[i]);
        [points addObject:[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude]];
    }
    
    return points;
}

- (void)searchWithCoord:(CLLocation *)location {
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"food";
    request.region = MKCoordinateRegionMakeWithDistance(location.coordinate, 800, 800);
    
    [[[MKLocalSearch alloc] initWithRequest:request] startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        if (!error && response) {
            [self.POIs addObjectsFromArray:response.mapItems];
        } else {
            
        }
    }];
}

- (void)showRoutesForStart:(MKPlacemark *)start end:(MKPlacemark *)end {
    MKMapItem *startLocation     = [[MKMapItem alloc] initWithPlacemark:start];
    MKMapItem *endLocation       = [[MKMapItem alloc] initWithPlacemark:end];
    
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.source               = startLocation;
    request.destination          = endLocation;
    
    MKDirections *directions     = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (!error && response.routes.count) {
            [self.mapView addOverlay:response.routes[0].polyline];
        } else {
            
        }
    }];
}

#pragma mark - CLLocationManagerDelegate, MKMapViewDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    // User granted location access
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    } else {
        [[TBAlertController simpleOKAlertWithTitle:@"Enable location services" message:@"Allowing this app to use your location may improve your experience."] showFromViewController:self];
    }
}

// Left this in this class because putting it in ERMapView caused the drop animation to disappear
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(nonnull id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return [self.mapView viewForAnnotation:annotation];
    } else {
        // TODO: reuse annotation views. see -[MKMapView dequeueReusableAnnotationViewWithIdentifier:
        MKPinAnnotationView *pin = [MKPinAnnotationView new];
        pin.animatesDrop         = YES;
        pin.pinColor             = MKPinAnnotationColorPurple;
        pin.canShowCallout       = YES;
        pin.calloutOffset        = CGPointMake(-8, 0);
        
        self.mapView.pinAddressLoadHandler = ^(NSString *address) {
            ERCalloutView *calloutView = [ERCalloutView viewForAnnotation:pin];
            calloutView.tapLeftHandler = ^{ self.startTextField.text = address; };
            calloutView.tapRightHandler = ^{ self.endTextField.text = address; };
            pin.leftCalloutAccessoryView = [ERCalloutView viewForAnnotation:pin];
        };
        
        return pin;
    }
}

@end
