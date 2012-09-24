//
//  EnvironmentController.m
//  SinK
//
//  Created by Andrew Sempere on 9/1/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//

#import "EnvironmentController.h"

@implementation EnvironmentController
@synthesize woof;

// Init
-(id)init{

    self = [super init];
        return self;
    
}


// AUTOMATIC: When UI is Loaded
- (void)awakeFromNib{

    NSString *filePath = @"/System/Library/Screen Savers/Spectrum.qtz";

    NSLog(@"Loading QZ:%@",filePath);
    [woof loadCompositionFromFile:filePath];
}

@end
