//
//  ERSuggestionsViewController.m
//  En Route
//
//  Created by Tanner on 3/9/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERSuggestionsViewController.h"
#import "ERSuggestionCell.h"


static NSString * const kSuggestionReuse = @"ERSuggestionCellReuseIdentifier";

@interface ERSuggestionsViewController ()
@property (nonatomic, readonly) NSArray *contacts;
@property (nonatomic, readonly) NSArray *locations;

@property (nonatomic, copy) void (^selectSuggestionAction)(NSString *address);
@end

@implementation ERSuggestionsViewController

- (void)loadView {
    [super loadView];
    
    self.tableView.backgroundView = [UIVisualEffectView lightBlurView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 70;
    [self.tableView registerClass:[ERSuggestionCell class] forCellReuseIdentifier:kSuggestionReuse];
}

- (NSString *)nameForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Papa John's Pizza";
}

- (NSString *)addressForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"7707 Stonesdale Drive, Houston, TX 77095, United States";
}

- (UIImage *)iconForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [UIImage imageNamed:@"testicon"];
}

#pragma mark UITableViewDataSource

+ (instancetype)withAction:(void (^)(NSString *))action {
    ERSuggestionsViewController *controller = [self new];
    controller.selectSuggestionAction = action;
    
    return controller;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ERSuggestionCell *cell = (id)[self.tableView dequeueReusableCellWithIdentifier:kSuggestionReuse];
    
    cell.nameLabel.text = [self nameForRowAtIndexPath:indexPath];
    cell.addressLabel.text = [self addressForRowAtIndexPath:indexPath];
    cell.iconImageView.image = [self iconForRowAtIndexPath:indexPath];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
    switch (section) {
        case 0:
            return self.contacts.count;
        case 1:
            return self.locations.count;
            
        default:
            return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
    NSInteger sections = 0;
    if (self.contacts.count)
        sections++;
    if (self.locations.count)
        sections++;
    
    return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Contacts";
        case 1:
            return @"Suggestions";
            
        default:
            return nil;
    }
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.selectSuggestionAction) {
        self.selectSuggestionAction([self addressForRowAtIndexPath:indexPath]);
    }
}

@end
