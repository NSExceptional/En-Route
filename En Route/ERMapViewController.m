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
#import "ERLocalSearchQueue.h"
#import "MKPlacemark+MKPointAnnotation.h"
#import "TBTimer.h"
#import "ERListViewController.h"


static const CGFloat kTFHeight          = 28;
static const CGFloat kTFSidePadding     = 6;
static const CGFloat kTFSpacing         = kTFSidePadding;
static const CGFloat kTFBottomPadding   = 12;

static BOOL trackUserInitially = YES;

@interface ERMapViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate>

@property (nonatomic) CLLocationManager *locationManager;

@property (nonatomic, readonly) UIVisualEffectView *controlsBackgroundView;
@property (nonatomic, readonly) ERAddressTextField *startTextField;
@property (nonatomic, readonly) ERAddressTextField *endTextField;

@property (nonatomic, readonly) UIBarButtonItem *clearButton;
@property (nonatomic, readonly) UIBarButtonItem *routeButton;
@property (nonatomic, readonly) UIBarButtonItem *listButton;
@property (nonatomic, readonly) UILabel *toolbarLabel;

@property (nonatomic) NSMutableSet *POIs;
@property (nonatomic) NSMutableSet *latestPOIs;
@property (nonatomic, readonly) NSArray *annotations;
@property (nonatomic, readonly) NSArray *latestAnnotations;

@property (nonatomic, readonly) BOOL hideButtons;
@property (nonatomic) MKAnnotationView *userLocationView;
@property (nonatomic) MKUserLocation *userLocation;
@property (nonatomic) MKAnnotationView *droppedPin;

@property (nonatomic) BOOL loadingResults;
@property (nonatomic) ERLocalSearchQueue *searchQueue;

@end


@implementation ERMapViewController


- (void)loadView {
    self.view = [[ERMapView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.mapView.delegate = self;
    
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat tfWidth = CGRectGetWidth([UIScreen mainScreen].bounds) - kTFSidePadding*2;
    CGFloat hairlineHeight = 1.f/[UIScreen mainScreen].scale;
    
    _controlsBackgroundView       = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    CGRect controlFrame           = CGRectMake(0, 0, screenWidth, kControlViewHeight);
    CGFloat viewHeight            = CGRectGetHeight(controlFrame);
    _controlsBackgroundView.frame = controlFrame;
    
    CGRect startFrame = CGRectMake(kTFSidePadding, (viewHeight-kTFBottomPadding) - kTFHeight*2 - kTFSpacing, tfWidth, kTFHeight);
    CGRect endFrame   = CGRectMake(kTFSidePadding, (viewHeight-kTFBottomPadding) - kTFHeight, tfWidth, kTFHeight);
    
    _startTextField = [[ERAddressTextField alloc] initWithFrame:startFrame];
    _endTextField   = [[ERAddressTextField alloc] initWithFrame:endFrame];
    _startTextField.nameLabel.text = @"Start:";
    _endTextField.nameLabel.text   = @"End:";
    _endTextField.fieldEntryOffset = _startTextField.estimatedFieldEntryOffset;
    _startTextField.delegate = self;
    _endTextField.delegate   = self;
    
    _toolbarLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    _toolbarLabel.font = [UIFont systemFontOfSize:12];
    
    UIView *hairline = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, viewHeight - hairlineHeight, screenWidth, hairlineHeight)];
        view.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.301];
        view;
    });
    
    [_controlsBackgroundView addSubview:_startTextField];
    [_controlsBackgroundView addSubview:_endTextField];
    [_controlsBackgroundView addSubview:hairline];
    [self.mapView addSubview:_controlsBackgroundView];
    
    NSString *rekt = [[NSUserDefaults standardUserDefaults] valueForKey:@"MapRekt"];
    if (rekt) {
        CGRect r = CGRectFromString(rekt);
        self.mapView.visibleMapRect = *((MKMapRect*)&r);
        self.mapView.userTrackingMode = MKUserTrackingModeNone;
        trackUserInitially = NO;
    }
}

- (ERMapView *)mapView {
    return (id)self.view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"En Route";
    self.POIs = [NSMutableSet set];
    self.latestPOIs = [NSMutableSet set];
    
    // Locaiton manager is used to get location permissions
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    
    // Toolbar items
    MKUserTrackingBarButtonItem *userTrackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    _listButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"list"] style:UIBarButtonItemStylePlain target:self action:@selector(showList)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *label = [[UIBarButtonItem alloc] initWithCustomView:_toolbarLabel];
    self.toolbarItems = @[userTrackingButton, spacer, label, spacer, _listButton];
    
    // Hide keyboard on tap
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self.startTextField action:@selector(resignFirstResponder)];
    [tap addTarget:self.endTextField action:@selector(resignFirstResponder)];
    [self.view addGestureRecognizer:tap];
    
    // Navbar items
    [self hideNavBar];
    _clearButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearButtonPressed)];
    _routeButton = [[UIBarButtonItem alloc] initWithTitle:@"Route" style:UIBarButtonItemStyleDone target:self action:@selector(beginRouting)];
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.leftBarButtonItem   = _clearButton;
    self.navigationItem.rightBarButtonItem  = _routeButton;
    
    [self updateNavigationItems];
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
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.POIs removeAllObjects];
    self.toolbarLabel.text = nil;
    
    [self updateButtons];
}

- (void)resetMapData {
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.POIs removeAllObjects];
}

- (void)showList {
    UITableViewController *list = [ERListViewController listItems:self.POIs.allObjects currentLocation:[self.userLocation valueForKey:@"location"]];
    UIViewController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    nav.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)beginRouting {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.loadingResults = YES;
    [self updateNavigationItems];
    
    [self getStartPlacemark:^(MKPlacemark *start) {
        [self getEndPlacemark:^(MKPlacemark *end) {
            [self showRoutesForStart:start end:end];
        }];
    }];
}

- (void)getStartPlacemark:(void(^)(MKPlacemark *start))callback {
    if ([self.startTextField.text isEqualToString:@"Current location"]) {
        callback([[MKPlacemark alloc] initWithCoordinate:[[self.userLocation valueForKey:@"location"] coordinate] addressDictionary:nil]);
    } else {
        [[CLGeocoder new] geocodeAddressString:self.startTextField.text completionHandler:^(NSArray *placemark, NSError *error) {
            if (placemark && placemark.count) {
                MKPlacemark *start = [[MKPlacemark alloc] initWithPlacemark:placemark[0]];
                callback(start);
            } else {
                [[TBAlertController simpleOKAlertWithTitle:@"Oops" message:@"Could not locate starting address"] showFromViewController:self];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                self.loadingResults = NO;
                [self updateNavigationItems];
            }
        }];
    }
}

- (void)getEndPlacemark:(void(^)(MKPlacemark *end))callback {
    if ([self.endTextField.text isEqualToString:@"Current location"]) {
        callback([[MKPlacemark alloc] initWithCoordinate:[[self.userLocation valueForKey:@"location"] coordinate] addressDictionary:nil]);
    } else {
        [[CLGeocoder new] geocodeAddressString:self.endTextField.text completionHandler:^(NSArray *placemark, NSError *error) {
            if (placemark && placemark.count) {
                MKPlacemark *end = [[MKPlacemark alloc] initWithPlacemark:placemark[0]];
                callback(end);
            } else {
                [[TBAlertController simpleOKAlertWithTitle:@"Oops" message:@"Could not locate destination address"] showFromViewController:self];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                self.loadingResults = NO;
                [self updateNavigationItems];
            }
        }];
    }
}

#pragma mark - Getters

- (NSArray *)latestAnnotations {
    return [[self.latestPOIs.allObjects valueForKeyPath:@"@unionOfObjects.placemark"] valueForKeyPath:@"@unionOfObjects.pointAnnotation"];
}

- (NSArray *)annotations {
    return [[self.POIs.allObjects valueForKeyPath:@"@unionOfObjects.placemark"] valueForKeyPath:@"@unionOfObjects.pointAnnotation"];
}

- (MKUserLocation *)userLocation {
    return (id)self.userLocationView.annotation;
}

#pragma mark - POI processing

- (NSArray<CLLocation*> *)coordinatesAlongRoute:(MKRoute *)route {
    NSMutableArray *points = [NSMutableArray array];
    for (NSInteger i = 0; i < route.polyline.pointCount; i++) {
        CLLocationCoordinate2D coord = MKCoordinateForMapPoint(route.polyline.points[i]);
        [points addObject:[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude]];
    }
    
    // Debugging
    //    NSMutableArray *placemarks = [NSMutableArray new];
    //    for (CLLocation *loc in points)
    //        [placemarks addObject:[[MKPlacemark alloc] initWithCoordinate:loc.coordinate addressDictionary:nil]];
    //    
    //    [self.mapView addAnnotations:placemarks];
    //    return @[];
    return points;
}

- (void)showRoutesForStart:(MKPlacemark *)start end:(MKPlacemark *)end {
    MKMapItem *startLocation     = [[MKMapItem alloc] initWithPlacemark:start];
    MKMapItem *endLocation       = [[MKMapItem alloc] initWithPlacemark:end];
    
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.source               = startLocation;
    request.destination          = endLocation;
    request.requestsAlternateRoutes = YES;
    
    MKDirections *directions     = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        
        if (!error && response.routes.count) {
            [self.mapView addOverlays:[response.routes valueForKeyPath:@"@unionOfObjects.polyline"]];
            
            // Add annotations
            [TBTimer startTimer];
            [self searchRoute:response.routes.firstObject then:response.routes.mutableCopy completed:[NSMutableArray array]];
            
        } else {
            [[TBAlertController simpleOKAlertWithTitle:@"Oops" message:@"Could not get directions"] showFromViewController:self];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            self.loadingResults = NO;
            [self updateNavigationItems];
        }
    }];
}

- (void)searchRoute:(MKRoute *)route then:(NSMutableArray *)alternates completed:(NSMutableArray *)usedRoutes {
    if (!route) {
        self.searchQueue = nil;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        self.loadingResults = NO;
        [self updateNavigationItems];
        return;
    }
    
    // Get coords, filter out already searched coords
    NSArray *coords = [self coordinatesAlongRoute:route];
    NSMutableSet *filteredCoords = [NSMutableSet setWithArray:coords];
    for (MKRoute *route in usedRoutes)
        [filteredCoords minusSet:[NSSet setWithArray:[self coordinatesAlongRoute:route]]];
    coords = filteredCoords.allObjects;
    
    // Perform search
    self.searchQueue = self.searchQueue ?: [ERLocalSearchQueue queueWithQuery:@"food" radius:1000];
    [self.searchQueue searchWithCoords:coords loopCallback:^(NSArray *mapItems) {
        [self.latestPOIs addObjectsFromArray:mapItems];
    } completionCallback:^{
        [self.latestPOIs minusSet:self.POIs];
        [self.POIs addObjectsFromArray:self.latestPOIs.allObjects];
        [self.mapView addAnnotations:self.latestAnnotations];
        [self.latestPOIs removeAllObjects];
        
        self.toolbarLabel.text = [NSString stringWithFormat:@"%@ restaurants along your route", @(self.POIs.count)];
        [self.toolbarLabel sizeToFit];
        self.listButton.enabled = self.POIs.count > 0;
        
        [alternates removeObject:route];
        [usedRoutes addObject:route];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self searchRoute:alternates.firstObject then:alternates completed:usedRoutes];
        });
    }];
}

- (BOOL)hideButtons {
    return _startTextField.text.length > 0 && _endTextField.text.length > 0;
}

- (void)updateNavigationItems {
    // Clear enabled if any text, Go enabled if both text
    self.clearButton.enabled  = !self.loadingResults && (_startTextField.text.length || _endTextField.text.length);
    self.routeButton.enabled = !self.loadingResults && self.hideButtons;
    self.listButton.enabled = self.POIs.count > 0;
}

- (void)updateButtons {
    [self updateNavigationItems];
    
    if (self.hideButtons) {
        self.userLocationView.leftCalloutAccessoryView = nil;
        self.droppedPin.leftCalloutAccessoryView = nil;
    } else {
        
        // User location button
        ERCalloutView *userCalloutView       = [ERCalloutView viewForAnnotation:self.userLocationView];
        userCalloutView.buttonTitleYOffset   += 5;
        userCalloutView.useDestinationButton = self.startTextField.text.length > 0;
        userCalloutView.buttonTapHandler     = ^{
            [self.mapView deselectAnnotation:self.userLocationView.annotation animated:YES];
            if (self.startTextField.text.length > 0) {
                self.endTextField.text = @"Current location";
            } else {
                self.startTextField.text = @"Current location";
            }
            
            [self updateButtons];
        };
        self.userLocationView.leftCalloutAccessoryView = userCalloutView;
        
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
        if (trackUserInitially)
            [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    } else {
        [[TBAlertController simpleOKAlertWithTitle:@"Enable location services" message:@"Allowing this app to use your location may improve your experience."] showFromViewController:self];
    }
}

//- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            self.startTextField.text = @"Current location";
//            self.endTextField.text = @"4081 East Byp, College Station, TX  77845, United States";
//            [self beginRouting];
//        });
//    });
//}

// Left this in this class because putting it in ERMapView caused the drop animation to disappear
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(nonnull id<MKAnnotation>)annotation {
    
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        MKPinAnnotationView *user = [[NSClassFromString(@"MKModernUserLocationView") alloc] initWithAnnotation:annotation reuseIdentifier:@"user"];
        self.userLocationView = user;
        
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
        // MKPointAnnotation class, for dropped pins and restaurants
        MKPointAnnotation *point = (id)annotation;
        
        if ([point.title isEqualToString:@"Dropped Pin"]) {
            // TODO: reuse annotation views. see -[MKMapView dequeueReusableAnnotationViewWithIdentifier:
            MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"dropped"];
            pin.animatesDrop         = YES;
            pin.pinColor             = MKPinAnnotationColorRed;
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
            
        } else {
            // For POIs
            MKPointAnnotation *point = (id)annotation;
            MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:point reuseIdentifier:@"poi"];
            pin.animatesDrop         = YES;
            pin.pinTintColor         = [UIColor colorWithRed:0.259 green:0.812 blue:0.816 alpha:1.000];
            pin.canShowCallout       = YES;
            pin.calloutOffset        = CGPointMake(-8, 0);
            
            return pin;
        }
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(nonnull id<MKOverlay>)overlay {
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    renderer.strokeColor = [UIColor colorWithRed:0.000 green:0.550 blue:1.000 alpha:1.000];
    renderer.lineWidth = 7;
    return renderer;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [[NSUserDefaults standardUserDefaults] setValue:MKStringFromMapRect(self.mapView.visibleMapRect) forKey:@"MapRekt"];
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

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self.searchQueue cancelRequests];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.loadingResults = NO;
    [self updateNavigationItems];
}

@end
