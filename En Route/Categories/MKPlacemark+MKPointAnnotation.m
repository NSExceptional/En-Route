//
//  MKPlacemark+MKPointAnnotation.m
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "MKPlacemark+MKPointAnnotation.h"
@import Contacts;


@implementation CLPlacemark (MKPointAnnotation)

- (NSString *)vCardStringForLocationWithName:(NSString *)name {
    CNPostalAddressFormatter *formatter = [CNPostalAddressFormatter new];
    NSString *address = [formatter stringFromPostalAddress:self.postalAddress];
    address = [address stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    return [NSString stringWithFormat:@"BEGIN:VCARD\nVERSION:3.0\nN:;%@;;;\nFN:%@\nORG:%@;\nitem1.URL:http://maps.apple.com/?address=%@&q=%@&ll=%f,%f\nitem1.X-ABLabel:map url\nEND:VCARD", name, name, name, address, name,
            self.location.coordinate.latitude, self.location.coordinate.longitude];
}

- (NSString *)formattedAddress {
    NSString *address = [self.addressDictionary[@"FormattedAddressLines"] componentsJoinedByString:@", "];
    if (address)
        return address;
    
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

- (CNPostalAddress *)postalAddress {
    CNMutablePostalAddress *address = [CNMutablePostalAddress new];
    address.street     = self.addressDictionary[@"Street"];
    address.city       = self.addressDictionary[@"City"];
    address.state      = self.addressDictionary[@"State"];
    address.postalCode = self.addressDictionary[@"ZIP"];
    address.country    = self.addressDictionary[@"Country"];
    
    return address.copy;
}

@end
