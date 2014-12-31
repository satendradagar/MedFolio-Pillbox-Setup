//
//  MPScanSSIDController.h
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 20/12/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPDeviceConfigurationViewController.h"
#import "MPNetwork.h"

@interface MPScanSSIDController : NSViewController
- (void)controllerReceivedScanMessage:(NSString *)scannerDetails;
@property (nonatomic)  MPDeviceConfigurationViewController *configurationViewController;
- (IBAction)didClickedNext:(id)sender;
- (MPNetwork *)selectedNetwork;

@end
