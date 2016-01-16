//
//  ERAdressTextField.h
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ERAddressTextField : UITextField

@property (nonatomic, readonly) UILabel *nameLabel;
@property (nonatomic, readonly) CGFloat estimatedFieldEntryOffset;
@property (nonatomic          ) CGFloat fieldEntryOffset;

- (void)_updateAtomBackground;
- (void)_updateAtomTextColor;

//@property (nonatomic) BOOL drawsAsAtom;
//@property (nonatomic) int atomStyle;
- (BOOL)drawsAsAtom;
- (void)setDrawsAsAtom:(BOOL)b;
- (int)atomStyle;
- (void)setAtomStyle:(int)style;

@end
