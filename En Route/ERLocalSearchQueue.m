//
//  ERLocalSearchQueue.m
//  En Route
//
//  Created by Tanner on 1/16/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "ERLocalSearchQueue.h"
#import "TBTimer.h"

#define RunBlock(block) if ( block ) block()
#define RunBlockP(block, params) if ( block ) block( params )


@interface ERLocalSearchQueue ()
@property (nonatomic) MKLocalSearchRequest *request;
@property (nonatomic) NSArray *locations;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSInteger secondsLeft;

@property (nonatomic) CGFloat delay;
@property (nonatomic) NSInteger total;

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
        [filteredCoords minusSet:[NSSet setWithArray:[self coordinatesAlongRoute:route]]];
    _locations = filteredCoords.array;
    
    [self filterLocations];
    
    // Calculate delay
    _delay = _locations.count <= 50 ? 0 : 1.2001;
    // Puts a hold on the next set of requests
    if (_locations.count <= 50) {
        _secondsLeft += 60;
    }
    
    // Dispatch so we can safely sleep the thread
    dispatch_async([ERLocalSearchQueue backgroundQueue], ^{
        
        // Needed to wait for old timer to finish and invalidate itself
        if (!self.ready) {
            RunBlockP(_pauseCallback, self.secondsLeft);
            [NSThread sleepForTimeInterval:self.secondsLeft+.01];
            RunBlock(_resumeCallback);
        }
        _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(decTimer) userInfo:nil repeats:YES];
        [_timer fire];
        
        // Make requests in a loop
        __block NSInteger i = _locations.count;
        for (CLLocation *loc in _locations) {
            self.request.region = MKCoordinateRegionMakeWithDistance(loc.coordinate, _searchRadius, _searchRadius);
            
            // Wait if necessary and call back to notify about the wait
            if (!self.ready) {
                RunBlockP(_pauseCallback, self.secondsLeft);
                [NSThread sleepForTimeInterval:self.secondsLeft+.01];
                RunBlock(_resumeCallback);
            }
            
            // Actual request
            [[[MKLocalSearch alloc] initWithRequest:self.request] startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
                if (self.didCancel) return;
                
                RunBlockP(_loopCallback, response.mapItems);
                
                // Counts
                ++_total;
                if (error) {
                    NSLog(@"-------FAIL------- %@", @(_total));
                    [TBTimer lap];
                }
                
                // Last one
                if (--i == 0) { RunBlock(_completion); }
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
    
    newLocs = (id)[newLocs filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<NSString *,id> *bindings) {
        return [newLocs countForObject:evaluatedObject] < 3;
    }]];
    
    self.locations = newLocs.allObjects;
}

@end
