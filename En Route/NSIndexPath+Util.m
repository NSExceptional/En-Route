//
//  NSIndexPath+Util.m
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "NSIndexPath+Util.h"

@implementation NSIndexPath (Util)

+ (NSArray *)indexPathsInSection:(NSUInteger)section inRange:(NSRange)range {
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSUInteger row = range.location; row < range.location + range.length; row++)
        [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
    
    return indexPaths.copy;
}

+ (NSArray *)indexPathsInSection:(NSUInteger)section withIndexes:(NSIndexSet *)indexes {
    NSParameterAssert(indexes);
    
    NSMutableArray *indexPaths = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
    }];
    
    return indexPaths.copy;
}

+ (NSArray *)indexPathsForArrayToAppend:(NSUInteger)appendCount to:(NSUInteger)currentCount {
    NSMutableArray *indexPaths   = [[NSMutableArray alloc] initWithCapacity:appendCount];
    
    for (NSUInteger index = 0; index < appendCount; index++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:currentCount + index inSection:0];
        [indexPaths addObject:indexPath];
    }
    
    return indexPaths.copy;
}

@end
