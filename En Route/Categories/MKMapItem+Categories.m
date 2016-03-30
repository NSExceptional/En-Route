//
//  MKMapItem+Categories.m
//  En Route
//
//  Created by Tanner on 3/29/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "MKMapItem+Categories.h"


NSString * const kCategoryGasStation        = @"Gas Station";
NSString * const kCategoryFoodAndRestaurant = @"Food Restaurants";
NSString * const kCategoryEducation         = @"Education";
NSString * const kCategoryFinancial         = @"Financial Services";
NSString * const kCategoryActiveLive        = @"Active Life";
NSString * const kCategoryHomeServices      = @"Home Serviecs";
NSString * const kCategoryShopping          = @"Shopping";
NSString * const kCategoryAutomotive        = @"Automotive";
NSString * const kCategoryMedical           = @"Health & Medical";
NSString * const kCategoryGovernment        = @"Government";
NSString * const kCategoryLocalServices     = @"Local Services";
NSString * const kCategoryHotel             = @"Hotel";
NSString * const kCategoryEntertainment     = @"Arts & Entertainment";
NSString * const kCategoryProfessional      = @"Professional Services";
NSString * const kCategoryEventServices     = @"Event Services";
NSString * const kCategoryNightlife         = @"Nightlife";
NSString * const kCategoryBeautyAndSpa      = @"Beauty & Spa";
NSString * const kCategoryRealEstate        = @"Real Estate";


@implementation MKMapItem (Categories)

- (UIImage *)categoryIcon {
    static NSDictionary *categoryStrings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        categoryStrings= @{kCategoryGasStation: @"c_gas_station",
                           kCategoryFoodAndRestaurant: @"c_food",
                           kCategoryEducation: @"c_education",
                           kCategoryFinancial: @"c_financial",
                           kCategoryActiveLive: @"c_active",
                           kCategoryHomeServices: @"c_home_services",
                           kCategoryShopping: @"c_shopping",
                           kCategoryAutomotive: @"c_automotive",
                           kCategoryMedical: @"c_medical",
                           kCategoryGovernment: @"c_government",
                           kCategoryLocalServices: @"c_local",
                           kCategoryHotel: @"c_hotel",
                           kCategoryEntertainment: @"c_entertainment",
                           kCategoryProfessional: @"c_professional",
                           kCategoryEventServices: @"c_event",
                           kCategoryNightlife: @"c_nightlife",
                           kCategoryBeautyAndSpa: @"c_beauty_spa",
                           kCategoryRealEstate: @"c_real_estate"};
    });
    
    for (NSString *categoryName in categoryStrings.allKeys)
        for (NSString *myCategory in [self categories])
            if ([categoryName containsString:myCategory]) {
                return categoryStrings[categoryName];
            }
    
    return [UIImage imageNamed:@"c_other"];
}

- (NSArray *)categories {
    NSArray *categories = [[[self valueForKey:@"place"] valueForKey:@"firstBusiness"] valueForKey:@"localizedCategories"];
    categories = [categories filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [[evaluatedObject valueForKey:@"level"] integerValue] == 1 ||
        [[[[evaluatedObject valueForKey:@"localizedNames"] valueForKeyPath:@"@unionOfArrays.self"] valueForKeyPath:@"@unionOfObjects.name"] containsObject:kCategoryGasStation];
    }]];
    categories = [[categories valueForKeyPath:@"@unionOfObjects.localizedNames"] valueForKeyPath:@"@unionOfArrays.self"];
    categories = [categories valueForKeyPath:@"@unionOfObjects.name"];
    
    return categories;
}

@end
