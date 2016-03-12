//
//  ERPickerCell.m
//  En Route
//
//  Created by Tanner on 3/11/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERPickerCell.h"
#import "Masonry.h"


@implementation ERPickerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self awakeFromNib];
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    _pickerView = [[UIPickerView alloc] initWithFrame:self.bounds];
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    
    self.meters = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    self.meters.text = @"meters";
    self.meters.center = self.contentView.center;
    [self.meters setFrameX:CGRectGetMinX(self.meters.frame) + 20];
    
    [self.contentView addSubview:_pickerView];
    
    [self.pickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
}

#pragma mark Properties

- (CGFloat)selectedRadius {
    return [self.pickerView selectedRowInComponent:0] * 100 + 400;
}

- (void)setSelectedRadius:(CGFloat)selectedRadius {
    selectedRadius = MIN(1500, MAX(selectedRadius, 400));
    NSInteger row = (selectedRadius - 400)/100;
    
    [self.pickerView selectRow:row inComponent:0 animated:YES];
}

#pragma mark UIPickerView stuff

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 12; // 400 to 1500
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return @(row * 100 + 400).stringValue; // start at 400
}

@end
