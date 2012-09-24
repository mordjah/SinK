//
//  OSCLogItem.m
//  SINLAB OSC Utility
//
//  Created by Andrew Sempere on 5/18/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import "OSCLogItem.h"

@implementation OSCLogItem

-(id)init{
    self = [super init];
    if (self){
        
        /*
         NSDate *today = [NSDate date];
         NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
         [dateFormat setDateFormat:@"ss hh:mm a MM/dd/YYYY"];
         NSString *dateString = [dateFormat stringFromDate:today];
         timeStamp=dateString;
         */
        
        oscAddress = @"address";
        oscData = @"data";
        timeStamp=@"";
    }
    return self;
}

@synthesize oscAddress;
@synthesize oscData;
@synthesize timeStamp;

@end
