//
//  NotificationCenterWrapper.m
//  SinK
//
//  Created by Andrew Sempere on 6/9/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import "NotificationCenterWrapper.h"

@implementation NotificationCenterWrapper

+ (void) postNotification_status:(NSString *) statusMessage{

    [[NSNotificationCenter defaultCenter] 
     postNotificationName: @"StatusUpdateRecieved"
     object: self
     userInfo:[NSDictionary dictionaryWithObject:statusMessage forKey:@"statusString"]];    
}


+ (void) postNotification_OSC:(NSString *) message{
    [[NSNotificationCenter defaultCenter] 
     postNotificationName: @"OSCSendThisString"
     object: self
     userInfo:[NSDictionary dictionaryWithObject:message forKey:@"oscString"]];    

}

+ (void) postNotification_statusAndOSC:(NSString *) message{
    
    [[NSNotificationCenter defaultCenter] 
     postNotificationName: @"StatusUpdateRecieved"
     object: self
     userInfo:[NSDictionary dictionaryWithObject:message forKey:@"statusString"]];    

    [[NSNotificationCenter defaultCenter] 
     postNotificationName: @"OSCSendThisString"
     object: self
     userInfo:[NSDictionary dictionaryWithObject:message forKey:@"oscString"]];  
}

@end
