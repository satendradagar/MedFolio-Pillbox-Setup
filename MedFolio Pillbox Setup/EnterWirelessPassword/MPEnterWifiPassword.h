//
//  MPEnterWifiPassword.h
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 21/12/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPNetwork.h"
#import "MPDeviceConfigurationViewController.h"

@interface MPEnterWifiPassword : NSViewController

@property (nonatomic, retain) MPNetwork *selectedNetwork;
@property (nonatomic)  MPDeviceConfigurationViewController *configurationViewController;
@property (weak) IBOutlet NSTextField *passwordField;
@property (nonatomic, retain) NSString *passwordString;
- (IBAction)didClickedNext:(id)sender;

@end
