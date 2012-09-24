//
//  NotificationCenterWrapper.h
//  SinK
//
//  Created by Andrew Sempere on 6/9/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NotificationCenterWrapper : NSObject

+ (void) postNotification_status:(NSString *)       statusUpdate;
+ (void) postNotification_OSC:(NSString *)          statusUpdate;
+ (void) postNotification_statusAndOSC:(NSString *) statusUpdate;

@end
