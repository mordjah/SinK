/*****************************************************************************
*                                                                            *
*  OpenNI 1.0 Alpha                                                          *
*  Copyright (C) 2010 PrimeSense Ltd.                                        *
*                                                                            *
*  This file began as part of OpenNI, now heavily modified                   *
*                                                                            *
*****************************************************************************/

//---------------------------------------------------------------------------
// Includes
//---------------------------------------------------------------------------
#include "SceneDrawer.h"
#import "CocoaOpenNI.h"
#import "NotificationCenterWrapper.h"
#import "AppSettings.h"

#if (XN_PLATFORM == XN_PLATFORM_MACOSX)
  #include <GLUT/glut.h>
#else
  #include <GL/glut.h>
#endif


// Settings
XnBool g_bDrawBackground = TRUE;
XnBool g_bDrawPixels = TRUE;
XnBool g_bDrawSkeleton = TRUE;
XnBool g_bPrintID = TRUE;
XnBool g_bPrintState = TRUE;
XnFloat Colors[][3] = {
  {0,1,1},
  {0,0,1},
  {0,1,0},
  {1,1,0},
  {1,0,0},
  {1,.5,0},
  {.5,1,0},
  {0,.5,1},
  {.5,0,1},
  {1,1,.5},
  {1,1,1}
};
XnUInt32 nColors = 10;
#define MAX_DEPTH 10000

// Global state
float g_pDepthHist[MAX_DEPTH];
GLfloat texcoords[8];

unsigned int getClosestPowerOfTwo(unsigned int n);
GLuint initTexture(void** buf, int& width, int& height);
void DrawRectangle(float topLeftX, float topLeftY, float bottomRightX, float bottomRightY);
void DrawTexture(float topLeftX, float topLeftY, float bottomRightX, float bottomRightY);
void glPrintString(void *font, char *str);
void DrawLimb(XnUserID player, XnSkeletonJoint eJoint1, XnSkeletonJoint eJoint2);


// Draw the information about the tracked users to the screen
void DrawUserInfo() {
    XnUserID aUsers[15];
    XnUInt16 nUsers = 15;
    [[CocoaOpenNI sharedOpenNI] userGenerator].GetUsers(aUsers, nUsers);
    char strLabel[50] = "";
    xnOSMemSet(strLabel, 0, sizeof(strLabel));
    XnPoint3D com;

    for (int i = 0; i < nUsers; ++i) {
        [[CocoaOpenNI sharedOpenNI] userGenerator].GetCoM(aUsers[i], com);
        [[CocoaOpenNI sharedOpenNI] depthGenerator].ConvertRealWorldToProjective(1, &com, &com);
        
        // Draw the centroid 
        sprintf(strLabel, "*%d*",aUsers[i]); 
        glColor4f(1-Colors[i%nColors][0], 1-Colors[i%nColors][1], 1-Colors[i%nColors][2], 1);
        glRasterPos2i(com.X, com.Y);
        glPrintString(GLUT_BITMAP_HELVETICA_18, strLabel);
        
        // If we're skeleton tracking
        if([[[AppSettings sharedAppSettings] configGetValueFor:@"mode_skeletonTracking"] isEqualToString:@"TRUE"]){
            
            // Mark users with status
            if (g_bPrintID) {
               
                if (!g_bPrintState) {                
                    sprintf(strLabel, "%d (%f,%f,%f)", aUsers[i],com.X,com.Y,com.Z);
                } else if ([[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().IsTracking(aUsers[i])) {
                    //sprintf(strLabel, "%d (%f,%f,%f) - Tracking", aUsers[i],com.X,com.Y,com.Z);
                    //sprintf(strLabel, "Tracking");
                } else if ([[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().IsCalibrating(aUsers[i])) {
                    //sprintf(strLabel, "%d (%f,%f,%f) - Gotcha. Now calibrating skeleton...", aUsers[i],com.X,com.Y,com.Z);                
                    sprintf(strLabel, "Calibrating skeleton...");                
                } else {
                    sprintf(strLabel, "Waiting for pose...");
                }
                glColor4f(1-Colors[i%nColors][0], 1-Colors[i%nColors][1], 1-Colors[i%nColors][2], 1);
                glRasterPos2i(com.X, com.Y);
                glPrintString(GLUT_BITMAP_HELVETICA_18, strLabel);
            }
            
            // Draw the articulated skeleton
            if (g_bDrawSkeleton && [[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().IsTracking(aUsers[i])) {
                glBegin(GL_LINES);
                glColor4f(1-Colors[aUsers[i]%nColors][0], 1-Colors[aUsers[i]%nColors][1], 1-Colors[aUsers[i]%nColors][2], 1);
                
                DrawLimb(aUsers[i], XN_SKEL_HEAD, XN_SKEL_NECK);
                
                DrawLimb(aUsers[i], XN_SKEL_NECK, XN_SKEL_LEFT_SHOULDER);
                DrawLimb(aUsers[i], XN_SKEL_LEFT_SHOULDER, XN_SKEL_LEFT_ELBOW);
                DrawLimb(aUsers[i], XN_SKEL_LEFT_ELBOW, XN_SKEL_LEFT_HAND);
                
                DrawLimb(aUsers[i], XN_SKEL_NECK, XN_SKEL_RIGHT_SHOULDER);
                DrawLimb(aUsers[i], XN_SKEL_RIGHT_SHOULDER, XN_SKEL_RIGHT_ELBOW);
                DrawLimb(aUsers[i], XN_SKEL_RIGHT_ELBOW, XN_SKEL_RIGHT_HAND);
                
                DrawLimb(aUsers[i], XN_SKEL_LEFT_SHOULDER, XN_SKEL_TORSO);
                DrawLimb(aUsers[i], XN_SKEL_RIGHT_SHOULDER, XN_SKEL_TORSO);
                
                DrawLimb(aUsers[i], XN_SKEL_TORSO, XN_SKEL_LEFT_HIP);
                DrawLimb(aUsers[i], XN_SKEL_LEFT_HIP, XN_SKEL_LEFT_KNEE);
                DrawLimb(aUsers[i], XN_SKEL_LEFT_KNEE, XN_SKEL_LEFT_FOOT);
                
                DrawLimb(aUsers[i], XN_SKEL_TORSO, XN_SKEL_RIGHT_HIP);
                DrawLimb(aUsers[i], XN_SKEL_RIGHT_HIP, XN_SKEL_RIGHT_KNEE);
                DrawLimb(aUsers[i], XN_SKEL_RIGHT_KNEE, XN_SKEL_RIGHT_FOOT);
                
                DrawLimb(aUsers[i], XN_SKEL_LEFT_HIP, XN_SKEL_RIGHT_HIP);
                
                DrawLimb(aUsers[i], XN_SKEL_LEFT_HIP, XN_SKEL_LEFT_KNEE);
                DrawLimb(aUsers[i], XN_SKEL_LEFT_KNEE, XN_SKEL_LEFT_ANKLE);
                DrawLimb(aUsers[i], XN_SKEL_LEFT_ANKLE, XN_SKEL_LEFT_FOOT);
                
                DrawLimb(aUsers[i], XN_SKEL_RIGHT_HIP, XN_SKEL_RIGHT_KNEE);
                DrawLimb(aUsers[i], XN_SKEL_RIGHT_KNEE, XN_SKEL_RIGHT_ANKLE);
                DrawLimb(aUsers[i], XN_SKEL_RIGHT_ANKLE, XN_SKEL_RIGHT_FOOT);
                
                glEnd();
            }
        }
        
        
    }
}


// Draw a limb of the skeleton point to point
void DrawLimb(XnUserID player, XnSkeletonJoint requestedStartPoint, XnSkeletonJoint requestedEndPoint) {
    

    
    // Exit if we're not tracking this user (lost them maybe)
    if (![[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().IsTracking(player)) {return;}
    
    // Looks like this is how you get the skeleton position for the player
    XnSkeletonJointPosition startPoint, endPoint;
    [[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().GetSkeletonJointPosition(player, requestedStartPoint, startPoint);
    [[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().GetSkeletonJointPosition(player, requestedEndPoint, endPoint);
    
    // Exit if we aren't sure about these points
    if (startPoint.fConfidence < 0.5 || endPoint.fConfidence < 0.5) {return;}
    
    // Draw the line!
    XnPoint3D pt[2];
    pt[0] = startPoint.position;
    pt[1] = endPoint.position;
    
    [[CocoaOpenNI sharedOpenNI] depthGenerator].ConvertRealWorldToProjective(2, pt, pt);
    glVertex3i(pt[0].X, pt[0].Y, 0);
    glVertex3i(pt[1].X, pt[1].Y, 0);
}




///////////////////////////////////////////////////////////////////////////////////////////////////
// HELPER FUNCTIONS

unsigned int getClosestPowerOfTwo(unsigned int n) {
  unsigned int m = 2;
  while(m < n) m <<= 1;
  return m;
}

void glPrintString(void *font, char *str) {
  size_t i, l = strlen(str);
  for(i = 0; i < l; i++) {
    glutBitmapCharacter(font, *str++);
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
// OPENGL MAGICS

GLuint initTexture(void** buf, int& width, int& height) {
    GLuint texID = 0;
    glGenTextures(1, &texID);
    
    width = getClosestPowerOfTwo(width);
    height = getClosestPowerOfTwo(height); 
    *buf = new unsigned char[width * height * 4];
    glBindTexture(GL_TEXTURE_2D, texID);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    return texID;
}


void DrawRectangle(float topLeftX, float topLeftY, float bottomRightX, float bottomRightY) {
    GLfloat verts[8] = {
        topLeftX, topLeftY,
        topLeftX, bottomRightY,
        bottomRightX, bottomRightY,
        bottomRightX, topLeftY
    };
    glVertexPointer(2, GL_FLOAT, 0, verts);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    //TODO: Maybe glFinish needed here instead - if there's some bad graphics crap
    glFinish();
}


void DrawTexture(float topLeftX, float topLeftY, float bottomRightX, float bottomRightY) {
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
    DrawRectangle(topLeftX, topLeftY, bottomRightX, bottomRightY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
}



void DrawDepthMap(const xn::DepthMetaData& dmd, const xn::SceneMetaData& smd) {
  static bool bInitialized = false;  
  static GLuint depthTexID;
  static unsigned char* pDepthTexBuf;
  static int texWidth, texHeight;
    /*
  float topLeftX;
  float topLeftY;
  float bottomRightY;
  float bottomRightX;
     */
    
float texXpos;
  float texYpos;

  if(!bInitialized) {
    texWidth =  getClosestPowerOfTwo(dmd.XRes());
    texHeight = getClosestPowerOfTwo(dmd.YRes());

    printf("Initializing depth texture: width = %d, height = %d\n", texWidth, texHeight);
    depthTexID = initTexture((void**)&pDepthTexBuf,texWidth, texHeight) ;
    printf("Initialized depth texture: width = %d, height = %d\n", texWidth, texHeight);

    bInitialized = true;
    
      /*
    topLeftX = dmd.XRes();
    topLeftY = 0;
    bottomRightY = dmd.YRes();
    bottomRightX = 0;
       */
      
    texXpos =(float)dmd.XRes()/texWidth;
    texYpos  =(float)dmd.YRes()/texHeight;

    memset(texcoords, 0, 8*sizeof(float));
    texcoords[0] = texXpos, texcoords[1] = texYpos, texcoords[2] = texXpos, texcoords[7] = texYpos;
  }

  unsigned int nValue = 0;
  unsigned int nHistValue = 0;
  unsigned int nIndex = 0;
  unsigned int nX = 0;
  unsigned int nY = 0;
  unsigned int nNumberOfPoints = 0;
  XnUInt16 g_nXRes = dmd.XRes();
  XnUInt16 g_nYRes = dmd.YRes();

  unsigned char* pDestImage = pDepthTexBuf;

  const XnDepthPixel* pDepth = dmd.Data();
  const XnLabel* pLabels = smd.Data();

  // Calculate the accumulative histogram
  memset(g_pDepthHist, 0, MAX_DEPTH*sizeof(float));
  for (nY=0; nY<g_nYRes; nY++)
  {
    for (nX=0; nX<g_nXRes; nX++)
    {
      nValue = *pDepth;

      if (nValue != 0)
      {
        g_pDepthHist[nValue]++;
        nNumberOfPoints++;
      }

      pDepth++;
    }
  }

  for (nIndex=1; nIndex<MAX_DEPTH; nIndex++) {
    g_pDepthHist[nIndex] += g_pDepthHist[nIndex-1];
  }
  if (nNumberOfPoints) {
    for (nIndex=1; nIndex<MAX_DEPTH; nIndex++) {
      g_pDepthHist[nIndex] = (unsigned int)(256 * (1.0f - (g_pDepthHist[nIndex] / nNumberOfPoints)));
    }
  }

  pDepth = dmd.Data();
  if (g_bDrawPixels) {
    XnUInt32 nIndex = 0;
    // Prepare the texture map
    for (nY=0; nY<g_nYRes; nY++)
    {
      for (nX=0; nX < g_nXRes; nX++, nIndex++)
      {

        pDestImage[0] = 0;
        pDestImage[1] = 0;
        pDestImage[2] = 0;
  
        // Draw the depth
        if (g_bDrawBackground || *pLabels != 0) {
          nValue = *pDepth;
          XnLabel label = *pLabels;
          XnUInt32 nColorID = label % nColors;
          if (label == 0)
          {
            nColorID = nColors;
          }

          if (nValue != 0)
          {
            nHistValue = g_pDepthHist[nValue];

            pDestImage[0] = nHistValue * Colors[nColorID][0]; 
            pDestImage[1] = nHistValue * Colors[nColorID][1];
            pDestImage[2] = nHistValue * Colors[nColorID][2];
          }
        }

        pDepth++;
        pLabels++;
        pDestImage+=3;
      }

      pDestImage += (texWidth - g_nXRes) *3;
    }
  } else {
    xnOSMemSet(pDepthTexBuf, 0, 3*2*g_nXRes*g_nYRes);
  }

  glBindTexture(GL_TEXTURE_2D, depthTexID);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, texWidth, texHeight, 0, GL_RGB, GL_UNSIGNED_BYTE, pDepthTexBuf);

  // Display the OpenGL texture map
  glColor4f(0.75, 0.75, 0.75, 1);

  glEnable(GL_TEXTURE_2D);
  DrawTexture(dmd.XRes(), dmd.YRes(), 0, 0);
  glDisable(GL_TEXTURE_2D);
}

