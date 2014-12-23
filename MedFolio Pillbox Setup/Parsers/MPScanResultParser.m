//
//  MPScanResultParser.m
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 23/12/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import "MPScanResultParser.h"

#define NETWORKS_SEPERATOR @"\n"
#define NETWORK_COMPONENT_SEPERATOR @","

@implementation MPScanResultParser

+ (NSArray *) networkObjectsFromScanResult:(NSString *)result errorReceived:(NSError **)error
{
    /*
     SCAN:Found 3
     01,01,-59,04,1104,28,c0,20:4e:7f:08:df:85,dad-rules
     02,03,-64,02,1104,28,00,00:30:bd:9b:49:22,basement
     03,10,-71,04,3100,28,00,90:27:e4:5d:fc:a7,URSOMONEY
     END:
     */
    NSArray *outputComponents = [result componentsSeparatedByString:NETWORKS_SEPERATOR];
    if (outputComponents.count > 2) {
        NSMutableArray *availableNetworks = [[NSMutableArray alloc] init];
        NSUInteger totalNetworks = outputComponents.count - 1;
        for (int i = 1; i< totalNetworks; i++) {
            NSString *networkComponentString = outputComponents[i];
            NSArray *networkComponentArray = [networkComponentString componentsSeparatedByString:NETWORK_COMPONENT_SEPERATOR];
            if (networkComponentArray.count == 9) {
                MPNetwork *network = [[MPNetwork alloc]init];
                network.index = networkComponentArray[0];
                network.channel = networkComponentArray[1];
                network.rssi = networkComponentArray[2];
                network.securityMode = networkComponentArray[3];
                network.capabilities = networkComponentArray[4];
                network.wpaConfiguration = networkComponentArray[5];
                network.wpsMode = networkComponentArray[6];
                network.macAddress = networkComponentArray[7];
                network.ssid = networkComponentArray[8];
                [availableNetworks addObject:network];
            }
        }
        return availableNetworks;
    }
    else
    {
        *error = [NSError errorWithDomain:@"No network found, Please retry later." code:12 userInfo:nil];
    }

    return nil;
}

@end
