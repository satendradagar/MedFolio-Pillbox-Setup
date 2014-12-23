//
//  MPDeviceCommand.h
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 19/12/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPDeviceCommand : NSObject

@property (nonatomic, retain) NSString *sendCommand;
@property (nonatomic, retain) NSString *expectedOutput;
@property (nonatomic, retain) NSString *secondaryExpectedOutput;

- (instancetype)initWithCommand:(NSString *)command andExpectedOutput:(NSString *)output;

@end
