//
//  MPDeviceConfigurationViewController.m
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 30/11/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import "MPDeviceConfigurationViewController.h"
#import "MPDeviceCommand.h"
#import "MPScanSSIDController.h"
#import "MPConnectivityController.h"

@interface MPDeviceConfigurationViewController ()
{
    NSArray *deviceCommands;
    NSUInteger executingCommandIndex;
    BOOL isAutoPilotMode;
    MPScanSSIDController *scanSsidController;
    MPConnectivityController *connectivityController;
    NSMutableString *completeCommandOutput;
}

@property (nonatomic, weak) IBOutlet NSView *mainContentView;
@property (weak) IBOutlet NSTextField *connectivityMessage;
@property (weak) IBOutlet NSTextField *pipeReadWriteError;
@property (weak) IBOutlet NSTextField *pipeReadWriteMessage;
@property (weak) IBOutlet NSTextField *setupMessages;
@property (weak) IBOutlet NSTextField *commandTextField;
- (IBAction)sendCommandToDevice:(id)sender;
- (IBAction)startAutoPilotMode:(id)sender;

@end

@implementation MPDeviceConfigurationViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    
    
    MPDeviceCommunication *deviceComm = [MPDeviceCommunication sharedInstance];

//    deviceComm.deviceProductId = 11894;
//    deviceComm.deviceVendorId = 8888;//Motorola
//    deviceComm.deviceProductId = 5131;
//    deviceComm.deviceVendorId = 4817;//Huawei
//
//    deviceComm.deviceProductId = 4779;
//    deviceComm.deviceVendorId = 1452;//Apple
    deviceComm.deviceProductId = 12;
    deviceComm.deviceVendorId = 1240;//PillBox
//
    [MPDeviceCommunication sharedInstance].deviceCommunicationDelegate = self;
    //[ [ “set wlan ssid $replace$\r”, “AOK”], [“set wlan pass $replace$\r”,”AOK”], [“save\r”,”Storing in config”]]
//    if (NSNotFound == [output rangeOfString:@"CMD"].location)
//    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
//        
//    } completionHandler:^{
//        
//    }];
    MPDeviceCommand *commandCMDMode = [[MPDeviceCommand alloc] initWithCommand:@"$$$" andExpectedOutput:@"CMD"];
    commandCMDMode.secondaryExpectedOutput = @"ERR";
    MPDeviceCommand *setWlanSSID = [[MPDeviceCommand alloc] initWithCommand:@"set wlan ssid E9\r" andExpectedOutput:@"AOK"];
    MPDeviceCommand *setWlanPass = [[MPDeviceCommand alloc] initWithCommand:@"set wlan pass olbapnas\r" andExpectedOutput:@"AOK"];
    MPDeviceCommand *storeData = [[MPDeviceCommand alloc] initWithCommand:@"save\r" andExpectedOutput:@"Storing in config"];
    MPDeviceCommand *rebootDevice = [[MPDeviceCommand alloc] initWithCommand:@"reboot\r" andExpectedOutput:@"GW="];
    MPDeviceCommand *scanDevice = [[MPDeviceCommand alloc] initWithCommand:@"scan\r" andExpectedOutput:@"END"];

    deviceCommands = @[commandCMDMode,setWlanSSID,setWlanPass,storeData,rebootDevice,scanDevice];

    [[MPDeviceCommunication sharedInstance] setupDevice];//Create a interface with device
    [self showScanSSIDView];
    // Do view setup here.
}


- (void)deviceDidReceiveDebugMessage:(NSString *)message
{
    self.setupMessages.stringValue = message;
}

- (void)deviceDidFailSetup:(NSError *)error
{
    self.connectivityMessage.stringValue = [error domain];
    self.connectivityMessage.textColor = [NSColor blueColor];

}

- (void)deviceDidConnected
{
    self.connectivityMessage.stringValue = @"Device Connected";
    self.connectivityMessage.textColor = [NSColor greenColor];

}

- (void)deviceDidDisconnected
{
    self.connectivityMessage.stringValue = @"Device disconnected";
    self.connectivityMessage.textColor = [NSColor redColor];
}

- (void)deviceCommunicationDidFailedWriteMessage:(NSError *)error
{
    self.pipeReadWriteError.stringValue = [error domain];
}

- (void)deviceCommunicationDidFailedReadMessage:(NSError *)error
{
    self.pipeReadWriteError.stringValue = [error domain];

}

- (void)deviceCommunicationDidWriteMessage:(NSString *)message
{
    self.pipeReadWriteMessage.stringValue = message;

}

- (void)deviceCommunicationdidReadMessage:(NSString *)message
{
    self.pipeReadWriteMessage.stringValue = message;
    if (isAutoPilotMode) {
        switch (executingCommandIndex) {
            case 0: //$$$ waiting for CMD or ERR
            {
                MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                if ([message rangeOfString:deviceCommand.expectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//present, Send second command
                    executingCommandIndex++;
                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];

                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                }
                else if ([message rangeOfString:deviceCommand.secondaryExpectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//ERR present, Send second command
                    executingCommandIndex++;
                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                    
                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                }
            }
                break;
                
            case 1: //set ssid, waiting for AOK
            case 2: //set wlan pass, waiting for AOK

            {
                MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                if ([message rangeOfString:deviceCommand.expectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//present, Send next command
                    executingCommandIndex++;
                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                    
                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                }
            }
                break;
                
            case 3: //save, waiting for Storing in config
            {
                MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                if ([message rangeOfString:deviceCommand.expectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//present, Send next command
                    executingCommandIndex++;
                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                }
            }
                break;
            case 4:
            {
                MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                if ([message rangeOfString:deviceCommand.expectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//present, Send next command
                    executingCommandIndex = 0;
                    isAutoPilotMode = NO;
                    [NSApp presentError:[NSError errorWithDomain:@"Data Saved successfully" code:0 userInfo:nil]];
                    
//                    executingCommandIndex++;
//                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
//                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                }

                break;
            }
            case 5:
            {
                [completeCommandOutput appendString:message];
                MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                if ([message rangeOfString:deviceCommand.expectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//present, Send next command
                    executingCommandIndex = 0;
                    isAutoPilotMode = NO;
                    [NSApp presentError:[NSError errorWithDomain:@"Data Saved successfully" code:0 userInfo:nil]];
                    
                    //                    executingCommandIndex++;
                    //                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                    //                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                }
                
                break;
            }
                
            default:
                break;
        }
    }
}

- (IBAction)didTappedConnect:(id)sender {
    [[MPDeviceCommunication sharedInstance] setupDevice];
}

- (IBAction)didTappedSendMsg:(id)sender {
    [[MPDeviceCommunication sharedInstance] writeMessage:@"$$$"];
//    [[MPDeviceCommunication sharedInstance] sendReadCommand];
    [[MPDeviceCommunication sharedInstance] readMessageOnSecondaryThread];

}

- (IBAction)didTappedReadMessage:(id)sender {
    [[MPDeviceCommunication sharedInstance] readMessageOnSecondaryThread];
}

- (IBAction)sendCommandToDevice:(id)sender {
    if (self.commandTextField.stringValue.length) {
        //Send command
        NSString *targetedString = [self.commandTextField.stringValue stringByAppendingString:@"\r"];
        [[MPDeviceCommunication sharedInstance] writeCommandMessage:targetedString];
    }
    else
    {
        [NSApp presentError:[NSError errorWithDomain:@"Please enter the command and try" code:0 userInfo:nil]];
    }
}

- (IBAction)startAutoPilotMode:(id)sender {
    isAutoPilotMode = YES;
    executingCommandIndex = 0;
    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
    
    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
    [[MPDeviceCommunication sharedInstance] readMessageOnSecondaryThread];

}

#pragma mark - show view methods
- (void)showScanSSIDView
{
    scanSsidController = [[MPScanSSIDController alloc] initWithNibName:@"MPScanSSIDController" bundle:nil];
    [self.view replaceSubview:self.mainContentView with:scanSsidController.view];
    self.mainContentView = scanSsidController.view;
    executingCommandIndex = 5;

    completeCommandOutput = [NSMutableString new];
}

- (void)showConnectivityView
{
    
}

-(void)showEnterPasswordView
{
    
}

-(void)showSaveDetailsView
{
    
}

-(void)showRebootingView
{
    
}

@end
