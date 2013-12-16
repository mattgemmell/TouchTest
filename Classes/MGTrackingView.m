//
//  MGTrackingView.m
//  TouchTest
//
//  Created by Matt Gemmell on 08/05/2010.
//

#import "MGTrackingView.h"
#import "MGTouchView.h"
#import <QuartzCore/QuartzCore.h>


#define MG_ANIMATION_APPEAR		@"Appear"
#define MG_ANIMATION_DISAPPEAR	@"Disappear"

#define MG_ANIMATE_ARROWS		YES


@interface MGTrackingView (MGPrivateMethods)

- (void)setup;
- (UIColor *)nextColor;

@end



@implementation MGTrackingView


#pragma mark Setup and teardown


- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
		[self setup];
    }
    return self;
}


- (void)awakeFromNib
{
	[self setup];
}


- (void)setup
{
	// Ensure we receive multiple touch events.
	self.multipleTouchEnabled = YES;
	self.exclusiveTouch = YES; // This helps avoid any orphan touches being left behind during rapid input.
	
	// Array of views to display the touches.
	touchViews = [[NSMutableArray arrayWithCapacity:0] retain];
	
	// Create the colors we'll cycle through for new touch-views.
	colors = [[NSArray arrayWithObjects:
			  [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0],
			  [UIColor orangeColor],
			  [UIColor redColor],
			  [UIColor magentaColor],
			  [UIColor brownColor],
			  [UIColor greenColor],
			  [UIColor blueColor],
			  [UIColor yellowColor],
			  [UIColor purpleColor],
			  [UIColor cyanColor],
			  nil] retain];
	lastColor = [colors count];
	
	// Create map to associate touch-events with views.
	touchMap = CFDictionaryCreateMutable(NULL, // use the default allocator
										 0,		// unlimited size
										 NULL,	// key callbacks - none, just do pointer comparison
										 NULL); // value callbacks - same.
}


- (void)dealloc
{
	[touchViews release];
	touchViews = nil;
	[colors release];
	colors = nil;
	
	CFRelease(touchMap);
	
	[super dealloc];
}


#pragma mark Drawing


- (void)drawRect:(CGRect)rect
{
	// Draw background.
	UIImage *img = [UIImage imageNamed:@"instinctivecode_logo.png"];
	CGSize imgSize = img.size;
	CGSize viewSize = [self bounds].size;
	CGPoint pt = CGPointMake((viewSize.width - imgSize.width) / 2.0, (viewSize.height - imgSize.height) / 2.0);
	[img drawAtPoint:pt blendMode:kCGBlendModeNormal alpha:0.5];
	
	// Draw axial markers.
	float width = 3.0; // width of the axial lines.
	CGPoint center;
	CGRect axis;
	for (MGTouchView *view in touchViews) {
		center = view.center;
		axis = CGRectMake(center.x - (width / 2.0), 0, width, viewSize.height);
		[view.color set];
		UIRectFill(axis);
		axis = CGRectMake(0, center.y - (width / 2.0), viewSize.width, width);
		UIRectFill(axis);
	}
	
	// Draw number of touches.
	[[UIColor whiteColor] set];
	pt = CGPointMake(5, 5); // inset from top-left corner.
	int numViews = [touchViews count];
	NSString *label = [NSString stringWithFormat:@"%d %@", numViews, ((numViews == 1) ? @"touch" : @"touches")]; // grammar is important, kids.
	[label drawAtPoint:pt withFont:[UIFont boldSystemFontOfSize:20.0]];
}


#pragma mark Interaction


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Create new MGTouchView(s) at appropriate coordinates, and begin tracking them.
	for (UITouch *touch in touches) {
		// Create view for this touch.
		float viewWidth = 120.0; // reasonable size so that the outer ring is visible around fingertips.
		MGTouchView *view = [[MGTouchView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, viewWidth)];
		view.center = [touch locationInView:self];
		view.color = [self nextColor];
		[touchViews addObject:view];
		[view release];
		
		// Apply an animation to fade and scale the view onto the screen.
		CALayer *layer = view.layer;
		layer.opacity = 0.0;
		[self addSubview:view];
		layer.transform = CATransform3DMakeScale(0.5, 0.5, 0.5); // "zoom up" by scaling from 50% to 100%.
		[UIView beginAnimations:MG_ANIMATION_APPEAR context:view];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
		[UIView setAnimationDelegate:self];
		layer.opacity = 1.0;
		layer.transform = CATransform3DIdentity; // the Identity transform matrix will return us to 100%, of course.
		[UIView commitAnimations];
		
		// Add view to the map for this touch. Yes, we use the touch event as the key in our dictionary.
		CFDictionarySetValue(touchMap, touch , view);
	}
	
	[self setNeedsDisplay];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Update relevant MGTouchViews and status display.
	for (UITouch *touch in touches) {
		// Obtain view corresponding to this touch event.
		// This works because each event in a chain of corresponding touches is at the same address in memory. Very useful.
		UIView *view = (UIView*)CFDictionaryGetValue(touchMap, touch);
		if (view) {
			// Update center to track the change to the touch.
			view.center = [touch locationInView:self];
		}
	}
	
	[self setNeedsDisplay];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Destroy relevant MGTouchViews.

	for (UITouch *touch in touches) {
		MGTouchView *view = (MGTouchView*)CFDictionaryGetValue(touchMap, touch);
		if (view) {
			// Update center in case it's moved since the last change.
			view.center = [touch locationInView:self];
			
			// Fade out.
			view.showArrows = NO;
			[UIView beginAnimations:MG_ANIMATION_DISAPPEAR context:view];
			[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
			[UIView setAnimationDelegate:self];
			CALayer *layer = view.layer;
			layer.opacity = 0.0;
			layer.transform = CATransform3DMakeScale(0.5, 0.5, 0.5); // Now we zoom down/out by scaling to 50%.
			[UIView commitAnimations];
		
			// Remove view from the map immediately. The animationDidStop:... method will remove the view itself.
			CFDictionaryRemoveValue(touchMap, touch);
		}

	}
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesEnded:touches withEvent:event];
}


- (IBAction)clearAllTouches:(id)sender
{
	NSArray *touchesArray = [(NSMutableDictionary *)touchMap allKeys];
	NSSet *touches = [NSSet setWithArray:touchesArray];
	[self touchesEnded:touches withEvent:nil];
}


#pragma mark Utilities


- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	MGTouchView *view = context;
	if (view && [touchViews containsObject:view]) {
		if ([finished boolValue] && [animationID isEqualToString:MG_ANIMATION_DISAPPEAR]) {
			// This is a fade-out animation, and it just finished. Remove the view.
			[touchViews removeObject:view];
			[view removeFromSuperview];
			
			// Clean up orphans, just in case any are hanging around.
			NSArray *views = [NSArray arrayWithArray:touchViews];
			for (view in views) {
				if (view.layer.opacity == 0.0) {
					[touchViews removeObject:view];
					[view removeFromSuperview];
				}
			}
			
			[self setNeedsDisplay];
			
		} else if ([animationID isEqualToString:MG_ANIMATION_APPEAR] && MG_ANIMATE_ARROWS) {
			// This is a fade-in animation, and we now want to activate the SCI-FI SPINNY ARROWS.
			view.showArrows = YES;
			CAKeyframeAnimation *rotation = [CAKeyframeAnimation animation];
			rotation.repeatCount = 1000; // "1000 full-circle repetitions ought to be enough for anybody."
			rotation.values = [NSArray arrayWithObjects:
							   [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0f, 0.0f, 0.0f, 1.0f)],
							   [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI, 0.0f, 0.0f, 1.0f)],
							   [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI * 2.0, 0.0f, 0.0f, 1.0f)],
							   nil];
			rotation.duration = 1.5; // duration to animate a full revolution of 2*Pi radians.
			[view.layer addAnimation:rotation forKey:@"transform"];
		}
	}
}


- (UIColor *)nextColor
{
	if (lastColor >= [colors count] - 1) {
		lastColor = 0;
	} else {
		lastColor++;
	}
	
	return [colors objectAtIndex:lastColor];
}


@end
