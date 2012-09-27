//
//  OSC.m
//  SinK
//
//  Created by Andrew Sempere on 6/10/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import "OSC.h"
#import "AppSettings.h"

@implementation OSC

@synthesize ui_sendOSC_ip;
@synthesize ui_sendOSC_port;
@synthesize ui_sendOSC_address;
@synthesize ui_sendOSC_message;
@synthesize ui_sendOSC_type;
@synthesize ui_recieveOSC_checkbox;
@synthesize ui_receiveOSC_port;
@synthesize ui_send_button;
@synthesize ui_sendLoop_button;

@synthesize ui_OSCSendingDisplay;
@synthesize ui_OSCAddressPartPrefix;

@synthesize ui_OSCaddressPartLeft;
@synthesize ui_OSCaddressPartLeft_checkbox;
@synthesize ui_coordinateSystem;
@synthesize ui_coordinateUnits;
@synthesize ui_OSCaddressPartRight;
@synthesize ui_OSCaddressPartBody;
@synthesize ui_OSCaddressPartBody_checkbox;
@synthesize ui_OSCaddressPartHead;
@synthesize ui_OSCaddressPartHead_checkbox;
@synthesize ui_OSCaddressPartNeck;
@synthesize ui_OSCaddressPartNeck_checkbox;
@synthesize ui_OSCaddressPartTorso;
@synthesize ui_OSCaddressPartTorso_checkbox;
@synthesize ui_OSCaddressPartShoulder;
@synthesize ui_OSCaddressPartShoulder_checkbox;
@synthesize ui_OSCaddressPartElbow;
@synthesize ui_OSCaddressPartElbow_checkbox;
@synthesize ui_OSCaddressPartHand;
@synthesize ui_OSCaddressPartHand_checkbox;
@synthesize ui_OSCaddressPartHip;
@synthesize ui_OSCaddressPartHip_checkbox;
@synthesize ui_OSCaddressPartKnee;
@synthesize ui_OSCaddressPartKnee_checkbox;
@synthesize ui_OSCaddressPartAnkle;
@synthesize ui_OSCaddressPartAnkle_checkbox;
@synthesize ui_OSCaddressPartFoot;
@synthesize ui_OSCaddressPartFoot_checkbox;
@synthesize ui_OSCDataPacketFormat;
@synthesize ui_OSCaddressPartRight_checkbox;
@synthesize OSCToolView;
@synthesize ui_tabSwitch;

@synthesize OSCTransmitButton;
@synthesize OSCTransmitStatus;
@synthesize SkeletonTransmitButton;
@synthesize SkeletonTransmitStatus;

@synthesize windowOSC = windowOSC;
@synthesize lock_icon;
@synthesize OSC_Send_statusLight;

//OSC 
OSCManager					*OSCmanagerObject;
OSCInPort					*recieveOSC_port;
OSCOutPort					*sendOSC_port;	
NSMutableArray              *oscMessages;
float                       *oscMessageCount;
NSTimer *timer;
id OSCOutput;
bool g_led_animating;

// Init
-(id)init{
    self = [super init];
    
    //	Make an OSC Manager
    OSCmanagerObject = [[OSCManager alloc] init];
    
    //	by default, the osc manager's delegate will be told when osc messages are received
    [OSCmanagerObject setDelegate:self];
    return self;

}


// AUTOMATIC: When UI is Loaded
- (void)awakeFromNib{
  
    //OSC Init
    [ui_recieveOSC_checkbox setState:NSOffState];
    [ui_receiveOSC_port setEditable:TRUE];
    [ui_receiveOSC_port setTextColor:[NSColor controlTextColor]];
    
    // Initialize OSC State Button
    [OSCTransmitButton setState:NSOnState];
    OSCTransmitButton.image=[[NSImage alloc] initWithContentsOfFile: [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/led_green.png"]];
    [OSCTransmitStatus setStringValue:@"OSC Transmit: ON"];

    // Initialize Skeleton State Button
    [SkeletonTransmitButton setState:NSOnState];
    SkeletonTransmitButton.image=[[NSImage alloc] initWithContentsOfFile: [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/led_green.png"]];
    [SkeletonTransmitStatus setStringValue:@"Skeleton Tracking: ON"];
  
    // create an output so I can send OSC data
    OSCOutput = [OSCmanagerObject 
               createNewOutputToAddress:ui_sendOSC_ip.stringValue 
               atPort:ui_sendOSC_port.intValue];
}



// Refresh Settings (called by a timer from AppDelegate, makes sure the internal state and the GUI stay consistent)
- (void) refreshSettings{

    // Force reload?
    if ([[[AppSettings sharedAppSettings] configGetValueFor:@"f_forceReload"] isEqualToString:@"TRUE"]){
        
        [self updateUIfromConfig];
        
        // Lock it up
        if([[[AppSettings sharedAppSettings] configGetValueFor:@"mode_skeletonTracking"]isEqualToString:@"FALSE"]){
            SkeletonTransmitButton.image=[[NSImage alloc] initWithContentsOfFile: [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/led_off.png"]];
            [SkeletonTransmitStatus setStringValue:@"Skeleton Tracking: OFF"];
            [self ui_lockSkeleton];
        }else{
            [[AppSettings sharedAppSettings] configSetValueFor:@"mode_skeletonTracking" :@"TRUE"];
            SkeletonTransmitButton.image=[[NSImage alloc] initWithContentsOfFile: [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/led_green.png"]];
            [SkeletonTransmitStatus setStringValue:@"Skeleton Tracking: ON"];  
            [self ui_unlockSkeleton];
        }
        
        if([[[AppSettings sharedAppSettings] configGetValueFor:@"mode_configLocked"]isEqualToString:@"TRUE"]){
            [self ui_lockSkeleton];
            [self ui_lockOther];
        }else{
            [self ui_unlockOther];
        }
        
        

        [[AppSettings sharedAppSettings] configSetValueFor:@"f_forceReload" :@"FALSE"];
    }

    
    // Disallow blank left/right
    if ([[ui_OSCaddressPartRight.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]){ui_OSCaddressPartRight.stringValue = @"right";}
    if ([[ui_OSCaddressPartLeft.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]){ui_OSCaddressPartLeft.stringValue = @"left";}
    
    // Refresh the OSC tool (outgoing IP display and the port if it's not already engaged)
    [ui_OSCSendingDisplay setStringValue:[NSString stringWithFormat:@"%@:%@", ui_sendOSC_ip.stringValue, ui_sendOSC_port.stringValue]];
    if ([ui_recieveOSC_checkbox state] == NSOffState){
        [ui_receiveOSC_port setStringValue:ui_sendOSC_port.stringValue];
    }
    
    // If the IP or Port has changed from what we remember last time, also update the OSC send object
    if  ((![[[AppSettings sharedAppSettings] configGetValueFor:@"OSC_ip"] isEqualToString: ui_sendOSC_ip.stringValue]) 
        || (![[[AppSettings sharedAppSettings] configGetValueFor:@"OSC_port"] isEqualToString: ui_sendOSC_port.stringValue])){
    
        OSCOutput = [OSCmanagerObject
                 createNewOutputToAddress:ui_sendOSC_ip.stringValue 
                 atPort:ui_sendOSC_port.intValue];
    }
       
    // Update the config in memory with whatever the UI says
    [self updateConfigFromUI];
    
}
    



// BUTTON: OSC On/off
- (IBAction)OSCTransmitButton:(id)sender {[self toggleOSCMode];}

- (void) toggleOSCMode{
   
    if (OSCTransmitButton.state == NSOnState){
       [[AppSettings sharedAppSettings] configSetValueFor:@"mode_OSCTransmit" :@"TRUE"];
        OSCTransmitButton.image=[[NSImage alloc] initWithContentsOfFile: [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/led_green.png"]];
       [OSCTransmitStatus setStringValue:@"OSC Transmit: ON"];
    }else{
        [[AppSettings sharedAppSettings] configSetValueFor:@"mode_OSCTransmit" :@"FALSE"];
        OSCTransmitButton.image=[[NSImage alloc] initWithContentsOfFile: [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/led_off.png"]];
        [OSCTransmitStatus setStringValue:@"OSC Transmit: OFF"];

    }
}


// BUTTON: Skeleton On/Off
- (IBAction)SkeletonTransmitButton:(id)sender {[self toggleSkeletonMode];}
- (void) toggleSkeletonMode{
    
    if (SkeletonTransmitButton.state == NSOnState){
        [[AppSettings sharedAppSettings] configSetValueFor:@"mode_skeletonTracking" :@"TRUE"];
        SkeletonTransmitButton.image=[[NSImage alloc] initWithContentsOfFile: [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/led_green.png"]];
        [SkeletonTransmitStatus setStringValue:@"Skeleton Tracking: ON"];       
        [self ui_unlockSkeleton];
        
        
    }else{
        [[AppSettings sharedAppSettings] configSetValueFor:@"mode_skeletonTracking" :@"FALSE"];
        SkeletonTransmitButton.image=[[NSImage alloc] initWithContentsOfFile: [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/led_off.png"]];
        [SkeletonTransmitStatus setStringValue:@"Skeleton Tracking: OFF"];
        [self ui_lockSkeleton];
        
    }

}

// MENU: Lock the configuration screen
- (IBAction)lock_configScreen:(id)sender {
    
    // Unlock everything
    if ([[[AppSettings sharedAppSettings] configGetValueFor:@"mode_configLocked"] isEqualToString:@"TRUE"]){
        
        // conditional unlock skeleton UI
        if ([[[AppSettings sharedAppSettings] configGetValueFor:@"mode_skeletonTracking"] isEqualToString:@"TRUE"]){
            [self ui_unlockSkeleton];
        }
        
        // unlock everything else
        [self ui_unlockOther];

        [[AppSettings sharedAppSettings] configSetValueFor:@"mode_configLocked" :@"FALSE"];
    
    // Lock everything
    }else{
        [[AppSettings sharedAppSettings] configSetValueFor:@"mode_configLocked" :@"TRUE"];

        // lock skeleton UI
        [self ui_lockSkeleton];
        
        // lock everything else
        [self ui_lockOther];
    }
}







// OSC ////////////////////////////////
- (void)setOscMessages:(NSMutableArray *)a{
    if (a == oscMessages) return;
    oscMessages = a;
}

- (IBAction)recieveOSC:(id)sender {
    
    //Checkbox OFF (no recieve)
    if ([ui_recieveOSC_checkbox state] == NSOffState){
        [ui_receiveOSC_port setEditable:TRUE];
        [ui_receiveOSC_port setTextColor:[NSColor controlTextColor]];
        [OSCmanagerObject deleteAllInputs];
        
    //Checkbox ON (receive)
    }else{
        
        // Bind the port
        if (([OSCmanagerObject createNewInputForPort:ui_sendOSC_port.intValue])){
            
            [ui_receiveOSC_port setEditable:FALSE];
            [ui_receiveOSC_port setTextColor:[NSColor secondarySelectedControlColor]];
            
            
        // Failed to bind               
        }else{
            // Uncheck and turn off
            [ui_recieveOSC_checkbox setState:NSOffState];
            [OSCmanagerObject deleteAllInputs];
            
            // Pop up an alert if it went wrong
            NSString *cancelButton = NSLocalizedString(@"Ok", 
                                                       @"Ok");
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"OSC Port Bind Error"];
            [alert setInformativeText:@"That port is already in use!"];
            [alert addButtonWithTitle:cancelButton];
            [alert runModal];
            [alert release];
            alert = nil;
        }
    }
}


// 1 second, used to loop sending of the OSC test message
- (IBAction)loopButton:(id)sender {
    if([ui_sendLoop_button state] == NSOnState){
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerOneSecond) userInfo:nil repeats:YES];
    }else{
        [timer invalidate];
    }
}
- (void) timerOneSecond{[self sendTestMsg:self];}



// The OSC library returns primative types, so we need to do a bit of work
// to get things in a usable format for us
- (NSString *)OSCDataAsString:(OSCValue *)messageValue{
    
    NSString *messageValueAsString=@"?";
    switch (messageValue.type)   {
            
            // Integer
        case OSCValInt:
            messageValueAsString = [NSString stringWithFormat:@"%i",messageValue.intValue];
            break;
            
            // Float
        case OSCValFloat:
            messageValueAsString = [NSString stringWithFormat:@"%f",messageValue.floatValue];
            break;
            
            // String
        case OSCValString:
            messageValueAsString = [NSString stringWithFormat:@"%@",messageValue.stringValue];
            break;
            
            // Unhandled types    
        case OSCValTimeTag:
        case OSCVal64Int:
        case OSCValDouble:
        case OSCValNil:
        case OSCValInfinity:
        case OSCValBlob:
        case OSCValBool:
        case OSCValMIDI:
        case OSCValColor:
        default:break;
    }
    
    return messageValueAsString;
}


// CALLBACK HANDLER: Incoming OSCMessage
- (void) receivedOSCMessage:(OSCMessage *)message{
    
    NSString *logMessage=@"";
    
    if (message.valueCount > 2){
        for (OSCValue *thisValue in message.valueArray) {
            logMessage = [NSString stringWithFormat:@"%@ %@",logMessage,[self OSCDataAsString:thisValue]]; 
        }
    }else {
        logMessage = [self OSCDataAsString:message.value];
    }
    
    NSArray *OSCMessage = [NSArray arrayWithObjects: message.address, logMessage, nil];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"OSCMessageReceived"
     object:self
     userInfo:[NSDictionary dictionaryWithObject:OSCMessage forKey:@"oscMessage"]];
}


// BUTTON: Send test message from OSCTool Panel
- (IBAction)sendTestMsg:(id)sender {

    // make an OSC message, obeying type from dropdown
    id newMsg = [OSCMessage createWithAddress:ui_sendOSC_address.stringValue];
    if ([ui_sendOSC_type.titleOfSelectedItem isEqualToString:@"float"] && ui_sendOSC_message.floatValue){
        [newMsg addFloat:ui_sendOSC_message.floatValue];    
    }else if ([ui_sendOSC_type.titleOfSelectedItem isEqualToString:@"integer"] && ui_sendOSC_message.intValue){      
        [newMsg addInt:ui_sendOSC_message.intValue];
    }else{
        [ui_sendOSC_type selectItemWithTitle:@"string"];
        [newMsg addString:ui_sendOSC_message.stringValue];            
    }
    
    // send the OSC message
    //NSLog(@"OSC: sent %@ '%@%@' on %@:%@ ", ui_sendOSC_type.titleOfSelectedItem, ui_sendOSC_address.stringValue,ui_sendOSC_message.stringValue,  ui_sendOSC_ip.stringValue, ui_sendOSC_port.stringValue);
    
    [ [OSCmanagerObject 
        createNewOutputToAddress:ui_sendOSC_ip.stringValue 
                          atPort:ui_sendOSC_port.intValue] 
                 sendThisMessage:newMsg];
}



// Status messages are strings prefixed with status
- (void) sendOutputViaOSC_status:(NSString *)message{
   
    if (ui_OSCaddressPartBody_checkbox.state == NSOnState){
        //OSCAddress=[ui_OSCaddressPartStatus"];
        //sendOSC=TRUE;
        //NSLog(@"STATUS %@",message);
    }
}



// Body part messages include user and coordinates
// FIX: a lot of the logic here uses the GUI, which should really use the data in memory instead
- (void) sendOutputViaOSC_bodyPart:(NSString *)messageType : (int)u: (float)x: (float)y: (float)z{

    if (OSCTransmitButton.state == NSOnState){
        NSString *OSCAddress =@"";
        BOOL sendOSC = FALSE;
        BOOL isRightHand=FALSE;
        
        if ([messageType isEqualToString: @"body"]){
            if (ui_OSCaddressPartBody_checkbox.state == NSOnState){
                //NSLog(@"sendbody");
                OSCAddress=ui_OSCaddressPartBody.stringValue;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"head"]){
            if(ui_OSCaddressPartHead_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartHead.stringValue;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"neck"]){
            if(ui_OSCaddressPartNeck_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartNeck.stringValue;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"torso"]){
            if(ui_OSCaddressPartTorso_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartTorso.stringValue;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"right_shoulder"]){
            if(ui_OSCaddressPartShoulder_checkbox.state == NSOnState && ui_OSCaddressPartRight_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartShoulder.stringValue;
                isRightHand=TRUE;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"right_elbow"]){
            if(ui_OSCaddressPartElbow_checkbox.state == NSOnState && ui_OSCaddressPartRight_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartElbow.stringValue;
                isRightHand=TRUE;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"right_hand"]){
            if(ui_OSCaddressPartHand_checkbox.state == NSOnState && ui_OSCaddressPartRight_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartHand.stringValue;
                isRightHand=TRUE;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"right_hip"]){
            if(ui_OSCaddressPartHip_checkbox.state == NSOnState && ui_OSCaddressPartRight_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartHip.stringValue;
                isRightHand=TRUE;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"right_knee"]){
            if(ui_OSCaddressPartKnee_checkbox.state == NSOnState && ui_OSCaddressPartRight_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartKnee.stringValue;
                isRightHand=TRUE;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"right_ankle"]){
            if(ui_OSCaddressPartAnkle_checkbox.state == NSOnState && ui_OSCaddressPartRight_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartAnkle.stringValue;
                isRightHand=TRUE;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"right_foot"]){
            if(ui_OSCaddressPartFoot_checkbox.state == NSOnState && ui_OSCaddressPartRight_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartFoot.stringValue;
                isRightHand=TRUE;
                sendOSC=TRUE;
            }
            
            
        } else if ([messageType isEqualToString: @"left_shoulder"]){
            if(ui_OSCaddressPartShoulder_checkbox.state == NSOnState && ui_OSCaddressPartLeft_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartShoulder.stringValue;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"left_elbow"]){
            if(ui_OSCaddressPartElbow_checkbox.state == NSOnState && ui_OSCaddressPartLeft_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartElbow.stringValue;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"left_hand"]){
            if(ui_OSCaddressPartHand_checkbox.state == NSOnState && ui_OSCaddressPartLeft_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartHand.stringValue;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"left_hip"]){
            if(ui_OSCaddressPartHip_checkbox.state == NSOnState && ui_OSCaddressPartLeft_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartHip.stringValue;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"left_knee"]){
            if(ui_OSCaddressPartKnee_checkbox.state == NSOnState && ui_OSCaddressPartLeft_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartKnee.stringValue;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"left_ankle"]){
            if(ui_OSCaddressPartAnkle_checkbox.state == NSOnState && ui_OSCaddressPartLeft_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartAnkle.stringValue;
                sendOSC=TRUE;
            }
            
        } else if ([messageType isEqualToString: @"left_foot"]){
            if(ui_OSCaddressPartFoot_checkbox.state == NSOnState && ui_OSCaddressPartLeft_checkbox.state == NSOnState){
                OSCAddress=ui_OSCaddressPartFoot.stringValue;
                sendOSC=TRUE;
            }
            
        } else {
            NSLog(@"I Don't know how to send messages of type %@",messageType);
        }
        
        
        // If we are actually sending the OSC
        if (sendOSC){
            if(isRightHand){
                OSCAddress = [OSCAddress stringByReplacingOccurrencesOfString:@"{side}" withString:ui_OSCaddressPartRight.stringValue];
            }else{
                OSCAddress = [OSCAddress stringByReplacingOccurrencesOfString:@"{side}" withString:ui_OSCaddressPartLeft.stringValue];
            }
            OSCAddress = [OSCAddress stringByReplacingOccurrencesOfString:@"{prefix}" withString:ui_OSCAddressPartPrefix.stringValue];
            OSCAddress = [OSCAddress stringByReplacingOccurrencesOfString:@"{localip}" withString:[[AppSettings sharedAppSettings] configGetValueFor:@"localIP"]]; 
            OSCAddress = [OSCAddress stringByReplacingOccurrencesOfString:@"{user}" withString:[NSString stringWithFormat:@"%i",u]];
                        
            //TODO: replace this lame hack with a regexp for multiple occurances of /
            //https://developer.apple.com/library/ios/#documentation/Foundation/Reference/NSRegularExpression_Class/Reference/Reference.html
            
            OSCAddress = [OSCAddress stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
            OSCAddress = [OSCAddress stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
            OSCAddress = [OSCAddress stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
            
            
            // Send via OSC (finally)
            id newMsg = [OSCMessage createWithAddress:OSCAddress];
            
            // Parse datapacket tokens
            NSString *dataPacket= ui_OSCDataPacketFormat.stringValue;
            dataPacket = [dataPacket stringByReplacingOccurrencesOfString:@" " withString:@""];
            dataPacket = [dataPacket stringByReplacingOccurrencesOfString:@"{" withString:@""];
            NSArray *tokens = [dataPacket componentsSeparatedByString: @"}"];
            for (id thisToken in tokens) {
                if ([thisToken isEqualToString:@"x"]){
                    // Projective X and Y coords go out as integers
                    if ([[[AppSettings sharedAppSettings] configGetValueFor:@"coordinateSystem"] isEqualToString:@"OPENNI Projective"]){
                        [newMsg addInt:x];
                    // Real world X and Y cooreds go out as float
                    }else {
                        [newMsg addFloat:x];
                    }
                }
                if ([thisToken isEqualToString:@"y"]){
                    // Projective X and Y coords go out as integers
                    if ([[[AppSettings sharedAppSettings] configGetValueFor:@"coordinateSystem"] isEqualToString:@"OPENNI Projective"]){
                        [newMsg addInt:y];
                    // Real world X and Y cooreds go out as float
                    }else {
                        [newMsg addFloat:y];
                    }
                }
                if ([thisToken isEqualToString:@"z"]){
                    // Z is always float
                    [newMsg addFloat:z];
                }
                if ([thisToken isEqualToString:@"user"]){
                    // User is integer
                    [newMsg addInt:u];
                }
                if ([thisToken isEqualToString:@"meaningoflife"]){
                    // User is integer
                    [newMsg addInt:42];
                }
            }
             

            
                        
            
            
            
            
            
            // Send 
            [OSCOutput sendThisMessage:newMsg];
            
            // Make indicator blink
            /*
            if (!g_led_animating){
                [NSThread detachNewThreadSelector:@selector(blinkLED) toTarget:self withObject:nil];
            }*/
            
        }
    }
    

             
}


// UI Helper functions turn things on and off

- (void) ui_lockOther{

    [lock_icon setImage:[NSImage imageNamed: NSImageNameLockLockedTemplate]];

    
    [OSCTransmitButton setEnabled:false];    
    [SkeletonTransmitButton setEnabled:false];
    [ui_sendOSC_ip setEditable:FALSE];
    [ui_sendOSC_ip setEnabled:FALSE];

    
    [ui_OSCAddressPartPrefix setEditable:FALSE];
    [ui_OSCDataPacketFormat setEditable:FALSE];
    [ui_OSCDataPacketFormat setBackgroundColor:[NSColor secondarySelectedControlColor]];
    [ui_OSCAddressPartPrefix setEnabled:FALSE];       
    [ui_OSCaddressPartBody setEditable:FALSE];
    [ui_OSCaddressPartBody_checkbox setEnabled:FALSE];
    
    [ui_OSCaddressPartBody setBackgroundColor:[NSColor secondarySelectedControlColor]];
    [ui_sendOSC_ip setBackgroundColor:[NSColor secondarySelectedControlColor]];
    
    [ui_sendOSC_port setBackgroundColor:[NSColor secondarySelectedControlColor]];
    
    [ui_OSCSendingDisplay setBackgroundColor:[NSColor secondarySelectedControlColor]];
    [ui_OSCAddressPartPrefix setBackgroundColor:[NSColor secondarySelectedControlColor]];
    
    
    [ui_coordinateUnits setEditable:FALSE];
    [ui_coordinateUnits setEnabled:FALSE];
    [ui_coordinateUnits setBackgroundColor:[NSColor secondarySelectedControlColor]];

    [ui_coordinateSystem setEditable:FALSE];
    [ui_coordinateSystem setEnabled:FALSE];
    [ui_coordinateSystem setBackgroundColor:[NSColor secondarySelectedControlColor]];

    
}

- (void) ui_unlockOther{

    [lock_icon setImage:[NSImage imageNamed: NSImageNameLockUnlockedTemplate]];
    
    [OSCToolView setHidden:FALSE];
    [OSCTransmitButton setEnabled:true];    
    [SkeletonTransmitButton setEnabled:true];
    [ui_sendOSC_ip setEditable:true];
    [ui_sendOSC_ip setEnabled:true];
  
 
    [ui_OSCAddressPartPrefix setEditable:true];
    [ui_OSCAddressPartPrefix setEnabled:true];
    [ui_OSCDataPacketFormat setEditable:true];
    [ui_OSCDataPacketFormat setBackgroundColor:[NSColor whiteColor]];
    [ui_OSCaddressPartBody setEditable:true];
    [ui_OSCaddressPartBody_checkbox setEnabled:true];
    
    [ui_OSCaddressPartBody setBackgroundColor:[NSColor whiteColor]];
    [ui_sendOSC_ip setBackgroundColor:[NSColor whiteColor]];
    [ui_sendOSC_port setBackgroundColor:[NSColor whiteColor]];
    
    [ui_OSCSendingDisplay setBackgroundColor:[NSColor whiteColor]];
    [ui_OSCAddressPartPrefix setBackgroundColor:[NSColor whiteColor]];
    
 
    [ui_coordinateUnits setEditable:true];
    [ui_coordinateUnits setEnabled:true];
    [ui_coordinateUnits setBackgroundColor:[NSColor whiteColor]];
    
    [ui_coordinateSystem setEditable:true];
    [ui_coordinateSystem setEnabled:true];
    [ui_coordinateSystem setBackgroundColor:[NSColor whiteColor]];

}


- (void) ui_lockSkeleton{
    [ui_OSCaddressPartLeft setEditable:FALSE];
    [ui_OSCaddressPartRight setEditable:FALSE];
    [ui_OSCaddressPartHead setEditable:FALSE];
    [ui_OSCaddressPartHead_checkbox setEnabled:FALSE];
    [ui_OSCaddressPartNeck setEditable:FALSE];

    [ui_OSCaddressPartLeft_checkbox setEnabled:FALSE];
    [ui_OSCaddressPartRight_checkbox setEnabled:FALSE];
    
    [ui_OSCaddressPartNeck_checkbox setEnabled:FALSE];
    [ui_OSCaddressPartTorso setEditable:FALSE];
    [ui_OSCaddressPartTorso_checkbox setEnabled:FALSE];
    [ui_OSCaddressPartShoulder setEditable:FALSE];
    [ui_OSCaddressPartShoulder_checkbox setEnabled:FALSE];
    [ui_OSCaddressPartElbow setEditable:FALSE];
    [ui_OSCaddressPartElbow_checkbox setEnabled:FALSE];
    [ui_OSCaddressPartHand setEditable:FALSE];
    [ui_OSCaddressPartHand_checkbox setEnabled:FALSE];
    [ui_OSCaddressPartHip setEditable:FALSE];
    [ui_OSCaddressPartHip_checkbox setEnabled:FALSE];
    [ui_OSCaddressPartKnee setEditable:FALSE];
    [ui_OSCaddressPartKnee_checkbox setEnabled:FALSE];
    [ui_OSCaddressPartAnkle setEditable:FALSE];
    [ui_OSCaddressPartAnkle_checkbox setEnabled:FALSE];
    [ui_OSCaddressPartFoot setEditable:FALSE];
    [ui_OSCaddressPartFoot_checkbox setEnabled:FALSE];
    
    [ui_OSCaddressPartLeft setBackgroundColor:[NSColor secondarySelectedControlColor]];
    [ui_OSCaddressPartRight setBackgroundColor:[NSColor secondarySelectedControlColor]];
    
    [ui_OSCaddressPartHead setBackgroundColor:[NSColor secondarySelectedControlColor]];
    [ui_OSCaddressPartNeck setBackgroundColor:[NSColor secondarySelectedControlColor]];
    [ui_OSCaddressPartTorso setBackgroundColor:[NSColor secondarySelectedControlColor]];
    [ui_OSCaddressPartShoulder setBackgroundColor:[NSColor secondarySelectedControlColor]];
    [ui_OSCaddressPartElbow setBackgroundColor:[NSColor secondarySelectedControlColor]];
    [ui_OSCaddressPartHand setBackgroundColor:[NSColor secondarySelectedControlColor]];
    [ui_OSCaddressPartHip setBackgroundColor:[NSColor secondarySelectedControlColor]];
    [ui_OSCaddressPartKnee setBackgroundColor:[NSColor secondarySelectedControlColor]];
    [ui_OSCaddressPartAnkle setBackgroundColor:[NSColor secondarySelectedControlColor]];
    [ui_OSCaddressPartFoot setBackgroundColor:[NSColor secondarySelectedControlColor]];
}

- (void) ui_unlockSkeleton{
    [ui_OSCaddressPartLeft setEditable:TRUE];
    [ui_OSCaddressPartRight setEditable:TRUE];
    [ui_OSCaddressPartHead setEditable:TRUE];
    [ui_OSCaddressPartHead_checkbox setEnabled:TRUE];
    [ui_OSCaddressPartNeck setEditable:TRUE];
    [ui_OSCaddressPartNeck_checkbox setEnabled:TRUE];
    [ui_OSCaddressPartLeft_checkbox setEnabled:TRUE];
    [ui_OSCaddressPartRight_checkbox setEnabled:TRUE];
    [ui_OSCaddressPartTorso setEditable:TRUE];
    [ui_OSCaddressPartTorso_checkbox setEnabled:TRUE];
    [ui_OSCaddressPartShoulder setEditable:TRUE];
    [ui_OSCaddressPartShoulder_checkbox setEnabled:TRUE];
    [ui_OSCaddressPartElbow setEditable:TRUE];
    [ui_OSCaddressPartElbow_checkbox setEnabled:TRUE];
    [ui_OSCaddressPartHand setEditable:TRUE];
    [ui_OSCaddressPartHand_checkbox setEnabled:TRUE];
    [ui_OSCaddressPartHip setEditable:TRUE];
    [ui_OSCaddressPartHip_checkbox setEnabled:TRUE];
    [ui_OSCaddressPartKnee setEditable:TRUE];
    [ui_OSCaddressPartKnee_checkbox setEnabled:TRUE];
    [ui_OSCaddressPartAnkle setEditable:TRUE];
    [ui_OSCaddressPartAnkle_checkbox setEnabled:TRUE];
    [ui_OSCaddressPartFoot setEditable:TRUE];
    [ui_OSCaddressPartFoot_checkbox setEnabled:TRUE];
    
    [ui_OSCaddressPartLeft setBackgroundColor:[NSColor whiteColor]];
    [ui_OSCaddressPartRight setBackgroundColor:[NSColor whiteColor]];
    
    [ui_OSCaddressPartHead setBackgroundColor:[NSColor whiteColor]];
    [ui_OSCaddressPartNeck setBackgroundColor:[NSColor whiteColor]];
    [ui_OSCaddressPartTorso setBackgroundColor:[NSColor whiteColor]];
    [ui_OSCaddressPartShoulder setBackgroundColor:[NSColor whiteColor]];
    [ui_OSCaddressPartElbow setBackgroundColor:[NSColor whiteColor]];
    [ui_OSCaddressPartHand setBackgroundColor:[NSColor whiteColor]];
    [ui_OSCaddressPartHip setBackgroundColor:[NSColor whiteColor]];
    [ui_OSCaddressPartKnee setBackgroundColor:[NSColor whiteColor]];
    [ui_OSCaddressPartAnkle setBackgroundColor:[NSColor whiteColor]];
    [ui_OSCaddressPartFoot setBackgroundColor:[NSColor whiteColor]];
}


// Update the config settings with the values from the UI
- (void) updateConfigFromUI{
    
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSC_ip" :ui_sendOSC_ip.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSC_port" :ui_sendOSC_port.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSC_address" :ui_OSCaddressPartFoot.stringValue];
    
     [[AppSettings sharedAppSettings] configSetValueFor:@"OSCDataPacketFormat" :ui_OSCDataPacketFormat.stringValue];
    
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCAddressPartPrefix" :ui_OSCAddressPartPrefix.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartLeft" :ui_OSCaddressPartLeft.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartRight" :ui_OSCaddressPartRight.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartBody" :ui_OSCaddressPartBody.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartBody_checkbox" :ui_OSCaddressPartBody_checkbox.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartHead" :ui_OSCaddressPartHead.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartHead_checkbox" :ui_OSCaddressPartHead_checkbox.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartNeck" :ui_OSCaddressPartNeck.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartNeck_checkbox" :ui_OSCaddressPartNeck_checkbox.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartTorso" :ui_OSCaddressPartTorso.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartTorso_checkbox" :ui_OSCaddressPartTorso_checkbox.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartShoulder" :ui_OSCaddressPartShoulder.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartShoulder_checkbox" :ui_OSCaddressPartShoulder_checkbox.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartElbow" :ui_OSCaddressPartElbow.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartElbow_checkbox" :ui_OSCaddressPartElbow_checkbox.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartHand" :ui_OSCaddressPartHand.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartHand_checkbox" :ui_OSCaddressPartHand_checkbox.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartHip" :ui_OSCaddressPartHip.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartHip_checkbox" :ui_OSCaddressPartHip_checkbox.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartKnee" :ui_OSCaddressPartKnee.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartKnee_checkbox" :ui_OSCaddressPartKnee_checkbox.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartAnkle" :ui_OSCaddressPartAnkle.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartAnkle_checkbox" :ui_OSCaddressPartAnkle_checkbox.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartFoot" :ui_OSCaddressPartFoot.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartFoot_checkbox" :ui_OSCaddressPartFoot_checkbox.stringValue];
    
    
    
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartLeft_checkbox" :ui_OSCaddressPartLeft_checkbox.stringValue];
    
    [[AppSettings sharedAppSettings] configSetValueFor:@"OSCaddressPartRight_checkbox" :ui_OSCaddressPartRight_checkbox.stringValue];
    
    [[AppSettings sharedAppSettings] configSetValueFor:@"coordinateSystem" :ui_coordinateSystem.stringValue];
    [[AppSettings sharedAppSettings] configSetValueFor:@"coordinateUnits" :ui_coordinateUnits.stringValue];    
    
    return;
}


// Update the UI with the values from the config
- (void) updateUIfromConfig{
    
    ui_sendOSC_ip.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSC_ip"];
    ui_sendOSC_port.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSC_port"];
    ui_OSCaddressPartFoot.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSC_address"];
    
    ui_OSCDataPacketFormat.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCDataPacketFormat"];
    
    ui_OSCAddressPartPrefix.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCAddressPartPrefix"];
    ui_OSCaddressPartLeft.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartLeft"];
    ui_OSCaddressPartRight.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartRight"];
    ui_OSCaddressPartBody.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartBody"];
    ui_OSCaddressPartBody_checkbox.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartBody_checkbox"];
    ui_OSCaddressPartHead.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartHead"];
    ui_OSCaddressPartHead_checkbox.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartHead_checkbox"];
    ui_OSCaddressPartNeck.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartNeck"];
    ui_OSCaddressPartNeck_checkbox.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartNeck_checkbox"];
    ui_OSCaddressPartTorso.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartTorso"];
    ui_OSCaddressPartTorso_checkbox.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartTorso_checkbox"];
    ui_OSCaddressPartShoulder.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartShoulder"];
    ui_OSCaddressPartShoulder_checkbox.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartShoulder_checkbox"];
    
    ui_OSCaddressPartElbow.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartElbow"];
    
    ui_OSCaddressPartElbow_checkbox.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartElbow_checkbox"];
    
    
    ui_OSCaddressPartHand.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartHand"];
    ui_OSCaddressPartHand_checkbox.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartHand_checkbox"];
    ui_OSCaddressPartHip.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartHip"];
    ui_OSCaddressPartHip_checkbox.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartHip_checkbox"];
    ui_OSCaddressPartKnee.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartKnee"];
    ui_OSCaddressPartKnee_checkbox.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartKnee_checkbox"];
    ui_OSCaddressPartAnkle.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartAnkle"];
    ui_OSCaddressPartAnkle_checkbox.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartAnkle_checkbox"];
    ui_OSCaddressPartFoot.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartFoot"];
    ui_OSCaddressPartFoot_checkbox.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartFoot_checkbox"];
    
    
    ui_OSCaddressPartLeft_checkbox.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartLeft_checkbox"];
    ui_OSCaddressPartRight_checkbox.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"OSCaddressPartRight_checkbox"];
    ui_coordinateSystem.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"coordinateSystem"];
    ui_coordinateUnits.stringValue = [[AppSettings sharedAppSettings] configGetValueFor:@"coordinateUnits"];
    
    return;
}




-(void)blinkLED{
    g_led_animating=true;
    
    OSC_Send_statusLight.image=[[NSImage alloc] initWithContentsOfFile: [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/led_green.png"]];
    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.25]];
    OSC_Send_statusLight.image=[[NSImage alloc] initWithContentsOfFile: [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/led_off.png"]];
    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.5]];

    g_led_animating=false;    
}



@end
