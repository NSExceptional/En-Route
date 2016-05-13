//
//  ERListViewController.m
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

@import MapKit;
@import Contacts;
#import "ERListViewController.h"
#import "ERListItemCell.h"
#import "ERListActivityCell.h"
#import "NSIndexPath+Util.h"
#import "MKPlacemark+MKPointAnnotation.h"
#import "ERMapItemActivityProvider.h"


static NSString * const kListItemReuse = @"listitemreuse";
static NSString * const kListActivityReuse = @"listactivityreuse";


@interface ERListViewController ()
@property (nonatomic) NSInteger expandedIndex;
@property (nonatomic) NSInteger availableOptions;
@property (nonatomic) CLLocation *currentLocation;
@property (nonatomic) NSArray *distances;
@end


@implementation ERListViewController

+ (instancetype)listItems:(NSArray *)items currentLocation:(CLLocation *)currentLocation {
    ERListViewController *list = [self new];
    list->_items = items;
    list.currentLocation = currentLocation;
    return list;
}

- (void)loadView {
    [super loadView];
    
    self.tableView.separatorInset  = UIEdgeInsetsMake(0, 15, 0, 0);
    self.tableView.backgroundColor = nil;
    self.tableView.backgroundView  = [UIVisualEffectView extraLightBlurView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [NSString stringWithFormat:@"%@ Locations", @(self.items.count)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    
    self.expandedIndex = NSNotFound;
    
    self.availableOptions = 4;
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yelp4://"]])
        _availableOptions--;
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]])
        _availableOptions--;
    

    [self.tableView registerNib:[UINib nibWithNibName:@"ListItemCell" bundle:nil] forCellReuseIdentifier:kListItemReuse];
    [self.tableView registerNib:[UINib nibWithNibName:@"ListActivityCell" bundle:nil] forCellReuseIdentifier:kListActivityReuse];
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        MKDistanceFormatter *df = [MKDistanceFormatter new];
        df.unitStyle = MKDistanceFormatterUnitStyleAbbreviated;
        
        NSMutableArray *distances = [NSMutableArray array];
        for (MKMapItem *item in self.items) {
            CLLocationDistance distance = [self.currentLocation distanceFromLocation:item.placemark.location];
            [distances addObject:[df stringFromDistance:distance]];
        }
        
        _distances = distances;
    });
}

- (void)done {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITableViewDelegate

- (BOOL)rowIsInDrawer:(NSIndexPath *)row {
    return NSLocationInRange(row.row, NSMakeRange(self.expandedIndex+1, self.availableOptions));
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Flip selected cell and previously expanded row, if any
    if (![self rowIsInDrawer:indexPath]) {
        ERListItemCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell flipChevron];
        if (self.expandedIndex != NSNotFound && self.expandedIndex != indexPath.row) {
            cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.expandedIndex inSection:0]];
            [cell flipChevron];
        }
    }
    
    [tableView beginUpdates];
    
    // Expand row when none are open
    if (self.expandedIndex == NSNotFound) {
        self.expandedIndex = indexPath.row;
        [self expandRow:indexPath.row];
    }
    // Initiate action for expanded row
    else if ([self rowIsInDrawer:indexPath]) {
        NSInteger row = indexPath.row - self.expandedIndex - 1;
        MKMapItem *item = self.items[self.expandedIndex];
        
        switch (row) {
            case 0:
                [self showShareSheetForMapItem:item];
                break;
            case 1:
                [self openPlacemarkInMaps:item.placemark];
                break;
            case 2:
                [self openPlacemarkInGoogleMaps:item.placemark];
                break;
            case 3:
                [self openPlacemarkInYelp:item.placemark];
                break;
        }
    }
    // Collapse tapped row
    else if (indexPath.row == self.expandedIndex) {
        [self collapseRow:self.expandedIndex];
        self.expandedIndex = NSNotFound;
    }
    // Collapse another row and expand tapped row
    else if (indexPath.row > self.expandedIndex) {
        // The order here is important
        [self collapseRow:self.expandedIndex];
        self.expandedIndex = NSNotFound;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [tableView beginUpdates];
            self.expandedIndex = indexPath.row - self.availableOptions;
            [self expandRow:self.expandedIndex];
            [tableView endUpdates];
        });
    } else {
        [self collapseRow:self.expandedIndex];
        self.expandedIndex = NSNotFound;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [tableView beginUpdates];
            self.expandedIndex = indexPath.row;
            [self expandRow:indexPath.row];
            [tableView endUpdates];
        });
    }
    
    [tableView endUpdates];
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.expandedIndex != NSNotFound && NSLocationInRange(indexPath.row, NSMakeRange(self.expandedIndex+1, self.availableOptions))) {
        NSInteger row = indexPath.row - self.expandedIndex - 1;
        
        ERListActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:kListActivityReuse forIndexPath:indexPath];
        
        // Separator line on last share cell
        if (row == (self.availableOptions-1)) {
            cell.separatorInset = UIEdgeInsetsZero;
        } else {
            cell.separatorInset = self.tableView.separatorInset;
        }
        
        switch (row) {
            case 0:
                cell.titleLabel.text = @"Share";
                cell.icon.image = [UIImage imageNamed:@"list_share"];
                break;
            case 1:
                cell.titleLabel.text = @"Open in Maps";
                cell.icon.image = [UIImage imageNamed:@"list_maps"];
                break;
            case 2:
                cell.titleLabel.text = @"Open in Google Maps";
                cell.icon.image = [UIImage imageNamed:@"list_google"];
                break;
            case 3:
                cell.titleLabel.text = @"Open in Yelp";
                cell.icon.image = [UIImage imageNamed:@"list_yelp"];
                break;
        }
        
        return cell;
    }
    
    NSInteger idx = indexPath.row;
    ERListItemCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kListItemReuse forIndexPath:indexPath];
    
    // Separator line on expanded cell
    cell.flipped = idx == self.expandedIndex;
    if (cell.flipped) {
        cell.separatorInset = UIEdgeInsetsZero;
    } else {
        cell.separatorInset = self.tableView.separatorInset;
    }
    
    // Offset idx into model because of expanded rows options
    if (self.expandedIndex != NSNotFound && indexPath.row > self.expandedIndex)
        idx -= self.availableOptions;
    
    MKMapItem *item         = self.items[idx];
    cell.titleLabel.text    = item.placemark.name;
    if (self.currentLocation) {
        cell.distanceLabel.text = self.distances[idx];
    } else {
        cell.distanceLabel.text = nil;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.expandedIndex != NSNotFound)
        return self.items.count + self.availableOptions;
    return self.items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

#pragma mark - Row expansion

- (void)expandRow:(NSInteger)row {
    NSArray *toInsert = [NSIndexPath indexPathsInSection:0 inRange:NSMakeRange(row+1, self.availableOptions)];
    [self.tableView insertRowsAtIndexPaths:toInsert withRowAnimation:UITableViewRowAnimationFade];
}

- (void)collapseRow:(NSInteger)row {
    NSArray *toDelete = [NSIndexPath indexPathsInSection:0 inRange:NSMakeRange(row+1, self.availableOptions)];
    [self.tableView deleteRowsAtIndexPaths:toDelete withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Actions

- (void)showShareSheetForMapItem:(MKMapItem *)item {
    //    ERMapItemActivityProvider *provider = [ERMapItemActivityProvider withName:item.name vCard:[item.placemark vCardStringForLocationWithName:item.name]];
    NSMutableArray *items = [NSMutableArray arrayWithObject:item.name];
    NSString *address = item.placemark.formattedAddress;
    if (address) {
        [items addObject:address];
    }
    if (item.url) {
        [items addObject:item.url];
    }
    UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    [self presentViewController:share animated:YES completion:nil];
}

- (void)openPlacemarkInMaps:(MKPlacemark *)placemark {
    NSMutableString *url = [@"http://maps.apple.com/?q=" stringByAppendingString:placemark.formattedAddress].mutableCopy;
    [url replaceOccurrencesOfString:@" +" withString:@"+" options:NSRegularExpressionSearch range:NSMakeRange(0, url.length)];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (void)openPlacemarkInGoogleMaps:(MKPlacemark *)placemark {
    NSMutableString *url = [@"comgooglemaps://?saddr=" stringByAppendingString:placemark.formattedAddress].mutableCopy;
    [url replaceOccurrencesOfString:@" +" withString:@"+" options:NSRegularExpressionSearch range:NSMakeRange(0, url.length)];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (void)openPlacemarkInYelp:(MKPlacemark *)placemark {
    NSMutableString *url = [NSString stringWithFormat:@"yelp4:///search?terms=%@&location=%@", placemark.name, placemark.formattedAddress].mutableCopy;
    [url replaceOccurrencesOfString:@" +" withString:@"+" options:NSRegularExpressionSearch range:NSMakeRange(0, url.length)];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

@end
