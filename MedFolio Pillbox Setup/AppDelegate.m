//
//  AppDelegate.m
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 28/11/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//
/*

 */
#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self.window performSelector:@selector(toggleFullScreen:) withObject:nil afterDelay:0.2];

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end
