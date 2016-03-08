//
//  NSString+TemporaryFile.h
//  En Route
//
//  Created by Tanner on 3/6/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (TemporaryFile)

- (NSString *)writeToTemporaryDirectoryWithType:(NSString *)extension;

@end
