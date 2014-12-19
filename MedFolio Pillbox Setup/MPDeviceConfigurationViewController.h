//
//  MPDeviceConfigurationViewController.h
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 30/11/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPDeviceCommunication.h"

@interface MPDeviceConfigurationViewController : NSViewController<MPDeviceCommunicationDelegate>
- (IBAction)didTappedConnect:(id)sender;
- (IBAction)didTappedSendMsg:(id)sender;
- (IBAction)didTappedReadMessage:(id)sender;

@end
