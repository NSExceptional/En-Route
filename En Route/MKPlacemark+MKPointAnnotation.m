//
//  MKPlacemark+MKPointAnnotation.m
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "MKPlacemark+MKPointAnnotation.h"

@implementation CLPlacemark (MKPointAnnotation)

- (NSString *)formattedAddress {
    NSString *address = [self.addressDictionary[@"FormattedAddressLines"] componentsJoinedByString:@", "];
    if (address) return address;
    
    NSMutableString *formatted = [NSMutableString string];
    [formatted appendString:self.addressDictionary[@"Street"]]; [formatted appendString:@", "];
    [formatted appendString:self.addressDictionary[@"City"]];   [formatted appendString:@", "];
    [formatted appendString:self.addressDictionary[@"State"]];
    [formatted appendString:self.addressDictionary[@"ZIP"]];
    
    return formatted.copy;
}

- (MKPointAnnotation *)pointAnnotation {
    MKPointAnnotation *point = [MKPointAnnotation new];
    point.coordinate = self.location.coordinate;
    point.title = self.name;
    point.subtitle = self.formattedAddress;
    return point;
}

@end
