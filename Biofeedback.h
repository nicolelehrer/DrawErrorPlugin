//
//  Biofeedback.h
//  Biofeedback
//
//  Created by Loren Olson on 9/22/08.
//  Copyright 2008 Arizona State University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PluginManager.h"
#import "BFScenario.h"

@class BFAnalysis;
@class LOMarker;
@class Matrix4f;
@class MulticastServer;
@class Notice;
@class BFAbstract;
@class BFCheckAngles;
@class BFTaskControl;
@class DrawError;


enum biofeedbackEnvironmentId {
	kEnvironmentIdPhysicalCupStart = 0,
	kEnvironmentIdIntro = 1,
	kEnvironmentIdAbstract = 2,
	kEnvironmentIdHybrid = 3,
	kEnvironmentIdHybrid2 = 4,
	kEnvironmentIdPhysicalCupEnd = 5,
	kEnvironmentIdDebug = 6
};

enum biofeedbackScenario {
	kBiofeedbackIntro,
	kBiofeedbackAbstract,
	kBiofeedbackAngles,
	kBiofeedbackBlack
};

enum calibrationModeEnum {
	kCalibrateBaseline,
	kCalibrateRestA,
	kCalibrateRestB,
	kCalibrateAAA,
	kCalibrateA1,
	kCalibrateA2,
	kCalibrateA3,
	kCalibrateA4,
	kCalibrateBBB,
	kCalibrateB1,
	kCalibrateB2,
	kCalibrateB3,
	kCalibrateB4,
	kCalibrateAB2,
	kCalibrateAB4
};



@interface Biofeedback : NSObject <DashPluginProtocol> {

	BOOL isLoaded; // if YES, the biofeedback objects have been created
	
	BFAnalysis * analysis;
	BFTaskControl * task;
	BFAbstract * abstract;
	DrawError * drawError;
	BFCheckAngles * checkAngles;
	
	NSMutableDictionary * markers;
    Matrix4f * flipMatrix;
	MulticastServer * feedbackServer;
	
	BOOL sentParameters;
	int	sceneNumber;
	int calibrationMode;
	BOOL showAlternateRange;
	
	NSArray * markerList;
	NSMutableArray * markerComponentList;
	
	Notice * lagNotice;
	Notice * checkNotice;
	Notice * infoNotice;
}

@property(retain) BFAnalysis * analysis;
@property(retain) BFTaskControl * task;
@property(retain) Matrix4f * flipMatrix;
@property(retain) MulticastServer * feedbackServer;
@property(assign) BOOL sentParameters;
@property(assign) int sceneNumber;
@property(assign) int calibrationMode;
@property(assign) BOOL showAlternateRange;
@property(retain) BFAbstract * abstract;
@property(retain) BFCheckAngles * checkAngles;



// class methods
+ (BOOL) initializePlugin:(NSBundle *)bundle;
+ (Biofeedback *) biofeedback;

// instance methods
- (void) updateLagNotice;
- (void) processFrame;
- (void) updateMarkers;
- (void) sendFeedbackParameters:(id<BioVisualArchiver>)sender;
- (void) setupActiveEnvironment;
- (void) showScenario:(int)scenario;
- (void) adjustCameraHeight;



@end
