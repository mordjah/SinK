//
//  ConsoleLogItem.h
//  SINLAB OSC Utility
//
//  Created by Andrew Sempere on 5/18/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConsoleLogItem : NSObject{
    NSString *timeStamp;
    NSString *consoleLine;
}

@property (copy) NSString *timeStamp;
@property (copy) NSString *consoleLine;

@end
