//
//  AppSettings.h
//  SinK
//
//  Created by Andrew Sempere on 6/10/12.
//  Copyright (c) 2012 SinLab / EPFL. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface AppSettings : NSObject
    
    +(AppSettings*)sharedAppSettings;

    -(NSString *)skeletonpartNameByID:(NSNumber *)partID;

    -(int)skeletonpartIDByname:(NSString *)partName;

    -(NSString *)configGetValueFor:(NSString *)thisKey;

    -(void)configSetValueFor:(NSString *)thisKey : (NSString *)thisValue;

    -(void)writeConfigToDisk;

    -(void)readConfigFromDisk;

    -(void)readDefaultConfigFromDisk;


@end
