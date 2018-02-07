//
//  MKMapItem+PostalAddress.m
//  En Route
//
//  Created by Tanner on 3/6/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "MKMapItem+PostalAddress.h"

@implementation MKMapItem (PostalAddress)

- (NSInteger)hash {
    if (self.placemark.title) {
        return self.placemark.title.hash;
    }

    return self.name.hash;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[MKMapItem class]])
        return [self.placemark.title isEqualToString:((MKMapItem *)object).placemark.title];

    return [super isEqual:object];
}

@end
