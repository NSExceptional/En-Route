//
//  ERSuggestion.h
//  En Route
//
//  Created by Tanner on 3/10/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Contacts;


@interface ERSuggestion : NSObject

+ (NSArray<ERSuggestion*> *)suggestionsFromContact:(CNContact *)contact query:(NSString *)query formatter:(CNPostalAddressFormatter *)formatter;
+ (NSArray<ERSuggestion*> *)suggestionsFromMapItems:(NSArray<MKMapItem*> *)items query:(NSString *)query;
+ (instancetype)suggestionWithName:(NSString *)name address:(NSString *)address icon:(UIImage *)icon query:(NSString *)query;

@property (nonatomic, readonly) NSAttributedString *name;
@property (nonatomic, readonly) NSAttributedString *address;
@property (nonatomic, readonly) UIImage *icon;

@end
