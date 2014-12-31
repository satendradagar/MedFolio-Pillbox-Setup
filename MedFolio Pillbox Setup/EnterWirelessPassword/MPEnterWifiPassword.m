//
//  MPEnterWifiPassword.m
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 21/12/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//
#define KSecurityModes @[@"OPEN",@"WEP",@"WPA1",@"MIXED",@"WPA2",@"Enterprise WEP",@"Enterprise WPA1",@"Enterprise WPA mixed",@"Enterprise WPA2",@"Enterprise NO security"]


#import "MPEnterWifiPassword.h"

@interface MPEnterWifiPassword ()
@property (weak) IBOutlet NSTextField *securityMode;

@end

@implementation MPEnterWifiPassword

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)setSelectedNetwork:(MPNetwork *)selectedNetwork
{
    _selectedNetwork = selectedNetwork;
    self.securityMode.stringValue = [self securityModeForSecurityCode:selectedNetwork.securityMode.integerValue];
    
    if (0 == selectedNetwork.securityMode.integerValue) {
        self.passwordField.stringValue = @"Password Not Required";
        self.configurationViewController.nextButton.enabled = YES;
        
    }
    else if (-1 == selectedNetwork.securityMode.integerValue){
        self.configurationViewController.nextButton.enabled = NO;

    }
    else if (1 <= selectedNetwork.securityMode.integerValue){
        self.configurationViewController.nextButton.enabled = YES;

    }
}
- (IBAction)didClickedNext:(id)sender{
    
}

- (NSString *)securityModeForSecurityCode:(NSUInteger)code
{
    return KSecurityModes[code];
}

@end
