//
//  ERLocalSearchQueue.m
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERLocalSearchQueue.h"
#import "TBTimer.h"


@interface ERLocalSearchQueue ()
@property (nonatomic          ) MKLocalSearchRequest *request;
@property (nonatomic, readonly) NSMutableArray *locations;
@property (nonatomic, readonly) NSTimer *timer;
@property (nonatomic          ) NSInteger secondsLeft;

@property (nonatomic          ) CGFloat delay;
@property (nonatomic          ) NSInteger batchSize;
@property (nonatomic          ) NSInteger failCount;
@property (nonatomic          ) NSInteger successCount;
@property (nonatomic          ) NSInteger total;

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
        _delay = 60;
        _batchSize = 50;
        
        _timer = [NSTimer timerWithTimeInterval:60 target:self selector:@selector(decTimer) userInfo:nil repeats:YES];
    }
    
    return self;
}

- (void)decTimer {
    self.secondsLeft--;
    if (_secondsLeft < 0) {
        _secondsLeft = 0;
    }
}

- (void)setSecondsLeft:(NSInteger)secondsLeft {
    if (_secondsLeft == 1 && secondsLeft == 0) {
        _total -= 50;
    }
    _secondsLeft = secondsLeft;
}

- (void)searchWithCoords:(NSArray *)locations loopCallback:(void(^)(NSArray *mapItems))callback completionCallback:(void(^)())completion {
    [self.locations setArray:locations];
    self.loopCallback = callback;
    self.completion = completion;
    
    [self filterLocations];
    
    if (_secondsLeft && _total > 50) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_secondsLeft+1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self makeBatchRequests];
        });
    } else {
        [_timer fire];
        [self makeBatchRequests];
    }
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

- (void)makeBatchRequests {
    if (!self.locations.count) return;
    
    NSInteger safeLoc = self.locations.count-_batchSize; if (safeLoc < 0) safeLoc = 0;
    NSInteger safeLen = MIN(self.locations.count, _batchSize);
    NSArray *next = [self.locations subarrayWithRange:NSMakeRange(safeLoc, safeLen)];
    [self.locations removeObjectsInRange:NSMakeRange(safeLoc, safeLen)];
    
    _secondsLeft += 60;
    
    __block NSInteger i = safeLen;
    for (CLLocation *loc in next) {
        self.request.region = MKCoordinateRegionMakeWithDistance(loc.coordinate, _searchRadius, _searchRadius);
        
        [[[MKLocalSearch alloc] initWithRequest:self.request] startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
            if (self.didCancel) return;
            
            if (self.loopCallback)
                self.loopCallback(response.mapItems);
            
            if (error) {
                NSLog(@"-------FAIL------- %@", @(++_total));
                [TBTimer lap];
            } else {
                NSLog(@"success: %@", @(++_total));
            }
            
            if (--i == 0) {
                // Last one
                if (self.locations.count == 0 && self.completion) {
                    self.completion();
                } else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self makeBatchRequests];
                    });
                }
            }
        }];
    }
}

@end
