//
//  MPScanSSIDController.m
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 20/12/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//
/*
 scan
 <4.00> (
 SCAN:Found 2
 01,11,-57,04,1100,1c,c0,(c8:b3:73:06:1a:6d,E9
 02,11,-55,00,0100,(00,00,c8:b3:73:06:1a:6f,E9-guest
 END:
 
 
 scannedNetworks	NSArray *	@"2 objects"	0x00006000000545b0
 [0]	MPNetwork *	0x600000092980	0x0000600000092980
 NSObject	NSObject
 _index	NSString *	@"01"	0x0000600000035000
 _channel	NSString *	@"11"	0x00007fff7a7fbb80
 _rssi	NSString *	@"-57"	0x0000600000035060
 _securityMode	NSString *	@"04"	0x0000600000034ec0
 _capabilities	NSString *	@"1100"	0x0000600000034fc0
 _wpaConfiguration	NSString *	@"1c"	0x0000600000034ea0
 _wpsMode	NSString *	@"c0"	0x0000600000035240
 _macAddress	NSString *	@"(c8:b3:73:06:1a:6d"	0x0000600000054760
 _ssid	NSString *	@"E9"	0x0000600000035220
 [1]	MPNetwork *	0x600000093100	0x0000600000093100
 NSObject	NSObject
 _index	NSString *	@"02"	0x0000600000034fe0
 _channel	NSString *	@"11"	0x00007fff7a7fbb80
 _rssi	NSString *	@"-55"	0x0000600000035180
 _securityMode	NSString *	@"00"	0x0000600000032c20
 _capabilities	NSString *	@"0100"	0x0000600000035d00
 _wpaConfiguration	NSString *	@"(00"	0x0000600000032dc0
 _wpsMode	NSString *	@"00"	0x0000600000038020
 _macAddress	NSString *	@"c8:b3:73:06:1a:6f"	0x00006000000555a0
 _ssid	NSString *	@"E9-guest"	0x0000600000035d20
 */

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
    self.configurationViewController.nextButton.enabled = NO;

//    [self userCalledRefreshSSID:nil];
//    [self performSelector:@selector(userCalledRefreshSSID:) withObject:nil afterDelay:5.0];
//    [_ssidPopupMenu removeAllItems];
//    [_ssidPopupMenu addItemWithTitle:@"E9"];
//    [_ssidPopupMenu addItemWithTitle:@"E9 second"];
    // Do view setup here.
}

- (IBAction)userChangedSSID:(id)sender {
    NSUInteger selectedIndex = [self.ssidPopupMenu indexOfSelectedItem];
    if (-1 != selectedIndex) {
        self.configurationViewController.nextButton.enabled = YES;
    }
    else{
        self.configurationViewController.nextButton.enabled = NO;
    }

}

- (IBAction)userCalledRefreshSSID:(id)sender {
    
    [self.ssidPopupMenu setEnabled:NO];
    [self.configurationViewController didTappedSendScanCommand:sender];
//    [[MPDeviceCommunication sharedInstance] writeCommandMessage:@"scan\r"];
}

- (void)controllerReceivedScanMessage:(NSString *)scannerDetails
{
    NSLog(@"controllerReceivedScanMessage: %@",scannerDetails);
    [self.ssidPopupMenu removeAllItems];
    [self.ssidPopupMenu setEnabled:YES];
    NSError *error = nil;
    scannedNetworks = [MPScanResultParser networkObjectsFromScanResult:scannerDetails errorReceived:&error];
    NSLog(@"scannedNetworks = %lu",(unsigned long)scannedNetworks.count);
    for (MPNetwork *scannedNetwork in scannedNetworks) {
        NSLog(@"added Menu: %@",scannedNetwork.ssid);
        [_ssidPopupMenu addItemWithTitle:scannedNetwork.ssid];
    }
    if (scannedNetworks.count) {
        self.configurationViewController.nextButton.enabled = YES;

    }
    //update popupbutton items
}

- (IBAction)didClickedNext:(id)sender{
    
}
- (MPNetwork *)selectedNetwork
{
    NSUInteger selectedIndex = [self.ssidPopupMenu indexOfSelectedItem];
    if (-1 != selectedIndex) {
        return [scannedNetworks objectAtIndex:selectedIndex];
    }
    return nil;
}

@end
