//
//  En-Route-Constants.h
//  En Route
//
//  Created by Tanner on 2/15/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void(^VoidBlock)();

extern NSString * const kCurrentLocationText;

extern NSString * const kPref_searchRadius;
extern NSString * const kPref_searchQuery;
extern NSString * const kPref_mapRect;
extern NSString * const kPref_didPromptForContactAccess;
extern NSString * const kPref_didShowRestrictedLocationAccessPrompt;
extern NSString * const kPref_didShowRestrictedContactAccessPrompt;

extern NSString * const kPref_locationDontAskAgain;
extern NSString * const kPref_locationNotRightNowDate;
extern NSString * const kPref_contactsDontAskAgain;
extern NSString * const kPref_contactsNotRightNowDate;

extern NSString * const kPref_lastLocationAccessStatus;
extern NSString * const kPref_lastContactsAccessStatus;

extern CGFloat const kAnimationDuration;