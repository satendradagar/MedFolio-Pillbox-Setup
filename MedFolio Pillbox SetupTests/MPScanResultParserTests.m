//
//  MPScanResultParserTests.m
//  MedFolio Pillbox Setup
//
//  Created by Satendra Personal on 23/12/14.
//  Copyright (c) 2014 CoreBits Software Solutions Pvt. Ltd(corebitss.com). All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "MPNetwork.h"
#import "MPScanResultParser.h"

@interface MPScanResultParserTests : XCTestCase

@end

@implementation MPScanResultParserTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testNetworkObjectsFromScanResultShouldReturnProperNetworks
{
    NSString *networkString = @"SCAN:Found 3\n01,01,-59,04,1104,28,c0,20:4e:7f:08:df:85,dad-rules\n02,03,-64,02,1104,28,00,00:30:bd:9b:49:22,basement\n03,10,-71,04,3100,28,00,90:27:e4:5d:fc:a7,URSOMONEY\nEND:";
    NSArray *networks = [MPScanResultParser networkObjectsFromScanResult:networkString errorReceived:nil];
    XCTAssertEqual(networks.count, 3,@"There must be equal number of ssids as expected");
}

- (void)testNetworkObjectsFromScanResultShouldNotNil
{
    NSString *networkString = @"SCAN:Found 3\n01,01,-59,04,1104,28,c0,20:4e:7f:08:df:85,dad-rules\n02,03,-64,02,1104,28,00,00:30:bd:9b:49:22,basement\n03,10,-71,04,3100,28,00,90:27:e4:5d:fc:a7,URSOMONEY\nEND:";
    NSArray *networks = [MPScanResultParser networkObjectsFromScanResult:networkString errorReceived:nil];
    XCTAssertNotNil(networks,@"Networks array should not nil");
}

- (void)testFirst_NetworkObjectsFromScanResultShouldMatchSSID
{
    NSString *networkString = @"SCAN:Found 3\n01,01,-59,04,1104,28,c0,20:4e:7f:08:df:85,dad-rules\n02,03,-64,02,1104,28,00,00:30:bd:9b:49:22,basement\n03,10,-71,04,3100,28,00,90:27:e4:5d:fc:a7,URSOMONEY\nEND:";
    NSArray *networks = [MPScanResultParser networkObjectsFromScanResult:networkString errorReceived:nil];
    MPNetwork *firstNetwork = networks[0];
    XCTAssertEqualObjects(@"dad-rules", firstNetwork.ssid,@"Network SSID should match with expected result");
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        
        // Put the code you want to measure the time of here.
    }];
}

@end
