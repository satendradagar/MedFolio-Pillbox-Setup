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
#import "MPEnterWifiPassword.h"
#import "MPRebootDeviceController.h"
#import "MPSaveDetailsController.h"
#import <time.h>

typedef NS_ENUM(NSUInteger, CurrentVisibleView) {
    ShowDeviceConnectivityView = 0,
    ScanSSIDView = 1,
    SetWlanPasswordView = 2,
    SaveConfigurationView = 3,
    RestartDeviceView = 4
};


@interface MPDeviceConfigurationViewController ()
{
    NSArray *deviceCommands;
    NSUInteger executingCommandIndex;
    BOOL isAutoPilotMode;
    MPScanSSIDController *scanSsidController;
    MPConnectivityController *connectivityController;
    MPEnterWifiPassword *enterPasswordController;
    MPSaveDetailsController *saveDetailsController;
    MPRebootDeviceController *rebootDeviceController;     
    NSMutableString *completeCommandOutput;
}
@property (weak) IBOutlet NSPanel *waitActionSheet;
@property (weak) IBOutlet NSTextField *waitSheetMessage;
@property (weak) IBOutlet NSProgressIndicator *waitSheetProgressIndicator;

@property (nonatomic, assign) CurrentVisibleView currentView;

@property (weak) IBOutlet NSTextField *stepMessageText;
@property (weak) IBOutlet NSButton *previousButton;
- (IBAction)didClickedPrevious:(id)sender;
- (IBAction)didClickedNext:(id)sender;

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
    MPDeviceCommand *disableAutoAssocitation = [[MPDeviceCommand alloc] initWithCommand:@"set wlan join 0\r" andExpectedOutput:@"AOK"];
    MPDeviceCommand *setWlanSSID = [[MPDeviceCommand alloc] initWithCommand:@"set wlan ssid E9\r" andExpectedOutput:@"AOK"];
    MPDeviceCommand *setWlanPass = [[MPDeviceCommand alloc] initWithCommand:@"set wlan pass olbapnas\r" andExpectedOutput:@"AOK"];
    MPDeviceCommand *storeData = [[MPDeviceCommand alloc] initWithCommand:@"save\r" andExpectedOutput:@"Storing in config"];
    MPDeviceCommand *rebootDevice = [[MPDeviceCommand alloc] initWithCommand:@"reboot\r" andExpectedOutput:@"*READY*"];
    MPDeviceCommand *enableAutoAssocitation = [[MPDeviceCommand alloc] initWithCommand:@"set wlan join 1\r" andExpectedOutput:@"AOK"];

    rebootDevice.secondaryExpectedOutput = @"AUTH-ERR";
    
    MPDeviceCommand *scanDevice = [[MPDeviceCommand alloc] initWithCommand:@"scan\r" andExpectedOutput:@"END:"];

    deviceCommands = @[commandCMDMode,scanDevice,setWlanSSID,setWlanPass,storeData,rebootDevice,disableAutoAssocitation,enableAutoAssocitation];
   
    [self showEnterPasswordView];

    [[MPDeviceCommunication sharedInstance] setupDevice];//Create a interface with device
//    sleep(2.0);

//    [self didTappedSendMsg:nil];
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
//    dispatch_async(dispatch_get_main_queue(), ^{
        [[MPDeviceCommunication sharedInstance] resetPipes];
//        [self startAutoPilotMode:nil];
        
        //AMD - Start
//        [[MPDeviceCommunication sharedInstance] readMessageOnSecondaryThread];

    [self startAutoPilotMode:nil];
//        [self performSelector:@selector(startAutoPilotMode:) withObject:nil afterDelay:1.0];
//    });

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
        [completeCommandOutput appendString:message];
        NSLog(@"incomplete output = %@, Executing = %lu",completeCommandOutput,(unsigned long)executingCommandIndex);
        
        //AMD Received from NSTimer. If we're timed out in state 0 (Send:$$$/Recv:CMD|ERR) retry, else return
        if ([message isEqualToString: @"<<TIMEOUT>>"]){
            if (executingCommandIndex != 0) return;
        }
        
        switch (executingCommandIndex) {
            case 0: //$$$ waiting for CMD or ERR
            {
                NSLog(@"read message switch 0");

                MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                if ([completeCommandOutput rangeOfString:deviceCommand.expectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//present, Send second command
//                    executingCommandIndex++;
//                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
//
//                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                    NSLog(@"Received CMD, so going to keep ");
                    [self disableAutoAssociation];
                }
                else if ([completeCommandOutput rangeOfString:deviceCommand.secondaryExpectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//ERR present, Send second command
//                    executingCommandIndex++;
//                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
//                    
//                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                    [self disableAutoAssociation];

                }
                else if ([completeCommandOutput rangeOfString:@"$$$" options:NSCaseInsensitiveSearch].location != NSNotFound){
                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:@"\r"];
                }}
                break;
            case 1:
            {
                NSLog(@"read message switch 1");

                MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                if ([completeCommandOutput rangeOfString:deviceCommand.expectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//present, Send next command
//                    executingCommandIndex = 0;
//                    isAutoPilotMode = NO;
                    [scanSsidController performSelectorOnMainThread:@selector(controllerReceivedScanMessage:) withObject:completeCommandOutput waitUntilDone:YES];
//                    [scanSsidController controllerReceivedScanMessage:completeCommandOutput];
                    [self hideWaitSheet];
                    NSLog(@"Receive complete scan result = \n%@",completeCommandOutput);
                    //                    [NSApp presentError:[NSError errorWithDomain:@"Data Saved successfully" code:0 userInfo:nil]];
                    //                    isAutoPilotMode = NO;
                    //                    executingCommandIndex++;
                    //                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                    //                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                }
                
            }
                break;
               
            case 2: //set ssid, waiting for AOK
            {
                NSLog(@"read message switch 2");
                MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                if ([completeCommandOutput rangeOfString:deviceCommand.expectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//present, Send next command
                    //                    executingCommandIndex++;
                    //                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                    //
                    //                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                    [self hideWaitSheet];
                    [self showEnterPasswordView];
                }
 
            }
                break;
            case 3: //set wlan pass, waiting for AOK

            {
                NSLog(@"read message switch 3");
                MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                if ([completeCommandOutput rangeOfString:deviceCommand.expectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//present, Send next command
//                    executingCommandIndex++;
//                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
//
//                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                    [self hideWaitSheet];
                    [self showSaveDetailsView];
                }
            }
                break;
                
            case 4: //save, waiting for Storing in config
            {
                NSLog(@"read message switch 4");
                MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                if ([completeCommandOutput rangeOfString:deviceCommand.expectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//present, Send next command
//                    executingCommandIndex++;
//                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
//                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                    [self hideWaitSheet];
                    [self showRebootingView];
                }
            }
                break;
            case 5:
            {
                NSLog(@"read message switch 5");
                MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                if ([completeCommandOutput rangeOfString:deviceCommand.expectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//present, Send next command
                    executingCommandIndex = 0;
                    isAutoPilotMode = NO;
                    [self enableAutoAssociation];
//                    [self hideWaitSheet];
//                    [NSApp presentError:[NSError errorWithDomain:@"Data Saved successfully" code:0 userInfo:nil]];
                    
//                    executingCommandIndex++;
//                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
//                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                }
                else if ([completeCommandOutput rangeOfString:deviceCommand.secondaryExpectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound)
                {
                                        [NSApp presentError:[NSError errorWithDomain:@"Password entered is not correct, Please verify password and enter it again." code:0 userInfo:nil]];
                    [self hideWaitSheet];
                    executingCommandIndex = 0;
                    [self showScanSSIDView];
                }

            }
                break;
            case 6: //save, waiting for Storing in config
            {
                NSLog(@"read message switch 6");
                MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                if ([completeCommandOutput rangeOfString:deviceCommand.expectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//present, Send next command
                    //                    executingCommandIndex++;
                    //                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                    //                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                    [self didTappedSendScanCommand:nil];
                }
            }
                break;
            case 7: //save, waiting for Storing in config
            {
                NSLog(@"read message switch 7");
                MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                if ([completeCommandOutput rangeOfString:deviceCommand.expectedOutput options:NSCaseInsensitiveSearch].location != NSNotFound) {//present, Send next command
                    //                    executingCommandIndex++;
                    //                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
                    //                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
                    [self hideWaitSheet];
                }
            }
                break;

            default:
                NSLog(@"read message switch Default");

                break;
        }
    }
}

- (IBAction)didTappedConnect:(id)sender {
    [[MPDeviceCommunication sharedInstance] setupDevice];
}

- (IBAction)didTappedSendMsg:(id)sender {

    executingCommandIndex = 0;
    completeCommandOutput = [NSMutableString new];
    [[MPDeviceCommunication sharedInstance] writeCommandMessage:@"$$$"];
    [[MPDeviceCommunication sharedInstance] readMessageOnSecondaryThread];

//    [[MPDeviceCommunication sharedInstance] sendReadCommand];

}

- (IBAction)didTappedReadMessage:(id)sender {
    [[MPDeviceCommunication sharedInstance] readMessageOnSecondaryThread];
}

- (IBAction)sendCommandToDevice:(id)sender {
    if (self.commandTextField.stringValue.length) {
        //Send command
        if ([self.commandTextField.stringValue isEqualToString:@"$$$"]) {
                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:@"$$$"];
        }
        else{
        NSString *targetedString = [self.commandTextField.stringValue stringByAppendingString:@"\r"];
        [[MPDeviceCommunication sharedInstance] writeCommandMessage:targetedString];
        }
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
    completeCommandOutput = [NSMutableString new];
    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
    [[MPDeviceCommunication sharedInstance] readMessageOnSecondaryThread];

}

- (IBAction)didTappedSendScanCommand:(id)sender
{
    isAutoPilotMode = YES;
    executingCommandIndex = 1;
    completeCommandOutput = [NSMutableString new];
    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
    
    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
}

- (void)disableAutoAssociation
{
    isAutoPilotMode = YES;
    executingCommandIndex = 6;
    completeCommandOutput = [NSMutableString new];
    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
    
    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
 
}

-(void)enableAutoAssociation
{
    isAutoPilotMode = YES;
    executingCommandIndex = 7;
    completeCommandOutput = [NSMutableString new];
    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
    
    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
    
}

#pragma mark - show view methods
- (void)showScanSSIDView
{
    self.currentView = ScanSSIDView;
    scanSsidController = [[MPScanSSIDController alloc] initWithNibName:@"MPScanSSIDController" bundle:nil];
    scanSsidController.configurationViewController = self;
    [self.view replaceSubview:self.mainContentView with:scanSsidController.view];
    self.mainContentView = scanSsidController.view;

}

- (void)showConnectivityView
{
    
}

-(void)showEnterPasswordView
{
    self.currentView = SetWlanPasswordView;
    enterPasswordController = [[MPEnterWifiPassword alloc] initWithNibName:@"MPEnterWifiPassword" bundle:nil];
    enterPasswordController.selectedNetwork = [scanSsidController selectedNetwork];
//    enterPasswordController.configurationViewController = self;
    [self.view replaceSubview:self.mainContentView with:enterPasswordController.view];
    self.mainContentView = enterPasswordController.view;
}

-(void)showSaveDetailsView
{
    self.currentView = SaveConfigurationView;
    saveDetailsController = [[MPSaveDetailsController alloc] initWithNibName:@"MPSaveDetailsController" bundle:nil];
    //    enterPasswordController.configurationViewController = self;
    [self.view replaceSubview:self.mainContentView with:saveDetailsController.view];
    self.mainContentView = saveDetailsController.view;

}

-(void)showRebootingView
{
    self.currentView = RestartDeviceView;
    rebootDeviceController = [[MPRebootDeviceController alloc] initWithNibName:@"MPRebootDeviceController" bundle:nil];
//    rebootDeviceController.configurationViewController = self;
    [self.view replaceSubview:self.mainContentView with:rebootDeviceController.view];
    self.mainContentView = rebootDeviceController.view;
}

- (IBAction)didClickedPrevious:(id)sender {
    switch (self.currentView) {
        case ShowDeviceConnectivityView:
        {
            
        }
            break;
            
        case ScanSSIDView:
        {
            [[NSApplication sharedApplication] terminate:self];
        }
            break;
            
        case SetWlanPasswordView:
            
        {
            [self showScanSSIDView];
        }
            break;
            
        case SaveConfigurationView:
        {
            [self showEnterPasswordView];
        }
            break;
            
        case RestartDeviceView:
        {
            [self showSaveDetailsView];
        }
            break;
            
        default:
            break;
    } 
}

- (void) showWaitSheetWithMessage:(NSString *)message contextInfo:(void *)contextInfo
{
    self.waitSheetMessage.stringValue = message;
    [self.waitSheetProgressIndicator startAnimation:nil];
    [NSApp beginSheet:self.waitActionSheet modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
          contextInfo:contextInfo];
    
}

- (void)hideWaitSheet
{
    [NSApp endSheet:self.waitActionSheet];
    //    [self setNetworkConfigStatus:NO];
    [self.waitActionSheet orderOut:nil];
    
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
        [self.waitSheetProgressIndicator stopAnimation:nil];
}

- (IBAction)didClickedNext:(id)sender {
    
    switch (self.currentView) {
            
        case ShowDeviceConnectivityView:
        {
            
        }
            break;
            
        case ScanSSIDView:
        {
            executingCommandIndex = 2;
            [self showWaitSheetWithMessage:@"Setting ssid into device" contextInfo:nil];
            completeCommandOutput = [NSMutableString new];

            [[MPDeviceCommunication sharedInstance] writeCommandMessage:[NSString stringWithFormat:@"set wlan ssid %@\r",[[scanSsidController selectedNetwork] ssid]]];

        }
            break;

        case SetWlanPasswordView:
        {
            NSString *passwordText = [[enterPasswordController passwordField] stringValue];
            NSString *temp = @"olbapnas";
            passwordText = temp;
            if (0 == passwordText.length) {
                
                [NSApp presentError:[NSError errorWithDomain:@"Enter password is nil" code:99 userInfo:nil]];
                return;
            }
            executingCommandIndex = 3;
            completeCommandOutput = [NSMutableString new];
            [self showWaitSheetWithMessage:@"Setting wlan password" contextInfo:nil];
            [[MPDeviceCommunication sharedInstance] writeCommandMessage:[NSString stringWithFormat:@"set wlan pass %@\r",passwordText]];

        }
            break;
            
        case SaveConfigurationView:
        {
            [self showWaitSheetWithMessage:@"Saving the configuration into device." contextInfo:nil];
            executingCommandIndex = 4;
            completeCommandOutput = [NSMutableString new];
                    MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];

                    [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];

        }
            break;
            
        case RestartDeviceView:
        {
            [self showWaitSheetWithMessage:@"Restarting the device to avail the setup." contextInfo:nil];
            executingCommandIndex = 5;
            completeCommandOutput = [NSMutableString new];

            MPDeviceCommand *deviceCommand = deviceCommands[executingCommandIndex];
            
            [[MPDeviceCommunication sharedInstance] writeCommandMessage:deviceCommand.sendCommand];
        }
            break;
            
        default:
            break;
    }
}
@end
