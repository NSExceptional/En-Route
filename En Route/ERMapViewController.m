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
#import "ERAddressTextField.h"


static const CGFloat kTFHeight          = 28;
static const CGFloat kTFSidePadding     = 6;
static const CGFloat kTFSpacing         = kTFSidePadding;
static const CGFloat kTFBottomPadding   = 12;

@interface ERMapViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate>

@property (nonatomic) CLLocationManager *locationManager;

@property (nonatomic, readonly) UIVisualEffectView *controlsBackgroundView;
@property (nonatomic, readonly) ERAddressTextField *startTextField;
@property (nonatomic, readonly) ERAddressTextField *endTextField;

@property (nonatomic) NSMutableArray *POIs; //points of interest

@property (nonatomic, readonly) BOOL hideButtons;
@property (nonatomic) MKAnnotationView *userLocation;
@property (nonatomic) MKAnnotationView *droppedPin;

@end


@implementation ERMapViewController


- (void)loadView {
    self.view = [[ERMapView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.mapView.delegate = self;
    
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat tfWidth = CGRectGetWidth([UIScreen mainScreen].bounds) - kTFSidePadding*2;
    CGFloat hairlineHeight = 1.f/[UIScreen mainScreen].scale;
    
    _controlsBackgroundView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    CGRect controlFrame = CGRectMake(0, 0, screenWidth, kControlViewHeight);
    _controlsBackgroundView.frame = controlFrame;
    CGFloat viewHeight = CGRectGetHeight(controlFrame);
    
    CGRect startFrame = CGRectMake(kTFSidePadding, (viewHeight-kTFBottomPadding) - kTFHeight*2 - kTFSpacing, tfWidth, kTFHeight);
    CGRect endFrame   = CGRectMake(kTFSidePadding, (viewHeight-kTFBottomPadding) - kTFHeight, tfWidth, kTFHeight);
    
    _startTextField = [[ERAddressTextField alloc] initWithFrame:startFrame];
    _endTextField   = [[ERAddressTextField alloc] initWithFrame:endFrame];
    _startTextField.nameLabel.text = @"Start:";
    _endTextField.nameLabel.text   = @"End:";
    _endTextField.fieldEntryOffset = _startTextField.estimatedFieldEntryOffset;
    _startTextField.delegate = self;
    _endTextField.delegate   = self;
    
    UIView *hairline = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, viewHeight - hairlineHeight, screenWidth, hairlineHeight)];
        view.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.301];
        view;
    });
    
    [_controlsBackgroundView addSubview:_startTextField];
    [_controlsBackgroundView addSubview:_endTextField];
    [_controlsBackgroundView addSubview:hairline];
    [self.mapView addSubview:_controlsBackgroundView];
}

- (ERMapView *)mapView {
    return (id)self.view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"En Route";
    self.POIs = [NSMutableArray array];
    
    // Locaiton manager is used to get location permissions
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    
    // Toolbar items
    MKUserTrackingBarButtonItem *userTrackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    UIBarButtonItem *list = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"list"] style:UIBarButtonItemStylePlain target:self action:@selector(showList)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[userTrackingButton, spacer, list];
    list.enabled = NO;
    
    // Hide keyboard on tap
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self.startTextField action:@selector(resignFirstResponder)];
    [tap addTarget:self.endTextField action:@selector(resignFirstResponder)];
    [self.view addGestureRecognizer:tap];
    
    // Navbar items
    [self hideNavBar];
    [self updateNavigationItems];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearButtonPressed)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Route" style:UIBarButtonItemStyleDone target:self action:@selector(beginRouting)];
    self.navigationController.toolbarHidden = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.locationManager requestWhenInUseAuthorization];
}

#pragma mark - View customization

- (void)hideNavBar {
    // Make navigation bar transparent
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.barTintColor    = [UIColor clearColor];
    self.navigationController.navigationBar.translucent     = YES;
    self.navigationController.navigationBar.shadowImage     = [UIImage new];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
}

#pragma mark - Actions

- (void)clearButtonPressed {
    [self.mapView removeOverlays:self.mapView.overlays];
    self.startTextField.text = nil;
    self.endTextField.text = nil;
}

- (void)showList {
}

- (void)beginRouting {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    __block MKPlacemark *start = nil, *end = nil;
    
    CLGeocoder *geocoder = [CLGeocoder new];
    // Get starting address
    [geocoder geocodeAddressString:self.startTextField.text completionHandler:^(NSArray *startPlacemank, NSError *error) {
        if (startPlacemank && startPlacemank.count) {
            start = [[MKPlacemark alloc] initWithPlacemark:startPlacemank[0]];
            // Get destination address
            [geocoder geocodeAddressString:self.endTextField.text completionHandler:^(NSArray *endPlacemark, NSError *error2) {
                if (endPlacemark && endPlacemark.count) {
                    end = [[MKPlacemark alloc] initWithPlacemark:endPlacemark[0]];
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
            [self.mapView addOverlays:[response.routes valueForKeyPath:@"@unionOfObjects.polyline"]];
        } else {
            [[TBAlertController simpleOKAlertWithTitle:@"Oops" message:@"Could not get directions"] showFromViewController:self];
        }
    }];
}

- (BOOL)hideButtons {
    return _startTextField.text.length > 0 && _endTextField.text.length > 0;
}

- (void)updateNavigationItems {
    // Clear enabled if any text, Go enabled if both text
    self.navigationItem.leftBarButtonItem.enabled  = _startTextField.text.length || _endTextField.text.length;
    self.navigationItem.rightBarButtonItem.enabled = self.hideButtons;
}

- (void)updateButtons {
    [self updateNavigationItems];
    
    if (self.hideButtons) {
        self.userLocation.leftCalloutAccessoryView = nil;
        self.droppedPin.leftCalloutAccessoryView = nil;
    } else {
        
        // User location button
        ERCalloutView *userCalloutView       = [ERCalloutView viewForAnnotation:self.userLocation];
        userCalloutView.buttonTitleYOffset   += 5;
        userCalloutView.useDestinationButton = self.startTextField.text.length > 0;
        userCalloutView.buttonTapHandler     = ^{
            [self.mapView deselectAnnotation:self.userLocation.annotation animated:YES];
            if (self.startTextField.text.length > 0) {
                self.endTextField.text = @"Current location";
            } else {
                self.startTextField.text = @"Current location";
            }
            
            [self updateButtons];
        };
        self.userLocation.leftCalloutAccessoryView = userCalloutView;
        
        // Dropped pin button
        ERCalloutView *droppedPinButton       = [ERCalloutView viewForAnnotation:self.droppedPin];
        droppedPinButton.useDestinationButton = self.startTextField.text.length > 0;
        droppedPinButton.buttonTapHandler     = ^{
            [self.mapView deselectAnnotation:self.droppedPin.annotation animated:YES];
            if (self.startTextField.text.length > 0) {
                self.endTextField.text = self.droppedPin.annotation.subtitle;
            } else {
                self.startTextField.text = self.droppedPin.annotation.subtitle;
            }
            
            [self updateButtons];
        };
        
        self.droppedPin.leftCalloutAccessoryView = droppedPinButton;
    }
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
        MKPinAnnotationView *user = [[NSClassFromString(@"MKModernUserLocationView") alloc] initWithAnnotation:annotation reuseIdentifier:@"user"];
        self.userLocation = user;
        
        // Hide buttons if both fields are full
        if (!self.hideButtons) {
            ERCalloutView *calloutView       = [ERCalloutView viewForAnnotation:user];
            calloutView.buttonTitleYOffset   += 5;
            calloutView.useDestinationButton = self.startTextField.text.length > 0;
            user.leftCalloutAccessoryView    = calloutView;
            
            calloutView.buttonTapHandler     = ^{
                [self.mapView deselectAnnotation:annotation animated:YES];
                if (self.startTextField.text.length > 0) {
                    self.endTextField.text = @"Current location";
                } else {
                    self.startTextField.text = @"Current location";
                }
                
                [self updateButtons];
            };
        }
        
        return user;
    } else {
        // TODO: reuse annotation views. see -[MKMapView dequeueReusableAnnotationViewWithIdentifier:
        MKPinAnnotationView *pin = [MKPinAnnotationView new];
        pin.animatesDrop         = YES;
        pin.pinColor             = MKPinAnnotationColorPurple;
        pin.canShowCallout       = YES;
        pin.calloutOffset        = CGPointMake(-8, 0);
        self.droppedPin = pin;
        
        self.mapView.pinAddressLoadHandler = ^(NSString *address) {
            
            // Hide buttons if both fields are full
            if (!self.hideButtons) {
                ERCalloutView *calloutView       = [ERCalloutView viewForAnnotation:pin];
                calloutView.useDestinationButton = self.startTextField.text.length > 0;
                pin.leftCalloutAccessoryView     = calloutView;
                calloutView.buttonTapHandler     = ^{
                    [self.mapView deselectAnnotation:annotation animated:YES];
                    if (self.startTextField.text.length > 0) {
                        self.endTextField.text = address;
                    } else {
                        self.startTextField.text = address;
                    }
                    
                    [self updateButtons];
                };
            }
        };
        
        return pin;
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(nonnull id<MKOverlay>)overlay {
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    renderer.strokeColor = [UIColor colorWithRed:0.000 green:0.550 blue:1.000 alpha:1.000];
    renderer.lineWidth = 5;
    return renderer;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _startTextField) {
        // Go to the next text field
        [_endTextField becomeFirstResponder];
    } else {
        // Only resign responder if text length
        if (textField.text.length) {
            [textField resignFirstResponder];
            [self beginRouting];
        }
    }
    
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self updateButtons];
}

@end
