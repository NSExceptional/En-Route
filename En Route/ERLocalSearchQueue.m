//
//  ERLocalSearchQueue.m
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERLocalSearchQueue.h"


@interface ERLocalSearchQueue ()
@property (nonatomic          ) MKLocalSearchRequest *request;
@property (nonatomic, readonly) NSMutableArray *locations;
@property (nonatomic          ) CGFloat delay;
@property (nonatomic          ) NSInteger failCount;
@property (nonatomic          ) NSInteger successCount;

@property (nonatomic, copy) void (^loopCallback)(NSArray *mapItems);
@property (nonatomic, copy) void (^completion)();

@property (nonatomic) BOOL didCancel;

@end


@implementation ERLocalSearchQueue

+ (instancetype)queueWithQuery:(NSString *)query radius:(CLLocationDistance)radius {
    ERLocalSearchQueue *queue = [self new];
    queue.query = query;
    queue.searchRadius = radius;
    return queue;
}

- (id)init {
    self = [super init];
    if (self) {
        _locations = [NSMutableArray array];
        _request   = [MKLocalSearchRequest new];
        _request.naturalLanguageQuery = @"food";
        _delay = .5;
    }
    
    return self;
}

- (void)searchWithCoords:(NSArray *)locations loopCallback:(void(^)(NSArray *mapItems))callback completionCallback:(void(^)())completion {
    [self.locations setArray:locations];
    self.loopCallback = callback;
    self.completion = completion;
    
    [self filterLocations];
    [self makeThreeRequests];
}

- (void)cancelRequests {
    _didCancel = YES;
}

- (void)filterLocations {
    NSCountedSet *newLocs = [NSCountedSet setWithArray:self.locations];
    for (CLLocation *loca in self.locations)
        for (CLLocation *locb in self.locations)
            if ([loca distanceFromLocation:locb] < _searchRadius)
                if (loca != locb)
                    [newLocs addObject:loca];
    
    newLocs = (id)[newLocs filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<NSString *,id> *bindings) {
        return [newLocs countForObject:evaluatedObject] < 3;
    }]];
    
    [self.locations setArray:newLocs.allObjects];
}

- (void)makeThreeRequests {
    if (!self.locations.count) return;
    
    NSInteger safeLoc = MIN(0, self.locations.count-3);
    NSInteger safeLen = MIN(self.locations.count, 3);
    NSArray *next = [self.locations subarrayWithRange:NSMakeRange(safeLoc, safeLen)];
    [self.locations removeObjectsInRange:NSMakeRange(safeLoc, safeLen)];
    
    __block NSInteger i = safeLen;
    for (CLLocation *loc in next) {
        self.request.region = MKCoordinateRegionMakeWithDistance(loc.coordinate, _searchRadius, _searchRadius);
        
        [[[MKLocalSearch alloc] initWithRequest:self.request] startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
            if (self.didCancel) return;
            
            if (self.loopCallback)
                self.loopCallback(response.mapItems);
            
            if (--i == 0) {
                // Last one
                if (self.locations.count == 0 && self.completion) {
                    self.completion();
                } else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self makeThreeRequests];
                        _delay = MAX(.25, _delay - 2);
                    });
                }
            }
            
            if (error) {
                _failCount++;
                _successCount = 0;
                if (_failCount > 1) {
                    _delay = MIN(_delay + 1, 5);
                    NSLog(@"T- %@ : Search failed, new delay: %@", @(self.locations.count), @(_delay));
                }
            } else {
                _successCount++;
                if (_successCount > 3)
                    _failCount = 0;
            }
        }];
    }
}

@end
