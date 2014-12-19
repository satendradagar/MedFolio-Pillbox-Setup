//
//  MPDeviceCommand.m
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 19/12/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import "MPDeviceCommand.h"

@implementation MPDeviceCommand

- (instancetype)initWithCommand:(NSString *)command andExpectedOutput:(NSString *)output
{
    self = [super init];
    if (self) {
        self.sendCommand = command;
        self.expectedOutput = output;
    }
    return self;
}

@end
