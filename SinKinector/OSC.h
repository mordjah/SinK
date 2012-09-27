//
//  OSC.h
//  SinK
//
//  Created by Andrew Sempere on 6/10/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VVOSC/VVOSC.h>

@interface OSC : NSObject

@property (retain)    IBOutlet NSTextField        *ui_OSCSendingDisplay;
@property (retain)    IBOutlet NSButtonCell       *ui_recieveOSC_checkbox;
@property (retain)    IBOutlet NSTextField        *ui_receiveOSC_port;
@property (retain)    IBOutlet NSButton           *ui_sendLoop_button;

@property (retain)    IBOutlet NSTextField        *ui_sendOSC_address;
@property (retain)    IBOutlet NSTextField        *ui_sendOSC_message;
@property (retain)    IBOutlet NSPopUpButton      *ui_sendOSC_type;
@property (retain)    IBOutlet NSButton           *ui_send_button;
@property (retain)    IBOutlet NSTextField        *ui_sendOSC_ip;
@property (retain)    IBOutlet NSTextField        *ui_sendOSC_port;

@property (assign)    IBOutlet NSComboBox         *ui_OSCAddressPartPrefix;

@property (retain)    IBOutlet NSTextField        *ui_OSCaddressPartDataPacket;

@property (retain)    IBOutlet NSTextField        *ui_OSCaddressPartLeft;
@property (retain)    IBOutlet NSTextField        *ui_OSCaddressPartRight;
@property (retain)    IBOutlet NSTextField        *ui_OSCaddressPartBody;
@property (retain)    IBOutlet NSButtonCell       *ui_OSCaddressPartBody_checkbox;
@property (retain)    IBOutlet NSTextField        *ui_OSCaddressPartHead;
@property (retain)    IBOutlet NSButtonCell       *ui_OSCaddressPartHead_checkbox;
@property (retain)    IBOutlet NSTextField        *ui_OSCaddressPartNeck;
@property (retain)    IBOutlet NSButtonCell       *ui_OSCaddressPartNeck_checkbox;
@property (retain)    IBOutlet NSTextField        *ui_OSCaddressPartTorso;
@property (retain)    IBOutlet NSButtonCell       *ui_OSCaddressPartTorso_checkbox;
@property (retain)    IBOutlet NSTextField        *ui_OSCaddressPartShoulder;
@property (retain)    IBOutlet NSButtonCell       *ui_OSCaddressPartShoulder_checkbox;
@property (retain)    IBOutlet NSTextField        *ui_OSCaddressPartElbow;
@property (retain)    IBOutlet NSButtonCell       *ui_OSCaddressPartElbow_checkbox;
@property (retain)    IBOutlet NSTextField        *ui_OSCaddressPartHand;
@property (retain)    IBOutlet NSButtonCell       *ui_OSCaddressPartHand_checkbox;
@property (retain)    IBOutlet NSTextField        *ui_OSCaddressPartHip;
@property (retain)    IBOutlet NSButtonCell       *ui_OSCaddressPartHip_checkbox;
@property (retain)    IBOutlet NSTextField        *ui_OSCaddressPartKnee;
@property (retain)    IBOutlet NSButtonCell       *ui_OSCaddressPartKnee_checkbox;
@property (retain)    IBOutlet NSTextField        *ui_OSCaddressPartAnkle;
@property (retain)    IBOutlet NSButtonCell       *ui_OSCaddressPartAnkle_checkbox;
@property (retain)    IBOutlet NSTextField        *ui_OSCaddressPartFoot;
@property (retain)    IBOutlet NSButtonCell       *ui_OSCaddressPartFoot_checkbox;

@property (assign) IBOutlet NSTextFieldCell *ui_OSCDataPacketFormat;

@property (assign) IBOutlet NSButtonCell *ui_OSCaddressPartRight_checkbox;
@property (assign) IBOutlet NSButton *ui_OSCaddressPartLeft_checkbox;
@property (assign) IBOutlet NSComboBox *ui_coordinateSystem;
@property (assign) IBOutlet NSComboBox *ui_coordinateUnits;

@property (assign) IBOutlet NSView *OSCToolView;
@property (assign) IBOutlet NSTabView *ui_tabSwitch;
@property (assign) IBOutlet NSButton *SkeletonTransmitButton;
@property (assign) IBOutlet NSTextFieldCell *SkeletonTransmitStatus;

@property (assign) IBOutlet NSButton *OSCTransmitButton;
@property (assign) IBOutlet NSTextFieldCell *OSCTransmitStatus;
@property (assign) IBOutlet NSWindow *windowOSC;

@property (assign) IBOutlet NSImageCell *lock_icon;

@property (assign) IBOutlet NSImageCell *OSC_Send_statusLight;

- (void) sendOutputViaOSC_status:(NSString *)message;
- (void) sendOutputViaOSC_bodyPart:(NSString *)messageType : (int)u: (float)x: (float)y: (float)z;
- (void) refreshSettings;
- (void) updateUIfromConfig;
@end
