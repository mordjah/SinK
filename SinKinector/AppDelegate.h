//
//  AppDelegate.h
//  SinKinect
//
//  Created by Andrew Sempere on 6/6/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <VVOSC/VVOSC.h>
#import "OSC.h"
@class DepthView; // Make use of the DepthView class

@interface AppDelegate : NSObject <NSApplicationDelegate>{
    IBOutlet DepthView *_depthView;
}

@property (assign) IBOutlet NSMenuItem *menu_Sink_reaquire;
@property (assign) IBOutlet NSWindow *mainWindow;
@property (assign) IBOutlet NSImageView *kinectStatusImage;
@property (assign) IBOutlet NSTextField *userCount;
@property (assign) IBOutlet NSTextField *userOnStageCount;
@property (assign) IBOutlet NSButtonCell *button_DepthView;
@property (assign) IBOutlet NSTextField *status_configFile;
@property (assign) IBOutlet NSTextField *status_localIP;
@property (assign) IBOutlet NSBox *hAxis;
@property (assign) IBOutlet NSBox *vAxis;
@property (assign) IBOutlet NSWindow *window_OSCTool;
@property (assign) IBOutlet NSMenuItem *menu_OSCToolLaunch;
@property (assign) IBOutlet NSMenu *menu_environment1;
@property (assign) IBOutlet NSWindow *window_environment1;

// Add a new outlet for the OSC instance created in the nib.
// You also have to bind this in IB by ctrl-dragging from 
// the app delegate to the OSC and setting it to "osc."
@property (assign) IBOutlet OSC *osc;


@end
