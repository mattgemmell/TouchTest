//
//  TouchTestAppDelegate.m
//  TouchTest
//
//  Created by Matt Gemmell on 08/05/2010.
//

#import "TouchTestAppDelegate.h"
#import "TouchTestViewController.h"

@implementation TouchTestAppDelegate

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];

	return YES;
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
