//
//  OSCLogTableController.h
//  SINLAB OSC Utility
//
//  Created by Andrew Sempere on 5/18/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <VVOSC/VVOSC.h>

@interface OSCLogTableController : NSObject{
    NSMutableArray *OSCLogArray;
    IBOutlet NSTableView *tableView;
}



@end
