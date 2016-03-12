//
//  ERRoutesController.h
//  En Route
//
//  Created by Tanner on 3/12/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MapKit;


typedef NS_ENUM(NSUInteger, ERSystemState)
{
    ERSystemStateDefault = 1,
    ERSystemStateSuggestion,
    ERSystemStateFindingRoutes,
    ERSystemStateRoutePicker,
    ERSystemStateResults,
    ERSystemStateSettings
};

@protocol ERRoutesControllerDelegate <NSObject>
- (void)clearButtonPressed;
- (void)settingsShouldAppear;
- (void)settingsShouldDismiss;
- (void)suggestionsShouldAppear;
- (void)suggestionsShouldDismiss;
- (void)beginFindingRoutes;
- (void)beginSearch;
- (void)resultsButtonPressed;

- (void)textFieldDidEndEditing;
- (void)textFieldWillClear;
- (void)textFieldTextDidChange:(NSString *)newString;
@end

@interface ERRoutesController : UIViewController

+ (instancetype)forNavigationItem:(UINavigationItem *)navigationItem toolbar:(UIToolbar *)toolbar trackingButton:(MKUserTrackingBarButtonItem *)button;

@property (nonatomic) id<ERRoutesControllerDelegate> delegate;
@property (nonatomic) ERSystemState state;

@property (nonatomic, readonly) UITextField *start;
@property (nonatomic, readonly) UITextField *dest;
@property (nonatomic, readonly) UITextField *activeTextField;
/// @return start if both fields are empty
@property (nonatomic, readonly) UITextField *emptyTextField;
@property (nonatomic, readonly) MKUserTrackingBarButtonItem *userTrackingButton;

@property (nonatomic, readonly) BOOL textFieldsBothFull;
@property (nonatomic, readonly) BOOL oneTextFieldFull;
@property (nonatomic, readonly) BOOL currentLocationIsPartOfRoute;

- (void)setToolbarText:(NSString *)text;
- (void)selectTextOfActiveField;
/// Call manually if you want
- (void)teardownSettingsState;


@end
