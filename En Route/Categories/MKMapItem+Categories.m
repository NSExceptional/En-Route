//
//  MKMapItem+Categories.m
//  En Route
//
//  Created by Tanner on 3/29/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "MKMapItem+Categories.h"


NSString * const kCategoryAirport           = @"Airport";
NSString * const kCategoryHotel             = @"Hotel";
NSString * const kCategoryGasStation        = @"Gas Station";
NSString * const kCategoryShopping          = @"Shopping";
NSString * const kCategoryFoodAndRestaurant = @"Food Restaurants";
NSString * const kCategoryEducation         = @"Education";
NSString * const kCategoryFinancial         = @"Financial Services";
NSString * const kCategoryActiveLive        = @"Active Life";
NSString * const kCategoryHomeServices      = @"Home Serviecs";
NSString * const kCategoryAutomotive        = @"Automotive";
NSString * const kCategoryMedical           = @"Health & Medical";
NSString * const kCategoryGovernment        = @"Government";
NSString * const kCategoryLocalServices     = @"Local Services";
NSString * const kCategoryEntertainment     = @"Arts & Entertainment";
NSString * const kCategoryProfessional      = @"Professional Services";
NSString * const kCategoryEventServices     = @"Event Services";
NSString * const kCategoryNightlife         = @"Nightlife";
NSString * const kCategoryBeautyAndSpa      = @"Beauty & Spa";
NSString * const kCategoryRealEstate        = @"Real Estate";


@implementation MKMapItem (Categories)

- (UIImage *)categoryIcon {
    UIImage *icon = objc_getAssociatedObject(self, @selector(categoryIcon));
    if (icon) {
        return icon;
    }
    
    self.categoryIcon = [self determineCategoryIcon];
    return self.categoryIcon;
}

- (void)setCategoryIcon:(UIImage *)categoryIcon {
    NSParameterAssert(categoryIcon);
    objc_setAssociatedObject(self, @selector(categoryIcon), categoryIcon, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)determineCategoryIcon {
    static NSDictionary *categoriesToIcons = nil;
    static NSArray *categories = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        categoriesToIcons= @{kCategoryAirport: @"c_airport",
                           kCategoryHotel: @"c_hotel",
                           kCategoryGasStation: @"c_gas_station",
                           kCategoryShopping: @"c_shopping",
                           kCategoryFoodAndRestaurant: @"c_food",
                           kCategoryEducation: @"c_education",
                           kCategoryFinancial: @"c_financial",
                           kCategoryActiveLive: @"c_active",
                           kCategoryHomeServices: @"c_home_services",
                           kCategoryAutomotive: @"c_automotive",
                           kCategoryMedical: @"c_medical",
                           kCategoryGovernment: @"c_government",
                           kCategoryLocalServices: @"c_local_services",
                           kCategoryEntertainment: @"c_entertainment",
                           kCategoryProfessional: @"c_professional",
                           kCategoryEventServices: @"c_event",
                           kCategoryNightlife: @"c_nightlife",
                           kCategoryBeautyAndSpa: @"c_beauty_spa",
                           kCategoryRealEstate: @"c_real_estate"};
        categories = @[kCategoryAirport, kCategoryHotel, kCategoryGasStation, kCategoryShopping,
                       kCategoryFoodAndRestaurant, kCategoryEducation, kCategoryFinancial,
                       kCategoryActiveLive, kCategoryHomeServices, kCategoryAutomotive,
                       kCategoryMedical, kCategoryGovernment, kCategoryLocalServices,
                       kCategoryEntertainment, kCategoryProfessional, kCategoryEventServices,
                       kCategoryNightlife, kCategoryBeautyAndSpa, kCategoryRealEstate];
    });
    
    for (NSString *categoryName in categories)
        for (NSString *myCategory in [self categories])
            if ([categoryName containsString:myCategory]) {
                return [UIImage imageNamed:categoriesToIcons[categoryName]];
            }
    
    return [UIImage imageNamed:@"c_other"];
}

- (NSArray *)categories {
    NSArray *categories = [[[self valueForKey:@"place"] valueForKey:@"firstBusiness"] valueForKey:@"localizedCategories"];
    categories = [[categories valueForKeyPath:@"@unionOfObjects.localizedNames"] valueForKeyPath:@"@unionOfArrays.self"];
    categories = [categories valueForKeyPath:@"@unionOfObjects.name"];
    
    return categories;
}

@end
