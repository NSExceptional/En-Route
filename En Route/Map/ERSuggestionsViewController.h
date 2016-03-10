//
//  ERSuggestionsViewController.h
//  En Route
//
//  Created by Tanner on 3/9/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ERSuggestionsViewController : UITableViewController

+ (instancetype)withAction:(void(^)(NSString *))action;

@end
