//
//  ERMapViewController.m
//  En Route
//
//  Created by Tanner on 1/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERMapViewController.h"
#import "ERCalloutView.h"
#import "ERMapNavigationBarBackground.h"
#import "ERLocalSearchQueue.h"
#import "ERListViewController.h"
#import "TBTableViewController.h"
#import "ERSuggestionsViewController.h"
#import "ERSettingsViewController.h"
#import "ERRoutesController.h"


static BOOL trackUserInitially = NO;

@interface ERMapViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate, ERRoutesControllerDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic, readonly) ERRoutesController *routesController;
@property (nonatomic, readonly) ERSuggestionsViewController *suggestions;

@property (nonatomic) ERSettingsViewController *settings;

@property (nonatomic          ) NSMutableSet *POIs;
@property (nonatomic          ) NSMutableSet *latestPOIs;
@property (nonatomic, readonly) NSArray      *annotations;
@property (nonatomic, readonly) NSArray      *latestAnnotations;

@property (nonatomic          ) MKAnnotationView *userLocationView;
@property (nonatomic, readonly) CLLocation       *userLocation;
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
    [super loadView];
    
    // Create MapView
    _mapView = [[ERMapView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:_mapView];
    self.mapView.delegate = self;
    
    // Navigation bar background view
    [self.navigationController.navigationBar hideDefaultBackground];
    self.navigationController.toolbarHidden = NO;
    
    // Routes controller
    MKUserTrackingBarButtonItem *button = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    _routesController = [ERRoutesController forNavigationItem:self.navigationItem toolbar:self.navigationController.toolbar trackingButton:button];
    [self addChildViewController:self.routesController];
    self.routesController.delegate = self;
    
    // Map rectangle
    NSString *rekt = [[NSUserDefaults standardUserDefaults] stringForKey:kPref_mapRect];
    if (rekt) {
        CGRect r = CGRectFromString(rekt);
        self.mapView.visibleMapRect = *((MKMapRect*)&r);
        self.mapView.userTrackingMode = MKUserTrackingModeNone;
        trackUserInitially = NO;
    } else {
        trackUserInitially = YES;
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Request location access or let the user know we need location access.
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        switch (status) {
            case kCLAuthorizationStatusNotDetermined: {
                // They told us not to ask again
                if ([[NSUserDefaults standardUserDefaults] boolForKey:kPref_locationDontAskAgain]) break;
                
                NSString *message = @"Do you want to allow En Route to use your location while using the app to provide you with a better experience? You can always disable this feature in Settings.";
                TBAlertController *locationRequest = [TBAlertController alertViewWithTitle:@"Location services" message:message];
                [locationRequest addOtherButtonWithTitle:@"Yes" buttonAction:^(NSArray *textFieldStrings) {
                    [self.locationManager requestWhenInUseAuthorization];
                }];
                [locationRequest addOtherButtonWithTitle:@"Not right now" buttonAction:^(NSArray *textFieldStrings) {
                    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kPref_locationNotRightNowDate];
                    self.mapView.userTrackingMode = MKUserTrackingModeNone;
                }];
                [locationRequest setCancelButtonWithTitle:@"No, don't ask me again" buttonAction:^(NSArray *textFieldStrings) {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPref_locationDontAskAgain];
                    self.mapView.userTrackingMode = MKUserTrackingModeNone;
                }];
                
                [locationRequest showFromViewController:self];
                
                break;
            }
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                if (trackUserInitially) {
                    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
                }
            case kCLAuthorizationStatusDenied:
            case kCLAuthorizationStatusRestricted:
                break;
        }
        
        [[NSUserDefaults standardUserDefaults] setInteger:status forKey:kPref_lastLocationAccessStatus];
    });
}

- (void)addChildViewController:(UIViewController *)childController {
    [super addChildViewController:childController];
    [self.view addSubview:childController.view];
}

#pragma mark - Routing

- (NSArray<CLLocation*> *)coordinatesAlongRoute:(MKRoute *)route {
    NSMutableArray *points = [NSMutableArray array];
    for (NSInteger i = 0; i < route.polyline.pointCount; i++) {
        CLLocationCoordinate2D coord = MKCoordinateForMapPoint(route.polyline.points[i]);
        [points addObject:[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude]];
    }
    
    return points;
}

- (void)showRoutesForStart:(MKPlacemark *)start end:(MKPlacemark *)end {
    [MKDirectionsRequest getDirectionsFrom:start to:end completion:^(MKDirectionsResponse * _Nullable response, NSError * _Nullable error) {
        self.loadingResults = NO;
        
        if (!error && response.routes.count) {
            // Add overlays, zoom
            [self.mapView addOverlays:[response.routes valueForKeyPath:@"@unionOfObjects.polyline"]];
            MKPolyline *line = (id)self.mapView.overlays.firstObject;
            [self.mapView setVisibleMapRect:line.boundingMapRect edgePadding:UIEdgeInsetsMake(100, 10, 160, 10) animated:YES];
            
            [self showRoutePicker:response.routes];
        } else {
            [[TBAlertController simpleOKAlertWithTitle:@"Oops" message:@"Could not get directions"] showFromViewController:self];
            self.routesController.state = ERSystemStateDefault;
            [self.routesController setToolbarText:nil];
        }
    }];
}

- (void)showRoutePicker:(NSArray *)routes {
    self.routesController.state = ERSystemStateRoutePicker;
    self.routes = routes;
    self.selectedRoute = routes.firstObject;
    [self setupRoutePickerView];
    [self presentPickerView];
}

- (void)setSelectedRoute:(MKRoute *)selectedRoute {
    _selectedRoute = selectedRoute;
    if (selectedRoute) {
        for (MKPolylineRenderer *renderer in self.renderers) {
            if (renderer.overlay == selectedRoute.polyline) {
                renderer.lineWidth = 10;
                renderer.alpha = 0.75;
            } else {
                renderer.lineWidth = 7;
                renderer.alpha = 0.4;
            }
            [renderer setNeedsDisplayInMapRect:self.mapView.visibleMapRect];
        }
    }
}

- (void)getStartPlacemark:(void(^)(MKPlacemark *start))callback {
    if ([self.routesController.start.text isEqualToString:kCurrentLocationText]) {
        NSParameterAssert(self.userLocation);
        callback([[MKPlacemark alloc] initWithCoordinate:self.userLocation.coordinate addressDictionary:nil]);
    } else {
        [[CLGeocoder new] geocodeAddressString:self.routesController.start.text completionHandler:^(NSArray *placemark, NSError *error) {
            if (placemark && placemark.count) {
                MKPlacemark *start = [[MKPlacemark alloc] initWithPlacemark:placemark[0]];
                callback(start);
            } else {
                [[TBAlertController simpleOKAlertWithTitle:@"Oops" message:@"Could not locate starting address"] showFromViewController:self];
                self.loadingResults = NO;
                self.routesController.state = ERSystemStateDefault;
            }
        }];
    }
}

- (void)getEndPlacemark:(void(^)(MKPlacemark *end))callback {
    if ([self.routesController.dest.text isEqualToString:kCurrentLocationText]) {
        callback([[MKPlacemark alloc] initWithCoordinate:[[self.userLocation valueForKey:@"location"] coordinate] addressDictionary:nil]);
    } else {
        [[CLGeocoder new] geocodeAddressString:self.routesController.dest.text completionHandler:^(NSArray *placemark, NSError *error) {
            if (placemark && placemark.count) {
                MKPlacemark *end = [[MKPlacemark alloc] initWithPlacemark:placemark[0]];
                callback(end);
            } else {
                [[TBAlertController simpleOKAlertWithTitle:@"Oops" message:@"Could not locate destination address"] showFromViewController:self];
                self.loadingResults = NO;
                self.routesController.state = ERSystemStateDefault;
            }
        }];
    }
}

#pragma mark - Properties

- (NSArray *)latestAnnotations {
    return [[self.latestPOIs.allObjects valueForKeyPath:@"@unionOfObjects.placemark"] valueForKeyPath:@"@unionOfObjects.pointAnnotation"];
}

- (NSArray *)annotations {
    return [[self.POIs.allObjects valueForKeyPath:@"@unionOfObjects.placemark"] valueForKeyPath:@"@unionOfObjects.pointAnnotation"];
}

- (CLLocation *)userLocation {
    return (id)[self.userLocationView valueForKey:@"lastLocation"];
}

- (ERLocalSearchQueue *)searchQueue {
    if (!_searchQueue) {
        NSString *query = [[NSUserDefaults standardUserDefaults] stringForKey:kPref_searchQuery];
        CGFloat radius = [[NSUserDefaults standardUserDefaults] doubleForKey:kPref_searchRadius];
        
        @weakify(self);
        _searchQueue = [ERLocalSearchQueue queueWithQuery:query radius:radius];
        // Pause callback
        _searchQueue.pauseCallback = ^(NSInteger secondsLeft) { @strongify(self)
            //NSString *message = [NSString stringWithFormat:@"En Route is limited in the number of requests it can make in a minute. Please wait for %@ seconds.", @(secondsLeft)];
            //[[TBAlertController simpleOKAlertWithTitle:@"Rate limiting" message:message] showFromViewController:self];
            [self.routesController setToolbarText:[NSString stringWithFormat:@"Waiting for %@ seconds…", @(secondsLeft)]];
        };
        // Resume callback
        _searchQueue.resumeCallback = ^{ @strongify(self)
            [self.routesController setToolbarText:[NSString stringWithFormat:@"Fetching results… %@ so far…", @(self.POIs.count)]];
        };
        // Error callback
        _searchQueue.errorCallback = ^{ @strongify(self)
            [self.routesController setToolbarText:[NSString stringWithFormat:@"Error, stopped early. Found %@ restaurants.", @(self.POIs.count)]];
        };
        // Debug callback
        _searchQueue.debugCallback = ^(NSInteger count) { @strongify(self)
            [self.routesController setToolbarText:[NSString stringWithFormat:@"Fetching %@ results… ", @(count)]];
        };
    }
    
    return _searchQueue;
}

- (void)setLoadingResults:(BOOL)loadingResults {
    _loadingResults = loadingResults;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = loadingResults;
}

#pragma mark - POI processing

- (void)cancelSearch {
    [_searchQueue cancelRequests];
    self.loadingResults = NO;
}

- (void)updateCalloutViews {
    if (self.routesController.textFieldsBothFull) {
        self.userLocationView.leftCalloutAccessoryView = nil;
        self.droppedPin.leftCalloutAccessoryView = nil;
    } else {
        
        // User location button
        ERCalloutView *userCalloutView       = [ERCalloutView viewForAnnotation:self.userLocationView];
        userCalloutView.buttonTitleYOffset  += 5;
        userCalloutView.useDestinationButton = self.routesController.start.text.length > 0;
        userCalloutView.buttonTapHandler     = ^{
            [self.mapView deselectAnnotation:self.userLocationView.annotation animated:YES];
            self.routesController.emptyTextField.text = kCurrentLocationText;
            [self updateCalloutViews];
        };
        self.userLocationView.leftCalloutAccessoryView = userCalloutView;
        
        // Dropped pin button
        ERCalloutView *droppedPinButton       = [ERCalloutView viewForAnnotation:self.droppedPin];
        droppedPinButton.useDestinationButton = userCalloutView.useDestinationButton;
        droppedPinButton.buttonTapHandler     = ^{
            [self.mapView deselectAnnotation:self.droppedPin.annotation animated:YES];
            self.routesController.emptyTextField.text = self.droppedPin.annotation.subtitle;
            [self updateCalloutViews];
        };
        
        self.droppedPin.leftCalloutAccessoryView = droppedPinButton;
    }
}

- (void)presentSuggestionsList {
    [self removeRoutesFromView];
    
    if (self.suggestions) {
        [self animateSuggestionsPresentation];
    } else {
        @weakify(self);
        _suggestions = [ERSuggestionsViewController withAction:^(NSAttributedString *address) { @strongify(self);
            if (self.routesController.start.isFirstResponder) {
                // Set text and go to next field
                self.routesController.start.text = address.string;
                [self.routesController.dest becomeFirstResponder];
                
                [self.routesController selectTextOfActiveField];
                
                [self.suggestions updateQuery:nil];
            } else if (self.routesController.dest.isFirstResponder) {
                self.routesController.dest.text = address.string;
            }
        } location:self.userLocation];
        
        CGFloat y = CGRectGetMaxY(self.routesController.view.frame);
        CGFloat w = CGRectGetWidth(self.routesController.view.frame);
        CGFloat h = CGRectGetHeight(self.view.frame) - y;
        self.suggestions.view.frame = CGRectMake(0, y, w, h);
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPref_didPromptForContactAccess];
        if (self.suggestions.canShowContacts) {
            [self animateSuggestionsPresentation];
        } else {
            UITextField *active = self.routesController.activeTextField;
            [self.suggestions requestContactAccess:^{
                [active becomeFirstResponder];
                [self animateSuggestionsPresentation];
            }];
        }
    }
}

- (void)animateSuggestionsPresentation {
    [self addChildViewController:self.suggestions];
    [self.suggestions animatePresentation];
}

#pragma mark - Picker view stuff

- (void)removeRoutesFromView {
    [self dismissPickerView];
    
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.renderers removeAllObjects];
    [self.routesController setToolbarText:nil];
    
    self.routes              = nil;
    self.selectedRoute       = nil;
    self.selectedRouteIndex  = 0;
    self.selectedCell        = nil;
}

- (void)setupRoutePickerView {
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
        cell.selectedBackgroundView = ({UIView *view = [UIView new]; view.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.198]; view;});
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
    
    CGFloat pxheight   = 1/[UIScreen mainScreen].scale;
    CGSize contentSize = _pickerController.tableView.contentSize;
    CGFloat y          = CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.navigationController.toolbar.frame) - contentSize.height;
    y                  += pxheight;
    CGFloat width      = CGRectGetWidth(self.view.frame);
    _pickerController.tableView.frame = CGRectMake(0, y, width, contentSize.height);
    
    UIView *hairline = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, pxheight)];
        view.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.200];
        view;
    });
    [_pickerController.tableView addSubview:hairline];
}

- (void)presentPickerView {
    CGFloat y = _pickerController.tableView.frame.origin.y;
    [_pickerController.tableView setFrameY:CGRectGetHeight(self.view.frame)];
    
    [self.view addSubview:_pickerController.tableView];
    
    [UIView animateSmoothly:^{
        [_pickerController.tableView setFrameY:y];
    } completion:nil];
}

- (void)dismissPickerView {
    _pickerController.tableView.userInteractionEnabled = NO;
    
    [UIView animateSmoothly:^{
        [_pickerController.tableView setFrameY:CGRectGetHeight(self.view.frame)];
    } completion:^(BOOL finished) {
        [_pickerController.tableView removeFromSuperview];
        _pickerController = nil;
    }];
}

#pragma mark - CLLocationManagerDelegate, MKMapViewDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [[NSUserDefaults standardUserDefaults] setInteger:status forKey:kPref_lastLocationAccessStatus];
    
    switch (status) {
        case kCLAuthorizationStatusRestricted: {
            [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
            
            // Tell the user once that their access is restricted
            if (![[NSUserDefaults standardUserDefaults] boolForKey:kPref_didShowRestrictedContactAccessPrompt]) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPref_didShowRestrictedContactAccessPrompt];
                NSString *message = @"It appears location services have been restricted. En Route won't be able to show you where you are.";
                [[TBAlertController simpleOKAlertWithTitle:@"Location services restricted" message:message] showFromViewController:self];
            }
            break;
        }
        case kCLAuthorizationStatusDenied: {
            [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
            
            // Tell the user that we want their location access
            NSString *message = @"En Route uses your location to tell you where you are, and to show you how far you are from a given restaurant. ";
            message = [message stringByAppendingString:@"You can enable access in settings."];
            [[TBAlertController simpleOKAlertWithTitle:@"En Route would like location access" message:message] showFromViewController:self];
            break;
        }
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            if (trackUserInitially) {
                [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
            }
        case kCLAuthorizationStatusNotDetermined:
            break;
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if (self.routesController.currentLocationIsPartOfRoute || self.routesController.userTrackingButton.state == MKUserTrackingStateNone) {
        return;
    }
    
    self.routesController.emptyTextField.text = kCurrentLocationText;
    
    [self updateCalloutViews];
    
    // Turn off tracking after 2 seconds to allow zooming first
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
    });
    
    //     Demo code
    //        static dispatch_once_t onceToken;
    //        dispatch_once(&onceToken, ^{
    //            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //                self.routesController.dest.text = @"I-55 S, Hammond, LA  70403, United States";
    //                [self beginFindingRoutes];
    //            });
    //        });
}

// Left this in this class because putting it in ERMapView caused the drop animation to disappear
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(nonnull id<MKAnnotation>)annotation {
    
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        MKPinAnnotationView *user = [[NSClassFromString(@"MKModernUserLocationView") alloc] initWithAnnotation:annotation reuseIdentifier:@"user"];
        self.userLocationView = user;
        
        // Hide buttons if both fields are full
        if (!self.routesController.textFieldsBothFull && !self.routesController.currentLocationIsPartOfRoute) {
            ERCalloutView *calloutView       = [ERCalloutView viewForAnnotation:user];
            calloutView.buttonTitleYOffset   += 5;
            calloutView.useDestinationButton = self.routesController.start.text.length > 0;
            user.leftCalloutAccessoryView    = calloutView;
            
            calloutView.buttonTapHandler     = ^{
                [self.mapView deselectAnnotation:annotation animated:YES];
                self.routesController.emptyTextField.text = kCurrentLocationText;
                
                [self updateCalloutViews];
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
                if (!self.routesController.textFieldsBothFull) {
                    ERCalloutView *calloutView       = [ERCalloutView viewForAnnotation:pin];
                    calloutView.useDestinationButton = self.routesController.start.text.length > 0;
                    pin.leftCalloutAccessoryView     = calloutView;
                    calloutView.buttonTapHandler     = ^{
                        [self.mapView deselectAnnotation:annotation animated:YES];
                        if (self.routesController.start.text.length > 0) {
                            self.routesController.dest.text = address;
                        } else {
                            self.routesController.start.text = address;
                        }
                        
                        [self updateCalloutViews];
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

#pragma mark - ERRoutesControllerDelegate

- (void)beginSearch {
    [self dismissPickerView];
    
    // Remove unselected overlays
    for (id<MKOverlay> overlay in self.mapView.overlays)
        if (overlay != self.selectedRoute.polyline)
            [self.mapView removeOverlay:overlay];
    
    self.loadingResults = YES;
    
    [self.searchQueue searchRoutes:@[self.selectedRoute] repeatedCallback:^(NSArray *mapItems) {
        // Update map, order is important
        [self.latestPOIs setSet:[NSSet setWithArray:mapItems]];
        [self.latestPOIs minusSet:self.POIs];
        [self.POIs addObjectsFromArray:mapItems];
        [self.mapView addAnnotations:self.latestAnnotations];
        
        // Update message and list button state
        [self.routesController setToolbarText:[NSString stringWithFormat:@"Fetching results… %@ so far…", @(self.POIs.count)]];
    } completion:^{
        // Remove queue, cleanup
        self.searchQueue = nil;
        [self.latestPOIs removeAllObjects];
        self.loadingResults = NO;
        
        // Final message
        [self.routesController setToolbarText:[NSString stringWithFormat:@"%@ restaurants along your route", @(self.POIs.count)]];
    }];
}

- (void)resultsButtonPressed {
    [self getStartPlacemark:^(MKPlacemark *start) {
        UITableViewController *list = [ERListViewController listItems:self.POIs.allObjects currentLocation:start.location];
        UIViewController *nav = [[UINavigationController alloc] initWithRootViewController:list];
        nav.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [self presentViewController:nav animated:YES completion:nil];
    }];
}

- (void)beginFindingRoutes {
    [self removeRoutesFromView];
    
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView removeAnnotations:self.mapView.resultAnnotations];
    [self.POIs removeAllObjects];
    
    [self updateCalloutViews];
    
    self.loadingResults = YES;
    
    [self getStartPlacemark:^(MKPlacemark *start) {
        [self getEndPlacemark:^(MKPlacemark *end) {
            [self showRoutesForStart:start end:end];
        }];
    }];
}

- (void)clearButtonPressed {
    // Remove overlays, clear fields
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.renderers removeAllObjects];
    
    [self.routesController setToolbarText:nil];
    
    // Remove annotations and POIs
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    [self dismissPickerView];
    [self resetMapData];
    [self updateCalloutViews];
}

- (void)resetMapData {
    self.routes              = nil;
    self.selectedRoute       = nil;
    self.selectedRouteIndex  = 0;
    self.selectedCell        = nil;
    [self.POIs removeAllObjects];
    [self.latestPOIs removeAllObjects];
}

- (void)textFieldDidEndEditing {
    [self updateCalloutViews];
}

- (void)textFieldWillClear {
    [self.suggestions updateQuery:nil];
}

- (void)textFieldTextDidChange:(NSString *)newString {
    [self.suggestions updateQuery:newString];
}

- (void)suggestionsShouldAppear {
    [self cancelSearch];
    [self presentSuggestionsList];
}

- (void)suggestionsShouldDismiss {
    [self.suggestions animateDismissalAndRemove];
}

- (BOOL)settingsShouldAppear {
    self.settings = _settings ?: [ERSettingsViewController new];
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height - 64;
    
    // Present modally if the table view would be too tall
    [self.settings.view sizeToFit];
    if (CGRectGetHeight(self.settings.view.frame) >= screenHeight) {
        self.settings.tableView.scrollEnabled = YES;
        [self presentViewController:[UINavigationController dismissableWithViewController:self.settings] animated:YES completion:nil];
        return NO;
    }
    // Present fancy if we have the room
    else {
        [self.mapView dim:^{
            [self.routesController teardownSettingsState];
        }];
        [self.settings presentInView:self.navigationController.view];
        
        return YES;
    }
}

- (void)settingsShouldDismiss {
    [self.settings dismissFromView];
    [self.mapView unDim];
}

@end
