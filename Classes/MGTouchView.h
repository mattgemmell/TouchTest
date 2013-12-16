//
//  MGTouchView.h
//  TouchTest
//
//  Created by Matt Gemmell on 08/05/2010.
//

#import <UIKit/UIKit.h>


@interface MGTouchView : UIView {
	UIColor *color;
	BOOL showArrows;
}

@property (nonatomic, retain) UIColor *color;
@property (nonatomic, assign) BOOL showArrows;

@end
