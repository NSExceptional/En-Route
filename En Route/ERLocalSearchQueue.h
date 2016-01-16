//
//  ERLocalSearchQueue.h
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

@import MapKit;


@interface ERLocalSearchQueue : NSObject

+ (instancetype)queueWithQuery:(NSString *)query radius:(CLLocationDistance)radius;

- (void)searchWithCoords:(NSArray *)locations loopCallback:(void(^)(NSArray *mapItems))callback completionCallback:(void(^)())completion;

@property (nonatomic) CLLocationDistance searchRadius;
@property (nonatomic) NSString *query;

- (void)cancelRequests;

@end
