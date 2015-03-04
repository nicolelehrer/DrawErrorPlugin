//
//  DrawErrorController.h
//  DrawError
//
//  Created by Nicole Lehrer on 1/13/09.
//  Copyright 2009 ASU. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DrawError;

@interface DrawErrorController : NSWindowController {
	DrawError * drawError;
	IBOutlet NSTextField * firstResp;	
}

@property(retain) DrawError * drawError;
@property(retain) NSTextField * firstResp;

// class methods
+ (DrawErrorController *) windowController;
+ (void) showWindowController:(id)sender;

// initializers
- (id) init;


@end
