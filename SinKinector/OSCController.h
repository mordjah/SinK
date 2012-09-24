//
//  OSCController.h
//  SinK
//
//  Created by Andrew Sempere on 6/10/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VVOSC/VVOSC.h>

@interface OSCController : NSObject{
    //OSC
    OSCManager					*OSCmanagerObject;
    OSCInPort					*recieveOSC_port;
    OSCOutPort					*sendOSC_port;	

    IBOutlet NSTextField		*ui_sendOSC_ip;
    IBOutlet NSTextField		*ui_sendOSC_port;
    IBOutlet NSTextField		*ui_sendOSC_address;
    IBOutlet NSTextField		*ui_sendOSC_message;
    IBOutlet NSPopUpButton      *ui_sendOSC_type;

    IBOutlet NSButtonCell       *ui_recieveOSC_checkbox;
    IBOutlet NSTextField		*ui_receiveOSC_port;

    // OSC Output config
    IBOutlet NSTextField        *ui_OSCaddressPartID;
    IBOutlet NSTextField        *ui_OSCaddressPartPrefix;
    IBOutlet NSTextField        *ui_OSCaddressPartUser;
    IBOutlet NSTextField        *ui_OSCaddressPartStatus;
    IBOutlet NSButtonCell       *ui_OSCaddressPartStatus_checkbox;
    IBOutlet NSTextField        *ui_OSCaddressPartLeft;
    IBOutlet NSTextField        *ui_OSCaddressPartRight;

    IBOutlet NSTextField        *ui_OSCaddressPartBody;
    IBOutlet NSButtonCell       *ui_OSCaddressPartBody_checkbox;
    IBOutlet NSTextField        *ui_OSCaddressPartHead;
    IBOutlet NSButtonCell       *ui_OSCaddressPartHead_checkbox;
    IBOutlet NSTextField        *ui_OSCaddressPartNeck;
    IBOutlet NSButtonCell       *ui_OSCaddressPartNeck_checkbox;
    IBOutlet NSTextField        *ui_OSCaddressPartTorso;
    IBOutlet NSButtonCell       *ui_OSCaddressPartTorso_checkbox;
    IBOutlet NSTextField        *ui_OSCaddressPartShoulder;
    IBOutlet NSButtonCell       *ui_OSCaddressPartShoulder_checkbox;
    IBOutlet NSTextField        *ui_OSCaddressPartElbow;
    IBOutlet NSButtonCell       *ui_OSCaddressPartElbow_checkbox;
    IBOutlet NSTextField        *ui_OSCaddressPartHand;
    IBOutlet NSButtonCell       *ui_OSCaddressPartHand_checkbox;
    IBOutlet NSTextField        *ui_OSCaddressPartHip;
    IBOutlet NSButtonCell       *ui_OSCaddressPartHip_checkbox;
    IBOutlet NSTextField        *ui_OSCaddressPartKnee;
    IBOutlet NSButtonCell       *ui_OSCaddressPartKnee_checkbox;
    IBOutlet NSTextField        *ui_OSCaddressPartAnkle;
    IBOutlet NSButtonCell       *ui_OSCaddressPartAnkle_checkbox;
    IBOutlet NSTextField        *ui_OSCaddressPartFoot;
    IBOutlet NSButtonCell       *ui_OSCaddressPartFoot_checkbox;

    IBOutlet NSButton           *ui_sendOSC_button;
    IBOutlet NSView             *ui_OSCaddressExample;
    
     NSMutableArray              *oscMessages;
}

@end
