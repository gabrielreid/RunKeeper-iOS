//
//  RootViewController.m
//  runkeepersample
//
//  Created by Reid van Melle on 11-09-16.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RootViewController.h"
#import "AppData.h"
#import "RunKeeperPathPoint.h"

@implementation NSString (NSString_TimeInterval)


+ (NSString*)stringWithTimeInterval:(NSTimeInterval)interval tenths:(BOOL)tenths {
	// FIXME support hours as well
	
	if (tenths) {
		int t = interval*10.0;
		return [NSString stringWithFormat:@"%d:%.2d.%.1d", t/600, (t%600)/10, (t%600)%10];
	}
	
	int t = interval;
	return [NSString stringWithFormat:@"%d:%.2d", t/60, t%60];
}



@end


@implementation RootViewController

@synthesize progressLabel, startButton, pauseButton, disconnectButton, connectButton;
@synthesize tickTimer, startTime, endTime, beginTime, locationManager;

- (void)updateViews
{
    RunKeeper *rk = [AppData sharedAppData].runKeeper;
    self.connectButton.enabled = !rk.connected;
    self.disconnectButton.hidden = !rk.connected;
    self.pauseButton.hidden = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    state = kStopped;
    self.title = @"RunKeeper Sample";
    self.progressLabel.text = @"Touch start to begin";
    [self updateViews];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = 0.0;
    [self.locationManager startUpdatingLocation]; 
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        RunKeeper *rk = [AppData sharedAppData].runKeeper;
        [rk postActivity:kRKRunning start:self.beginTime 
                distance:nil
                duration:[NSNumber numberWithFloat:[self.endTime timeIntervalSinceDate:self.startTime] + elapsedTime]
                calories:nil 
               heartRate:nil 
                   notes:@"What a great workout!" 
                    path:rk.currentPath
                 success:^{
                     UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Success" 
                                                                      message:@"Your activity was posted to your RunKeeper account."
                                                                     delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
                     [alert show];
                     
                 }
                  failed:^(NSError *err){
                      NSString *msg = [NSString stringWithFormat:@"Upload to RunKeeper failed: %@", [err localizedDescription]]; 
                      UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Failed" 
                                                                       message:msg
                                                                      delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
                      [alert show];
                  }];
    }
}

- (IBAction)toggleStart
{
    if (state == kStopped) {
        state = kRunning;
        elapsedTime = 0;
        self.startTime = [NSDate date];
        self.beginTime = self.startTime;
        [self.startButton setTitle:@"STOP" forState:UIControlStateNormal];
        self.pauseButton.hidden = NO;
        RunKeeperPathPoint *point = [[[RunKeeperPathPoint alloc] initWithLocation:self.locationManager.location ofType:kRKStartPoint] autorelease];
        [[NSNotificationCenter defaultCenter] postNotificationName:kRunKeeperNewPointNotification object:point];
        self.tickTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(tick) userInfo:nil	repeats:YES];
    } else if ((state == kRunning) || (state == kPaused)) {
        state = kStopped;
        [self.startButton setTitle:@"START" forState:UIControlStateNormal];
        self.pauseButton.hidden = YES;
        [tickTimer invalidate];
        self.tickTimer = nil;
        self.endTime = [NSDate date];
        elapsedTime += [self.endTime timeIntervalSinceDate:self.startTime];
        RunKeeperPathPoint *point = [[[RunKeeperPathPoint alloc] initWithLocation:self.locationManager.location ofType:kRKEndPoint] autorelease];
        [[NSNotificationCenter defaultCenter] postNotificationName:kRunKeeperNewPointNotification  object:point];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Upload?" 
                                                         message:@"Would you like to upload your activity to RunKeeper?"
                                                        delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"OK", nil] autorelease];
        [alert show];
        self.progressLabel.text = @"Touch start to begin";
        
    }
}

- (IBAction)togglePause
{
    if (state == kRunning) {
        state = kPaused;
        [self.pauseButton setTitle:@"RESUME" forState:UIControlStateNormal];
        elapsedTime += [[NSDate date] timeIntervalSinceDate:self.startTime];
        [tickTimer invalidate];
        self.tickTimer = nil;
        RunKeeperPathPoint *point = [[[RunKeeperPathPoint alloc] initWithLocation:locationManager.location ofType:kRKPausePoint] autorelease];
        [[NSNotificationCenter defaultCenter] postNotificationName:kRunKeeperNewPointNotification 
                                                            object:point];
    } else if (state == kPaused) {
        state = kRunning;
        [self.pauseButton setTitle:@"PAUSE" forState:UIControlStateNormal];
        self.startTime = [NSDate date];
        self.tickTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(tick) userInfo:nil	repeats:YES];
        RunKeeperPathPoint *point = [[[RunKeeperPathPoint alloc] initWithLocation:locationManager.location ofType:kRKResumePoint] autorelease];
        [[NSNotificationCenter defaultCenter] postNotificationName:kRunKeeperNewPointNotification 
                                                            object:point];
    }
}

- (IBAction)connectToRunKeeper
{
    [[AppData sharedAppData].runKeeper tryToConnect:self];
}

- (IBAction)disconnect
{
    [[AppData sharedAppData].runKeeper disconnect];
    [self updateViews];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Disconnect" 
                                                     message:@"Running Intensity is no longer linked to your RunKeeper account"
                                                    delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];
}

- (void)tick {
	self.progressLabel.text = [NSString stringWithTimeInterval:[[NSDate date] timeIntervalSinceDate:self.startTime] + elapsedTime tenths:NO];
}

#pragma mark CLLocationDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation 
{
    //NSLog(@"didUpdateLocation: %@", newLocation);
    if ((state == kRunning) || (state == kPaused)) {
        RunKeeperPathPoint *point = [[[RunKeeperPathPoint alloc] initWithLocation:newLocation ofType:kRKGPSPoint] autorelease];
        [[NSNotificationCenter defaultCenter] postNotificationName:kRunKeeperNewPointNotification object:point];
    }
    
}

#pragma mark RunKeeperConnectionDelegate

// Connected is called when an existing auth token is found
- (void)connected
{
    [self updateViews];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Connected" 
                                                     message:@"Running Intensity is linked to your RunKeeper account"
                                                    delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];
    
}

// Called when the request to connect to runkeeper failed
- (void)connectionFailed:(NSError*)err
{
    [self updateViews];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Connection Failed" 
                                                     message:@"The link to your RunKeeper account failed."
                                                    delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];
}

// Called when authentication is needed to connect to RunKeeper --- normally, the client app will call
// tryToAuthorize at this point
- (void)needsAuthentication
{
    [[AppData sharedAppData].runKeeper tryToAuthorize];
}


/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.progressLabel = nil;
    self.startButton = nil;
    self.disconnectButton = nil;
    self.pauseButton = nil;
    self.connectButton = nil;

    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void)dealloc
{
    [super dealloc];
    [self.progressLabel release];
    [self.startButton release];
    [self.pauseButton release];
    [self.disconnectButton release];
    [self.connectButton release];
    [tickTimer invalidate];
	[tickTimer release];
    if (locationManager) {
        [locationManager stopUpdatingLocation];
        [locationManager release];
    }
}

@end
