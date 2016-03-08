//
//  NSString+TemporaryFile.m
//  En Route
//
//  Created by Tanner on 3/6/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "NSString+TemporaryFile.h"

@implementation NSString (TemporaryFile)

- (NSString *)writeToTemporaryDirectoryWithType:(NSString *)extension {
    extension = [@"." stringByAppendingString:extension];
    NSString *path = [[NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID UUID].UUIDString] stringByAppendingString:extension];
    NSError *error = nil;
    [self writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        return nil;
    }
    
    return path;
}

@end
