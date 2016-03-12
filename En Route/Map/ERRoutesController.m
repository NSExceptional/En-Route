//
//  ERRoutesController.m
//  En Route
//
//  Created by Tanner on 3/12/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERRoutesController.h"
#import "ERMapNavigationBarBackground.h"


@interface ERRoutesController () <UITextFieldDelegate>
@property (nonatomic, readonly) ERMapNavigationBarBackground *barBackground;
@property (nonatomic, readonly) UINavigationItem *managedNavigationItem;
@property (nonatomic, readonly) UIToolbar *toolbar;

@property (nonatomic, readonly) UIBarButtonItem *routeButton;
@property (nonatomic, readonly) UIBarButtonItem *searchButton;
@property (nonatomic, readonly) UIBarButtonItem *clearButton;
@property (nonatomic, readonly) UIBarButtonItem *cancelButton;
@property (nonatomic, readonly) UIBarButtonItem *listButton;
@property (nonatomic, readonly) UIBarButtonItem *settingsButton;
@property (nonatomic, readonly) UIBarButtonItem *dismissSettingsButton;
@property (nonatomic, readonly) UILabel *toolbarLabel;

@property (nonatomic) NSArray *leftToolbarItems;
@property (nonatomic) BOOL showsResultsButton;

@property (nonatomic) ERSystemState stateBeforeSettings;
@end

@implementation ERRoutesController

#pragma mark Initialization

+ (instancetype)forNavigationItem:(UINavigationItem *)navigationItem toolbar:(UIToolbar *)toolbar trackingButton:(MKUserTrackingBarButtonItem *)button {
    ERRoutesController *routes     = [self new];
    routes->_managedNavigationItem = navigationItem;
    routes->_toolbar               = toolbar;
    routes->_userTrackingButton    = button;
    
    return routes;
}

- (void)loadView {
    _barBackground = [ERMapNavigationBarBackground new];
    self.view = self.barBackground;
    
    // Toolbar label
    _toolbarLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    self.toolbarLabel.font = [UIFont systemFontOfSize:12];
    
    // Toolbar buttons
    UIButton *settings = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [settings addTarget:self action:@selector(settingsButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    _settingsButton = [[UIBarButtonItem alloc] initWithCustomView:settings];
    _listButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"list"] style:UIBarButtonItemStylePlain target:self.delegate action:@selector(resultsButtonPressed)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *label  = [[UIBarButtonItem alloc] initWithCustomView:self.toolbarLabel];
    UIBarButtonItem *inset  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    inset.width = -6;
    self.leftToolbarItems = @[inset, _userTrackingButton, spacer, label, spacer];
    
    // Navbar items
    _routeButton  = [[UIBarButtonItem alloc] initWithTitle:@"Route" style:UIBarButtonItemStyleDone target:self action:@selector(routeButtonPressed)];
    _searchButton = [[UIBarButtonItem alloc] initWithTitle:@"Search" style:UIBarButtonItemStyleDone target:self action:@selector(searchButtonPressed)];
    _clearButton  = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearButtonPressed)];
    _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    _dismissSettingsButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSettingsButtonPressed)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.start.delegate = self;
    self.dest.delegate  = self;
    
    self.state = ERSystemStateDefault;
    
    [self.start addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld context:nil];
    [self.dest addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld context:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Won't execute the first time
    self.toolbar.items = [self.leftToolbarItems arrayByAddingObject:self.settingsButton];
}

#pragma mark Misc

- (void)updateTextDependentButtons {
    self.routeButton.enabled = self.textFieldsBothFull;
    self.clearButton.enabled = self.oneTextFieldFull;
}

- (ERAddressTextField *)start {
    return self.barBackground.startTextField;
}

- (ERAddressTextField *)dest {
    return self.barBackground.endTextField;
}

#pragma mark Public interface

- (void)selectTextOfActiveField {
    UITextField *start = self.barBackground.startTextField;
    UITextField *end   = self.barBackground.endTextField;
    
    if (start.isFirstResponder) {
        start.selectedTextRange = [start textRangeFromPosition:start.beginningOfDocument toPosition:start.endOfDocument];
    } else if (end.isFirstResponder) {
        end.selectedTextRange = [end textRangeFromPosition:end.beginningOfDocument toPosition:end.endOfDocument];
    }
}

- (BOOL)textFieldsBothFull {
    return self.start.text.length > 0 && self.dest.text.length > 0;
}

- (BOOL)oneTextFieldFull {
    return self.start.text.length > 0 || self.dest.text.length > 0;
}

- (UITextField *)emptyTextField {
    if (!self.start.text.length)
        return self.start;
    if (!self.dest.text.length)
        return self.dest;
    
    return nil;
}

- (UITextField *)activeTextField {
    if (self.start.isFirstResponder)
        return self.start;
    if (self.dest.isFirstResponder)
        return self.dest;
    return nil;
}

- (void)setState:(ERSystemState)state {
    if (_state == state) return;
    
    if (state == ERSystemStateSettings) {
        self.stateBeforeSettings = _state;
    }
    
    _state = state;
    
    self.showsResultsButton = state == ERSystemStateResults;
    
    switch (state) {
        case ERSystemStateDefault:
            [self setupInitialState]; break;
            
        case ERSystemStateSuggestion:
            [self setupSuggestionState]; break;
            
        case ERSystemStateFindingRoutes:
            [self setupFindingRoutesState]; break;
            
        case ERSystemStateRoutePicker:
            [self setupRoutePickerState]; break;
            
        case ERSystemStateResults:
            [self setupResultsState]; break;
            
        case ERSystemStateSettings:
            [self setupSettingsState]; break;
    }
}

- (void)setDelegate:(id<ERRoutesControllerDelegate>)delegate {
    _delegate = delegate;
    if (self.listButton) {
        self.listButton.target = delegate;
        self.listButton.action = @selector(resultsButtonPressed);
    }
}

- (void)setToolbarText:(NSString *)text {
    self.toolbarLabel.text = text;
    [self.toolbarLabel sizeToFit];
}

- (BOOL)currentLocationIsPartOfRoute {
    return [self.start.text isEqualToString:kCurrentLocationText] || [self.dest.text isEqualToString:kCurrentLocationText];
}

#pragma mark Button actions
// Results button goes directly to delegate

- (void)clearButtonPressed {
    self.start.text = nil;
    self.dest.text  = nil;
    
    [self.userTrackingButton.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
    self.state = ERSystemStateDefault;
    
    [self.delegate clearButtonPressed];
    [self updateTextDependentButtons];
}

- (void)cancelButtonPressed {
    [self.start resignFirstResponder];
    [self.dest resignFirstResponder];
    
    self.state = ERSystemStateDefault;
    
    [self.delegate suggestionsShouldDismiss];
}

- (void)routeButtonPressed {
    if (self.state == ERSystemStateSuggestion) {
        [self.delegate suggestionsShouldDismiss];
    }
    self.state = ERSystemStateFindingRoutes;
}

- (void)searchButtonPressed {
    self.state = ERSystemStateResults;
}

- (void)settingsButtonPressed {
    self.state = ERSystemStateSettings;
}

- (void)dismissSettingsButtonPressed {
    [self teardownSettingsState];
}

#pragma mark State management

- (void)setupInitialState {
    self.barBackground.shrunken = NO;
    self.clearButton.enabled = self.oneTextFieldFull;
    self.routeButton.enabled = self.textFieldsBothFull;
    self.managedNavigationItem.leftBarButtonItem  = self.clearButton;
    self.managedNavigationItem.rightBarButtonItem = self.routeButton;
}

- (void)setupSuggestionState {
    self.barBackground.shrunken = NO;
    self.cancelButton.enabled = YES;
    self.routeButton.enabled  = self.textFieldsBothFull;
    self.managedNavigationItem.leftBarButtonItem  = self.cancelButton;
    self.managedNavigationItem.rightBarButtonItem = self.routeButton;
    
    [self.delegate suggestionsShouldAppear];
}

- (void)setupFindingRoutesState {
    self.barBackground.shrunken = YES;
    self.clearButton.enabled  = NO;
    self.searchButton.enabled = NO;
    self.managedNavigationItem.leftBarButtonItem  = self.clearButton;
    self.managedNavigationItem.rightBarButtonItem = self.searchButton;
    
    [self.activeTextField resignFirstResponder];
    
    [self setToolbarText:@"Calculating routes…"];
    
    [self.delegate beginFindingRoutes];
}

- (void)setupRoutePickerState {
    self.barBackground.shrunken = NO;
    self.clearButton.enabled  = YES;
    self.searchButton.enabled = YES;
    self.managedNavigationItem.leftBarButtonItem  = self.clearButton;
    self.managedNavigationItem.rightBarButtonItem = self.searchButton;
    
    [self setToolbarText:nil];
}

- (void)setupResultsState {
    self.barBackground.shrunken = NO;
    self.clearButton.enabled = YES;
    self.managedNavigationItem.leftBarButtonItem  = self.clearButton;
    self.managedNavigationItem.rightBarButtonItem = nil;
    
    self.barBackground.shrunken = YES;
    
    [self.delegate beginSearch];
}

- (void)setupSettingsState {
    self.barBackground.shrunken = YES;
    self.managedNavigationItem.leftBarButtonItem  = nil;
    self.managedNavigationItem.rightBarButtonItem = self.dismissSettingsButton;
    
    [self.delegate settingsShouldAppear];
}

- (void)teardownSettingsState {
    self.barBackground.shrunken = NO;
    [self.delegate settingsShouldDismiss];
    
    self.state = self.stateBeforeSettings;
    self.stateBeforeSettings = 0;
}

- (void)setShowsResultsButton:(BOOL)showsResultsButton {
    if (_showsResultsButton == showsResultsButton) return;
    _showsResultsButton = showsResultsButton;
    
    if (showsResultsButton) {
        self.toolbar.items = [self.leftToolbarItems arrayByAddingObject:self.listButton];
    } else {
        self.toolbar.items = [self.leftToolbarItems arrayByAddingObject:self.settingsButton];
    }
}

#pragma mark - UITextFieldDelegate

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self updateTextDependentButtons];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.barBackground.startTextField) {
        // Go to the next text field
        [self.barBackground.endTextField becomeFirstResponder];
        [self selectTextOfActiveField];
    } else {
        // Text field will not return unless there is text
        [textField resignFirstResponder];
        
        [self.delegate suggestionsShouldDismiss];
        self.state = ERSystemStateFindingRoutes;
    }
    
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self.delegate textFieldDidEndEditing];
}

- (BOOL)textFieldShouldClear:(ERAddressTextField *)textField {
    [self.delegate textFieldWillClear];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (textField.drawsAsAtom) {
            textField.drawsAsAtom = NO;
        }
        
        [self updateTextDependentButtons];
    });
    
    return YES;
}

- (BOOL)textField:(ERAddressTextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self.delegate textFieldTextDidChange:[textField.text stringByReplacingCharactersInRange:range withString:string]];
    
    if (!string.length && range.length == textField.text.length) {
        if (textField.drawsAsAtom) {
            textField.drawsAsAtom = NO;
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateTextDependentButtons];
    });
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (self.state != ERSystemStateSuggestion) {
        self.state = ERSystemStateSuggestion;
    }
}

@end
