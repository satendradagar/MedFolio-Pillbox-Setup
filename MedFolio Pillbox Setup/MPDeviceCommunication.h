//
//  MPDeviceCommunication.h
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 28/11/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPDeviceCommunication;

@protocol MPDeviceCommunicationDelegate<NSObject>

@optional

- (void)deviceDidReceiveDebugMessage:(NSString *)message;
- (void)deviceDidFailSetup:(NSError *)error;
- (void)deviceDidConnected;
- (void)deviceDidDisconnected;

- (void)deviceCommunicationDidFailedWriteMessage:(NSError *)error;
- (void)deviceCommunicationDidFailedReadMessage:(NSError *)error;
- (void)deviceCommunicationDidWriteMessage:(NSString *)message;
- (void)deviceCommunicationdidReadMessage:(NSString *)message;

@end

@interface MPDeviceCommunication : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic,readwrite) SInt32 deviceVendorId;
@property (nonatomic,readwrite) SInt32 deviceProductId;
- (instancetype)initWithVendorId:(SInt32)vendorId andProductId:(SInt32 )productId;

@property (nonatomic ,unsafe_unretained) id<MPDeviceCommunicationDelegate> deviceCommunicationDelegate;
/*
 */
- (int)setupDevice;
- (void) resetPipes;

- (void)writeMessage:(NSString *)message;
- (void)writeCommandMessage:(NSString *)message;

- (void)sendReadCommand;

- (void)readMessage;
- (void)readMessageOnSecondaryThread;
- (void)readMessageAsync;

@end
