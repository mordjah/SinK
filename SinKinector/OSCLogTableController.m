//
//  OSCLogTableController.m
//  SINLAB OSC Utility
//
//  Created by Andrew Sempere on 5/18/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import "OSCLogTableController.h"
#import "OSCLogItem.h"

@implementation OSCLogTableController

-(id)init{
    self = [super init];
    if (self){
        OSCLogArray = [[NSMutableArray alloc] init];
    }
    
    // NC listen for OSC messages
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(handleNotifications:)
               name:@"OSCMessageReceived"
             object:nil];
    
    return self;
}


// NOTIFICATION HANDLER Handle incoming OSC Messages 
- (void) handleNotifications:(NSNotification *)notification{
    
    if ([[notification name] isEqualToString:@"OSCMessageReceived"]){
        
        NSArray *logItem = [[notification userInfo] objectForKey:@"oscMessage"];
        NSString *logAddress = [logItem objectAtIndex:0];
        NSString *logData = [logItem objectAtIndex:1];
        
        id newLogEntry = [[OSCLogItem alloc]init];
        [newLogEntry setOscAddress:logAddress];
        [newLogEntry setOscData:logData];
        
        [OSCLogArray addObject:newLogEntry];
        [tableView reloadData];
        [newLogEntry release];
         
    }
}



// Clear the log
- (IBAction)clear:(id)sender{
    [OSCLogArray removeAllObjects];
    [tableView reloadData];
}


// These two function constitute the (minimal) interface for table views
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableview{
    return [OSCLogArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    OSCLogItem *i = [OSCLogArray objectAtIndex:row];
    NSString *identifier = [tableColumn identifier];
    return [i valueForKey:identifier];
}


@end
