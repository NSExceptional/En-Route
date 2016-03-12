//
//  ERSettingsViewController.h
//  En Route
//
//  Created by Tanner on 3/11/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ERPickerCell;


@interface ERSettingsViewController : UITableViewController

- (void)presentInView:(UIView *)view;
- (void)dismissFromView;

@end
