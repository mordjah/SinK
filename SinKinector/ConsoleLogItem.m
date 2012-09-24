//
//  ConsoleLogItem.m
//  SINLAB OSC Utility
//
//  Created by Andrew Sempere on 5/18/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import "ConsoleLogItem.h"

@implementation ConsoleLogItem

-(id)init{
    self = [super init];
    
    if (self){
        
        /*
        NSDate *today = [[NSDate date] retain];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        //[dateFormat setDateFormat:@"ss hh:mm a MM/dd/YYYY"];
        [dateFormat setDateFormat:@"hh:mm:ss"];
        NSString *dateString = [[dateFormat stringFromDate:today] retain];
        timeStamp=dateString;
        */
        
        timeStamp=@"";
        consoleLine = @"";

        
    }
    return self;
}

@synthesize consoleLine;
@synthesize timeStamp;

@end
