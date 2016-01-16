//
//  ERMapViewController.m
//  En Route
//
//  Created by Tanner on 1/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERMapViewController.h"
#import "TBAlertController.h"

@interface ERMapViewController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property (nonatomic) CLLocationManager *locationManager;

@property (nonatomic, readonly) UIVisualEffectView *controlsBackgroundView;
@property (nonatomic, readonly) UITextField *startTextField;
@property (nonatomic, readonly) UITextField *endTextField;

@property (nonatomic) MKPlacemark *startLocation;
@property (nonatomic) MKPlacemark *endLocation;

@property (nonatomic) NSMutableArray *POIs; //points of interest
@end


@implementation ERMapViewController


- (void)loadView {
    self.view = [[ERMapView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.mapView.delegate = self;
    
    _controlsBackgroundView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    
}

- (MKMapView *)mapView {
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
    
    [self setupTextFields];
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
        
        pin.leftCalloutAccessoryView = ({
            UIView *view    = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 104, CGRectGetHeight(pin.frame)+10)];
            view.tintColor  = [UIColor whiteColor];
            UIButton *start = [UIButton buttonWithType:UIButtonTypeSystem];
            UIButton *end   = [UIButton buttonWithType:UIButtonTypeSystem];
            start.frame     = CGRectMake(0, 0, 52, CGRectGetHeight(view.frame));
            end.frame       = CGRectMake(52, 0, 52, CGRectGetHeight(view.frame));
            start.backgroundColor = [UIColor colorWithRed:0.200 green:0.400 blue:1.000 alpha:1.000];
            end.backgroundColor   = [UIColor colorWithRed:0.600 green:0.000 blue:1.000 alpha:1.000];
            [start setTitle:@"Start" forState:UIControlStateNormal];
            [end setTitle:@"End" forState:UIControlStateNormal];
            start.titleEdgeInsets = end.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 5, 0);
            
            [view addSubview:start];
            [view addSubview:end];
            view;
        });
        
        return pin;
    }
}

@end
