//
//  DrawError.h
//  DrawError
//
//  Created by Loren Olson on 10/8/07.
//  Copyright 2007 Arizona State University. All rights reserved.
//
//  This class implements a SCREM Render Engine plugin named DrawError.

#import <Cocoa/Cocoa.h>
#import "PluginManager.h"
#import "Transform.h"
#import "Material.h"
#import "Texture2d.h"
#import "TextureController.h"
#import "Shader.h"
#import "TimeController.h"
#import "BFScenario.h"
#import "DAnimateFloat.h"
#import "BFAbstract.h"
#import "BFTaskControl.h"


@class DTime;
@class DAnimateFloat;
@class Texture2d;


@interface DrawError : Transform <DashPluginProtocol> {
	
 	Texture2d *				redTexture;
	Texture2d *             greyTexture;

 	Texture2d *				frameTexture;
	BFAnalysis *			analysis;
	BFAbstract *			abstract;
	BFTaskControl *			task;
	
    NSMutableArray *        spatialErrorValuesCopy;
	DAnimateFloat *			errorIntensityAnimation;

	float		intensityFader;

	BOOL		turnAnalysisOn;
	BOOL		turnGreySpaceOn;

	float		maxHandTrajErrorXE;
	float		maxHandTrajErrorYE;
	float		maxHandTrajErrorXM;
	float		maxHandTrajErrorYM;
	float		maxHandTrajErrorXM2;
	float		maxHandTrajErrorYM2;
	float		maxHandTrajErrorXL;
	float		maxHandTrajErrorYL;	
	
	float		errorMagE;
	float		errorMagM;
	float		errorMagM2;
	float		errorMagL;

	float		S1;
	float		S2;
	float		S3;
	float		S4;
	float		S5;
	
	float		xDiameter;
	float		yDiameter;
	
	int			rad;
	int			radInnerE;
	int			radOuterE;
	int			radInnerM;
	int			radOuterM;
	int			radInnerM2;
	int			radOuterM2;
	int			radInnerL;
	int			radOuterL;
	
 	int			thetaE;
	int			thetaM;
	int			thetaM2;
	int			thetaL;

	int			angleStep;
	
	int			magnitudeMappingType;
	
	int			smallCount;
	int			mediumCount;
	int			largeCount;
	int			continuousFactor;
	
	float		texCountE;
	float		texCountM;
	float		texCountM2;
	float		texCountL;	

	float		intensityE;	
	float		intensityM;	
	float		intensityM2;	
	float		intensityL;	
	
	float		intensityEgrey;	
	float		intensityMgrey;	
	float		intensityM2grey;	
	float		intensityLgrey;	
	
	float		smallErrorUpperBound;
	float		mediumErrorUpperBound;
	float		largeErrorUpperBound;
	
	float		errorThreshold;
	
	float		xDiameterFactorE;
	float		yDiameterFactorE;
	float		xDiameterFactorM;
	float		yDiameterFactorM;
	float		xDiameterFactorM2;
	float		yDiameterFactorM2;
	float		xDiameterFactorL;
	float		yDiameterFactorL;
	
}

@property(assign) float		intensityFader;
@property(assign) float		xDiameterFactorE;
@property(assign) float		yDiameterFactorE;
@property(assign) float		xDiameterFactorM;
@property(assign) float		yDiameterFactorM;
@property(assign) float		xDiameterFactorM2;
@property(assign) float		yDiameterFactorM2;
@property(assign) float		xDiameterFactorL;
@property(assign) float		yDiameterFactorL;


@property(assign) float		errorThreshold;

@property(assign) int		magnitudeMappingType;

@property(assign) float		smallErrorUpperBound;
@property(assign) float		mediumErrorUpperBound;
@property(assign) float		largeErrorUpperBound;

@property(assign) BOOL		turnGreySpaceOn;
@property(assign) BOOL		turnAnalysisOn;

@property(assign) int		rad;
@property(assign) int		radInnerE;
@property(assign) int		radOuterE;
@property(assign) int		radInnerM;
@property(assign) int		radOuterM;
@property(assign) int		radInnerM2;
@property(assign) int		radOuterM2;
@property(assign) int		radInnerL;
@property(assign) int		radOuterL;

@property(assign) float		intensityE;	
@property(assign) float		intensityM;	
@property(assign) float		intensityM2;	
@property(assign) float		intensityL;	

@property(assign) float		intensityEgrey;	
@property(assign) float		intensityMgrey;	
@property(assign) float		intensityM2grey;	
@property(assign) float		intensityLgrey;	

@property(assign) float		xDiameter;
@property(assign) float		yDiameter;

@property(assign) int		thetaE;
@property(assign) int		thetaM;
@property(assign) int		thetaM2;
@property(assign) int		thetaL;

@property(assign) int		angleStep;

@property(assign) float		S1;
@property(assign) float		S2;
@property(assign) float		S3;
@property(assign) float		S4;
@property(assign) float		S5;

@property(assign) float		maxHandTrajErrorXE;
@property(assign) float		maxHandTrajErrorYE;
@property(assign) float		maxHandTrajErrorXM;
@property(assign) float		maxHandTrajErrorYM;
@property(assign) float		maxHandTrajErrorXM2;
@property(assign) float		maxHandTrajErrorYM2;
@property(assign) float		maxHandTrajErrorXL;
@property(assign) float		maxHandTrajErrorYL;

@property(assign) float		errorMagE;
@property(assign) float		errorMagM;
@property(assign) float		errorMagM2;
@property(assign) float		errorMagL;

@property(assign) float		texCountE;
@property(assign) float		texCountM;
@property(assign) float		texCountM2;
@property(assign) float		texCountL;

@property(assign) int		smallCount;
@property(assign) int		mediumCount;
@property(assign) int		largeCount;
@property(assign) int		continuousFactor;
 

// class methods
+ (BOOL) initializePlugin:(NSBundle *)bundle;
+ (IBAction)showError:(id)sender;


@end
