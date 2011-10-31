//
//  RunKeeper.h
//  rrgps-iphone
//
//  Created by Reid van Melle on 11-09-14.
//  Copyright 2011 Brierwood Design Co-operative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXOAuth2.h"

typedef void(^RIBasicCompletionBlock)(void);
typedef void(^RIJSONCompletionBlock)(id json);
typedef void(^RIBasicFailedBlock)(NSError *err);

typedef enum {
    kRKRunning,
    kRKCycling,
    kRKMountainBiking,
    kRKWalking,
    kRKHiking,
    kRKDownhillSkiing,
    kRKXCountrySkiing,
    kRKSnowboarding,
    kRKSkating,
    kRKSwimming,
    kRKWheelchair,
    kRKRowing,
    kRKElliptical,
    kRKOther
} RunKeeperActivityType;

// 


@protocol RunKeeperConnectionDelegate <NSObject>

@optional
// Connected is called when an existing auth token is found
- (void)connected;

// Called when the request to connect to runkeeper failed
- (void)connectionFailed:(NSError*)err;

// Called when authentication is needed to connect to RunKeeper --- normally, the client app will call
// tryToAuthorize at this point
- (void)needsAuthentication;
@end

extern NSString *const kRunKeeperNewPointNotification;

@interface RunKeeper : NSObject <NXOAuth2ClientDelegate> {
    
@private
    NXOAuth2Client *oauthClient; 
    BOOL connected;
    NSDictionary *paths;
    NSNumber *userID;
    NSString *clientID, *clientSecret;
    id <RunKeeperConnectionDelegate> delegate;
}

@property (nonatomic, retain) NSDate *startPointTimestamp;
@property (nonatomic, retain) NSString *clientID, *clientSecret;
@property (nonatomic, retain, readonly) NXOAuth2Client *oauthClient;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, retain) NSDictionary *paths;
@property (nonatomic, retain) NSNumber *userID;
@property (nonatomic, retain) NSMutableArray *currentPath;

/** @name Connection and Authorization */

/** Takes a long URL and returns a shortened version of it.
 
 Takes the long URL specfied in _longURLString_ and returns a shortened version in the block specified in _result_.
 
 In case of an error the block spefied by _error_ is executed with additional information of the cause of the failure.
 
 @param longURLString The long URL string to shorten
 @param result The block to execute upon success. The block should take a single NSString* parameter and have no return value
 @param error The block to execute upon failure. The block should take a single NSError* parameter and have no return value*/

- (id)initWithClientID:(NSString*)clientID clientSecret:(NSString*)secret;
- (void)handleOpenURL:(NSURL *)url;
- (void)tryToConnect:(id <RunKeeperConnectionDelegate>)delegate;
- (void)tryToAuthorize;
- (void)disconnect;

- (void)postActivity:(RunKeeperActivityType)activity start:(NSDate*)start distance:(NSNumber*)distance
                 duration:(NSNumber*)duration calories:(NSNumber*)calories avgHeartRate:(NSNumber*)avgHeartRate
               notes:(NSString*)notes path:(NSArray*)path heartRatePoints:(NSArray*)heartRatePoints
             success:(RIBasicCompletionBlock)success failed:(RIBasicFailedBlock)failed;


//- (void)getProfile:(

@end

extern NSString *const kRunKeeperErrorDomain;
extern NSString *const kRunKeeperStatusTextKey;
