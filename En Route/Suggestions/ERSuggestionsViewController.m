//
//  ERSuggestionsViewController.m
//  En Route
//
//  Created by Tanner on 3/9/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERSuggestionsViewController.h"
#import "ERSuggestionCell.h"
#import "ERSuggestion.h"
@import Contacts;


#define SectionSwitch(section, v1, v2, other) NSInteger sec = section; if (!self.contacts.count) { sec++; } switch (sec) { \
case 0: return v1; \
case 1: return v2; \
default: return other;}


static NSString * const kSuggestionReuse = @"ERSuggestionCellReuseIdentifier";
static CLLocationDistance searchRadius = 10000;

@interface ERSuggestionsViewController ()
@property (nonatomic, readonly) NSArray<ERSuggestion*> *contacts;
@property (nonatomic, readonly) NSArray<ERSuggestion*> *locations;

@property (nonatomic, readonly) CNContactStore *contactStore;
@property (nonatomic, readonly) MKLocalSearchRequest *request;
@property (nonatomic, readonly) CNPostalAddressFormatter *addressFormatter;

@property (nonatomic) NSTimeInterval lastQueryTime;
@property (nonatomic) NSString *recentQuery;

@property (nonatomic, copy) void (^selectSuggestionAction)(NSAttributedString *address);
@end

@implementation ERSuggestionsViewController

+ (instancetype)withAction:(void (^)(NSAttributedString *))action location:(CLLocation *)location {
    ERSuggestionsViewController *controller = [[self alloc] initWithStyle:UITableViewStylePlain];
    controller.selectSuggestionAction = action;
    controller.request.region = MKCoordinateRegionMakeWithDistance(location.coordinate, searchRadius, searchRadius);
    
    return controller;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        _request = [MKLocalSearchRequest new];
        _contactStore = [CNContactStore new];
        _addressFormatter = [CNPostalAddressFormatter new];
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    
    self.tableView.separatorInset  = UIEdgeInsetsMake(0, 24, 0, 0);
    self.tableView.backgroundColor = nil;
    self.tableView.backgroundView  = [UIVisualEffectView lightBlurView];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 70;
    [self.tableView registerClass:[ERSuggestionCell class] forCellReuseIdentifier:kSuggestionReuse];
    
    // Observe keyboard did show notification to resize view
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidAppear:) name:UIKeyboardDidShowNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Request contact access
    [self canShowContacts];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self updateQuery:nil];
}

- (void)keyboardDidAppear:(NSNotification *)notification {
    NSValue *keyboardFrameBegin = [notification.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrame = keyboardFrameBegin.CGRectValue;
    
    CGRect newFrame       = self.view.frame;
    newFrame.size.height -= keyboardFrame.size.height;
    self.view.frame = newFrame;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Contact access

- (BOOL)canShowContacts {
    static BOOL access = NO;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        [[NSUserDefaults standardUserDefaults] setInteger:status forKey:kPref_lastContactsAccessStatus];
        
        switch (status) {
            case CNAuthorizationStatusNotDetermined: {
                break;
            }
            case CNAuthorizationStatusRestricted: {
                // Tell the user once that their access is restricted
                if (![[NSUserDefaults standardUserDefaults] boolForKey:kPref_didShowRestrictedContactAccessPrompt]) {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPref_didShowRestrictedContactAccessPrompt];
                    NSString *message = @"It appears address book access has been restricted. En Route won't be able to suggest them as part of your trip.";
                    [[TBAlertController simpleOKAlertWithTitle:@"Address book access restricted" message:message] showFromViewController:self];
                }
                break;
            }
            case CNAuthorizationStatusDenied: { break; }
            case CNAuthorizationStatusAuthorized: {
                access = YES;
            }
        }
    });
    
    return access;
}

- (void)requestContactAccess:(VoidBlock)callback {
    // Go back if we can already see contacts or if we already asked
    if (self.canShowContacts || [[NSUserDefaults standardUserDefaults] boolForKey:kPref_didPromptForContactAccess]) {
        if (callback) callback();
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPref_didPromptForContactAccess];
    
    NSString *message = @"En Route can suggest your contacts as destinations as you type if you grant it access. Do you want to grant access now?";
    TBAlertController *alert = [TBAlertController alertViewWithTitle:@"Address book access" message:message];
    
    [alert addOtherButtonWithTitle:@"Yes!" buttonAction:^(NSArray * _Nonnull textFieldStrings) {
        CNContactStore *store = [CNContactStore new];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError *error) {
            [self canShowContacts];
            if (!granted) {
                NSString *message = @"You can enable access in settings if you change your mind.";
                [[TBAlertController simpleOKAlertWithTitle:@"Address book access" message:message] showFromViewController:self];
            }
            
            // Present suggestions again
            dispatch_async(dispatch_get_main_queue(), ^{
                if (callback) callback();
            });
        }];
    }];
    [alert addOtherButtonWithTitle:@"Not right now" buttonAction:^(NSArray *textFieldStrings) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kPref_contactsNotRightNowDate];
    }];
    [alert setCancelButtonWithTitle:@"No, don't ask me again" buttonAction:^(NSArray * _Nonnull textFieldStrings) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPref_contactsDontAskAgain];
    }];
    
    [alert showFromViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

#pragma mark Appearance

- (void)animatePresentation {
    self.view.alpha = 0;
    [UIView animateSmoothly:^{
        self.view.alpha = 1;
    }];
}

- (void)animateDismissalAndRemove {
    [UIView animateSmoothly:^{
        self.view.alpha = 0;
        self.view.transform = CGAffineTransformMakeScale(.8, .8);
    } completion:^(BOOL finished) {
        self.view.transform = CGAffineTransformMakeScale(1, 1);
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];
}

#pragma mark Model

- (void)updateQuery:(NSString *)query {
    if (!query.length) {
        // Reset table
        self.recentQuery   = nil;
        self.lastQueryTime = 0;
        _contacts  = nil;
        _locations = nil;
    }
    else {
        // User might have retyped something without clearing the text field
        if (self.recentQuery && ![query hasPrefix:self.recentQuery]) {
            _contacts  = nil;
            _locations = nil;
        }
        self.lastQueryTime = [NSDate date].timeIntervalSince1970;
        self.recentQuery   = query;
        _contacts = [self searchContacts:query];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.lastQueryTime > 0 && [NSDate date].timeIntervalSince1970 >= self.lastQueryTime) {
                self.lastQueryTime = 0;
                [self searchNearby:self.recentQuery callback:^(NSArray *locations) {
                    _locations = locations;
                    //                NSLog(@"%@", locations);
                    [self.tableView reloadData];
                }];
            }
        });
    }
    
    [self.tableView reloadData];
}

- (NSArray<ERSuggestion*> *)searchContacts:(NSString *)query {
    if (!self.canShowContacts) return @[];
    
    NSArray *keys = @[@"givenName", @"familyName", @"nickname", @"organizationName", @"postalAddresses", @"thumbnailImageData"];
    CNContactFetchRequest *fetch = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
    
    NSMutableArray *contacts = [NSMutableArray array];
    [self.contactStore enumerateContactsWithFetchRequest:fetch error:nil usingBlock:^(CNContact *contact, BOOL *stop) {
        if (contact.postalAddresses.count) {
            [contacts addObjectsFromArray:[ERSuggestion suggestionsFromContact:contact query:query formatter:self.addressFormatter]];
        }
        
        // Stop at 10 or more contacts
        if (contacts.count >= 10) {
            *stop = YES;
        }
    }];
    
    return contacts.copy;
}

- (void)searchNearby:(NSString *)query callback:(void(^)(NSArray *locations))callback {
    NSParameterAssert(callback);
    self.request.naturalLanguageQuery = query;
    
    [[[MKLocalSearch alloc] initWithRequest:self.request] startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        callback([ERSuggestion suggestionsFromMapItems:response.mapItems query:query]);
    }];
}

- (ERSuggestion *)suggestionForRowAtIndexpath:(NSIndexPath *)indexPath {
    SectionSwitch(indexPath.section, self.contacts[indexPath.row], self.locations[indexPath.row], nil);
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ERSuggestionCell *cell = (id)[self.tableView dequeueReusableCellWithIdentifier:kSuggestionReuse];
    ERSuggestion *suggestion = [self suggestionForRowAtIndexpath:indexPath];
    
    cell.nameLabel.attributedText = suggestion.name;
    cell.addressLabel.attributedText = suggestion.address;
    [cell setIcon:suggestion.icon];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    SectionSwitch(section, self.contacts.count, self.locations.count, 0);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = 0;
    if (self.contacts.count)
        sections++;
    if (self.locations.count)
        sections++;
    
    return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    SectionSwitch(section, @"Contacts", @"Suggestions", nil);
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.selectSuggestionAction) {
        self.selectSuggestionAction([self suggestionForRowAtIndexpath:indexPath].address);
        [self updateQuery:nil];
    }
}

@end
