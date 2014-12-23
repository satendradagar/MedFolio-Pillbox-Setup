//
//  MPNetwork.h
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 23/12/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPNetwork : NSObject

@property (nonatomic,retain) NSString *index;
@property (nonatomic,retain) NSString *channel;
@property (nonatomic,retain) NSString *rssi;
@property (nonatomic,retain) NSString *securityMode;
@property (nonatomic,retain) NSString *capabilities;
@property (nonatomic,retain) NSString *wpaConfiguration;
@property (nonatomic,retain) NSString *wpsMode;
@property (nonatomic,retain) NSString *macAddress;
@property (nonatomic,retain) NSString *ssid;

@end
