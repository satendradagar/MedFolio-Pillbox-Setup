//
//  MPScanSSIDController.h
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 20/12/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MPScanSSIDController : NSViewController
- (void)controllerReceivedScanMessage:(NSString *)scannerDetails;

@end
