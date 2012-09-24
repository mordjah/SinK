//
//  OSCController.m
//  SinK
//
//  Created by Andrew Sempere on 6/10/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import "OSCController.h"

@implementation OSCController

// Init
-(id)init{
    self = [super init];
    
    // NOTIFICATION CENTER register listeners
    [[NSNotificationCenter defaultCenter] 
     addObserver:self
     selector:@selector(ncHandler_Generic:)
     name:@"StatusUpdateRecieved"
     object:nil];
    
    [[NSNotificationCenter defaultCenter] 
     addObserver:self
     selector:@selector(ncHandler_Generic:)
     name:@"OSCSendThisString"
     object:nil];
    
    
    //	Make an OSC Manager
    OSCmanagerObject = [[OSCManager alloc] init];
    
    //	by default, the osc manager's delegate will be told when osc messages are received
    [OSCmanagerObject setDelegate:self];
    
    
    //OSC
    [ui_recieveOSC_checkbox setState:NSOnState];
    [ui_receiveOSC_port setEditable:FALSE];
    [ui_receiveOSC_port setTextColor:[NSColor secondarySelectedControlColor]];
    [OSCmanagerObject createNewInputForPort:ui_sendOSC_port.intValue];
    
    //[ui_receiveOSC_port setEditable:TRUE];
    //[ui_receiveOSC_port setTextColor:[NSColor controlTextColor]];

    
    return self;
}





@end
