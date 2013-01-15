//
//  Report.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 14/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "Report.h"
#import "PreyModule.h"
#import "PreyRestHttp.h"
#import "PreyConfig.h"
#import "PicturesController.h"

@implementation Report

@synthesize modules,waitForLocation,waitForPicture,url, picture;

- (id) init {
    self = [super init];
    if (self != nil) {
		waitForLocation = NO;
        waitForPicture = NO;
		reportData = [[NSMutableDictionary alloc] init];
    }
    return self;
}
- (void) sendIfConditionsMatch {
    if (waitForPicture){
        UIImage *lastPicture = [[[PicturesController instance]lastPicture] copy];
        if (lastPicture != nil){
            self.picture = lastPicture;
            waitForPicture = NO;
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"pictureReady" object:nil];
        }
        [lastPicture release];
        waitForPicture = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground ? NO:waitForPicture; //Can't take pictures if in bg.
    }
    if (!waitForPicture && !waitForLocation) {
        @try {
            PreyLogMessageAndFile(@"Report", 5, @"Sending report now!");
            
            PreyRestHttp *userHttp = [[[PreyRestHttp alloc] init] autorelease];
            [userHttp sendReport:self];
            [self performSelectorOnMainThread:@selector(alertReportSent) withObject:nil waitUntilDone:NO];
            self.picture = nil;
        }
        @catch (NSException *exception) {
            PreyLogMessageAndFile(@"Report", 0, @"Report couldn't be sent: %@", [exception reason]);
        }
    }
}
- (void) send {
    PreyLogMessage(@"Report", 5, @"Attempting to send the report.");
	if (waitForLocation) {
		PreyLogMessage(@"Report", 5, @"Have to wait for a location before send the report.");
		[[NSNotificationCenter defaultCenter] addObserver:self
			selector:@selector(locationUpdated:)
			name:@"locationUpdated" object:nil];
	} 
    if (waitForPicture) {
		PreyLogMessage(@"Report", 5, @"Have to wait the picture be taken before send the report.");
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(pictureReady:)
                                                     name:@"pictureReady" object:nil];
	} 
    [self sendIfConditionsMatch];
}


//parameters: {geo[lng]=-122.084095, geo[alt]=0.0, geo[lat]=37.422006, geo[acc]=0.0, api_key=rod8vlf13jco}

- (NSMutableDictionary *) getReportData {
	PreyModule* module;
	for (module in modules){
		if ([module reportData] != nil)
			[reportData addEntriesFromDictionary:[module reportData]];
	}
	return reportData;
}

- (void) fillReportData:(ASIFormDataRequest*) request {
    PreyModule* module;
	for (module in modules){
		if ([module reportData] != nil)
			[reportData addEntriesFromDictionary:[module reportData]];
	}
    
    [reportData enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
		[request addPostValue:(NSString*)object forKey:(NSString *) key];
	}];
    if (picture != nil)
        [request addData:UIImagePNGRepresentation(picture) withFileName:@"picture.png" andContentType:@"image/png" forKey:@"webcam[picture]"];
    picture = nil;
} 

- (void) pictureReady:(NSNotification *)notification {
    self.picture = (UIImage*)[notification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"pictureReady" object:nil];
    waitForPicture = NO;
	[self sendIfConditionsMatch];
    
}

- (void)locationUpdated:(NSNotification *)notification
{
    CLLocation *newLocation = (CLLocation*)[notification object];
	NSMutableDictionary *data = [[[NSMutableDictionary alloc] init] autorelease];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.coordinate.longitude] forKey:[NSString stringWithFormat:@"%@[%@]",@"geo",@"lng"]];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.coordinate.latitude] forKey:[NSString stringWithFormat:@"%@[%@]",@"geo",@"lat"]];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.altitude] forKey:[NSString stringWithFormat:@"%@[%@]",@"geo",@"alt"]];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.horizontalAccuracy] forKey:[NSString stringWithFormat:@"%@[%@]",@"geo",@"acc"]];
	[reportData addEntriesFromDictionary:data];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"locationUpdated" object:nil];
    waitForLocation = NO;
	[self sendIfConditionsMatch];
}

- (void) dealloc {
	[super dealloc];
	[reportData release];
    [modules release];
    [url release];
    [picture release];
}
@end
