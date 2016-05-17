//
//  ERLocalSearchQueue.m
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERLocalSearchQueue.h"

#define RunBlock(block) if ( block ) block()
#define RunBlockP(block, params) if ( block ) block( params )


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
    
    RunBlockP(_debugCallback, _locations.count);
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

- (void)filterLocations {
    NSCountedSet *newLocs = [NSCountedSet setWithArray:self.locations];
    for (CLLocation *loca in self.locations)
        for (CLLocation *locb in self.locations)
            if ([loca distanceFromLocation:locb] < _searchRadius)
                if (loca != locb)
                    [newLocs addObject:loca];
    
    self.locations = [self optimize:newLocs];
}

- (NSArray *)optimize:(NSCountedSet *)set {
    NSArray *a = [self filteredSetObjectsWithMaxCount:3 set:set];
    NSArray *b = [self filteredSetObjectsWithMaxCount:4 set:set];
    NSArray *c = [self filteredSetObjectsWithMaxCount:5 set:set];
    
    if (a.count > 50) return a;
    if (c.count < 50) return c;
    if (b.count < 50) return b;
    return a;
}

- (NSArray *)filteredSetObjectsWithMaxCount:(NSInteger)count set:(NSCountedSet *)set {
    return [set filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<NSString *,id> *bindings) {
        return [set countForObject:evaluatedObject] < count;
    }]].allObjects;
}

@end
