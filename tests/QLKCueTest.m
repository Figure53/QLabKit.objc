//
//  QLKCueTest.m
//  QLabKit
//
//  Created by Zach Waugh on 10/23/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "QLKCue.h"

@interface QLKCueTest : XCTestCase

@end

@implementation QLKCueTest

- (void)testEquality
{
  QLKCue *cue = [[QLKCue alloc] initWithDictionary:@{@"uniqueID": @"1"}];
  QLKCue *cue2 = [[QLKCue alloc] initWithDictionary:@{@"uniqueID": @"1"}];
  QLKCue *cue3 = [[QLKCue alloc] initWithDictionary:@{@"uniqueID": @"2"}];
  
  expect(cue).to.equal(cue2);
  expect(cue).toNot.equal(cue3);
  expect(cue2).toNot.equal(cue3);
}

- (void)testIsAudio
{
	QLKCue *cue = [[QLKCue alloc] init];
	cue = [[QLKCue alloc] init];
	cue.type = QLKCueTypeAudio;
	
  expect(cue).toNot.beNil();
  expect([cue isAudio]).to.beTruthy();
  
	cue.type = QLKCueTypeFade;
	expect([cue isAudio]).to.beTruthy();
	
	cue.type = QLKCueTypeMicrophone;
  expect([cue isAudio]).to.beTruthy();
	
	cue.type = QLKCueTypeVideo;
  expect([cue isVideo]).to.beTruthy();
  expect([cue isAudio]).to.beTruthy();
}

// Ensure icon file name formatting is correct
- (void)testIconFileName
{
	QLKCue *cue = [[QLKCue alloc] init];
  expect(cue).toNot.beNil();
  expect([cue iconFile]).to.equal(@"cue.png");
  
  cue.type = QLKCueTypeAudio;
  expect([cue iconFile]).to.equal(@"audio.png");
}

- (void)testIconExists
{
	QLKCue *cue = [[QLKCue alloc] init];
  cue.type = QLKCueTypeAudio;
  
  NSBundle *bundle = [NSBundle mainBundle];
  NSString *iconFile = [cue iconFile];
  NSString *iconPath = [bundle pathForResource:iconFile.pathComponents[0] ofType:nil];
  
  expect([[NSFileManager defaultManager] fileExistsAtPath:iconPath]).to.beTruthy();
}

- (void)testCueSearch
{
  QLKCue *cue = [[QLKCue alloc] init];
  cue.uid = @"__main__";
  
  expect([cue cueWithId:@"test"]).to.beNil();
  
  QLKCue *child = [[QLKCue alloc] init];
  child.uid = @"1";
  cue.cues = [[NSMutableArray alloc] initWithArray:@[child]];
  
  expect(child).to.equal([cue cueWithId:@"1"]);
  
  QLKCue *subChild = [[QLKCue alloc] init];
  subChild.uid = @"2";
  child.type = @"Group";
  child.cues = [[NSMutableArray alloc] initWithArray:@[subChild]];
  
  expect(subChild).to.equal([cue cueWithId:@"2"]);
}
@end
