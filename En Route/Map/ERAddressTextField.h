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

@property (nonatomic, getter=safe_drawsAsAtom, setter=safe_setDrawsAsAtom:) BOOL drawsAsAtom;
@property (nonatomic, getter=safe_atomStyle, setter=safe_setAtomStyle:) int atomStyle;

@end
