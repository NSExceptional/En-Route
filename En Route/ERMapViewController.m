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
#import "TBTableViewController.h"

#import <EXTScope.h>
#import "MirrorKit.h"


static const CGFloat kTFHeight        = 28;
static const CGFloat kTFSidePadding   = 6;
static const CGFloat kTFSpacing       = kTFSidePadding;
static const CGFloat kTFBottomPadding = 12;

static BOOL trackUserInitially = YES;

@interface ERMapViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate>

@property (nonatomic) CLLocationManager *locationManager;

@property (nonatomic, readonly) UIVisualEffectView *controlsBackgroundView;
@property (nonatomic, readonly) ERAddressTextField *startTextField;
@property (nonatomic, readonly) ERAddressTextField *endTextField;

@property (nonatomic, readonly) UIBarButtonItem *clearButton;
@property (nonatomic, readonly) UIBarButtonItem *routeButton;
@property (nonatomic, readonly) UIBarButtonItem *searchButton;
@property (nonatomic, readonly) UIBarButtonItem *listButton;
@property (nonatomic, readonly) UILabel *toolbarLabel;

@property (nonatomic          ) NSMutableSet *POIs;
@property (nonatomic          ) NSMutableSet *latestPOIs;
@property (nonatomic, readonly) NSArray      *annotations;
@property (nonatomic, readonly) NSArray      *latestAnnotations;

@property (nonatomic, readonly) BOOL             hideButtons;
@property (nonatomic          ) MKAnnotationView *userLocationView;
@property (nonatomic, readonly) MKUserLocation   *userLocation;
@property (nonatomic          ) MKAnnotationView *droppedPin;

@property (nonatomic) BOOL                  loadingResults;
@property (nonatomic) ERLocalSearchQueue    *searchQueue;
@property (nonatomic) NSArray               *routes;
@property (nonatomic) MKRoute               *selectedRoute;
@property (nonatomic) NSInteger             selectedRouteIndex;
@property (nonatomic) NSMutableArray        *renderers;
@property (nonatomic) TBTableViewController *pickerController;
@property (nonatomic) UITableViewCell       *selectedCell;

@end


@implementation ERMapViewController


- (void)loadView {
    // Create MapView
    [super loadView];
    _mapView  = [[ERMapView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:_mapView];
    self.mapView.delegate = self;
    //    [self.mapView.panningGestureRecognizer addTarget:self action:@selector(updateOverlays)];
    
    CGFloat screenWidth    = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat textFieldWidth = CGRectGetWidth([UIScreen mainScreen].bounds) - kTFSidePadding*2;
    CGFloat hairlineHeight = 1.f/[UIScreen mainScreen].scale;
    
    // Setup nav bar thingy
    _controlsBackgroundView       = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    CGRect controlFrame           = CGRectMake(0, 0, screenWidth, kControlViewHeight);
    CGFloat viewHeight            = CGRectGetHeight(controlFrame);
    _controlsBackgroundView.frame = controlFrame;
    
    CGRect startFrame = CGRectMake(kTFSidePadding, (viewHeight-kTFBottomPadding) - kTFHeight*2 - kTFSpacing, textFieldWidth, kTFHeight);
    CGRect endFrame   = CGRectMake(kTFSidePadding, (viewHeight-kTFBottomPadding) - kTFHeight, textFieldWidth, kTFHeight);
    
    // Place text fields
    _startTextField = [[ERAddressTextField alloc] initWithFrame:startFrame];
    _endTextField   = [[ERAddressTextField alloc] initWithFrame:endFrame];
    _startTextField.nameLabel.text = @"Start:";
    _endTextField.nameLabel.text   = @"End:";
    _endTextField.fieldEntryOffset = _startTextField.estimatedFieldEntryOffset;
    _startTextField.delegate = self;
    _endTextField.delegate   = self;
    
    // Toolbar label
    _toolbarLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    _toolbarLabel.font = [UIFont systemFontOfSize:12];
    
    // Nav bar hairline
    UIView *hairline = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, viewHeight - hairlineHeight, screenWidth, hairlineHeight)];
        view.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.301];
        view;
    });
    
    // Add subviews
    [_controlsBackgroundView addSubview:_startTextField];
    [_controlsBackgroundView addSubview:_endTextField];
    [_controlsBackgroundView addSubview:hairline];
    [self.mapView addSubview:_controlsBackgroundView];
    
    // Map rectangle
    NSString *rekt = [[NSUserDefaults standardUserDefaults] valueForKey:@"MapRekt"];
    if (rekt) {
        CGRect r = CGRectFromString(rekt);
        self.mapView.visibleMapRect = *((MKMapRect*)&r);
        self.mapView.userTrackingMode = MKUserTrackingModeNone;
        trackUserInitially = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title  = @"En Route";
    _POIs       = [NSMutableSet set];
    _latestPOIs = [NSMutableSet set];
    _renderers  = [NSMutableArray array];
    
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
    [self.mapView addGestureRecognizer:tap];
    
    // Navbar items
    [self hideNavBar];
    _clearButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearButtonPressed)];
    _routeButton = [[UIBarButtonItem alloc] initWithTitle:@"Route" style:UIBarButtonItemStyleDone target:self action:@selector(beginRouting)];
    _searchButton = [[UIBarButtonItem alloc] initWithTitle:@"Search" style:UIBarButtonItemStyleDone target:self action:@selector(searchRoute)];
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.leftBarButtonItem   = _clearButton;
    self.navigationItem.rightBarButtonItem  = _routeButton;
    
    [self updateNavigationItems];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Request location access or let the user know we need location access.
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            NSString *message = @"Do you want to allow En Route to use your location while using the app to provide you with a better experience? You can always disable this feature in Settings.";
            TBAlertController *locationRequest = [TBAlertController alertViewWithTitle:@"Location services" message:message];
            [locationRequest addOtherButtonWithTitle:@"Yes" buttonAction:^(NSArray * _Nonnull textFieldStrings) {
                [self.locationManager requestWhenInUseAuthorization];
            }];
            [locationRequest addOtherButtonWithTitle:@"Not right now" buttonAction:^(NSArray *textFieldStrings) {
                [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:@"location_days_since_last_request"];
            }];
            [locationRequest setCancelButtonWithTitle:@"No, don't ask me again" buttonAction:^(NSArray * _Nonnull textFieldStrings) {
                [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"location_dont_ask_again"];
            }];
            
            [locationRequest showFromViewController:self];
            
            
            break;
        }
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse: {
            break;
        }
    }
    
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
    [self prepareForDefaultState];
    [self.startTextField resignFirstResponder];
    [self.endTextField resignFirstResponder];
}

- (void)showList {
    UITableViewController *list = [ERListViewController listItems:self.POIs.allObjects currentLocation:[self.userLocation valueForKey:@"location"]];
    UIViewController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    nav.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)beginRouting {
    [self.startTextField resignFirstResponder];
    [self.endTextField resignFirstResponder];
    
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView removeAnnotations:self.mapView.resultAnnotations];
    [self.POIs removeAllObjects];
    self.toolbarLabel.text = nil;
    
    [self updateMapButtons];
    
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
        NSParameterAssert(self.userLocation);
        CLLocation *location = [self.userLocation valueForKey:@"location"];
        callback([[MKPlacemark alloc] initWithCoordinate:location.coordinate addressDictionary:nil]);
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
    
    self.toolbarLabel.text = @"Calculating routes…";
    [self.toolbarLabel sizeToFit];
    
    MKDirections *directions     = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        self.loadingResults = NO;
        
        if (!error && response.routes.count) {
            // Add overlays, zoom
            [self.mapView addOverlays:[response.routes valueForKeyPath:@"@unionOfObjects.polyline"]];
            MKPolyline *line = (id)self.mapView.overlays.firstObject;
            [self.mapView setVisibleMapRect:line.boundingMapRect edgePadding:UIEdgeInsetsMake(100, 10, 160, 10) animated:YES];
            
            [self showRoutePicker:response.routes];
        } else {
            [[TBAlertController simpleOKAlertWithTitle:@"Oops" message:@"Could not get directions"] showFromViewController:self];
            [self updateNavigationItems];
            self.toolbarLabel.text = nil;
        }
    }];
}

- (void)showRoutePicker:(NSArray *)routes {
    self.routes = routes;
    self.selectedRoute = routes.firstObject;
    [self prepareForSearchState];
}

- (void)setSelectedRoute:(MKRoute *)selectedRoute {
    _selectedRoute = selectedRoute;
    if (selectedRoute) {
        for (MKPolylineRenderer *renderer in self.renderers) {
            if (renderer.overlay == selectedRoute.polyline) {
                renderer.lineWidth = 12;
                renderer.alpha = 0.75;
            } else {
                renderer.lineWidth = 8;
                renderer.alpha = 0.4;
            }
            [renderer setNeedsDisplayInMapRect:self.mapView.visibleMapRect];
        }
    }
}

- (void)searchRoute {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.loadingResults = YES;
    [self prepareForResultsState];
    [self updateNavigationItems];
    
    // Init queue
    @weakify(self);
    self.searchQueue = self.searchQueue ?: [ERLocalSearchQueue queueWithQuery:@"food" radius:1000];
    // Pause callback
    self.searchQueue.pauseCallback = ^(NSInteger secondsLeft) { @strongify(self)
        //NSString *message = [NSString stringWithFormat:@"En Route is limited in the number of requests it can make in a minute. Please wait for %@ seconds.", @(secondsLeft)];
        //[[TBAlertController simpleOKAlertWithTitle:@"Rate limiting" message:message] showFromViewController:self];
        self.toolbarLabel.text = [NSString stringWithFormat:@"Waiting for %@ seconds…", @(secondsLeft)];
        [self.toolbarLabel sizeToFit];
    };
    // Resume callback
    self.searchQueue.resumeCallback = ^{ @strongify(self)
        self.toolbarLabel.text = [NSString stringWithFormat:@"Fetching results… %@ so far…", @(self.POIs.count)];
        [self.toolbarLabel sizeToFit];
    };
    // Error callback
    self.searchQueue.errorCallback = ^{ @strongify(self)
        self.toolbarLabel.text = [NSString stringWithFormat:@"Error, stopped early. Found %@ restaurants.", @(self.POIs.count)];
        [self.toolbarLabel sizeToFit];
    };
    // Debug callback
    self.searchQueue.debugCallback = ^(NSInteger count) { @strongify(self)
        self.toolbarLabel.text = [NSString stringWithFormat:@"Fetching %@ results… ", @(count)];
        [self.toolbarLabel sizeToFit];
    };
    
    [self.searchQueue searchRoutes:@[self.selectedRoute] repeatedCallback:^(NSArray *mapItems) {
        // Update map, order is important
        [self.latestPOIs setSet:[NSSet setWithArray:mapItems]];
        [self.latestPOIs minusSet:self.POIs];
        [self.POIs addObjectsFromArray:mapItems];
        [self.mapView addAnnotations:self.latestAnnotations];
        
        // Update message and list button state
        self.toolbarLabel.text = [NSString stringWithFormat:@"Fetching results… %@ so far…", @(self.POIs.count)];
        [self.toolbarLabel sizeToFit];
        self.listButton.enabled = self.POIs.count > 0;
    } completion:^{
        // Remove queue, cleanup
        self.searchQueue = nil;
        [self.latestPOIs removeAllObjects];
        self.loadingResults = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self updateNavigationItems];
        
        // Final message
        self.toolbarLabel.text = [NSString stringWithFormat:@"%@ restaurants along your route", @(self.POIs.count)];
        [self.toolbarLabel sizeToFit];
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

- (void)updateMapButtons {
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
            
            [self updateMapButtons];
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
            
            [self updateMapButtons];
        };
        
        self.droppedPin.leftCalloutAccessoryView = droppedPinButton;
    }
}

#pragma mark - View management

- (void)setupInitialBarButtonItems {
    _clearButton.enabled = NO;
    _routeButton.enabled = NO;
    self.navigationItem.leftBarButtonItem  = _clearButton;
    self.navigationItem.rightBarButtonItem = _routeButton;
}

- (void)setupSearchBarButtonItems {
    _clearButton.enabled = YES;
    self.navigationItem.rightBarButtonItem = _searchButton;
}

- (void)setupResultsBarButtonItems {
    _clearButton.enabled = YES;
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)resetMapView {
    [_pickerController.tableView removeFromSuperview];
    _pickerController = nil;
    
    // Remove overlays, clear fields
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.renderers removeAllObjects];
    self.startTextField.text = nil;
    self.endTextField.text   = nil;
    // Remove annotations and POIs
    [self.mapView removeAnnotations:self.mapView.annotations];
    self.toolbarLabel.text = nil;
}

- (void)resetMapData {
    self.routes              = nil;
    self.selectedRoute       = nil;
    self.selectedRouteIndex  = 0;
    self.selectedCell        = nil;
    [self.POIs removeAllObjects];
    [self.latestPOIs removeAllObjects];
}


- (void)prepareForDefaultState {
    [self setupInitialBarButtonItems];
    [self resetMapView];
    [self resetMapData];
    [self updateMapButtons];
    
    self.startTextField.userInteractionEnabled = YES;
    self.endTextField.userInteractionEnabled = YES;
}

- (void)prepareForSearchState {
    [self setupSearchBarButtonItems];
    
    self.toolbarLabel.text = nil;
    
    self.startTextField.userInteractionEnabled = NO;
    self.endTextField.userInteractionEnabled = NO;
    
    _pickerController = [TBTableViewController new];
    _pickerController.defaultCanSelectRow = YES;
    _pickerController.tableView.tintColor = self.view.tintColor;
    _pickerController.tableView.scrollEnabled = NO;
    
    NSMutableArray *titles = [NSMutableArray array];
    for (NSInteger i = 1; i <= self.routes.count; i++)
        [titles addObject:[NSString stringWithFormat:@"Route %@", @(i)]];
    _pickerController.rowTitles = @[titles.copy];
    
    _pickerController.configureCellBlock = ^(UITableViewCell *cell, NSIndexPath *ip) {
        cell.textLabel.textColor = [UIColor colorWithRed:0.973 green:0.271 blue:0.298 alpha:1.000];
        cell.textLabel.font = [UIFont systemFontOfSize:17];
        if (ip.row == _selectedRouteIndex) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _selectedCell = cell;
        }
    };
    
    @weakify(self);
    _pickerController.didSelectCellBlock = ^(UITableViewCell *cell, NSIndexPath *ip) { @strongify(self)
        self.selectedCell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryType              = UITableViewCellAccessoryCheckmark;
        self.selectedCell               = cell;
        self.selectedRouteIndex         = ip.row;
        self.selectedRoute              = self.routes[ip.row];
    };
    
    CGSize contentSize = _pickerController.tableView.contentSize;
    CGFloat y          = CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.navigationController.toolbar.frame) - contentSize.height;
    y                  += 1/[UIScreen mainScreen].scale;
    CGFloat width      = CGRectGetWidth(self.view.frame);
    _pickerController.tableView.frame = CGRectMake(0, y, width, contentSize.height);
    [self.view addSubview:_pickerController.tableView];
}

- (void)prepareForResultsState {
    [self setupResultsBarButtonItems];
    [_pickerController.tableView removeFromSuperview];
    _pickerController = nil;
    
    // Remove unselected overlays
    for (id<MKOverlay> overlay in self.mapView.overlays)
        if (overlay != self.selectedRoute.polyline)
            [self.mapView removeOverlay:overlay];
    
    
}

#pragma mark - CLLocationManagerDelegate, MKMapViewDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusRestricted: {
            NSString *message = @"It appears location services have been restricted. En Route won't be able to show you where you are.";
            [[TBAlertController simpleOKAlertWithTitle:@"Location services restructed" message:message] showFromViewController:self];
            break;
        }
        case kCLAuthorizationStatusDenied: {
            NSString *message = @"En Route needs access to your location to tell you where you are, and to show you how far you are from a given location.";
            [[TBAlertController simpleOKAlertWithTitle:@"En Route needs location access" message:message] showFromViewController:self];
            break;
        }
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse: {
            if (trackUserInitially)
                [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
            break;
        }
    }
}

// Demo code
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.startTextField.text = @"Current location";
            self.endTextField.text = @"4081 East Byp, College Station, TX  77845, United States";
            [self beginRouting];
        });
    });
}

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
                
                [self updateMapButtons];
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
            
            @weakify(self);
            self.mapView.pinAddressLoadHandler = ^(NSString *address) { @strongify(self)
                
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
                        
                        [self updateMapButtons];
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
    renderer.lineWidth = 8;
    renderer.strokeColor = self.view.tintColor;//[UIColor colorWithRed:0.000 green:0.550 blue:1.000 alpha:1.000];
    renderer.alpha = 0.4;
    [self.renderers addObject:renderer];
    return renderer;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [[NSUserDefaults standardUserDefaults] setValue:MKStringFromMapRect(self.mapView.visibleMapRect) forKey:@"MapRekt"];
}

//- (void)updateOverlays {
//    NSLog(@"============ Updating");
//    for (MKOverlayRenderer *renderer in self.renderers)
//        [renderer setNeedsDisplay];
//}

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
    [self updateMapButtons];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self.searchQueue cancelRequests];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.loadingResults = NO;
    [self updateNavigationItems];
}

@end
