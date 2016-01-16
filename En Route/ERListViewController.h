//
//  ERListViewController.h
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ERListViewController : UITableViewController

+ (instancetype)listItems:(NSArray *)items currentLocation:(CLLocation *)currentLocation;

@property (nonatomic, readonly) NSArray<MKMapItem*> *items;

@end
