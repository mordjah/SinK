//
//  AppSettings.mm
//  SinK
//
//  Created by Andrew Sempere on 6/10/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//


#import "AppSettings.h"
#import "CocoaOpenNI.h"

@implementation AppSettings
static AppSettings* _sharedAppSettings = nil;

NSDictionary *lt_SkeletonPartByID;
NSDictionary *lt_SkeletonPartByName;
NSMutableDictionary *appConfiguration;

+(AppSettings*)sharedAppSettings
{
	@synchronized([AppSettings class])
	{
		if (!_sharedAppSettings)
			_sharedAppSettings=[[self alloc] init];
		return _sharedAppSettings;
	}
    
	return nil;
}

+(id)alloc
{
	@synchronized([AppSettings class])
	{
		NSAssert(_sharedAppSettings == nil, @"Attempted to allocate a second instance of a singleton.");
		_sharedAppSettings = [super alloc];
		return _sharedAppSettings;
	}
    
	return nil;
}

-(id)init {
	self = [super init];
	if (self != nil) {

		////////////
       
        lt_SkeletonPartByID = [NSDictionary new];
        lt_SkeletonPartByName = [NSDictionary new];
        appConfiguration = [NSMutableDictionary new];
        
        // Skeleton lookup table
        NSArray *skeletonParts_name = [NSArray arrayWithObjects: 
                                              //@"body", 
                                              @"head",
                                              @"neck",
                                              @"torso",
                                              @"right_shoulder",
                                              @"right_elbow",
                                              @"right_hand",
                                              @"right_hip",
                                              @"right_knee",
                                              @"right_ankle",
                                              @"right_foot",
                                              @"left_shoulder",
                                              @"left_elbow",
                                              @"left_hand",
                                              @"left_hip",
                                              @"left_knee",
                                              @"left_ankle",
                                              @"left_foot",
                                              nil];
        
        NSArray *skeletonParts_id = [NSArray arrayWithObjects: 
                                            //[NSNumber numberWithInteger:XN_SKEL_TORSO],
                                            [NSNumber numberWithInteger:XN_SKEL_HEAD],
                                            [NSNumber numberWithInteger:XN_SKEL_NECK],
                                            [NSNumber numberWithInteger:XN_SKEL_TORSO],                                           
                                            [NSNumber numberWithInteger:XN_SKEL_RIGHT_SHOULDER],                                            
                                            [NSNumber numberWithInteger:XN_SKEL_RIGHT_ELBOW],                                           
                                            [NSNumber numberWithInteger:XN_SKEL_RIGHT_HAND],                                           
                                            [NSNumber numberWithInteger:XN_SKEL_RIGHT_HIP],                                            
                                            [NSNumber numberWithInteger:XN_SKEL_RIGHT_KNEE],                                            
                                            [NSNumber numberWithInteger:XN_SKEL_RIGHT_ANKLE],                                           
                                            [NSNumber numberWithInteger:XN_SKEL_RIGHT_FOOT],                                            
                                            [NSNumber numberWithInteger:XN_SKEL_LEFT_SHOULDER],                                           
                                            [NSNumber numberWithInteger:XN_SKEL_LEFT_ELBOW],                                            
                                            [NSNumber numberWithInteger:XN_SKEL_LEFT_HAND],                                          
                                            [NSNumber numberWithInteger:XN_SKEL_LEFT_HIP],                                            
                                            [NSNumber numberWithInteger:XN_SKEL_LEFT_KNEE],                                          
                                            [NSNumber numberWithInteger:XN_SKEL_LEFT_ANKLE],                                           
                                            [NSNumber numberWithInteger:XN_SKEL_LEFT_FOOT],                                  
                                            nil];
        
        lt_SkeletonPartByID = [[NSDictionary alloc] initWithObjects: skeletonParts_name forKeys: skeletonParts_id];
        lt_SkeletonPartByName = [[NSDictionary alloc] initWithObjects: skeletonParts_id  forKeys: skeletonParts_name];
        

        ////////////
	}
    
	return self;
}

// SKELETON lookup
-(NSString *)skeletonpartNameByID:(NSNumber *)partID{
    return [lt_SkeletonPartByID objectForKey:partID];
}

-(int)skeletonpartIDByname:(NSString *)partName{
    return [[lt_SkeletonPartByName objectForKey:partName] intValue];
}


// APP CONFIG functions
-(NSString *)configGetValueFor:(NSString *)thisKey{
    return [appConfiguration objectForKey:thisKey];    
}

-(void)configSetValueFor:(NSString *)thisKey : (NSString *)thisValue{
    [appConfiguration setObject: thisValue  forKey: thisKey];
}

// Write settings to disk
- (void)writeConfigToDisk{
    
    NSSavePanel *savePanel = [[NSSavePanel alloc] init];   
    [savePanel setNameFieldStringValue:@".conf"];

    if ([savePanel runModal] == NSOKButton){
        
        [[AppSettings sharedAppSettings] configSetValueFor:@"ConfigurationID" :[[savePanel URL] absoluteString]];
        
        NSData *xmlData = (NSData *)CFPropertyListCreateXMLData(kCFAllocatorDefault, (CFPropertyListRef)appConfiguration);
        if(xmlData){
            NSLog(@"No error creating XML data.");
            [xmlData writeToURL:[savePanel URL] atomically:YES];
        }else{
            NSLog(@"ERROR SAVING FILE");
        }
        
        [xmlData release];
    }

}

// Read default settings from disk
- (void)readDefaultConfigFromDisk{

    NSString *path = [[NSBundle mainBundle] pathForResource:@"DEFAULT" ofType:@"CONF"];
    NSMutableDictionary *incomingAppConfiguration = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    
    if (incomingAppConfiguration){
        NSArray *keys = [incomingAppConfiguration allKeys];
        for (NSString *key in keys){
            NSString *value = [incomingAppConfiguration objectForKey:key];
            [self configSetValueFor:key :value];
            [[AppSettings sharedAppSettings] configSetValueFor:@"f_forceReload" :@"TRUE"];
        }
    }
      
}

// Read settings from disk
- (void)readConfigFromDisk{
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
    if ([openPanel runModal] == NSOKButton){
        
        
        NSMutableDictionary *incomingAppConfiguration = [NSMutableDictionary dictionaryWithContentsOfURL:[openPanel URL]];
        
        if (incomingAppConfiguration){
            
            NSArray *keys = [incomingAppConfiguration allKeys];
            for (NSString *key in keys){
                NSString *value = [incomingAppConfiguration objectForKey:key];
                [self configSetValueFor:key :value];
                [[AppSettings sharedAppSettings] configSetValueFor:@"f_forceReload" :@"TRUE"];
            }

            
        }else{
            NSLog(@"ERROR: File invalid or something");
        }
    
        
    }
    return;
}






@end



