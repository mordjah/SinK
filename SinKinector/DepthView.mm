// This code handles the OPENGL view.

//
//  DepthView.m
//  CocoaOpenNI
//
//  Created by John Boiles on 1/13/12.
//  Copyright (c) 2012 John Boiles. All rights reserved.
//

#import "DepthView.h"
#import <OpenGL/gl.h>
#import "CocoaOpenNI.h"
#include <XnCppWrapper.h>

#define kKinectWidth (640.0)
#define kKinectHeight (480.0)

@implementation DepthView


// drawRect is defined by the openGL spec. Calling things here ensures everything is set up properly
- (void)drawRect:(NSRect)bounds {
    
      if ([[CocoaOpenNI sharedOpenNI] isStarted]) {

        // NI - Process the data
        xn::SceneMetaData sceneMD;
        xn::DepthMetaData depthMD;
        [[CocoaOpenNI sharedOpenNI] depthGenerator].GetMetaData(depthMD);
        [[CocoaOpenNI sharedOpenNI] userGenerator].GetUserPixels(0, sceneMD);


        // OpenGL 
        glEnableClientState(GL_VERTEX_ARRAY);
        glDisableClientState(GL_COLOR_ARRAY);
        glPushMatrix();
        glLoadIdentity();
        glMatrixMode(GL_PROJECTION);
        glOrtho(0, 640, 480, 0, -4.0f, 4.0f);
        
        //SceneDrawer (part of OPENNI)
        DrawDepthMap(depthMD, sceneMD);
        DrawUserInfo();

        // OpenGL
        glPopMatrix();
        glFlush();
  }
}

@end
