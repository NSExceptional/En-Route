//
//  ERSuggestion.m
//  En Route
//
//  Created by Tanner on 3/10/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERSuggestion.h"

CGFloat const kIconHeight = 42;

@implementation ERSuggestion
@synthesize icon = _icon;

+ (NSArray<ERSuggestion*> *)suggestionsFromContact:(CNContact *)contact query:(NSString *)query formatter:(CNPostalAddressFormatter *)formatter {
    NSMutableArray *suggestions = [NSMutableArray array];
    
    // Find the corresponding address, since contacts may have more than one
    CNPostalAddress *address;
    for (CNLabeledValue<CNPostalAddress*> *entry in contact.postalAddresses) {
        if ([[formatter stringFromPostalAddress:entry.value] containsString:query]) {
            address = entry.value;
            break;
        }
    }
    
    if (!address) {
        // Make multiple suggestions with each address, since we matched the name and not the address
        CNMutableContact *mutable;
        for (CNLabeledValue<CNPostalAddress*> *address in contact.postalAddresses) {
            mutable = contact.mutableCopy;
            mutable.postalAddresses = @[[CNLabeledValue labeledValueWithLabel:@"address" value:address.value]];
            ERSuggestion *optional = [ERSuggestion suggestionFromContact:mutable.copy query:query formatter:formatter];
            if (optional) {
                [suggestions addObject:optional];
            }
        }
    } else {
        UIImage *icon = [UIImage imageWithData:contact.thumbnailImageData];
        [suggestions addObject:[ERSuggestion suggestionWithName:contact.displayName address:[formatter stringFromPostalAddress:address] icon:icon query:query]];
    }
    
    return suggestions.copy;
}

+ (instancetype)suggestionFromContact:(CNContact *)contact query:(NSString *)query formatter:(CNPostalAddressFormatter *)formatter {
    NSString *plainAddress = [formatter stringFromPostalAddress:contact.postalAddresses.firstObject.value];
    NSString *name;
    
    // Find the matching name, if any
    for (NSString *string in @[contact.displayName, contact.nickname, contact.organizationName]) {
        if ([string containsString:query]) {
            name = string;
            break;
        }
    }
    // Use full name otherwise
    if (!name) {
        // Return nothing if neither the name or address match the query
        if (![plainAddress containsString:query]) {
            return nil;
        }
        
        name = contact.givenName;
    }
    
    
    return [self suggestionWithName:name address:plainAddress icon:[UIImage imageWithData:contact.thumbnailImageData] query:query];
}

+ (instancetype)suggestionWithName:(NSString *)name address:(NSString *)address icon:(UIImage *)icon query:(NSString *)query {
    ERSuggestion *suggestion = [self new];
    suggestion.icon = icon;
    // Add bold attribute to matching parts of strings
    
    if ([name containsString:query]) {
        NSMutableAttributedString *mName = [[NSMutableAttributedString alloc] initWithString:name];
        [mName addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17] range:[name rangeOfString:query]];
        suggestion->_name = mName.copy;
    } else {
        suggestion->_name = [[NSAttributedString alloc] initWithString:name];
    }
    
    if ([address containsString:query]) {
        NSMutableAttributedString *mAddress = [[NSMutableAttributedString alloc] initWithString:address];
        [mAddress addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17] range:[address rangeOfString:query]];
        suggestion->_address = mAddress.copy;
    } else {
        suggestion->_address = [[NSAttributedString alloc] initWithString:address];
    }
    
    return suggestion;
}

+ (NSArray<ERSuggestion*> *)suggestionsFromMapItems:(NSArray<MKMapItem *> *)items query:(NSString *)query {
    NSMutableArray *suggestions = [NSMutableArray array];
    
    for (MKMapItem *item in items) {
        [suggestions addObject:[ERSuggestion suggestionWithName:item.name address:item.placemark.formattedAddress icon:nil query:query]];
    }
    
    return suggestions.copy;
}

- (UIImage *)icon {
    return _icon ?: [UIImage imageNamed:@"testicon"];
}

- (void)setIcon:(UIImage *)icon {
    if (icon) {
        if (icon.size.height > icon.size.width) {
            icon = [icon scaledDownToFitSize:CGSizeMake(kIconHeight, CGFLOAT_MAX)];
        } else if (icon.size.width > icon.size.height) {
            icon = [icon scaledDownToFitSize:CGSizeMake(CGFLOAT_MAX, kIconHeight)];
        } else {
            icon = [icon scaledDownToFitSize:CGSizeMake(kIconHeight, kIconHeight)];
        }
    }
    
    _icon = icon;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ name=%@, address=%@>",
            NSStringFromClass(self.class), self.name.string, [self.address.string stringByReplacingOccurrencesOfString:@"\n" withString:@", "]];
}

@end
