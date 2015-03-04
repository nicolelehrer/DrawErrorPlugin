//
//  DrawErrorController.m
//  DrawError
//
//  Created by Nicole Lehrer on 1/13/09.
//  Copyright 2009 ASU. All rights reserved.
//

#import "DrawErrorController.h"
#import "DrawError.h"
#import "GNUstep.h"
#import "Log.h"

static DrawErrorController * gDrawErrorWindow = nil;

@implementation DrawErrorController

@synthesize drawError;
@synthesize firstResp;

#pragma mark -
#pragma mark class methods

+ (void) initialize
{
	if ( self == [DrawErrorController class] ) {
		gDrawErrorWindow = nil;
    }
}


+ (DrawErrorController *) windowController
{
	if (gDrawErrorWindow != nil) return gDrawErrorWindow;
	gDrawErrorWindow = [[DrawErrorController alloc] init];
	return gDrawErrorWindow;
}


+ (void) showWindowController:(id)sender
{
	if (gDrawErrorWindow == nil) [DrawErrorController windowController];
    NSScreen * menuScreen = [[NSScreen screens] objectAtIndex:0];
    NSRect screenRect = [menuScreen frame];
    [[gDrawErrorWindow window] setFrameOrigin:screenRect.origin];
	[gDrawErrorWindow showWindow:sender];
}



#pragma mark -
#pragma mark initializer


// designated initializer
- (id) init
{
	if (gDrawErrorWindow) return gDrawErrorWindow;
	
	self = [super initWithWindowNibName:@"DrawError"];
    if (self == nil) {
		logError( @"DrawErrorController super init failed" );
		return nil;
	}
		
	return self;
}



#pragma mark -
#pragma mark instance methods


- (void) awakeFromNib
{
	logDebug( @"awakeFromNib" );
	[[self window] setInitialFirstResponder:firstResp];
	
}


@end
