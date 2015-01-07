//
//  MPEnterWifiPassword.m
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 21/12/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//
#define KSecurityModes @[@"OPEN",@"WEP",@"WPA1",@"MIXED",@"WPA2",@"Enterprise WEP",@"Enterprise WPA1",@"Enterprise WPA mixed",@"Enterprise WPA2",@"Enterprise NO security"]


#import "MPEnterWifiPassword.h"

@interface MPEnterWifiPassword ()<NSTextFieldDelegate>
@property (weak) IBOutlet NSTextField *securityMode;
- (IBAction)userDidClickedOnPassword:(NSSecureTextField *)sender;

@end

@implementation MPEnterWifiPassword

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do view setup here.
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.passwordField.delegate = self;
    [self.passwordField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.5];
    self.passwordField.nextResponder = self.configurationViewController.nextButton;
//    [[NSApp mainWindow] performSelector:@selector(makeFirstResponder:) withObject:self.passwordField afterDelay:0.5];

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

- (void)controlTextDidChange:(NSNotification *)notification {
    self.passwordString = [notification.object stringValue];
    // there was a text change in some control
}

- (IBAction)userDidClickedOnPassword:(NSSecureTextField *)sender {
//    if (sender.stringValue.length) {
//        [self.configurationViewController.nextButton becomeFirstResponder];
//    }
}
@end
