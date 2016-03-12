//
//  CNContact+Name.m
//  En Route
//
//  Created by Tanner on 3/11/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "CNContact+Name.h"


@implementation CNContact (Name)

- (NSString *)displayName {
    if (self.givenName.length && self.familyName.length) {
        return [NSString stringWithFormat:@"%@ %@", self.givenName, self.familyName];
    } else {
        return self.givenName.length ? self.givenName :
               self.familyName.length ? self.familyName :
               self.nickname.length ? self.nickname :
               self.organizationName.length ? self.organizationName :
               @"No name";
    }
}

@end
