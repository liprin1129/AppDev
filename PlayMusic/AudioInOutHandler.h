//
//  AudioInOutHandler.h
//  PlayMusic
//
//  Created by Seongmuk Gang on 28/12/2016.
//  Copyright © 2016 Seongmuk Gang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioInOutHandler : NSObject{
    AUGraph processingGraph;
    AudioUnit ioUnitInstance;
    AudioStreamBasicDescription myASBD;
}

@property (nonatomic, assign) double graphSampleRate;
@property (nonatomic, assign) NSTimeInterval ioBufferDuration;

- (void) CheckNSError:(NSError*)error errorMessage:(NSString *)operation;
- (void) CheckStatusError:(OSStatus)error errorMessage:(NSString *)operation;

- (void) mAaudioFormat:(AudioStreamBasicDescription *)ASBD mSampleRate:(double)sampleRate
             mFormatID:(UInt32)formatID mFormatFlags:(UInt32)formatFlags
       mBytesPerPacket:(UInt32)bytesPerPacket mFramesPerPacket:(UInt32)framesPerPacket
        mBytesPerFrame:(UInt32)bytesPerFrame mChannelsPerFrame:(UInt32)channelsPerFrame
       mBitsPerChannel:(UInt32)bitsPerChannel;

// control object
- (void) startAUGraph;
- (void) stopAUGraph;

@end
