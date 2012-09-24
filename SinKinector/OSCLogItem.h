//
//  OSCLogItem.h
//  SINLAB OSC Utility
//
//  Created by Andrew Sempere on 5/18/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSCLogItem : NSObject{
    NSString *timeStamp;
    NSString *oscData;
    NSString *oscAddress;
    //int port;
    
}

@property (copy) NSString *timeStamp;
@property (copy) NSString *oscData;
@property (copy) NSString *oscAddress;
//@property int port;

@end
