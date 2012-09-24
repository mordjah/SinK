//
//  ConsoleLogTableController.m
//  SINLAB OSC Utility
//
//  Created by Andrew Sempere on 5/18/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import "ConsoleLogTableController.h"
#import "ConsoleLogItem.h"
#import "OSC.h"

@implementation ConsoleLogTableController

bool mode_Paused = FALSE;

-(id)init{
    self = [super init];
    if (self){
        ConsoleLogArray = [[NSMutableArray alloc] init];
    }
    
    // NC listen for Console messages
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(handleNotifications:)
               name:@"ConsoleMessageReceived"
             object:nil];
    
    return self;
}


// NOTIFICATION HANDLER Handle incoming Messages 
- (void) handleNotifications:(NSNotification *)notification{
    // STATUS UPDATE: Update the status bar 
    if (!mode_Paused && [[notification name] isEqualToString: @"ConsoleMessageReceived"]){
        //NSLog(@"%@",[[notification userInfo] objectForKey:@"statusString"]);
        //[_statusBar setStringValue:[[notification userInfo] objectForKey:@"statusString"]];
        id newLogEntry = [[ConsoleLogItem alloc]init];
        [newLogEntry setConsoleLine:[[notification userInfo] objectForKey:@"statusString"]];
        [ConsoleLogArray addObject:newLogEntry];
        [tableView reloadData];
        [newLogEntry release];
    }
}

// Pause the log
- (IBAction)pause:(id)sender{
    mode_Paused = !mode_Paused;
}

// Clear the log
- (IBAction)clear:(id)sender{
    [ConsoleLogArray removeAllObjects];
    [tableView reloadData];
}



// These two function constitute the (minimal) interface for table views
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableview{
    return [ConsoleLogArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    ConsoleLogItem *i = [ConsoleLogArray objectAtIndex:row];
    NSString *identifier = [tableColumn identifier];
    return [i valueForKey:identifier];
}


@end
