//
//  DrawError.m
//  DrawError
//
//  Created by Loren Olson on 10/8/07.
//  Copyright 2007 Arizona State University. All rights reserved.
//
//  This class implements plugin named DrawError.

#import "Dash.h"
#import "DAnimation.h"
#import "Log.h"
#import "GraphicsState.h"
#import "glShapes.h"
#import "Screm.h"
#import "MaterialController.h"
#import "TextureController.h"
#import "opengl_defs.h"

#import "DrawError.h"
#import "DrawErrorController.h"

#import "BFAnalysis.h"
#import "BFTaskControl.h"
#import "Biofeedback.h"
#import "BFImageModel.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <OpenGL/glext.h>
#import <math.h>


@interface DrawError(private)

+(void) createMenu;
+(IBAction) showError:(id)sender;

-(void) getMaxAnalysisValues;
-(void) calcMagnitudeSML;
-(void) calcMagnitudeContinous;
-(void) clearError;
-(void) drawErrorSummary;
-(void) drawGreyErrorSpace;
-(void) calcErrorValues;

@end

@implementation DrawError

#pragma mark ---- class methods ----

+ (BOOL) initializePlugin:(NSBundle *)bundle
{
	logInfo( @"initializePlugin DrawError" );
	[DrawError createMenu];   // in Biofeedback plugin
	return YES;
}


+(IBAction)showError:(id)sender
{
//	[[DrawError alloc] initWithName: @"DrawError" parent:[Dash root]];	// in Biofeedback plugin
	[DrawErrorController showWindowController:self];
} 


+ (void) createMenu 
{
	
	NSMenu * errorMenu = [[NSMenu alloc] initWithTitle:@"drawError"];
	[errorMenu setAutoenablesItems:YES];
	
	NSMenuItem * item = [[NSMenuItem alloc] initWithTitle:@"Show Error" action:@selector(showError:) keyEquivalent:@""];
	[item setTarget:self];
	[errorMenu addItem:item];
	[item release];
		
	item = [[NSMenuItem alloc] initWithTitle:@"drawError" action:NULL keyEquivalent:@""];
	[item setSubmenu:errorMenu];
	NSMenu * mainMenu = [[NSApplication sharedApplication] mainMenu];
	int n = [mainMenu numberOfItems];
	[mainMenu insertItem:item atIndex:n-2];
		
}


#pragma mark ---- initializers  ----

- (void) createDrawErrorWindow {
	[[DrawErrorController windowController] setDrawError:self]; // in Biofeedback plugin
}


- (id) initWithName:(NSString *)aName parent:(Node *)aParent {
	
    if (![super initWithName:aName parent:aParent]) {
        logError( @"DrawError, super init failed!" );
        return nil;
    }
	
	abstract = [[[Biofeedback alloc] init] abstract];
	analysis = [[[Biofeedback alloc] init] analysis];
	task = [[[Biofeedback alloc] init] task];

	
	frameTexture = [[TextureController textureController] createTexture2dWithImage:@"biofeedback/abstract/frame.png" target:GL_TEXTURE_RECTANGLE_ARB];	
	redTexture = [[TextureController textureController] createTexture2dWithImage:@"biofeedback/abstract/error/TestStripes.png" target:GL_TEXTURE_RECTANGLE_ARB];
	greyTexture = [[TextureController textureController] createTexture2dWithImage:@"biofeedback/abstract/error/TestStripesGrey.png" target:GL_TEXTURE_RECTANGLE_ARB];
		
    spatialErrorValuesCopy = [[NSMutableArray alloc] init];
	intensityFader = 1.0;
	errorIntensityAnimation = [[DAnimateFloat alloc] initWithObject:self path:@"intensityFader" from:0.0 to:1.0 duration:1.0];

//	[self createDrawErrorWindow];
	
	//segments error along percentagePrimeZ
	self.S1 = 0;
	self.S2 = .25;
	self.S3 = .5;
	self.S4 = .75;
	self.S5 = 1;
	
	self.intensityE = 1;
	self.intensityM = .8;
	self.intensityM2 = .6;
	self.intensityL = .6;
	
	self.intensityEgrey = 0.2423313;
	self.intensityMgrey = 0.1809816;
	self.intensityM2grey = 0.1380368;
	self.intensityLgrey = 0.107362;
	
	self.xDiameter = 7;
	self.yDiameter = 4;

	self.radInnerE = 590;
	self.radOuterE = 580;
	self.radInnerM = 630;
	self.radOuterM = 450;
	self.radInnerM2 = 477;
	self.radOuterM2 = 342;
	self.radInnerL = 366;
	self.radOuterL = 258;
	
	// for inside diameter "persp" appearance 
	self.xDiameterFactorE = 2.944785;
	self.yDiameterFactorE = 3.067485;
	self.xDiameterFactorM = 2.08589;
	self.yDiameterFactorM = 2.208589;
	self.xDiameterFactorM2 = 2.08589;
	self.yDiameterFactorM2 = 2.208589;
	self.xDiameterFactorL = 1.840491;
	self.yDiameterFactorL = 2.08589;
	
	// for calcMagnitudeSML 
	// errorThreshold is min amount of error magnitude for calcMagnitudeContinous as well
	self.smallCount = 12;
	self.mediumCount = 24;
	self.largeCount = 48;
	self.errorThreshold = 0.1; 
	self.smallErrorUpperBound =	0.471;
	self.mediumErrorUpperBound = 0.943;
	self.largeErrorUpperBound = 1.414;
	
	self.magnitudeMappingType = 1;
	
	// number of bars drawn per amount of error 
	self.continuousFactor = 60;
	
	// how big the red bars look 
	self.angleStep = 6;
	
    return self;
	
}



#pragma mark ---- instance methods  ----

-(void) calcMagnitudeSML	//calcs error in steps of only small, medium, large; steps must be even
{
	if ((int)smallCount % 2 != 0) {
		self.smallCount = (int)smallCount + 1; 
	}
	
	if ((int)mediumCount % 2 != 0) {
		self.mediumCount = (int)mediumCount + 1; 
	}
	
	if ((int)largeCount % 2 != 0) {
		self.largeCount = (int)largeCount + 1; 
	}
	
	if (errorMagE > errorThreshold && errorMagE <= smallErrorUpperBound) {self.texCountE = smallCount;}
	if (errorMagE > smallErrorUpperBound && errorMagE <= mediumErrorUpperBound) {self.texCountE = self.mediumCount;}
	if (errorMagE > mediumErrorUpperBound && errorMagE <= largeErrorUpperBound) {self.texCountE =  self.largeCount;}
	
	if (errorMagM > errorThreshold && errorMagM <= smallErrorUpperBound) {self.texCountM =  self.smallCount;}
	if (errorMagM > smallErrorUpperBound && errorMagM <= mediumErrorUpperBound) {self.texCountM =  self.mediumCount;}
	if (errorMagM > mediumErrorUpperBound && errorMagM <= largeErrorUpperBound) {self.texCountM =  self.largeCount;}		
	
	if (errorMagM2 > errorThreshold && errorMagM2 <= smallErrorUpperBound) {self.texCountM2 = self. smallCount;}
	if (errorMagM2 > smallErrorUpperBound && errorMagM2 <= mediumErrorUpperBound) {self.texCountM2 =  self.mediumCount;}
	if (errorMagM2 > mediumErrorUpperBound && errorMagM2 <= largeErrorUpperBound) {self.texCountM2 =  self.largeCount;}
	
	if (errorMagL > errorThreshold && errorMagL <= smallErrorUpperBound) {self.texCountL =  self.smallCount;}
	if (errorMagL > smallErrorUpperBound && errorMagL <= mediumErrorUpperBound) {self.texCountL =  self.mediumCount;}
	if (errorMagL > mediumErrorUpperBound && errorMagL <= largeErrorUpperBound) {self.texCountL =  self.largeCount;}	
}

- (void) calcMagnitudeContinous	  //calcs error in steps determined by error*continousFactor; steps must be even
{
	if (errorMagE > errorThreshold) {
		if ((int)(errorMagE*continuousFactor) % 2 == 0) {
			self.texCountE = (int)(errorMagE*continuousFactor); 
		} 		
		else { 
			self.texCountE = (int)(errorMagE*continuousFactor) + 1; 
		}
	} 
	else { 
		self.texCountE = 0;
	}
		
	if (errorMagM > errorThreshold) 
	{
		if ((int)(errorMagM*continuousFactor) % 2 == 0) {	
			self.texCountM = (int)(errorMagM*continuousFactor);
		} 
		else { 
			self.texCountM = (int)(errorMagM*continuousFactor) + 1; 
		}
	} 
	else {
		self.texCountM = 0;
	}

		
	if (errorMagM2 > errorThreshold) {
		if ((int)(errorMagM2*continuousFactor) % 2 == 0) {	
			self.texCountM2 = (int)(errorMagM2*continuousFactor);
		} 
		else { 
			self.texCountM2 = (int)(errorMagM2*continuousFactor) + 1; 
		}
	} 
	else {
		self.texCountM2 = 0;
	}
	
	
	if (errorMagL > errorThreshold) {
		if ((int)(errorMagL*continuousFactor) % 2 == 0) {	
			self.texCountL = (int)(errorMagL*continuousFactor);
		} 
		else { 
			self.texCountL = (int)(errorMagL*continuousFactor) + 1; 
		}
	} 
	else {
		self.texCountL = 0; 
	}
	
}
	


-(void)getMaxAnalysisValues //takes 4 maximum values of x and y end point error along zprime specified by S1, S2, S3, S4, S5
{
	float maximumXE = 0.0;
	float maximumYE = 0.0;
	float maximumXM = 0.0;
	float maximumYM = 0.0;
	float maximumXM2 = 0.0;
	float maximumYM2 = 0.0;
	float maximumXL = 0.0;
	float maximumYL = 0.0;
	
	int countTotal = [spatialErrorValuesCopy count];
	
	int i;
	for (i = 0; i < countTotal; i = i+3) {
        
		NSNumber * xValue = [spatialErrorValuesCopy objectAtIndex:i+1];
		NSNumber * yValue = [spatialErrorValuesCopy objectAtIndex:i+2];
				
		if	(([[spatialErrorValuesCopy objectAtIndex:i] floatValue] > S1) && ([[spatialErrorValuesCopy objectAtIndex:i] floatValue] <= S2)) {
			if( fabs([xValue floatValue]) > fabs(maximumXE)) {
				maximumXE = [xValue floatValue];
			}
			if( fabs([yValue floatValue]) > fabs(maximumYE)) {
				maximumYE = [yValue floatValue];
			}
		}	
		
		if(([[spatialErrorValuesCopy objectAtIndex:i] floatValue] > S2) && ([[spatialErrorValuesCopy objectAtIndex:i] floatValue] <= S3)) {
			if( fabs([xValue floatValue]) > fabs(maximumXM)) {
				maximumXM = [xValue floatValue];
			}
			if( fabs([yValue floatValue]) > fabs(maximumYM)) {
				maximumYM = [yValue floatValue];
			}
		}	
		
		if(([[spatialErrorValuesCopy objectAtIndex:i] floatValue] > S3) && ([[spatialErrorValuesCopy objectAtIndex:i] floatValue] <= S4)) {
			if( fabs([xValue floatValue]) > fabs(maximumXM2)) {
				maximumXM2 = [xValue floatValue];}
			if( fabs([yValue floatValue]) > fabs(maximumYM2)) {
				maximumYM2 = [yValue floatValue];
			}
		}	
		
		if(([[spatialErrorValuesCopy objectAtIndex:i] floatValue] > S4) && ([[spatialErrorValuesCopy objectAtIndex:i] floatValue] <= S5)) {
			if( fabs([xValue floatValue]) > fabs(maximumXM)) {	
				maximumXL = [xValue floatValue];
			}
			if( fabs([yValue floatValue]) > fabs(maximumYM)) {	
				maximumYL = [yValue floatValue];
			}
		}	
	}		
	
    
	//if (turnAnalysisOn) {
    if (1) {
		self.maxHandTrajErrorXE = maximumXE;
		self.maxHandTrajErrorYE = maximumYE;
		self.maxHandTrajErrorXM = maximumXM;
		self.maxHandTrajErrorYM = maximumYM;
		self.maxHandTrajErrorXM2 = maximumXM2;
		self.maxHandTrajErrorYM2 = maximumYM2;
		self.maxHandTrajErrorXL = maximumXL;
		self.maxHandTrajErrorYL = maximumYL;
 	}
    

//	logInfo( @" Error MAG E is %f", errorMagE);
//	logInfo( @" Error MAG M is %f", errorMagM);  
//	logInfo( @" Error MAG M2 is %f", errorMagM2);
//	logInfo( @" Error MAG L is %f", errorMagL);
	

}



-(void) calcErrorValues

{	
	if (analysis.status == kStatusGrasping && abstract.statusChanged) {
		[errorIntensityAnimation resetFrom:self.intensityFader to:1.0 duration:.5];
		//[DAnimation animate:errorIntensityAnimation withDelay:0.25];
        [DAnimation animate:errorIntensityAnimation];
	}
	else if (analysis.status == kStatusStop && abstract.statusChanged) {
		[errorIntensityAnimation resetFrom:self.intensityFader to:0.0 duration:1.0];
		[DAnimation animate:errorIntensityAnimation];
	}
	
 	[self getMaxAnalysisValues];
	
	//calcs the composite error magnitude from the x and y error values 
	self.errorMagE = sqrt(maxHandTrajErrorXE*maxHandTrajErrorXE + maxHandTrajErrorYE*maxHandTrajErrorYE); 	
	self.errorMagM = sqrt(maxHandTrajErrorXM*maxHandTrajErrorXM + maxHandTrajErrorYM*maxHandTrajErrorYM); 	
	self.errorMagM2 = sqrt(maxHandTrajErrorXM2*maxHandTrajErrorXM2 + maxHandTrajErrorYM2*maxHandTrajErrorYM2); 	
	self.errorMagL = sqrt(maxHandTrajErrorXL*maxHandTrajErrorXL + maxHandTrajErrorYL*maxHandTrajErrorYL); 	
	
	//calcs the position at which error was made from the x and y error values 
	if (maxHandTrajErrorXE == 0) {	
		if (maxHandTrajErrorYE > 0) {
			self.thetaE = 90; 
		}
		if (maxHandTrajErrorYE < 0) {
			self.thetaE = 270; 
		} 
	}
	
	if (maxHandTrajErrorXE != 0) {	
		self.thetaE = (int)(atan2 (maxHandTrajErrorYE,maxHandTrajErrorXE) * 180 / 3.14); 
	}			
	
	
	
	if (maxHandTrajErrorXM == 0) {	
		if (maxHandTrajErrorYM > 0) {
			self.thetaM = 90; 
		}
		if (maxHandTrajErrorYM < 0) {
			self.thetaM = 270; 
		} 
	}
	
	if (maxHandTrajErrorXM != 0) {	
		self.thetaM =  (int)(atan2 (maxHandTrajErrorYM,maxHandTrajErrorXM) * 180 / 3.14); 
	}			
	
	
	
	if (maxHandTrajErrorXM2 == 0) {	
		if (maxHandTrajErrorYM2 > 0) {
			self.thetaM2 = 90; 
		}
		if (maxHandTrajErrorYM2 < 0) {
			self.thetaM2 = 270; 
		} 
	}
	
	if (maxHandTrajErrorXM2 != 0) {
		self.thetaM2 = (int)(atan2 (maxHandTrajErrorYM2,maxHandTrajErrorXM2) * 180 / 3.14); 
	}			
	
	
	
	if (maxHandTrajErrorXL == 0) {
		if (maxHandTrajErrorYL > 0) {
			self.thetaL = 90; 
		}
		if (maxHandTrajErrorYL < 0) {
			self.thetaL = 270; 
		} 
	}
	
	if (maxHandTrajErrorXL != 0) {
		self.thetaL = (int)(atan2 (maxHandTrajErrorYL,maxHandTrajErrorXL) * 180 / 3.14); 
	}			
	
	
/*	if (errorMagE > 0 && errorMagE <= 0.471) {self.texCountE = smallCount;}
	if (errorMagE > .471 && errorMagE <= 0.943) {self.texCountE = mediumCount;}
	if (errorMagE > 0.943 && errorMagE <= 1.414) {self.texCountE = largeCount;}
	
	if (errorMagM > 0 && errorMagM <= 0.471) {self.texCountM = smallCount;}
	if (errorMagM > .471 && errorMagM <= 0.943) {self.texCountM = mediumCount;}
	if (errorMagM > 0.943 && errorMagM <= 1.414) {self.texCountM = largeCount;}		
	
	if (errorMagM2 > 0 && errorMagM2 <= 0.471) {self.texCountM2 = smallCount;}
	if (errorMagM2 > .471 && errorMagM2 <= 0.943) {self.texCountM2 = mediumCount;}
	if (errorMagM2 > 0.943 && errorMagM2 <= 1.414) {self.texCountM2 = largeCount;}
	
	if (errorMagL > 0 && errorMagL <= 0.471) {self.texCountL = smallCount;}
	if (errorMagL > .471 && errorMagL <= 0.943) {self.texCountL = mediumCount;}
	if (errorMagL > 0.943 && errorMagL <= 1.414) {self.texCountL = largeCount;}	*/
	
	
}				
	
	
-(void) clearError
{			
	self.maxHandTrajErrorXE = 0;
	self.maxHandTrajErrorYE = 0;
	self.maxHandTrajErrorXM = 0;
	self.maxHandTrajErrorYM = 0;
	self.maxHandTrajErrorXM2 = 0;
	self.maxHandTrajErrorYM2 = 0;
	self.maxHandTrajErrorXL = 0;
	self.maxHandTrajErrorYL = 0;
	
	self.errorMagE = 0;
	self.errorMagL = 0;
	self.errorMagM = 0;
	self.errorMagM2 = 0; 	
}



-(void) drawGreyErrorSpace
{   
		
	int angle = 0;
	int xc = 10;
	int yc = 10;
	int z = 10;
	
	int shift;	
	
	glEnable(GL_TEXTURE_RECTANGLE_ARB );
	glTranslated(0, 0, 0);

//EARLY 
	 
	glPushMatrix();
	glRotatef( 90, 1, 0, 0 );

	glColor4f( 1, 1, 1, intensityEgrey * intensityFader);
	
	[self calcMagnitudeContinous];
	[greyTexture bindTexture];	
	
	glBegin(GL_QUADS);
	
	for (shift = 0; shift < 180-texCountE; shift=shift+angleStep) {		
		
		for ( angle=(shift-thetaE+texCountE/2); angle<(2*angleStep+shift-thetaE+texCountE/2); angle=angle+angleStep) {
			rad = radInnerE;
			float angle_radians = angle * (float)3.14159 / (float)180;
			float x = xc + rad * (float)xDiameterFactorE*7/4*cos(angle_radians);
			float y = yc + rad * (float)yDiameterFactorE*sin(angle_radians);
			
			if (angle == (shift-thetaE+texCountE/2)) { 
				glTexCoord2f(0, 0);
			}
			if (angle == (angleStep+shift-thetaE+texCountE/2)) { 
				glTexCoord2f(1, 0);
			}
			
			glVertex3f(x,z,y);		
		}
		
		for ( angle=(angleStep+shift-thetaE+texCountE/2); angle>(-angleStep+shift-thetaE+texCountE/2); angle=angle-angleStep) {
			rad = radOuterE;
			float angle_radians = angle * (float)3.14159 / (float)180;	
			float x = xc + rad * (float)xDiameter*cos(angle_radians);
			float y = yc + rad * (float)yDiameter*sin(angle_radians);
			
			if (angle == (shift-thetaE+texCountE/2)) { 
				glTexCoord2f(0,1);
			}
			if (angle == (angleStep+shift-thetaE+texCountE/2)) { 
				glTexCoord2f(1, 1);
			}
			
			glVertex3f(x,z,y);
		}
	}	
	
	
//MIDDLE 1
	
	glColor4f( 1, 1, 1, intensityMgrey * intensityFader );	

	for (shift = 0; shift < 180-texCountM; shift=shift+angleStep) {
		
		for ( angle=(shift-thetaM+texCountM/2); angle<(2*angleStep+shift-thetaM+texCountM/2); angle=angle+angleStep) {
			rad = radInnerM;
			float angle_radians = angle * (float)3.14159 / (float)180;
			float x = xc + rad * (float)xDiameterFactorM*7/4*cos(angle_radians);
			float y = yc + rad * (float)yDiameterFactorM*sin(angle_radians);
			
			if (angle == (shift-thetaM+texCountM/2)) { 
				glTexCoord2f(0, 0);
			}
			if (angle == (angleStep+shift-thetaM+texCountM/2)) { 
				glTexCoord2f(1, 0);
			}
			
			glVertex3f(x,z,y);		
		}
			
		for ( angle=(angleStep+shift-thetaM+texCountM/2); angle>(-angleStep+shift-thetaM+texCountM/2); angle=angle-angleStep) {
			rad = radOuterM;
			float angle_radians;
			
			angle_radians = angle * (float)3.14159 / (float)180;	
			float x = xc + rad * (float)xDiameter*cos(angle_radians);
			float y = yc + rad * (float)yDiameter*sin(angle_radians);
			
			if (angle == (shift-thetaM+texCountM/2)) { 
				glTexCoord2f(0,1);
			}
			if (angle == (angleStep+shift-thetaM+texCountM/2)) { 
				glTexCoord2f(1, 1);
			}
			
			glVertex3f(x,z,y);
		}
	}	
		
	
//MIDDLE 2
	glColor4f( 1, 1, 1, intensityM2grey * intensityFader);
	
	for (shift = 0; shift < 180 - texCountM2; shift=shift+angleStep) {	
	
		for ( angle=(shift-thetaM2+texCountM2/2); angle<(2*angleStep+shift-thetaM2+texCountM2/2); angle=angle+angleStep) {
			rad = radInnerM2;
			float angle_radians = angle * (float)3.14159 / (float)180;
			float x = xc + rad * (float)xDiameterFactorM2*7/4*cos(angle_radians);
			float y = yc + rad * (float)yDiameterFactorM2*sin(angle_radians);
			
			if (angle == (shift-thetaM2+texCountM2/2)) { 
				glTexCoord2f(0, 0);	
			}
			if (angle == (angleStep+shift-thetaM2+texCountM2/2)) { 
				glTexCoord2f(1, 0);	
			}
			
			glVertex3f(x,z,y);		
		}
		
		for ( angle=(angleStep+shift-thetaM2+texCountM2/2); angle>(-angleStep+shift-thetaM2+texCountM2/2); angle=angle-angleStep) {
			rad = radOuterM2;
			float angle_radians = angle * (float)3.14159 / (float)180;
			float x = xc + rad * (float)xDiameter*cos(angle_radians);
			float y = yc + rad * (float)yDiameter*sin(angle_radians);
			
			if (angle == (shift-thetaM2+texCountM2/2)){ 
				glTexCoord2f(0,1);
			}
			if (angle == (angleStep+shift-thetaM2+texCountM2/2)){ 
				glTexCoord2f(1, 1);
			}
			
			glVertex3f(x,z,y);
		}
	}
	

	
//LATE	

	glColor4f( 1, 1, 1, intensityLgrey * intensityFader );
	
	for (shift = 0; shift < 180 - texCountL; shift=shift+angleStep) {
	
		for ( angle=(shift-thetaL+texCountL/2); angle<(2*angleStep+shift-thetaL+texCountL/2); angle=angle+angleStep) {
			rad = radInnerL;
			float angle_radians = angle * (float)3.14159 / (float)180;
			float x = xc + rad * (float)xDiameterFactorL*7/4*cos(angle_radians);
			float y = yc + rad * (float)yDiameterFactorL*sin(angle_radians);
			
			if (angle == (shift-thetaL+texCountL/2)) { 
				glTexCoord2f(0, 0); 
			}
			if (angle == (angleStep+shift-thetaL+texCountL/2)) { 
				glTexCoord2f(1, 0); 
			}
			
			glVertex3f(x,z,y);		
		}
		
		
		for ( angle=(angleStep+shift-thetaL+texCountL/2); angle>(-angleStep+shift-thetaL+texCountL/2); angle=angle-angleStep) {	
			rad = radOuterL;
			float angle_radians = angle * (float)3.14159 / (float)180;
			float x = xc + rad * (float)xDiameter*cos(angle_radians);
			float y = yc + rad * (float)yDiameter*sin(angle_radians);
			
			if (angle == (shift-thetaL+texCountL/2)) { 
				glTexCoord2f(0,1);
			}
			if (angle == (angleStep + shift-thetaL+texCountL/2)) { 
				glTexCoord2f(1, 1);
			}
			
			glVertex3f(x,z,y);
		}
	}

	glEnd();
	glPopMatrix();	
	glDisable(GL_TEXTURE_RECTANGLE_ARB);
	
}




-(void) drawErrorSummary
{   	
	int angle=0;
	int xc = 10;
	int yc = 10;
	int z = 10;
	
	int shift;	
	
	glEnable(GL_TEXTURE_RECTANGLE_ARB );
	glTranslated(0, 0, 0);

	glPushMatrix();
	glRotatef( 90, 1, 0, 0 );
	glColor4f( 1, 1, 1, intensityE * intensityFader );
	
	[redTexture bindTexture];	

	if (magnitudeMappingType == 0) { 
		[self calcMagnitudeSML]; 
	} 
	if (magnitudeMappingType == 1) { 
		[self calcMagnitudeContinous];
	}
	
	
//EARLY
	glBegin(GL_QUADS);
	
	
	for (shift = 0; shift < texCountE; shift=shift+angleStep)
	{	
		//for flaring or edges
		//		if (angle == (shift-thetaE)) {
		//			angle_radians = (angle-perspFactor) * (float)3.14159 / (float)180; }else{
		//			angle_radians = angle * (float)3.14159 / (float)180;}
		
		//only goes thru loop 2x per quad, and places 2 points in clockwise order
		for ( angle=(shift-thetaE-texCountE/2); angle<(2*angleStep+shift-thetaE-texCountE/2); angle=angle+angleStep) {
			rad = radInnerE;
			float angle_radians = angle * (float)3.14159 / (float)180;
			float x = xc + rad * (float)xDiameterFactorE*7/4*cos(angle_radians);
			float y = yc + rad * (float)yDiameterFactorE*sin(angle_radians);
				
			if (angle == (shift-thetaE-texCountE/2)) { 
				glTexCoord2f(0, 0); 
			}
			if (angle == (angleStep+shift-thetaE-texCountE/2)) { 
				glTexCoord2f(1, 0); 
			}
				glVertex3f(x,z,y);		
			}
			
		
		for ( angle=(angleStep+shift-thetaE-texCountE/2); angle>(-angleStep+shift-thetaE-texCountE/2); angle=angle-angleStep) {	
			rad = radOuterE;
			float angle_radians = angle * (float)3.14159 / (float)180;
			float x = xc + rad * (float)xDiameter*cos(angle_radians);
			float y = yc + rad * (float)yDiameter*sin(angle_radians);
				
			if (angle == (shift-thetaE-texCountE/2)) { 
				glTexCoord2f(0,1);
			}
			if (angle == (angleStep + shift-thetaE-texCountE/2)) { 
				glTexCoord2f(1, 1);
			}				
			glVertex3f(x,z,y);
		}
	
	}
		
	
//MIDDLE 1
	glColor4f( 1, 1, 1, intensityM * intensityFader );
	
	for (shift = 0; shift < texCountM; shift=shift+angleStep) {
	
		for ( angle=(shift-thetaM-texCountM/2); angle<(2*angleStep+shift-thetaM-texCountM/2); angle=angle+angleStep) {
			rad = radInnerM;
			float angle_radians = angle * (float)3.14159 / (float)180;
			float x = xc + rad * (float)xDiameterFactorM*7/4*cos(angle_radians);
			float y = yc + rad * (float)yDiameterFactorM*sin(angle_radians);
		
			if (angle == (shift-thetaM-texCountM/2)) { 
				glTexCoord2f(0, 0);
			}
			if (angle == (angleStep+shift-thetaM-texCountM/2)) { 
				glTexCoord2f(1, 0);
			}
			
			glVertex3f(x,z,y);		
		}
	
		for ( angle=(angleStep+shift-thetaM-texCountM/2); angle>(-angleStep+shift-thetaM-texCountM/2); angle=angle-angleStep) {
			rad = radOuterM;
			float angle_radians = angle * (float)3.14159 / (float)180;	
			float x = xc + rad * (float)xDiameter*cos(angle_radians);
			float y = yc + rad * (float)yDiameter*sin(angle_radians);
		
			if (angle == (shift-thetaM-texCountM/2)) { 
				glTexCoord2f(0,1);
			}
			if (angle == (angleStep+shift-thetaM-texCountM/2)) { 
				glTexCoord2f(1, 1);
			}
			glVertex3f(x,z,y);
		}
	}	
	
//MIDDLE 2
	glColor4f( 1, 1, 1, intensityM2 * intensityFader);
	
	for (shift = 0; shift < texCountM2; shift=shift+angleStep) {	
		for ( angle=(shift-thetaM2-texCountM2/2); angle<(2*angleStep+shift-thetaM2-texCountM2/2); angle=angle+angleStep) {
			rad = radInnerM2;
			float angle_radians = angle * (float)3.14159 / (float)180;
			float x = xc + rad * (float)xDiameterFactorM2*7/4*cos(angle_radians);
			float y = yc + rad * (float)yDiameterFactorM2*sin(angle_radians);
		
			if (angle == (shift-thetaM2-texCountM2/2)) { 
				glTexCoord2f(0, 0);	
			}
			if (angle == (angleStep+shift-thetaM2-texCountM2/2)) { 
				glTexCoord2f(1, 0);
			}
			glVertex3f(x,z,y);		
		}
		
		for ( angle=(angleStep+shift-thetaM2-texCountM2/2); angle>(-angleStep+shift-thetaM2-texCountM2/2); angle=angle-angleStep) {
			rad = radOuterM2;
			float angle_radians = angle * (float)3.14159 / (float)180;
			float x = xc + rad * (float)xDiameter*cos(angle_radians);
			float y = yc + rad * (float)yDiameter*sin(angle_radians);
		
			if (angle == (shift-thetaM2-texCountM2/2)) { 
				glTexCoord2f(0,1);
			}
			if (angle == (angleStep+shift-thetaM2-texCountM2/2)) { 
				glTexCoord2f(1, 1);
			}
			glVertex3f(x,z,y);
		}
	}


	
//LATE	
	glColor4f( 1, 1, 1, intensityL * intensityFader );
		
	for (shift = 0; shift < texCountL; shift=shift+angleStep) {
		for ( angle=(shift-thetaL-texCountL/2); angle<(2*angleStep+shift-thetaL-texCountL/2); angle=angle+angleStep) {
			rad = radInnerL;
			float angle_radians = angle * (float)3.14159 / (float)180;
			float x = xc
			+ rad * (float)xDiameterFactorL*7/4*cos(angle_radians);
			float y = yc + rad * (float)yDiameterFactorL*sin(angle_radians);
		
			if (angle == (shift-thetaL-texCountL/2)) { 
				glTexCoord2f(0, 0); 
			}
			if (angle == (angleStep+shift-thetaL-texCountL/2)) { 
				glTexCoord2f(1, 0); 
			}
			glVertex3f(x,z,y);		
		}
		
		for ( angle=(angleStep+shift-thetaL-texCountL/2); angle>(-angleStep+shift-thetaL-texCountL/2); angle=angle-angleStep)
		{	
			rad = radOuterL;
			float angle_radians = angle * (float)3.14159 / (float)180;
			float x = xc + rad * (float)xDiameter*cos(angle_radians);
			float y = yc + rad * (float)yDiameter*sin(angle_radians);
		
			if (angle == (shift-thetaL-texCountL/2)) { 
				glTexCoord2f(0,1);
			}
			if (angle == (angleStep + shift-thetaL-texCountL/2)) { 
				glTexCoord2f(1, 1);
			}
			glVertex3f(x,z,y);
		}
	}
	
	glEnd();
	glPopMatrix();	
	
	glDisable(GL_TEXTURE_RECTANGLE_ARB);

}




- (void) drawShape:(GraphicsState *)state {
	
	glPushMatrix();
	glDisable( GL_LIGHTING );
	glDisable( GL_DEPTH_TEST );
	glDisable( GL_CULL_FACE );
	glDisable( GL_FOG );
	
	glColor4f(1.0, 1.0, 1.0, 1.0);

	glEnable( GL_TEXTURE_RECTANGLE_ARB );
	glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE );
	glEnable( GL_BLEND );
	glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
		
	[self drawGreyErrorSpace];
	
	if 	(task.enableParticleFreeze == 1) {
		
		if (analysis.status == kStatusReady) {	
			[self clearError];	
		}
	
	//	if (turnAnalysisOn) {
        if (1) {
				
			if ( (analysis.status == kStatusBack) || (analysis.status == kStatusStop) || (analysis.status == kStatusGrasping)) {
				
                if (abstract.statusChanged && analysis.status == kStatusGrasping) {
                    [spatialErrorValuesCopy release];
                    spatialErrorValuesCopy = [[analysis spatialErrorValues] copy];
                }
                
				[self calcErrorValues];
				
				if (task.enableGrey == 1) {
					[self drawGreyErrorSpace];
				}
				
				[self drawErrorSummary];	

			}
		}
	}
    
    /*
	if (!turnAnalysisOn) {	
		
		[self calcErrorValues];
		
		if (turnGreySpaceOn) {
			[self drawGreyErrorSpace];
		}
		
		[self drawErrorSummary];

	}
     */
	
	glDisable( GL_TEXTURE_RECTANGLE_ARB );
	glPopMatrix();
	
}

#pragma mark ---- NSObject  ----

- (void) dealloc
{		
	[errorIntensityAnimation release];
	[greyTexture release];
	[redTexture release];
	[frameTexture release];

	[super dealloc];
}

- (NSString *)description
{
    return( [NSString stringWithFormat:@"DrawError %@", name ] );
}


@synthesize intensityFader;

@synthesize xDiameterFactorE;
@synthesize yDiameterFactorE;
@synthesize xDiameterFactorM;
@synthesize yDiameterFactorM;
@synthesize xDiameterFactorM2;
@synthesize yDiameterFactorM2;
@synthesize xDiameterFactorL;
@synthesize yDiameterFactorL;

@synthesize magnitudeMappingType;

@synthesize errorThreshold;
@synthesize smallErrorUpperBound;
@synthesize mediumErrorUpperBound;
@synthesize largeErrorUpperBound;

@synthesize turnGreySpaceOn;
@synthesize turnAnalysisOn;
@synthesize angleStep;

@synthesize radInnerE;
@synthesize radOuterE;
@synthesize radInnerM;
@synthesize radOuterM;
@synthesize radInnerM2;
@synthesize radOuterM2;
@synthesize radInnerL;
@synthesize radOuterL;
@synthesize rad;

@synthesize intensityE;
@synthesize intensityM;
@synthesize intensityM2;
@synthesize intensityL;

@synthesize intensityEgrey;
@synthesize intensityMgrey;
@synthesize intensityM2grey;
@synthesize intensityLgrey;

@synthesize smallCount;
@synthesize mediumCount;
@synthesize largeCount;
@synthesize continuousFactor;

@synthesize xDiameter;
@synthesize yDiameter;

@synthesize thetaE;
@synthesize thetaM;
@synthesize thetaM2;
@synthesize thetaL;

@synthesize maxHandTrajErrorXE;
@synthesize maxHandTrajErrorYE;
@synthesize maxHandTrajErrorXM;
@synthesize maxHandTrajErrorYM;
@synthesize maxHandTrajErrorXM2;
@synthesize maxHandTrajErrorYM2;
@synthesize maxHandTrajErrorXL;
@synthesize maxHandTrajErrorYL;

@synthesize errorMagE;
@synthesize errorMagM;
@synthesize errorMagM2;
@synthesize errorMagL;

@synthesize texCountE;
@synthesize texCountM;
@synthesize texCountM2;
@synthesize texCountL;

@synthesize S1;
@synthesize S2;
@synthesize S3;
@synthesize S4;
@synthesize S5;


@end
