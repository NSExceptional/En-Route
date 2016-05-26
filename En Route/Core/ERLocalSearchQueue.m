//
//  ERLocalSearchQueue.m
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERLocalSearchQueue.h"


#define RunBlock(block) if ( block ) block()
#define RunBlockP(block, ...) if ( block ) block( __VA_ARGS__ )

static CLLocationDistance const kMinDistanceBetweenPoints = 200;

@interface ERLocalSearchQueue ()
@property (nonatomic) MKLocalSearchRequest *request;
@property (nonatomic) NSArray *locations;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSInteger secondsLeft;

@property (nonatomic) CGFloat delay;
@property (nonatomic) NSInteger total;

@property (nonatomic) NSDate *lastRequestActivity;
@property (nonatomic) NSInteger lastRequestCount;

@property (nonatomic, copy) VoidBlock loopCallback;
@property (nonatomic, copy) VoidBlock completion;;

@property (nonatomic) BOOL didCancel;

@end


@implementation ERLocalSearchQueue

+ (instancetype)queueWithQuery:(NSString *)query radius:(CLLocationDistance)radius {
    ERLocalSearchQueue *queue = [self new];
    queue.query = query;
    queue.searchRadius = radius;
    return queue;
}

static dispatch_queue_t _backgroundQueue;

+ (dispatch_queue_t)backgroundQueue {
    @synchronized(self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _backgroundQueue = dispatch_queue_create("erlocalsearchqueue", DISPATCH_QUEUE_SERIAL);
        });
        return _backgroundQueue;
    }
}

- (id)init {
    self = [super init];
    if (self) {
        _locations = [NSMutableArray array];
        _request   = [MKLocalSearchRequest new];
        _request.naturalLanguageQuery = @"food";
    }
    
    return self;
}

- (NSString *)query {
    return self.request.naturalLanguageQuery;
}

- (void)setQuery:(NSString *)query {
    self.request.naturalLanguageQuery = query;
}

- (void)decTimer {
    self.secondsLeft--;
    if (_secondsLeft < 0) {
        _secondsLeft = 0;
        [_timer invalidate];
        _timer = nil;
    }
}

- (BOOL)ready {
    return _secondsLeft <= 0;
}

- (void)setSecondsLeft:(NSInteger)secondsLeft {
    if (_secondsLeft == 1 && secondsLeft == 0) {
        _total -= 50;
    }
    _secondsLeft = secondsLeft;
}

- (void)searchRoutes:(NSArray<MKRoute *> *)routes repeatedCallback:(ArrayBlock)callback completion:(VoidBlock)completion {
    self.loopCallback = callback;
    self.completion = completion;
    
    // Get all coords in an array
    NSMutableOrderedSet *filteredCoords = [NSMutableOrderedSet orderedSet];
    for (MKRoute *route in routes)
        [filteredCoords addObjectsFromArray:[self coordinatesAlongRoute:route]];
    _locations = filteredCoords.array;
    
    [self filterLocations];
    [filteredCoords removeObjectsInArray:self.locations];
    
    RunBlockP(_debugCallback, self.locations, filteredCoords.array);
    if (!_locations.count) {
        // Return if we have no requests to make.
        RunBlock(_completion);
        return;
    }
    
    // Calculate delay
    _delay = _locations.count <= 50 ? 0 : 1.2001;
    
    // Puts a hold on the next set of requests if necessary.
    // If we made the last request over a minute ago, we have nothing
    // to do here. Otherwise, if the number of requests made previously plus
    // the number of requests we're about to make is <= 50 change the request
    // count but do not update the request date, since we're gonna count it
    // as one big request. Else, if the last request count is < 50,
    // delay the next set of requests by 60 - {t since last req} seconds.
    // This will ensure we never make more than 50 req / min.
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:_lastRequestActivity];
    if (_lastRequestActivity && interval < 60) {
        if ((_lastRequestCount % 51) + _locations.count <= 50) {
            _lastRequestCount += _locations.count;
        } else if ((_lastRequestCount % 51) <= 50) {
            _secondsLeft += 60 - interval;
            // If neither of the above are true, then this will be true implicitly.
            // We only need to reset the delay in the event where we're making <= 50
            // requests after making n * 50 + y requests, where y < 50.
        } else {//if (_locations.count <= 50) {
            _delay = 1.2001;
        }
    }
    
    // Dispatch so we can safely sleep the thread
    dispatch_async([ERLocalSearchQueue backgroundQueue], ^{
        
        // Needed to wait for old timer to finish and invalidate itself
        if (!self.ready) {
            RunBlockP(_pauseCallback, self.secondsLeft);
            [NSThread sleepForTimeInterval:self.secondsLeft+.01];
            RunBlock(_resumeCallback);
        }
        
        _lastRequestActivity = [NSDate date];
        _lastRequestCount = _locations.count;
        _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(decTimer) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        
        // Make requests in a loop
        __block NSInteger i = _locations.count;
        __block BOOL stop = NO;
        for (CLLocation *loc in _locations) { if (stop) break;
            self.request.region = MKCoordinateRegionMakeWithDistance(loc.coordinate, self.searchRadius, self.searchRadius);
            
            // Wait if necessary and call back to notify about the wait
            if (!self.ready) {
                RunBlockP(_pauseCallback, self.secondsLeft);
                [NSThread sleepForTimeInterval:self.secondsLeft+.01];
                RunBlock(_resumeCallback);
            }
            
            // Actual request
            [[[MKLocalSearch alloc] initWithRequest:self.request] startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
                assert(i > 0);
                if (self.didCancel) return;
                if (stop) return;
                
                RunBlockP(_loopCallback, response.mapItems);
                
                // Counts
                ++_total;
                if (error) {
                    NSLog(@"/n/nFAIL: %@, %@", @(_total), error.localizedDescription);
                    //                    [TBTimer lap];
                    //                    RunBlock(_errorCallback);
                    //                    stop = YES; // Terminate loop, no completion block
                    //                    _lastRequestActivity = [NSDate date];
                }
                
                // Last one
                if (--i == 0) {
                    RunBlock(_completion);
                    _lastRequestActivity = [NSDate date];
                }
            }];
            
            [NSThread sleepForTimeInterval:_delay];
        }
    });
}

- (NSArray<CLLocation*> *)coordinatesAlongRoute:(MKRoute *)route {
    NSMutableArray *points = [NSMutableArray array];
    for (NSInteger i = 0; i < route.polyline.pointCount; i++) {
        CLLocationCoordinate2D coord = MKCoordinateForMapPoint(route.polyline.points[i]);
        [points addObject:[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude]];
    }
    
    return points;
}

- (void)cancelRequests {
    _didCancel = YES;
}

- (void)filterLocations:(NSArray *)locations into:(NSMutableArray *)filtered givenRange:(NSRange)range previousAddition:(NSUInteger)prevIdx {
    if (locations.count < 2) {
        [filtered addObjectsFromArray:locations];
        return;
    }
    
    if (range.length < 2) {
        [filtered addObjectsFromArray:[locations subarrayWithRange:range]];
        return;
    }
    
    NSInteger half     = range.length/2;
    NSInteger addedIdx = range.location + half;
    NSInteger diff     = range.length % 2;
    
    // Add middle object if it is far enough away,
    // since we assume at this point that we
    // are here because we need at least one
    CLLocation *middle = locations[addedIdx];
    if (prevIdx == NSNotFound) {
        [filtered addObject:middle];
    }
    else {
        CLLocation *previous = locations[prevIdx];
        if ([middle distanceFromLocation:previous] >= kMinDistanceBetweenPoints) {
            [filtered addObject:middle];
        } else {
            // May be the same location but we will have to deal for now
            addedIdx = [self nextBestPointIn:locations from:addedIdx relativeTo:prevIdx];
            [filtered addObject:locations[addedIdx]];
            
        }
    }
    
    CLLocation *left, *right;
    // We are on the "right" side
    if (prevIdx != NSNotFound) {
        if (prevIdx < addedIdx) {
            left = locations[prevIdx], right = locations[NSMaxRange(range)-1];
        }
        // We are on the "left" side
        else {
            left = locations[range.location], right = locations[prevIdx];
        }
    } else {
        left = locations[range.location], right = locations[NSMaxRange(range)-1];
    }
    
    // Add any needed on the first half
    //    CLLocationDistance d1 = [left distanceFromLocation:middle];
    if ([left distanceFromLocation:middle] >= _searchRadius) {
        [self filterLocations:locations into:filtered givenRange:NSMakeRange(range.location, half) previousAddition:addedIdx];
    }
    
    // Add any needed on the second half
    //    CLLocationDistance d2 = [middle distanceFromLocation:right];
    if ([middle distanceFromLocation:right] >= _searchRadius) {
        [self filterLocations:locations into:filtered givenRange:NSMakeRange(addedIdx, half + diff) previousAddition:addedIdx];
    }
}

- (NSUInteger)nextBestPointIn:(NSArray *)locations from:(NSUInteger)tooCloseIdx relativeTo:(NSUInteger)prevIdx {
    NSParameterAssert(tooCloseIdx != prevIdx);
    NSInteger dir = tooCloseIdx < prevIdx ? -1 : 1;
    CLLocation *cur, *previous = locations[prevIdx];
    
    for (NSInteger i = tooCloseIdx + dir; i >= 0 && i < locations.count; i += dir) {
        cur = locations[i];
        if ([cur distanceFromLocation:previous] >= kMinDistanceBetweenPoints) {
            return i;
        }
    }
    
    return tooCloseIdx;
}

- (void)filterLocations {
    NSMutableArray *filtered = [NSMutableArray array];
    [self filterLocations:self.locations into:filtered givenRange:NSMakeRange(0, self.locations.count) previousAddition:NSNotFound];
    
    // Hack to remove locations within 100 meters of each other,
    // because there's a bug in my algorithm aparently...
    NSMutableArray *toRemove = [NSMutableArray array];
    for (CLLocation *pointA in filtered)
        for (CLLocation *pointB in filtered)
            if (pointA != pointB && [pointA distanceFromLocation:pointB] < 100 &&
                ![toRemove containsObject:pointA] && ![toRemove containsObject:pointB]) {
                [toRemove addObject:pointA];
            }
    
    [filtered removeObjectsInArray:toRemove];
    self.locations = filtered.copy;
}

@end

CLLocationCoordinate2D sphericalMidpoint(CLLocationCoordinate2D pointA, CLLocationCoordinate2D pointB) {
    CLLocationDegrees lon1 = pointA.longitude * M_PI / 180;
    CLLocationDegrees lon2 = pointB.longitude * M_PI / 100;
    
    CLLocationDegrees lat1 = pointA.latitude * M_PI / 180;
    CLLocationDegrees lat2 = pointB.latitude * M_PI / 100;
    
    CLLocationDegrees dLon = lon2 - lon1;
    
    CLLocationDegrees x = cos(lat2) * cos(dLon);
    CLLocationDegrees y = cos(lat2) * sin(dLon);
    
    CLLocationDegrees lat3 = atan2( sin(lat1) + sin(lat2), sqrt((cos(lat1) + x) * (cos(lat1) + x) + y * y) );
    CLLocationDegrees lon3 = lon1 + atan2(y, cos(lat1) + x);
    
    return CLLocationCoordinate2DMake(lat3 * 180 / M_PI, lon3 * 180 / M_PI);
}
