//
//  ERMapItemActivityProvider.m
//  En Route
//
//  Created by Tanner on 3/6/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERMapItemActivityProvider.h"

@implementation ERMapItemActivityProvider

+ (instancetype)withName:(NSString *)name vCard:(NSString *)vCard {
    ERMapItemActivityProvider *provider = [self new];
    provider->_name = name;
    provider->_vCardString = vCard;
    
    return provider;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
    return [NSData new];
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType {
    return [self.vCardString dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController dataTypeIdentifierForActivityType:(NSString *)activityType {
    return @"public.vcard";
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController attachmentNameForActivityType:(id)type {
    return [NSString stringWithFormat:@"%@.loc.vcf", self.name];
}

@end
