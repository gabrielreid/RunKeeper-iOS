//
//  RunKeeperHeartRatePoint.m
//  AudiblePulseApp
//
//  Created by Gabriel Reid on 31/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RunKeeperHeartRatePoint.h"

@implementation RunKeeperHeartRatePoint

- (id)initWithTimeStamp:(double)timeStamp heartRate:(int)heartRate {
    self = [super init];
    if (self){
        mTimeStamp = timeStamp;
        mHeartRate = heartRate;
    }
    return self;
}

- (id)proxyForJson {
    return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithDouble:mTimeStamp], @"timestamp",
            [NSNumber numberWithInt:mHeartRate], @"heart_rate", nil];
}

@end
