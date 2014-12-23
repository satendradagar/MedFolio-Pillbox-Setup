//
//  MPDeviceCommunication.m
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 28/11/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#include <mach/mach.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/IOCFPlugIn.h>
#import <Foundation/Foundation.h>

#import "MPDeviceCommunication.h"

//#define USE_ASYNC_IO    //Comment this line out if you want to use
//synchronous calls for reads and writes
#define kTestMessage            "adb devices"

#define DeviceCommunicaton [MPDeviceCommunication sharedInstance]
static MPDeviceCommunication *sharedInstance = nil;
char                     gBuffer[64];
IOUSBInterfaceInterface     **interface = NULL;
int readPipe;
int writePipe;

@interface MPDeviceCommunication()
{
    //Global variables
    IONotificationPortRef    gNotifyPort;
    io_iterator_t            gRawAddedIter;
    io_iterator_t            gRawRemovedIter;
    BOOL isAlreadyReading;

//    io_iterator_t            gBulkTestAddedIter;
//    io_iterator_t            gBulkTestRemovedIter;
}

//@property (nonatomic,readwrite) SInt32 deviceVendorId;
//@property (nonatomic,readwrite) SInt32 deviceProductId;

@end

@implementation MPDeviceCommunication

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype) initWithVendorId:(SInt32)vendorId andProductId:(SInt32)productId;
{
    self = [super init];
    if (self) {
        self.deviceVendorId = vendorId;
        self.deviceProductId = productId;
    }
    return self;
}

//void BulkTestDeviceRemoved(void *refCon, io_iterator_t iterator)
//{
//    kern_return_t	kr;
//    io_service_t	obj;
//    
//    while ( (obj = IOIteratorNext(iterator)) )
//    {
//        printf("Bulk test device removed.\n");
//        kr = IOObjectRelease(obj);
//    }
//}

void ReadCompletion(void *refCon, IOReturn result, void *arg0)
{
    IOUSBInterfaceInterface **interface = (IOUSBInterfaceInterface **) refCon;
    UInt32      numBytesRead = (UInt32) arg0;
    UInt32      i;
    
    printf("Asynchronous bulk read complete\n");
    if (result != kIOReturnSuccess) {
        printf("error from async bulk read (%08x)\n", result);
        (void) (*interface)->USBInterfaceClose(interface);
        (void) (*interface)->Release(interface);
        return;
    }
    //Check the complement of the buffer’s contents for original data
    for (i = 0; i < numBytesRead; i++)
        gBuffer[i] = ~gBuffer[i];
    
    printf("Read \"%s\" (%d bytes) from bulk endpoint\n", gBuffer, numBytesRead);
}


void WriteCompletion(void *refCon, IOReturn result, void *arg0)
{
    IOUSBInterfaceInterface **interface = (IOUSBInterfaceInterface **) refCon;
    UInt32                  numBytesWritten = (UInt32) arg0;
    UInt32                  numBytesRead;
    
    printf("Asynchronous write complete\n");
    if (result != kIOReturnSuccess)
    {
        printf("error from asynchronous bulk write (%08x)\n", result);
        (void) (*interface)->USBInterfaceClose(interface);
        (void) (*interface)->Release(interface);
        return;
    }
    printf("Wrote \"%s\" (%d bytes) to bulk endpoint\n", kTestMessage, numBytesWritten);
    
    numBytesRead = sizeof(gBuffer) - 1; //leave one byte at the end for
    //NULL termination
    result = (*interface)->ReadPipeAsync(interface, 9, gBuffer, numBytesRead, ReadCompletion, refCon);
    if (result != kIOReturnSuccess)
    {
        printf("Unable to perform asynchronous bulk read (%08x)\n", result);
        (void) (*interface)->USBInterfaceClose(interface);
        (void) (*interface)->Release(interface);
        return;
    }
}


IOReturn FindInterfaces(IOUSBDeviceInterface **device)
{
    IOReturn                    kr;
    IOUSBFindInterfaceRequest   request;
    io_iterator_t               iterator;
    io_service_t                usbInterface;
    IOCFPlugInInterface         **plugInInterface = NULL;
//    IOUSBInterfaceInterface     **interface = NULL;
    HRESULT                     result;
    SInt32                      score;
    UInt8                       interfaceClass;
    UInt8                       interfaceSubClass;
    UInt8                       interfaceNumEndpoints;
    int                         pipeRef;
    
#ifndef USE_ASYNC_IO
//    UInt32                      numBytesRead;
//    UInt32                      i;
#else
    CFRunLoopSourceRef          runLoopSource;
#endif
    
    //Placing the constant kIOUSBFindInterfaceDontCare into the following
    //fields of the IOUSBFindInterfaceRequest structure will allow you
    //to find all the interfaces
    request.bInterfaceClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
    request.bAlternateSetting = kIOUSBFindInterfaceDontCare;
    
    //Get an iterator for the interfaces on the device
    kr = (*device)->CreateInterfaceIterator(device,
                                            &request, &iterator);
    while (usbInterface = IOIteratorNext(iterator))
    {
        //Create an intermediate plug-in
        kr = IOCreatePlugInInterfaceForService(usbInterface,
                                               kIOUSBInterfaceUserClientTypeID,
                                               kIOCFPlugInInterfaceID,
                                               &plugInInterface, &score);
        //Release the usbInterface object after getting the plug-in
        kr = IOObjectRelease(usbInterface);
        if ((kr != kIOReturnSuccess) || !plugInInterface)
        {
            printf("Unable to create a plug-in (%08x)\n", kr);
            [DeviceCommunicaton deviceDidFailSetup:[NSError errorWithDomain:[NSString stringWithFormat:@"Unable to create a plug-in (%08x)\n", kr] code:0 userInfo:nil]];

            break;
        }
        
        //Now create the device interface for the interface
        result = (*plugInInterface)->QueryInterface(plugInInterface,CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),(LPVOID *) &interface);
        //No longer need the intermediate plug-in
        (*plugInInterface)->Release(plugInInterface);
        
        if (result || !interface)
        {
            printf("Couldn’t create a device interface for the interface (%08x)\n", (int) result);
            [DeviceCommunicaton deviceDidFailSetup:[NSError errorWithDomain:[NSString stringWithFormat:@"Couldn’t create a device interface for the interface (%08x)\n", (int) result] code:0 userInfo:nil]];

            break;
        }
        
        //Get interface class and subclass
        kr = (*interface)->GetInterfaceClass(interface,&interfaceClass);
        
        kr = (*interface)->GetInterfaceSubClass(interface,&interfaceSubClass);
        
        printf("Interface class %d, subclass %d\n", interfaceClass,
               interfaceSubClass);
        [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Interface class %d, subclass %d\n", interfaceClass,interfaceSubClass]];
        //Now open the interface. This will cause the pipes associated with
        //the endpoints in the interface descriptor to be instantiated
        kr = (*interface)->USBInterfaceOpen(interface);
        if (kr != kIOReturnSuccess)
        {
            printf("Unable to open interface (%08x)\n", kr);
            [DeviceCommunicaton deviceDidFailSetup:[NSError errorWithDomain:[NSString stringWithFormat:@"Unable to open interface (%08x)\n", kr] code:0 userInfo:nil]];
            (void) (*interface)->Release(interface);
            break;
        }
        
        //Get the number of endpoints associated with this interface
        kr = (*interface)->GetNumEndpoints(interface,
                                           &interfaceNumEndpoints);
        if (kr != kIOReturnSuccess)
        {
            printf("Unable to get number of endpoints (%08x)\n", kr);
            [DeviceCommunicaton deviceDidFailSetup:[NSError errorWithDomain:[NSString stringWithFormat:@"Unable to get number of endpoints (%08x)\n", kr] code:0 userInfo:nil]];
            (void) (*interface)->USBInterfaceClose(interface);
            (void) (*interface)->Release(interface);
            break;
        }
        
        printf("Interface has %d endpoints\n", interfaceNumEndpoints);
        [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Interface has %d endpoints\n", interfaceNumEndpoints]];
        //Access each pipe in turn, starting with the pipe at index 1
        //The pipe at index 0 is the default control pipe and should be
        //accessed using (*usbDevice)->DeviceRequest() instead
        for (pipeRef = 1; pipeRef <= interfaceNumEndpoints; pipeRef++)
        {
            IOReturn        kr2;
            UInt8           direction;
            UInt8           number;
            UInt8           transferType;
            UInt16          maxPacketSize;
            UInt8           interval;
            char            *message;
            
            kr2 = (*interface)->GetPipeProperties(interface,
                                                  pipeRef, &direction,
                                                  &number, &transferType,
                                                  &maxPacketSize, &interval);
            if (kr2 != kIOReturnSuccess){
                printf("Unable to get properties of pipe %d (%08x)\n",
                       pipeRef, kr2);
                [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Unable to get properties of pipe %d (%08x)\n",pipeRef, kr2]];
            }
            else
            {
                printf("PipeRef %d: ", pipeRef);
                [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"PipeRef %d: ", pipeRef]];
                switch (direction)
                {
                    case kUSBOut:
                        message = "out";
                        break;
                    case kUSBIn:
                        message = "in";
                        break;
                    case kUSBNone:
                        message = "none";
                        break;
                    case kUSBAnyDirn:
                        message = "any";
                        break;
                    default:
                        
                        message = "???";
                }
                printf("direction %s, ", message);
                [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"direction %s, ", message]];
                switch (transferType)
                {
                    case kUSBControl:
                        message = "control";
                        break;
                    case kUSBIsoc:
                        message = "isoc";
                        break;
                    case kUSBBulk:
                        message = "bulk";
                        break;
                    case kUSBInterrupt:
                        message = "interrupt";
                        break;
                    case kUSBAnyType:
                        message = "any";
                        break;
                    default:
                        message = "???";
                }
                if (transferType == kUSBBulk && direction == kUSBOut) {
                    writePipe = pipeRef;
                }
                if (transferType == kUSBBulk && direction == kUSBIn) {
                    readPipe = pipeRef;
                }

                printf("transfer type %s, maxPacketSize %d\n", message,
                       maxPacketSize);
                [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"transfer type %s, maxPacketSize %d\n", message,maxPacketSize]];
            }
        }
        
#ifndef USE_ASYNC_IO    //Demonstrate synchronous I/O
//        kr = (*interface)->WritePipe(interface, 2, kTestMessage, strlen(kTestMessage));
//        if (kr != kIOReturnSuccess)
//        {
//            printf("Unable to perform bulk write (%08x)\n", kr);
//            [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Unable to perform bulk write (%08x)\n", kr]];
//            (void) (*interface)->USBInterfaceClose(interface);
//            (void) (*interface)->Release(interface);
//            break;
//        }
//        
//        printf("Wrote \"%s\" (%ld bytes) to bulk endpoint\n", kTestMessage,
//               (UInt32) strlen(kTestMessage));
//        [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Wrote \"%s\" (%ld bytes) to bulk endpoint\n", kTestMessage,(UInt32) strlen(kTestMessage)]];
//        numBytesRead = sizeof(gBuffer) - 1; //leave one byte at the end
//        //for NULL termination
//        kr = (*interface)->ReadPipe(interface, 0, gBuffer,
//                                    &numBytesRead);
//        if (kr != kIOReturnSuccess)
//        {
//            printf("Unable to perform bulk read (%08x)\n", kr);
//            [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Unable to perform bulk read (%08x)\n", kr]];
//
//            (void) (*interface)->USBInterfaceClose(interface);
//            (void) (*interface)->Release(interface);
//            break;
//        }
//        
//        //Because the downloaded firmware echoes the one’s complement of the
//        //message, now complement the buffer contents to get the original data
//        for (i = 0; i < numBytesRead; i++)
//            gBuffer[i] = ~gBuffer[i];
//        
//        printf("Read \"%s\" (%ld bytes) from bulk endpoint\n", gBuffer,
//               numBytesRead);
//        [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Read \"%s\" (%ld bytes) from bulk endpoint\n", gBuffer,numBytesRead]];
//
//        
#else
        //Demonstrate asynchronous I/O
        //As with service matching notifications, to receive asynchronous
        //I/O completion notifications, you must create an event source and
        //add it to the run loop
        kr = (*interface)->CreateInterfaceAsyncEventSource(
                                                           interface, &runLoopSource);
        if (kr != kIOReturnSuccess)
        {
            printf("Unable to create asynchronous event source (%08x)\n", kr);
            [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Unable to create asynchronous event source (%08x)\n", kr]];
            (void) (*interface)->USBInterfaceClose(interface);
            (void) (*interface)->Release(interface);
            break;
        }
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource,
                           kCFRunLoopDefaultMode);
        printf("Asynchronous event source added to run loop\n");
        [DeviceCommunicaton deviceDidReceiveDebugMessage:@"Asynchronous event source added to run loop\n"];
        bzero(gBuffer, sizeof(gBuffer));
        strcpy(gBuffer, kTestMessage);
        kr = (*interface)->WritePipeAsync(interface, 2, gBuffer,
                                          strlen(gBuffer),
                                          WriteCompletion, (void *) interface);
        if (kr != kIOReturnSuccess)
        {
            printf("Unable to perform asynchronous bulk write (%08x)\n",
                   kr);
            [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Unable to perform asynchronous bulk write (%08x)\n",kr]];

            (void) (*interface)->USBInterfaceClose(interface);
            (void) (*interface)->Release(interface);
            break;
        }
#endif
        //For this test, just use first interface, so exit loop
        break;
    }
    return kr;
}



//void BulkTestDeviceAdded(void *refCon, io_iterator_t iterator)
//{
//    kern_return_t           kr;
//    io_service_t            usbDevice;
//    IOUSBDeviceInterface    **device=NULL;
//    
//    while (usbDevice = IOIteratorNext(iterator))
//    {
//        //Create an intermediate plug-in using the
//        //IOCreatePlugInInterfaceForService function
//        
//        //Release the device object after getting the intermediate plug-in
//        
//        //Create the device interface using the QueryInterface function
//        
//        //Release the intermediate plug-in object
//        
//        //Check the vendor, product, and release number values to
//        //confirm we’ve got the right device
//        
//        //Open the device before configuring it
//        kr = (*device)->USBDeviceOpen(device);
//        
//        //Configure the device by calling ConfigureDevice
//        
//        //Close the device and release the device interface object if
//        //the configuration is unsuccessful
//        
//        //Get the interfaces
//        kr = FindInterfaces(device);
//        if (kr != kIOReturnSuccess)
//        {
//            printf("Unable to find interfaces on device: %08x\n", kr);
//            (*device)->USBDeviceClose(device);
//            (*device)->Release(device);
//            continue;
//        }
//        
//        //If using synchronous IO, close and release the device interface here
//#ifndef USB_ASYNC_IO
//        kr = (*device)->USBDeviceClose(device);
//        kr = (*device)->Release(device);
//#endif
//    }
//}

IOReturn WriteToDevice(IOUSBDeviceInterface **dev, UInt16 deviceAddress, UInt16 length, UInt8 writeBuffer[])
{
    IOUSBDevRequest     request;
    
    request.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBVendor, kUSBDevice);
    request.bRequest = 0x02;
    request.wValue   = deviceAddress;
    request.wIndex   = 0;
    request.wLength  = length;
    request.pData    = writeBuffer;
    
    return (*dev)->DeviceRequest(dev, &request);
}


IOReturn ConfigureDevice(IOUSBDeviceInterface **dev)
{
    UInt8                           numConfig;
    IOReturn                        kr;
    IOUSBConfigurationDescriptorPtr configDesc;
    
    //Get the number of configurations. The sample code always chooses
    //the first configuration (at index 0) but your code may need a
    //different one
    kr = (*dev)->GetNumberOfConfigurations(dev, &numConfig);
    if (!numConfig)
        return -1;
    printf("configurations = %d",numConfig);
    [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"configurations = %d",numConfig]];
    //Get the configuration descriptor for index 0
    kr = (*dev)->GetConfigurationDescriptorPtr(dev, 0, &configDesc);
    if (kr)
    {
        printf("Couldn’t get configuration descriptor for index %d (err = %08x)\n", 0, kr);
        [DeviceCommunicaton deviceDidFailSetup:[NSError errorWithDomain:[NSString stringWithFormat:@"Couldn’t get configuration descriptor for index %d (err = %08x)\n", 0, kr] code:0 userInfo:nil]];
        return -1;
    }
    
    //Set the device’s configuration. The configuration value is found in
    //the bConfigurationValue field of the configuration descriptor
    kr = (*dev)->SetConfiguration(dev, configDesc->bConfigurationValue);
    if (kr)
    {
        printf("Couldn’t set configuration to value %d (err = %08x)\n", 0,
               kr);
        [DeviceCommunicaton deviceDidFailSetup:[NSError errorWithDomain:[NSString stringWithFormat:@"Couldn’t set configuration to value %d (err = %08x)\n",0,kr] code:0 userInfo:nil]];

        return -1;
    }
    return kIOReturnSuccess;
}

void RawDeviceAdded(void *refCon, io_iterator_t iterator)
{
    kern_return_t               kr;
    io_service_t                usbDevice;
    IOCFPlugInInterface         **plugInInterface = NULL;
    IOUSBDeviceInterface        **dev = NULL;
    HRESULT                     result;
    SInt32                      score;
    UInt16                      vendor;
    UInt16                      product;
    //    UInt16                      release;
    
    while (usbDevice = IOIteratorNext(iterator))
    {
        //Create an intermediate plug-in
        kr = IOCreatePlugInInterfaceForService(usbDevice,
                                               kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,
                                               &plugInInterface, &score);
        //Don’t need the device object after intermediate plug-in is created
        kr = IOObjectRelease(usbDevice);
        if ((kIOReturnSuccess != kr) || !plugInInterface)
        {
            printf("Unable to create a plug-in (%08x)\n", kr);
            [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Unable to create a plug-in (%08x)\n", kr]];
            continue;
        }
        //Now create the device interface
        result = (*plugInInterface)->QueryInterface(plugInInterface,
                                                    CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                                    (LPVOID *)&dev);
        //Don’t need the intermediate plug-in after device interface
        //is created
        (*plugInInterface)->Release(plugInInterface);
        
        if (result || !dev)
        {
            printf("Couldn’t create a device interface (%08x)\n",
                   (int) result);
            [DeviceCommunicaton deviceDidFailSetup:[NSError errorWithDomain:[NSString stringWithFormat:@"Couldn’t create a device interface (%08x)\n",(int) result] code:(int) result userInfo:nil]];
            continue;
        }
        
        //Check these values for confirmation
        kr = (*dev)->GetDeviceVendor(dev, &vendor);
        kr = (*dev)->GetDeviceProduct(dev, &product);
        //        kr = (*dev)->GetDeviceReleaseNumber(dev, &release); // INDIO la release non ci interessa!
        //        if ((vendor != kOurVendorID) || (product != kOurProductID) || (release != 1))
        if ((vendor != [DeviceCommunicaton deviceVendorId]) || (product != [DeviceCommunicaton deviceProductId]))
        {
            printf("Found unwanted device (vendor = %d, product = %d)\n", vendor, product);
            [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Found unwanted device (vendor = %d, product = %d)\n", vendor, product]];
            (void) (*dev)->Release(dev);
            continue;
        }
        
        //Open the device to change its state
        kr = (*dev)->USBDeviceOpen(dev);
        if (kr != kIOReturnSuccess)
        {
            printf("Unable to open device: %08x\n", kr);
            [DeviceCommunicaton deviceDidFailSetup:[NSError errorWithDomain:[NSString stringWithFormat:@"Unable to open device: %08x\n", kr] code:kr userInfo:nil]];
            (void) (*dev)->Release(dev);
            continue;
        }
        //Configure device
        kr = ConfigureDevice(dev);
        if (kr != kIOReturnSuccess)
        {
            printf("Unable to configure device: %08x\n", kr);
                        [DeviceCommunicaton deviceDidFailSetup:[NSError errorWithDomain:[NSString stringWithFormat:@"Unable to configure device: %08x\n", kr] code:kr userInfo:nil]];
            (void) (*dev)->USBDeviceClose(dev);
            (void) (*dev)->Release(dev);
            continue;
        }
        
        ///////////
        io_name_t devicename;
        if ((IORegistryEntryGetName(usbDevice, devicename) !=KERN_SUCCESS) == KERN_SUCCESS) {
            printf("Device name: %s\n", devicename);
            [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Device name: %s\n", devicename]];
        }
        
        printf("OUT:  Device name: %s\n", devicename);
        [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"OUT:  Device name: %s\n", devicename]];
        io_name_t entrypath;
        if (IORegistryEntryGetPath(usbDevice, kIOServicePlane, entrypath) == KERN_SUCCESS) {
            printf("\tDevice entry path: %s\n", entrypath);
            [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"\tDevice entry path: %s\n", entrypath]];

        }
        
        CFMutableDictionaryRef properties;
        IORegistryEntryCreateCFProperties(usbDevice, &properties, kCFAllocatorDefault, 0);
        //        if (properties) {
        //            CFShow(properties);
        //        }
        
        ///////////
        
        //Download firmware to device
        /*        kr = DownloadToDevice(dev);
         if (kr != kIOReturnSuccess)
         {
         printf("Unable to download firmware to device: %08x\n", kr);
         (void) (*dev)->USBDeviceClose(dev);
         (void) (*dev)->Release(dev);
         continue;
         }
         */
        //Close this device and release object
        kr = FindInterfaces(dev);
        [DeviceCommunicaton deviceDidConnected];
        kr = (*dev)->USBDeviceClose(dev);
        kr = (*dev)->Release(dev);
    }
}

void RawDeviceRemoved(void *refCon, io_iterator_t iterator)
{
    kern_return_t   kr;
    io_service_t    object;
    [DeviceCommunicaton deviceDidDisconnected];
    while (object = IOIteratorNext(iterator))
    {
        kr = IOObjectRelease(object);
        if (kr != kIOReturnSuccess)
        {
            printf("Couldn’t release raw device object: %08x\n", kr);
            [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Couldn’t release raw device object: %08x\n", kr]];
            continue;
        }
    }
}

-(int) setupDevice
{
    mach_port_t             masterPort;
    CFMutableDictionaryRef  matchingDict;
    CFRunLoopSourceRef      runLoopSource;
    kern_return_t           kr;
    SInt32                  usbVendor  = self.deviceVendorId;
    SInt32                  usbProduct = self.deviceProductId;
    
    //Create a master port for communication with the I/O Kit
    kr = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (kr || !masterPort)
    {
        printf("ERR: Couldn’t create a master I/O Kit port(%08x)\n", kr);
        [DeviceCommunicaton deviceDidFailSetup:[NSError errorWithDomain:[NSString stringWithFormat:@"Couldn’t create a master I/O Kit port(%08x)\n", kr] code:0 userInfo:nil]];

        return -1;
    }
    //Set up matching dictionary for class IOUSBDevice and its subclasses
    matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
    if (!matchingDict)
    {
        printf("Couldn’t create a USB matching dictionary\n");
        [DeviceCommunicaton deviceDidFailSetup:[NSError errorWithDomain:@"Couldn’t create a USB matching dictionary\n" code:0 userInfo:nil]];

        mach_port_deallocate(mach_task_self(), masterPort);
        return -1;
    }
    
    //Add the vendor and product IDs to the matching dictionary.
    //This is the second key in the table of device-matching keys of the
    //USB Common Class Specification
    CFDictionarySetValue(matchingDict, CFSTR(kUSBVendorName),
                         CFNumberCreate(kCFAllocatorDefault,
                                        kCFNumberSInt32Type, &usbVendor));
    CFDictionarySetValue(matchingDict, CFSTR(kUSBProductName),
                         CFNumberCreate(kCFAllocatorDefault,
                                        kCFNumberSInt32Type, &usbProduct));
    
    //To set up asynchronous notifications, create a notification port and
    //add its run loop event source to the program’s run loop
    gNotifyPort = IONotificationPortCreate(masterPort);
    runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource,
                       kCFRunLoopDefaultMode);
    
    //Retain additional dictionary references because each call to
    //IOServiceAddMatchingNotification consumes one reference
    matchingDict = (CFMutableDictionaryRef) CFRetain(matchingDict);
//    matchingDict = (CFMutableDictionaryRef) CFRetain(matchingDict);
//    matchingDict = (CFMutableDictionaryRef) CFRetain(matchingDict);
    
    //Now set up two notifications: one to be called when a raw device
    //is first matched by the I/O Kit and another to be called when the
    //device is terminated
    //Notification of first match:
    kr = IOServiceAddMatchingNotification(gNotifyPort,
                                          kIOFirstMatchNotification, matchingDict,
                                          RawDeviceAdded, NULL, &gRawAddedIter);
    //Iterate over set of matching devices to access already-present devices
    //and to arm the notification
    
    //Notification of termination:
    kr = IOServiceAddMatchingNotification(gNotifyPort,
                                          kIOTerminatedNotification, matchingDict,
                                          RawDeviceRemoved, NULL, &gRawRemovedIter);
    //Iterate over set of matching devices to release each one and to
    //arm the notification
    RawDeviceRemoved(NULL, gRawRemovedIter);
    RawDeviceAdded(NULL, gRawAddedIter);

    //Now change the USB product ID in the matching dictionary to match
    //the one the device will have after the firmware has been downloaded
//    usbProduct = kOurProductIDBulkTest;
//    CFDictionarySetValue(matchingDict, CFSTR(kUSBProductName),
//                         CFNumberCreate(kCFAllocatorDefault,
//                                        kCFNumberSInt32Type, &usbProduct));
    
    //Now set up two notifications: one to be called when a bulk test device
    //is first matched by the I/O Kit and another to be called when the
    //device is terminated.
    //Notification of first match
//    kr = IOServiceAddMatchingNotification(gNotifyPort,
//                                          kIOFirstMatchNotification, matchingDict,
//                                          BulkTestDeviceAdded, NULL, &gBulkTestAddedIter);
    //Iterate over set of matching devices to access already-present devices
    //and to arm the notification
//    BulkTestDeviceAdded(NULL, gBulkTestAddedIter);
//    
//    //Notification of termination
//    kr = IOServiceAddMatchingNotification(gNotifyPort,
//                                          kIOTerminatedNotification, matchingDict,
//                                          BulkTestDeviceRemoved, NULL, &gBulkTestRemovedIter);
//    //Iterate over set of matching devices to release each one and to
//    //arm the notification. NOTE: this function is not shown in this document.
//    BulkTestDeviceRemoved(NULL, gBulkTestRemovedIter);
    
    //Finished with master port
    mach_port_deallocate(mach_task_self(), masterPort);
    masterPort = 0;
    
    //Start the run loop so notifications will be received
//    CFRunLoopRun();
    
    //Because the run loop will run forever until interrupted,
    //the program should never reach this point
    return 0;
}


- (void)writeMessage:(NSString *)message
{
//#define SSCOM_STR = 0x02; // STX
//#define SSCOM_CMD_PUT_SERIAL_MSG = 0xAB;
    uint8_t bytes[] = {0x02,0xAB,0x03,0x24,0x24,0x24,0x03};
    NSString *completeCommand = [NSString stringWithFormat:@"%c%c%d%@%c",2,171,(int)message.length,message,3];/*STX,A,B,Len,Payload,ETX*/
    kern_return_t           kr;
    kr = (*interface)->ClearPipeStall(interface,writePipe);
    NSLog(@"kr = %d",kr);
    kr = (*interface)->ClearPipeStall(interface,readPipe);
    NSLog(@"kr = %d",kr);

    kr = (*interface)-> ResetPipe(interface,writePipe);
    NSLog(@"kr = %d",kr);

    kr = (*interface)->ResetPipe(interface,readPipe);
    NSLog(@"kr = %d",kr);
    
    printf("\nPrinting ASCII for write pipe:");
    for (int i = 0; i < 7; i++) {
        printf("0x%02x,",bytes[i]);
    }

    printf("\nWriting data to device: ");
    for (int i = 0; i < 7; i++) {
        if (isprint(bytes[i]))
            printf("%c ",bytes[i]);
    }


    char *cCommand = (char *)[completeCommand cStringUsingEncoding:NSUTF8StringEncoding];
//    cCommand = "adb get-serialno";
    
//    completeCommand = @"adb devices";
//    NSData *writableData = [completeCommand dataUsingEncoding:NSUTF8StringEncoding];
    //kr = (*interface)->WritePipe(interface, writePipe, (void *)writableData.bytes, (UInt32)writableData.length );

    kr = (*interface)->WritePipe(interface, writePipe, bytes, 7);//(UInt32)strlen(cCommand) - 1);
        if (kr != kIOReturnSuccess)
        {
            printf("Unable to perform bulk write (%08x)\n", kr);
            [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Unable to perform bulk write (%08x)\n", kr]];
            (void) (*interface)->USBInterfaceClose(interface);
            (void) (*interface)->Release(interface);
        }

//        printf("Wrote \"%s\" (%d bytes) to bulk endpoint\n", cCommand,(UInt32) strlen(cCommand));
        [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Wrote \"%s\" (%d bytes) to bulk endpoint\n", cCommand,(UInt32) strlen(cCommand)]];
    
}

- (void)writeCommandMessage:(NSString *)message
{
    //#define SSCOM_STR = 0x02; // STX
    //#define SSCOM_CMD_PUT_SERIAL_MSG = 0xAB;
    uint8_t *asciiArray = (uint8_t *)malloc((message.length + 4)* sizeof(uint8_t));
    int count = 0;
    asciiArray[count++] = 0x02;
    asciiArray[count++] = 0xAB;
    asciiArray[count++] = message.length;
    
    for (int stringCounter = 0; stringCounter < message.length; stringCounter ++) {
        asciiArray[count++] = [message characterAtIndex:stringCounter];
    }
    asciiArray[count++] = 3;

    kern_return_t           kr;
    
    
/*STX,A,B,Len,Payload,ETX*/
//    kr = (*interface)->ClearPipeStall(interface,writePipe);
//    NSLog(@"kr = %d",kr);
//    kr = (*interface)->ClearPipeStall(interface,readPipe);
//    NSLog(@"kr = %d",kr);
//    
//    kr = (*interface)-> ResetPipe(interface,writePipe);
//    NSLog(@"kr = %d",kr);
//    
//    kr = (*interface)->ResetPipe(interface,readPipe);
    NSLog(@"kr = %d",kr);
    
    printf("\nPrinting ASCII for write pipe:");
    for (int i = 0; i < count; i++) {
        printf("0x%02x,",asciiArray[i]);
    }
    NSMutableString *inputString = [[NSMutableString alloc] init];
    printf("\nWriting data to device: ");
    for (int i = 0; i < count; i++) {
        if (isprint(asciiArray[i]))
        {
            printf("%c ",asciiArray[i]);
            [inputString appendFormat:@"%c",asciiArray[i]];
        }
    }
    [DeviceCommunicaton deviceDidReceiveDebugMessage:inputString];

    
    //    cCommand = "adb get-serialno";
    
    //    completeCommand = @"adb devices";
    //    NSData *writableData = [completeCommand dataUsingEncoding:NSUTF8StringEncoding];
    //kr = (*interface)->WritePipe(interface, writePipe, (void *)writableData.bytes, (UInt32)writableData.length );
    
    kr = (*interface)->WritePipe(interface, writePipe, asciiArray, count);//(UInt32)strlen(cCommand) - 1);
    free(asciiArray);
    if (kr != kIOReturnSuccess)
    {
        printf("Unable to perform bulk write (%08x)\n", kr);
        [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Unable to perform bulk write (%08x)\n", kr]];
        (void) (*interface)->USBInterfaceClose(interface);
        (void) (*interface)->Release(interface);
    }
    
    //        printf("Wrote \"%s\" (%d bytes) to bulk endpoint\n", cCommand,(UInt32) strlen(cCommand));
//    [DeviceCommunicaton deviceCommunicationDidWriteMessage:[NSString stringWithFormat:@"Wrote  (%d bytes) to bulk endpoint\n", count]];
    [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Wrote  (%d bytes) to bulk endpoint\n", count]];

    
}
- (void)sendReadCommand
{
    //#define SSCOM_STR = 0x02; // STX
    //#define SSCOM_CMD_PUT_SERIAL_MSG = 0xAB;
//    #define SSCOM_CMD_GET_SERIAL_MSG = 0xAC
//    [self writeMessage:@"$$$"];
//    NSString *completeCommand = [NSString stringWithFormat:@"%c%c%c%c",2,172,0,3];/*STX,A,B,Len,Payload,ETX*/
    uint8_t bytes2[] = {0x02,0xAC,0x00,0x03};
//    printf("\nWriting read command to device: ");
//    for (int i = 0; i < 4; i++) {
//        if (isprint(bytes2[i]))
//            printf("%c ",bytes2[i]);
//    }
    kern_return_t           kr;
//    char *cCommand = (char *)[completeCommand cStringUsingEncoding:NSUTF8StringEncoding];
    kr = (*interface)->WritePipe(interface, writePipe, bytes2, 4);//UInt32)strlen(cCommand) - 1);
    if (kr != kIOReturnSuccess)
    {
        printf("Unable to perform bulk write (%08x)\n", kr);
        [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Unable to perform bulk write (%08x)\n", kr]];
        (void) (*interface)->USBInterfaceClose(interface);
        (void) (*interface)->Release(interface);
    }
    
    
//    printf("Wrote \"%s\" (%d bytes) to bulk endpoint\n", cCommand,(UInt32) strlen(cCommandsa));
//    [DeviceCommunicaton deviceCommunicationDidWriteMessage:[NSString stringWithFormat:@"Wrote \"%s\" (%d bytes) to bulk endpoint\n",  cCommand,(UInt32) strlen(cCommand)]];
}

- (void)readMessage
{
    UInt32                      numBytesRead;
    __block char                     gBuffer2[64];
    kern_return_t           kr;

    for (int i=0; i < 64; i++) {
        gBuffer2[i] = '\0';
    }//Create empty string
    numBytesRead = sizeof(gBuffer2) - 1; //leave one byte at the end
    //for NULL termination
    kr = (*interface)->ReadPipe(interface, readPipe, gBuffer2,
                                &numBytesRead);
//
//    NSMutableData* data = [NSMutableData dataWithLength:64];
//    UInt32 readSize = 64;
//    //read data
//    kr = (*interface)->ReadPipe(interface, readPipe, data.mutableBytes, &readSize);
//   [data setLength:readSize];

//    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"Read message = %@",message);
//
    if (kr != kIOReturnSuccess)
    {
        printf("Unable to perform bulk read (%08x)\n", kr);
        dispatch_async(dispatch_get_main_queue(), ^{
            [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Unable to perform bulk read (%08x)\n", kr]];
        });
        
        (void) (*interface)->USBInterfaceClose(interface);
        (void) (*interface)->Release(interface);
    }
    
//            for (int i = 0; i < numBytesRead; i++)
//                gBuffer2[i] = ~gBuffer2[i];
    printf("read characters from the device\n:");
    
    for (int i = 0; i < numBytesRead; i++){
        printf("%c",gBuffer2[i]);
    }
    printf("\n");
//    puts(gBuffer2);
//    printf("Read \"%s\" (%d bytes) from bulk endpoint\n", gBuffer2,
//           numBytesRead);
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Read \"%s\" (%d bytes) from bulk endpoint\n", gBuffer2,numBytesRead]];
//        [DeviceCommunicaton deviceCommunicationdidReadMessage:[NSString stringWithUTF8String:gBuffer2]];
//    });

    //
    
}

- (void)readMessageAsync
{
    UInt32                      numBytesRead;
    char                     gBuffer2[64];
    kern_return_t           kr;
    for (int i=0; i < 64; i++) {
        gBuffer2[i] = '\0';
    }//Create empty string
    numBytesRead = sizeof(gBuffer2) - 1; //leave one byte at the end
    //for NULL termination
    kr = (*interface)->ReadPipeAsync(interface, readPipe , gBuffer2, numBytesRead, ReadCompletion, NULL);

//    kr = (*interface)->ReadPipe(interface, readPipe, gBuffer2,&numBytesRead);
    if (kr != kIOReturnSuccess)
    {
        printf("Unable to perform bulk read (%08x)\n", kr);
        [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Unable to perform bulk read (%08x)\n", kr]];
        
        (void) (*interface)->USBInterfaceClose(interface);
        (void) (*interface)->Release(interface);
    }
    
    //            for (int i = 0; i < numBytesRead; i++)
    //                gBuffer2[i] = ~gBuffer2[i];
    printf("\n");
    
    for (int i = 0; i < numBytesRead; i++){
        printf("%c",gBuffer2[i]);
    }
    printf("\n");
    puts(gBuffer2);
    printf("Read \"%s\" (%d bytes) from bulk endpoint\n", gBuffer2,
           numBytesRead);
    [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Read \"%s\" (%d bytes) from bulk endpoint\n", gBuffer2,numBytesRead]];
    [DeviceCommunicaton deviceCommunicationdidReadMessage:[NSString stringWithUTF8String:gBuffer2]];
    //
    
}

-(void) readMessageOnSecondaryThread
{
    if (isAlreadyReading) {
        return;
    }
    isAlreadyReading = YES;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      while (1) {
          UInt32                      numBytesRead;
//          char                     gBuffer2[64];
          kern_return_t           kr;
          uint8_t               intBuffer[64];
          for (int i=0; i < 64; i++) {
              intBuffer[i] = '\0';
          }//Create empty string
          numBytesRead = sizeof(intBuffer) - 1; //leave one byte at the end
          //for NULL termination
          printf("Waiting to complete read");
          __block BOOL isReadCompleted = NO;
          dispatch_async(dispatch_get_current_queue(), ^{
              while (NO ==isReadCompleted) {
                  [self sendReadCommand];
//                  printf("Sent read command");
                  sleep(1.125);
              }

          });
          
          kr = (*interface)->ReadPipe(interface, readPipe, intBuffer,
                                      &numBytesRead);
          isReadCompleted = YES;
          printf("\nPrinting ASCII:");
          for (int i = 0; i < numBytesRead; i++) {
              printf("0x%02x,",intBuffer[i]);
              //          [hexStr appendFormat:@"%02x ", dbytes[i]];
          }
          
          //      NSString *outputFromHex = [self NSDataToHex:(uint8_t *)intBuffer];
          NSString *output = [[NSString alloc] initWithBytes:intBuffer length:numBytesRead encoding:NSASCIIStringEncoding];
          NSLog(@"output = %@",output);
          
          dispatch_async(dispatch_get_main_queue(), ^{
              [DeviceCommunicaton deviceDidReceiveDebugMessage:@"Waiting to complete read"];
          });
          
          if (kr != kIOReturnSuccess)
          {
              dispatch_async(dispatch_get_main_queue(), ^{
                  printf("Unable to perform bulk read (%08x)\n", kr);
                  [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Unable to perform bulk read (%08x)\n", kr]];
              });
              
              (void) (*interface)->USBInterfaceClose(interface);
              (void) (*interface)->Release(interface);
          }
          
          NSMutableString *outputString = [[NSMutableString alloc] init];
          printf("\nWill print characters now\n\n");
          
          for (int i = 0; i < numBytesRead; i++){
              if (isprint(intBuffer[i]))
              {
                  printf("%c",intBuffer[i]);
                  [outputString appendFormat:@"%c",intBuffer[i]];
              }
          }
          printf("\n");
          
          printf("Will print ascii now\n\n");
          
          for (int i = 0; i < numBytesRead; i++){
              printf("%d ",intBuffer[i]);
          }
          printf("\n");
          dispatch_async(dispatch_get_main_queue(), ^{
            [DeviceCommunicaton deviceCommunicationdidReadMessage:outputString];
            });
//          puts(gBuffer2);
//          printf("Read \"%s\" (%d bytes) from bulk endpoint\n", gBuffer2,numBytesRead);
          //      dispatch_async(dispatch_get_main_queue(), ^{
          //          [DeviceCommunicaton deviceDidReceiveDebugMessage:[NSString stringWithFormat:@"Read \"%s\" (%d bytes) from bulk endpoint\n", gBuffer2,numBytesRead]];
          //          [DeviceCommunicaton deviceCommunicationdidReadMessage:[NSString stringWithUTF8String:gBuffer2]];
          //      });
          
          //
//          if (NSNotFound == [output rangeOfString:@"CMD"].location) {
//              [self performSelector:_cmd withObject:nil afterDelay:1];
//          }
      }
//      isAlreadyReading = NO;
  });

}

//-(NSString*) NSDataToHex:(uint8_t *)data
//{
//    const unsigned char *dbytes = [data bytes];
//    NSMutableString *hexStr =
//    [NSMutableString stringWithCapacity:[data length]*2];
//    int i;
//    for (i = 0; i < [data length]; i++) {
//        [hexStr appendFormat:@"%02x ", dbytes[i]];
//    }
//    return [NSString stringWithString: hexStr];
//}

#pragma mark delegate method invocation with validation if delegate exist and responds for a selector

- (void)deviceDidReceiveDebugMessage:(NSString *)message
{
    if ([self.deviceCommunicationDelegate respondsToSelector:_cmd]) {
        [self.deviceCommunicationDelegate deviceDidReceiveDebugMessage:message];
    }
}

- (void)deviceDidFailSetup:(NSError *)error
{
    if ([self.deviceCommunicationDelegate respondsToSelector:_cmd]) {
        [self.deviceCommunicationDelegate deviceDidFailSetup:error];
    }
}

- (void)deviceDidConnected
{
    if ([self.deviceCommunicationDelegate respondsToSelector:_cmd]) {
        [self.deviceCommunicationDelegate deviceDidConnected];
    }
    
}

- (void)deviceDidDisconnected
{
    if ([self.deviceCommunicationDelegate respondsToSelector:_cmd]) {
        [self.deviceCommunicationDelegate deviceDidDisconnected];
    }
    
}

- (void)deviceCommunicationDidFailedWriteMessage:(NSError *)error
{
    if ([self.deviceCommunicationDelegate respondsToSelector:_cmd]) {
        [self.deviceCommunicationDelegate deviceCommunicationDidFailedWriteMessage:error];
    }
    
}

- (void)deviceCommunicationDidFailedReadMessage:(NSError *)error
{
    if ([self.deviceCommunicationDelegate respondsToSelector:_cmd]) {
        [self.deviceCommunicationDelegate deviceCommunicationDidFailedReadMessage:error];
    }
    
}

- (void)deviceCommunicationDidWriteMessage:(NSString *)message
{
    if ([self.deviceCommunicationDelegate respondsToSelector:_cmd]) {
        [self.deviceCommunicationDelegate deviceCommunicationDidWriteMessage:message];
    }
    
}

- (void)deviceCommunicationdidReadMessage:(NSString *)message
{
    if ([self.deviceCommunicationDelegate respondsToSelector:_cmd]) {
        [self.deviceCommunicationDelegate deviceCommunicationdidReadMessage:message];
    }
}

@end
