//
//  MPDeviceDisconnectivityController.h
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 06/01/15.
//  Copyright (c) 2015 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPDeviceConfigurationViewController.h"

@interface MPDeviceDisconnectivityController : NSViewController
@property (nonatomic,weak) MPDeviceConfigurationViewController *configurationViewController;

- (void)playNext;
- (void)playPrevious;

@end
