//
//  MPScanSSIDController.m
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 20/12/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import "MPScanSSIDController.h"
#import "MPDeviceCommunication.h"
#import "MPScanResultParser.h"
#import "MPNetwork.h"

@interface MPScanSSIDController ()
{
    NSArray *scannedNetworks;
    
}

@property (weak) IBOutlet NSPopUpButton *ssidPopupMenu;
- (IBAction)userChangedSSID:(id)sender;
- (IBAction)userCalledRefreshSSID:(id)sender;

@end

@implementation MPScanSSIDController

- (void)awakeFromNib {
    [super awakeFromNib];
    [self userCalledRefreshSSID:nil];
//    [_ssidPopupMenu removeAllItems];
//    [_ssidPopupMenu addItemWithTitle:@"E9"];
//    [_ssidPopupMenu addItemWithTitle:@"E9 second"];
    // Do view setup here.
}

- (IBAction)userChangedSSID:(id)sender {
    
}

- (IBAction)userCalledRefreshSSID:(id)sender {
    
    [self.ssidPopupMenu setEnabled:NO];
    [[MPDeviceCommunication sharedInstance] writeCommandMessage:@"scan\r"];
}

- (void)controllerReceivedScanMessage:(NSString *)scannerDetails
{
    [self.ssidPopupMenu setEnabled:YES];
    NSError *error = nil;
    scannedNetworks = [MPScanResultParser networkObjectsFromScanResult:scannerDetails errorReceived:&error];
    //update popupbutton items
}
@end
