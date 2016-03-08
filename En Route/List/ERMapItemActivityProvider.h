//
//  ERMapItemActivityProvider.h
//  En Route
//
//  Created by Tanner on 3/6/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ERMapItemActivityProvider : NSObject <UIActivityItemSource>

+ (instancetype)withName:(NSString *)name vCard:(NSString *)vCard;

@property (nonatomic, readonly) NSString *vCardString;
@property (nonatomic, readonly) NSString *name;

@end
