//
//  MPDeviceDisconnectivityController.m
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 06/01/15.
//  Copyright (c) 2015 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import "MPDeviceDisconnectivityController.h"

#define CirularImageSet @[@"ConnectPowerAdaptor.png",@"ShowMedFolioUsbPort.png",@"ShowMacUsbPort.png"]

@interface MPDeviceDisconnectivityController ()
{
    NSInteger currentShowingStep;
}

@property (weak) IBOutlet NSImageView *mainImageView;

@end

@implementation MPDeviceDisconnectivityController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)playNext
{
    currentShowingStep++;
    currentShowingStep = currentShowingStep % [CirularImageSet count];
    _mainImageView.image = [NSImage imageNamed:CirularImageSet[currentShowingStep]];
}

- (void)playPrevious
{
    currentShowingStep--;
    if (currentShowingStep >= 0) {
        _mainImageView.image = [NSImage imageNamed:CirularImageSet[currentShowingStep]];
    }
    else
    {
        [NSApp terminate:self];
    }
}

@end
