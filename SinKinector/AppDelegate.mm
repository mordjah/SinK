//
//  AppDelegate.m
//  SinKinect
//
//  Created by Andrew Sempere on 6/6/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import "AppDelegate.h"
#import "CocoaOpenNI.h"
#import <OpenGL/gl.h>
#import "DepthView.h"
#import "NotificationCenterWrapper.h"
#import "OSC.h"
#import "AppSettings.h"

@implementation AppDelegate

@synthesize menu_Sink_reaquire = _menu_Sink_reaquire;
@synthesize mainWindow = _mainWindow;
@synthesize kinectStatusImage = _kinectStatusImage;
@synthesize userCount = _userCount;
@synthesize userOnStageCount = _userOnStageCount;
@synthesize button_DepthView = _button_DepthView;
@synthesize status_configFile = _status_configFile;
@synthesize osc = _osc;
@synthesize status_localIP = _status_localIP;
@synthesize hAxis = _hAxis;
@synthesize vAxis = _vAxis;
@synthesize window_OSCTool = _window_OSCTool;
@synthesize menu_OSCToolLaunch = _menu_OSCToolLaunch;
@synthesize menu_environment1 = _menu_environment1;
@synthesize window_environment1 = _window_environment1;


//OPENNI Vars
XnUserID aUsers[15];
XnUInt16 numberOfUsers = 0;
xn::SceneMetaData sceneMD;
xn::DepthMetaData depthMD;
bool mode_displayScene = TRUE;
NSTimer *timer_OSC;
NSString *statusImg_loading = [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/sink_load.png"];
NSString *statusImg_paused = [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/sink_kinectPaused.png"];
NSString *statusImg_unreachable = [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/sink_kinectUnreachable.png"];


// Init
-(id)init{
    self = [super init];
    
    // NOTIFICATION CENTER register listeners
    [[NSNotificationCenter defaultCenter] 
        addObserver:self
           selector:@selector(ncHandler_Generic:)
               name:@"StatusUpdateRecieved"
             object:nil];
    
    
    // Initital State
    [[AppSettings sharedAppSettings] configSetValueFor:@"mode_skeletonTracking" :@"FALSE"];
    [[AppSettings sharedAppSettings] configSetValueFor:@"mode_depthView" :@"TRUE"];
    [[AppSettings sharedAppSettings] configSetValueFor:@"mode_configLocked" :@"FALSE"];
    [[AppSettings sharedAppSettings] configSetValueFor:@"mode_OSCTransmit" :@"TRUE"];
  
    
    return self;
}


///////////////////////////////////////////////////////////////////
// Automatic Callbacks
///////////////////////////////////////////////////////////////////

// AUTOMATIC: Before the ap is launched
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification{}

// AUTOMATIC: When the UI is drawn
- (void)awakeFromNib{
    
    [_userCount setStringValue:@"0"];

    //Hide the depth view (we make it visible once it's ready)
    [[AppSettings sharedAppSettings] configSetValueFor:@"mode_depthView" :@"FALSE"];
    _depthView.hidden = true;    
    _button_DepthView.image=[[NSImage alloc] initWithContentsOfFile: [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/led_off.png"]];
    [_button_DepthView setEnabled:false];
    
    // Turn off the axis for now
    [_hAxis setHidden:true];
    [_vAxis setHidden:true];
    
    // Hide the counts
    [_userCount setHidden:true];
    [_userOnStageCount setHidden:true];
}


// AUTOMATIC: When the application is fully launched
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{

    // Load the default config from disk
    [self loadDefault];

    //FIX: This is not the right way to get the IP, but I'm not sure how
    _status_localIP.stringValue = [[NSHost currentHost] name];
    [[AppSettings sharedAppSettings] configSetValueFor:@"localIP" :_status_localIP.stringValue];
    _status_configFile.stringValue=[[AppSettings sharedAppSettings] configGetValueFor:@"ConfigurationID"];

    // Refresh UI
    [_osc refreshSettings];
    
    //On a regular timer, call the "display" function, occurs at 30Hz, or 30fps.
    //Second line prevents the timer from pausing UI events
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(processFrame) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];

    // Hide main window
    //[_mainWindow miniaturize:self];
    
    // Foreground main window
    [_mainWindow makeKeyAndOrderFront:self];

    // Initialize the kinect hardware
    [self initKinect];
    
}


///////////////////////////////////////////////////////////////////
// Init
///////////////////////////////////////////////////////////////////
-(void)initKinect{

    // Indicate we're loading
    _depthView.hidden = true;
    _kinectStatusImage.image = [[NSImage alloc] initWithContentsOfFile: statusImg_loading];
    
    //Set up the openni "production unit" using an XML config file
    [NotificationCenterWrapper postNotification_status:@"Initializing Kinect..."];
    [[CocoaOpenNI sharedOpenNI] startWithConfigPath:[[NSBundle mainBundle] pathForResource:@"KinectConfig" ofType:@"xml"]];
    
    // If everything went okay, set up a depth and user generator (we only need one of each)
    if ([[CocoaOpenNI sharedOpenNI] isStarted]) {

        [_menu_Sink_reaquire setEnabled:false];
        [[CocoaOpenNI sharedOpenNI] depthGenerator].GetMetaData(depthMD);
        [[CocoaOpenNI sharedOpenNI] userGenerator].GetUserPixels(0, sceneMD);

        // Status update
        [NotificationCenterWrapper postNotification_status:@"Kinect Initialized!"];
                
        // Depthview Button
        [[AppSettings sharedAppSettings] configSetValueFor:@"mode_depthView" :@"TRUE"];
        _button_DepthView.image=[[NSImage alloc] initWithContentsOfFile: [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/led_green.png"]];
        [_button_DepthView setEnabled:true];

        // Turn off loading image
        _kinectStatusImage.hidden = true;
        
        // Show user counts
        [_userCount setHidden:false];
        [_userOnStageCount setHidden:false];

               
    } else {
        [NotificationCenterWrapper postNotification_status:@"Kinect not found!"];
        _kinectStatusImage.image = [[NSImage alloc] initWithContentsOfFile: statusImg_unreachable];
    }
    
}


///////////////////////////////////////////////////////////////////
// Timers
///////////////////////////////////////////////////////////////////

// @30Hz, used to update the OpenGL view for the kinect
- (void)processFrame {
    
    
    // Refresh settings
    [_osc refreshSettings];
    
    // Make sure the context is running before we do all the stuff below
    if ([CocoaOpenNI sharedOpenNI].started) {
        
        // OpenNI: Update everything
        [[CocoaOpenNI sharedOpenNI] context].WaitAnyUpdateAll();
                      
        //Update UI display count of users being tracked
        numberOfUsers =  [[CocoaOpenNI sharedOpenNI] userGenerator].GetNumberOfUsers();
        [[CocoaOpenNI sharedOpenNI] userGenerator].GetUsers(aUsers, numberOfUsers);
        [_userCount setStringValue:[NSString stringWithFormat:@"%i",numberOfUsers]]; 
        
        // Setup
        int usersOnStage=0;
        XnPoint3D pointInSpace;
        
        
        
        // Do we want Projective or Real World coordinates?
        bool f_projectiveCoordinates=([[[AppSettings sharedAppSettings] configGetValueFor:@"coordinateSystem"] isEqualToString:@"OPENNI Projective"]);
        
        // Turn off the axis if Projective
        [_hAxis setHidden:f_projectiveCoordinates];
        [_vAxis setHidden:f_projectiveCoordinates];        
        
        // What units? (if RW we apply this too all coords, if projective just to Z)
        float unitConversionMultiplier=1;
        if ([[[AppSettings sharedAppSettings] configGetValueFor:@"coordinateUnits"] isEqualToString:@"meters"]){
            unitConversionMultiplier=.001;
        }else if ([[[AppSettings sharedAppSettings] configGetValueFor:@"coordinateUnits"] isEqualToString:@"centimeters"]){
            unitConversionMultiplier=.1;
        }else{
            unitConversionMultiplier=1;
        }
             
        
        //For each user being tracked
        for (int i = 0; i < numberOfUsers; ++i) {
            // PART 1: USER BLOB TRACKING
            
            // The userGenerator has the information (COM=Center Of Mass)
            // Coordinates are real world by default
            [[CocoaOpenNI sharedOpenNI] userGenerator].GetCoM(aUsers[i], pointInSpace);
            
            
            // If a user goes off screen, we "track" them for a bit, resulting in empty coordinates for COM. 
            // We don't care about offscreen users, so just ignore it
            if (pointInSpace.Z > 0){
                
                // Increment onstage count
                usersOnStage=usersOnStage+1;
                
                // Convert if we want real world
                if (f_projectiveCoordinates){
                    [[CocoaOpenNI sharedOpenNI] depthGenerator].ConvertRealWorldToProjective(1, &pointInSpace, &pointInSpace);   
                }
                
                // Handle unit conversion (default is mm)
                // We don't unit convert X and Y on projective, because they are in pixels, but we do discard the decimal
                if (f_projectiveCoordinates){
                    pointInSpace.X = floor(pointInSpace.X);
                    pointInSpace.Y = floor(pointInSpace.Y);                
                }else{
                    pointInSpace.X = pointInSpace.X * unitConversionMultiplier;
                    pointInSpace.Y = pointInSpace.Y * unitConversionMultiplier;
                }
                pointInSpace.Z = pointInSpace.Z * unitConversionMultiplier;
                
                // OSC Body: Send out the tracked body
                [_osc sendOutputViaOSC_bodyPart:@"body" :aUsers[i] :pointInSpace.X :pointInSpace.Y :pointInSpace.Z ];
            }
            
            
            
            
            // PART 2: SKELETON TRACKING
            
            // Skeleton: Send out coords of each bodypart if we are tracking this user AND global skeleton tracking is on
            if ( ([[[AppSettings sharedAppSettings] configGetValueFor:@"mode_skeletonTracking"] isEqualToString:@"TRUE"]) &&
                 [[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().IsTracking(aUsers[i])) {

                
                // A skeleton is comprised of...
                NSArray *skeleton = [NSArray arrayWithObjects: 
                                    [NSNumber numberWithInteger:XN_SKEL_HEAD],
                                    [NSNumber numberWithInteger:XN_SKEL_NECK],
                                    [NSNumber numberWithInteger:XN_SKEL_TORSO],                                           
                                    [NSNumber numberWithInteger:XN_SKEL_RIGHT_SHOULDER],                                            
                                    [NSNumber numberWithInteger:XN_SKEL_RIGHT_ELBOW],                                           
                                    [NSNumber numberWithInteger:XN_SKEL_RIGHT_HAND],                                           
                                    [NSNumber numberWithInteger:XN_SKEL_RIGHT_HIP],                                            
                                    [NSNumber numberWithInteger:XN_SKEL_RIGHT_KNEE],                                            
                                    [NSNumber numberWithInteger:XN_SKEL_RIGHT_ANKLE],                                           
                                    [NSNumber numberWithInteger:XN_SKEL_RIGHT_FOOT],                                            
                                    [NSNumber numberWithInteger:XN_SKEL_LEFT_SHOULDER],                                           
                                    [NSNumber numberWithInteger:XN_SKEL_LEFT_ELBOW],                                            
                                    [NSNumber numberWithInteger:XN_SKEL_LEFT_HAND],                                          
                                    [NSNumber numberWithInteger:XN_SKEL_LEFT_HIP],                                            
                                    [NSNumber numberWithInteger:XN_SKEL_LEFT_KNEE],                                          
                                    [NSNumber numberWithInteger:XN_SKEL_LEFT_ANKLE],                                           
                                    [NSNumber numberWithInteger:XN_SKEL_LEFT_FOOT],                                  
                                    nil];
                
                // Loop over skeleton array
                NSEnumerator *skeletonPart = [skeleton objectEnumerator];
                XnSkeletonJointPosition thisBodyPart;
                id thisPart;
                while ((thisPart = [skeletonPart nextObject])) {
                    
                    // Grab the coordinates for the part
                    [[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().GetSkeletonJointPosition(aUsers[i], (XnSkeletonJoint)[thisPart integerValue], thisBodyPart);

                    // If our confidence level is ok, send the results out
                    if (thisBodyPart.fConfidence > .5){
                        
                        
                        // Convert if we want real world
                        if (f_projectiveCoordinates){
                            [[CocoaOpenNI sharedOpenNI] depthGenerator].ConvertRealWorldToProjective(1, &thisBodyPart.position, &thisBodyPart.position);   
                        }
                        
                        // Handle unit conversion (default is mm)
                        // We don't unit convert X and Y on projective, because they are in pixels, but we do discard the decimal
                        if (f_projectiveCoordinates){
                            thisBodyPart.position.X = floor(thisBodyPart.position.X);
                            thisBodyPart.position.Y = floor(thisBodyPart.position.Y);                
                        }else{
                            thisBodyPart.position.X = thisBodyPart.position.X * unitConversionMultiplier;
                            thisBodyPart.position.Y = thisBodyPart.position.Y * unitConversionMultiplier;
                        }
                        thisBodyPart.position.Z = thisBodyPart.position.Z * unitConversionMultiplier;

                        
                        
                        
                        // Send! 
                        [_osc sendOutputViaOSC_bodyPart:[[AppSettings sharedAppSettings] skeletonpartNameByID:thisPart] 
                                                       :aUsers[i] 
                                                       :thisBodyPart.position.X 
                                                       :thisBodyPart.position.Y 
                                                       :thisBodyPart.position.Z ];
                    }
                }
            }

        }
        
        // Update the onstage count
        [_userOnStageCount setStringValue:[NSString stringWithFormat:@"%i",usersOnStage]]; 

        
        // DISPLAY the scene 
        if (mode_displayScene){
            // OpenGL: Force an update of the framebuffer (fires "drawRect" in DepthView class)
            [_depthView setNeedsDisplay:YES];
            // Make OPENGL window visible if hidden (we do it here so we don't show the garbage framebuffer on loading)
            if (_depthView.hidden = true){_depthView.hidden = false;}
        }
    }    
}

///////////////////////////////////////////////////////////////////
// Actions for Menu items
///////////////////////////////////////////////////////////////////
- (IBAction)reaquire_Kinect:(id)sender {
    [self initKinect];
}

// Load the configuration
- (IBAction)config_load:(id)sender {
    [[AppSettings sharedAppSettings] readConfigFromDisk];
}

// Save the configuration to disk
- (IBAction)config_save:(id)sender {
    [[AppSettings sharedAppSettings] writeConfigToDisk];
}

// Load the Default config file
- (IBAction)config_reset:(id)sender {[self loadDefault];}
- (void) loadDefault{
    if(![[[AppSettings sharedAppSettings] configGetValueFor:@"mode_configLocked"]isEqualToString:@"TRUE"]){
        [[AppSettings sharedAppSettings] readDefaultConfigFromDisk];
    }
}

- (IBAction)menu_OSCLogger:(id)sender {
    //[_window_OSCTool center];
    [_window_OSCTool makeKeyAndOrderFront:self];
}

- (IBAction)menu_config:(id)sender {
    // Center and foreground us
    //[_mainWindow center];
    [_mainWindow makeKeyAndOrderFront:self];
    
}


///////////////////////////////////////////////////////////////////
// Notifications
///////////////////////////////////////////////////////////////////

//HANDLER
- (void) ncHandler_Generic:(NSNotification *)notification{
    
    // STATUS UPDATE: Update the status bar 
    if ([[notification name] isEqualToString: @"StatusUpdateRecieved"]){
        //NSLog(@"%@",[[notification userInfo] objectForKey:@"statusString"]);
        
        [_osc sendOutputViaOSC_status:[[notification userInfo] objectForKey:@"statusString"] ];
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"ConsoleMessageReceived"
         object:self
         userInfo:[NSDictionary dictionaryWithObject:[[notification userInfo] objectForKey:@"statusString"] forKey:@"statusString"]];
    }

}



@end
