//
//  TouchTestAppDelegate.h
//  TouchTest
//
//  Created by Matt Gemmell on 08/05/2010.
//

#import <UIKit/UIKit.h>

@class TouchTestViewController;

@interface TouchTestAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    TouchTestViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet TouchTestViewController *viewController;

@end

