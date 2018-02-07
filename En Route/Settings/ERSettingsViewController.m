//
//  ERSettingsViewController.m
//  En Route
//
//  Created by Tanner on 3/11/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERSettingsViewController.h"
#import "ERPickerCell.h"
#import "ERTextFieldCell.h"
@import MessageUI;


static NSString * const kQueryReuse = @"ERQueryCellReuse";
static NSString * const kRadiusReuse = @"ERRadiusCellReuse";
static NSString * const kFeedbackReuse = @"ERFeedbackCellsReuse";

@interface ERSettingsViewController () <MFMailComposeViewControllerDelegate>
@property (nonatomic, readonly) NSArray *reuseIdentifiers;
@property (nonatomic, readonly) ERPickerCell *radiusCell;
@property (nonatomic, readonly) ERTextFieldCell *queryCell;
@property (nonatomic          ) CGFloat radiusPreference;
@property (nonatomic          ) NSString *queryPreference;
@end

@implementation ERSettingsViewController

- (id)init {
    return [self initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.scrollEnabled   = NO;
    self.tableView.layoutMargins   = UIEdgeInsetsZero;
    self.tableView.rowHeight       = 44;
    self.tableView.estimatedRowHeight = 120;
    self.tableView.tableHeaderView = ({
        CGFloat scale = [UIScreen mainScreen].scale, width = self.view.frame.size.width;
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 1.f/scale)];
        view.backgroundColor = self.tableView.separatorColor;
        view;
    });
    self.tableView.tableFooterView = ({
        CGFloat width = self.view.frame.size.width, height = 50;
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        view.backgroundColor = self.tableView.backgroundColor;
        view;
    });
    
    // Reuse identifiers per cell, accessed by [section][row]
    _reuseIdentifiers = @[@[kQueryReuse], @[kRadiusReuse], @[kFeedbackReuse]];
    [self.tableView registerClass:[ERTextFieldCell class] forCellReuseIdentifier:kQueryReuse];
    [self.tableView registerClass:[ERPickerCell class] forCellReuseIdentifier:kRadiusReuse];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kFeedbackReuse];
}

- (void)presentInView:(UIView *)view {
    [self.tableView sizeToFit];
    [self.tableView setFrameY:CGRectGetHeight(view.frame)];
    [view addSubview:self.tableView];
    [UIView animateSmoothly:^{
        CGFloat y = CGRectGetHeight(view.frame) - CGRectGetHeight(self.tableView.frame);
        [self.tableView setFrameY:y];
    }];
}

- (void)dismissFromView {
    self.radiusPreference = self.radiusCell.selectedRadius;
    self.queryPreference  = self.queryCell.text;
    
    [UIView animateSmoothly:^{
        [self.tableView setFrameY:CGRectGetHeight(self.tableView.superview.frame)];
    } completion:^(BOOL finished) {
        [self.tableView removeFromSuperview];
    }];
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(indexPath.section == 2);
    
    // The only selectable row is in the third section
    if (indexPath.section == 2) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self composeEmail];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 1:
            return 120;
        default:
            return 44;
    }
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:self.reuseIdentifiers[indexPath.section][indexPath.row]];
    switch (indexPath.section) {
        case 0: {
            _queryCell = (id)cell;
            self.queryCell.text = self.queryPreference;
            break;
        }
        case 1: {
            // Obtain a reference to the time interval picker
            _radiusCell = (id)cell;
            self.radiusCell.selectedRadius = self.radiusPreference;
            break;
        }
        case 2: {
            cell.textLabel.text = @"Send feedback";
            cell.textLabel.textColor = [UIColor colorWithRed:0.000 green:0.400 blue:1.000 alpha:1.000];
            cell.textLabel.font      = [cell.textLabel.font fontWithSize:17];
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Query";
        case 1:
            return @"Search radius";
        case 2:
            return nil;
            
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Tap to edit. What are you looking for?\nA place to eat, lodging, etc.";
        case 1:
            return @"Radius (in meters) to search along the path of the route you choose."
            " Larger radii will search faster, but smaller radii will yield more results in most cases. Use a small radius with very short routes.";
        case 2:
            return @"Copyright Tanner Bennett 2018."
            " Designed by Mark Malstrom and Tanner Bennett. Find me on Twitter at @NSExceptional. I appreciate your purchase!";
        default:
            return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (cell == self.radiusCell) {
        self.radiusCell.meters.font = [(UILabel *)[self.radiusCell.pickerView subviewWithClass:[UILabel class]] font];
    }
}

#pragma mark Feedback

- (void)composeEmail {
    NSString *body = [NSString stringWithFormat:@"%@, %@\n\n", [UIDevice currentDevice].model, [UIDevice currentDevice].systemVersion];
    MFMailComposeViewController *mail = [MFMailComposeViewController new];
    mail.mailComposeDelegate = self;
    mail.view.tintColor = [UIColor colorWithRed:0.000 green:0.400 blue:1.000 alpha:1.000];
    [mail setSubject:@"En Route Feedback"];
    [mail setMessageBody:body isHTML:NO];
    [mail setToRecipients:@[@"tannerbennett@icloud.com"]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:mail animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Preference accessors

- (CGFloat)radiusPreference {
    return [[NSUserDefaults standardUserDefaults] doubleForKey:kPref_searchRadius];
}

- (void)setRadiusPreference:(CGFloat)radiusPreference {
    [[NSUserDefaults standardUserDefaults] setDouble:radiusPreference forKey:kPref_searchRadius];
}

- (NSString *)queryPreference {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kPref_searchQuery];
}

- (void)setQueryPreference:(NSString *)queryPreference {
    [[NSUserDefaults standardUserDefaults] setObject:queryPreference forKey:kPref_searchQuery];
}

@end
