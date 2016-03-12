//
//  ERPickerCell.h
//  En Route
//
//  Created by Tanner on 3/11/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ERPickerCell : UITableViewCell <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, readonly) UIPickerView *pickerView;
@property (nonatomic) CGFloat selectedRadius;
@property (nonatomic) UILabel *meters;

@end
