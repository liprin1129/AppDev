//
//  AudioInOutHandler.m
//  PlayMusic
//
//  Created by Seongmuk Gang on 28/12/2016.
//  Copyright © 2016 Seongmuk Gang. All rights reserved.
//

#import "AudioInOutHandler.h"

@implementation AudioInOutHandler

- (id)init {
    //self = [super init];
    
    [self setupAudioSession];
    [self setupAudioUnits];
    
    return self;
}

#pragma mark Logging OSStatus Error Codes
- (void) CheckNSError:(NSError*)error errorMessage:(NSString *)operation{
    if (error == noErr) NSLog(@"Good: %@ \n\n", operation); //return;
    else {
        NSLog(@"Error: Couldn't %@ \n\n", operation);
        exit(1);
    }
}

/*
 - (void) testCheckNSError{
 [AlertPopUpControllerViewController popUpAlert];
 }
 */
- (void) CheckStatusError:(OSStatus)error errorMessage:(NSString *)operation{
    if (error == noErr) NSLog(@"Good: %@ \n\n", operation);
    else {
        NSLog(@"Error: Couldn't %@ \n\n", operation);
        exit(1);
    }
}

#pragma mark Configure the audio session
- (void) setupAudioSession{
    self.graphSampleRate = 44100.0;
    self.ioBufferDuration = .005;
    
    NSError *audioSessionError = nil;
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    
    
    // set the session's sample rate
    [sessionInstance setPreferredSampleRate:self.graphSampleRate error:&audioSessionError];
    [self CheckNSError:audioSessionError errorMessage:@"set session's preferred sample rate"];
    
    // we are going to play and record so we pick that category
    [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&audioSessionError];
    [self CheckNSError:audioSessionError errorMessage:@"set session's audio category"];
    
    // set the buffer duration to 5 ms
    [sessionInstance setPreferredIOBufferDuration:self.ioBufferDuration error:&audioSessionError];
    [self CheckNSError:audioSessionError errorMessage:@"set session's IO buffer duration"];
    
    [sessionInstance setActive:YES error:&audioSessionError];
    [self CheckNSError:audioSessionError errorMessage:@"set Active"];
}

# pragma mark Specify the Audio Units You Want
- (void) setupAudioUnits {
    NSLog (@"\nConfiguring and then initializing audio processing graph\n");
    OSStatus statusError;
    
    // Create a new instance of AURemoteIO
    AudioComponentDescription ioUnitDescription;
    ioUnitDescription.componentType         = kAudioUnitType_Output;
    ioUnitDescription.componentSubType      = kAudioUnitSubType_RemoteIO;
    ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioUnitDescription.componentFlags        = 0;
    ioUnitDescription.componentFlagsMask    = 0;
    
    // Build an Audio Processing Graph
    statusError = NewAUGraph(&processingGraph);
    [self CheckStatusError:statusError errorMessage:@"create new AUGraph"];
    
    AUNode ioNode;
    
    statusError = AUGraphAddNode(processingGraph, &ioUnitDescription, &ioNode);
    [self CheckStatusError:statusError errorMessage:@"add node"];
    
    statusError = AUGraphOpen(processingGraph);
    [self CheckStatusError:statusError errorMessage:@"open AUGraph"];
    
    statusError = AUGraphNodeInfo(processingGraph, ioNode, NULL, &ioUnitInstance);
    [self CheckStatusError:statusError errorMessage:@"get AUGraph node info"];
    
    // Enable input and output on AURemoteIO
    // Input is enabled on the input scope of the input element
    AudioUnitElement ioUnitInputBus = 1;
    UInt32 enableInput = 1;
    statusError = AudioUnitSetProperty(ioUnitInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, ioUnitInputBus, &enableInput, sizeof(enableInput));
    [self CheckStatusError:statusError errorMessage:@"enable input on AURemoteIO"];
    
    /* This is default setting, so there's no need to implement this code */
    /*
     AudioUnitElement ioUnitOutputBus = 0;
     UInt32 enableOutput = 1;
     statusError = AudioUnitSetProperty(ioUnitInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, ioUnitOutputBus, &enableOutput, sizeof(enableOutput));
     [self CheckStatusError:statusError errorMessage:@"enable Output on AURemoteIO"];
     */
    
    
    // Set output audio stream format description of input element
    [self mAaudioFormat:&myASBD mSampleRate:44100.0 mFormatID:kAudioFormatLinearPCM mFormatFlags:kAudioFormatFlagIsSignedInteger mBytesPerPacket:2 mFramesPerPacket:1 mBytesPerFrame:2 mChannelsPerFrame:1 mBitsPerChannel:16];
    
    statusError = AudioUnitSetProperty(ioUnitInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, ioUnitInputBus, &myASBD, sizeof(myASBD));
    [self CheckStatusError:statusError errorMessage:@"enable output on AURemoteIO"];
    
    //Connecting Audio Units using the Audio Processing Graph API
    statusError = AUGraphConnectNodeInput(processingGraph, ioNode, 1, ioNode, 0);
    [self CheckStatusError:statusError errorMessage:@"connet audio units"];
    
    //Initialize Audio Processing Graph
    statusError = AUGraphInitialize(processingGraph);
    //if (statusError) { printf("AUGraphInitialize result %d %08X %4.4s\n", (int)statusError, (unsigned int)statusError, (char*)&statusError); return; }
    [self CheckStatusError:statusError errorMessage:@"initialise AUGraph"];
}

- (void) startAUGraph{
    // NSLog (@"Starting audio processing graph");
    OSStatus statusError = AUGraphStart(processingGraph);
    [self CheckStatusError:statusError errorMessage:@"start audio processing graph"];
}

- (void) stopAUGraph{
    OSStatus statusError = AUGraphStop(processingGraph);
    [self CheckStatusError:statusError errorMessage:@"stop audio processing graph"];
}


- (void) mAaudioFormat:(AudioStreamBasicDescription *)ASBD mSampleRate:(double)sampleRate mFormatID:(UInt32)formatID mFormatFlags:(UInt32)formatFlags mBytesPerPacket:(UInt32)bytesPerPacket mFramesPerPacket:(UInt32)framesPerPacket mBytesPerFrame:(UInt32)bytesPerFrame mChannelsPerFrame:(UInt32)channelsPerFrame mBitsPerChannel:(UInt32)bitsPerChannel{
    
    AudioStreamBasicDescription *audioFormat = ASBD;
    
    memset(audioFormat, 0, sizeof(*audioFormat));
    
    audioFormat->mSampleRate = sampleRate;
    audioFormat->mFormatID = formatID;
    audioFormat->mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | formatFlags;
    audioFormat->mBytesPerPacket = bytesPerPacket;
    audioFormat->mFramesPerPacket = framesPerPacket;
    audioFormat->mBytesPerFrame = bytesPerFrame;
    audioFormat->mChannelsPerFrame = channelsPerFrame;
    audioFormat->mBitsPerChannel = bitsPerChannel;
}

@end
