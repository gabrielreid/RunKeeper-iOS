//
//  RunKeeperHeartRatePoint.h
//  AudiblePulseApp
//
//  Created by Gabriel Reid on 31/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RunKeeperHeartRatePoint : NSObject {
@private
    int mHeartRate;
    double mTimeStamp;
}

- (id)initWithTimeStamp:(double)timeStamp heartRate:(int)heartRate;
- (id)proxyForJson;

@end
