//
//  MPScanResultParser.h
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 23/12/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPNetwork.h"

#define NO_SSID_FOUND 12
#define WEP_NOT_SUPPORTED 13

@interface MPScanResultParser : NSObject

+ (NSArray *) networkObjectsFromScanResult:(NSString *)result errorReceived:(NSError **)error;
@end
