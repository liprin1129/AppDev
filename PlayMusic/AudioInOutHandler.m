//
//  AudioInOutHandler.m
//  PlayMusic
//
//  Created by Seongmuk Gang on 28/12/2016.
//  Copyright © 2016 Seongmuk Gang. All rights reserved.
//

#import "AudioInOutHandler.h"

static OSStatus inputRenderCallback (
                                     
                                     void                        *inRefCon,      // A pointer to a struct containing the complete audio data
                                     //    to play, as well as state information such as the
                                     //    first sample to play on this invocation of the callback.
                                     AudioUnitRenderActionFlags  *ioActionFlags, // Unused here. When generating audio, use ioActionFlags to indicate silence
                                     //    between sounds; for silence, also memset the ioData buffers to 0.
                                     const AudioTimeStamp        *inTimeStamp,   // Unused here.
                                     UInt32                      inBusNumber,    // The mixer unit input bus that is requesting some new
                                     //        frames of audio data to play.
                                     UInt32                      inNumberFrames, // The number of frames of audio to provide to the buffer(s)
                                     //        pointed to by the ioData parameter.
                                     AudioBufferList             *ioData         // On output, the audio data to play. The callback's primary
//        responsibility is to fill the buffer(s) in the
//        AudioBufferList.
) {
    printf ("SineWaveRenderProc needs %u frames at %f\n", (unsigned int)inNumberFrames, CFAbsoluteTimeGetCurrent());
    
    return noErr;
}

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
    
    //............................................................................
    // 1. Instantiate and open an audio processing graph
    //............................................................................
    
    // Create a new audio processing graph.
    statusError = NewAUGraph(&processingGraph);
    [self CheckStatusError:statusError errorMessage:@"create new AUGraph"];
    
    // Specify the audio unit component descriptions for the audio units to be
    //    added to the graph.
    AudioComponentDescription ioUnitDescription;        // I/O unit
    ioUnitDescription.componentType         = kAudioUnitType_Output;
    ioUnitDescription.componentSubType      = kAudioUnitSubType_RemoteIO;
    ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioUnitDescription.componentFlags        = 0;
    ioUnitDescription.componentFlagsMask    = 0;
    
    // Add nodes to the audio processing graph.
    AUNode ioNode;              // node for I/O unit
    
    statusError = AUGraphAddNode(processingGraph, &ioUnitDescription, &ioNode);
    [self CheckStatusError:statusError errorMessage:@"add I/O node"];
    
    // Open the audio processing graph
    statusError = AUGraphOpen(processingGraph);
    [self CheckStatusError:statusError errorMessage:@"open AUGraph"];
    
    //............................................................................
    // 2. Obtain the unit instance from its corresponding node.
    //............................................................................
    
    statusError = AUGraphNodeInfo(processingGraph, ioNode, NULL, &ioUnitInstance);
    [self CheckStatusError:statusError errorMessage:@"get AUGraph node info"];
    
    //............................................................................
    // 3. Configure the unit
    //............................................................................
    
    //  *Enable input and output on AURemoteIO
    //  Input is enabled on the input scope of the input element
    //  Output is enabled on the output scope of the output element
    UInt32 one = 1;
    
    statusError = AudioUnitSetProperty(ioUnitInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
    [self CheckStatusError:statusError errorMessage:@"enable input on AURemoteIO"];
    
    statusError = AudioUnitSetProperty(ioUnitInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one));
    [self CheckStatusError:statusError errorMessage:@"enable Output on AURemoteIO"];
    
    // Set audio stream format of input element
    [self mAaudioFormat:&myASBD mSampleRate:self.graphSampleRate mFormatID:kAudioFormatLinearPCM mFormatFlags:kAudioFormatFlagIsSignedInteger mBytesPerPacket:2 mFramesPerPacket:1 mBytesPerFrame:2 mChannelsPerFrame:1 mBitsPerChannel:16];
    
    statusError = AudioUnitSetProperty(ioUnitInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &myASBD, sizeof(myASBD));
    [self CheckStatusError:statusError errorMessage:@"set the input client format on AURemoteIO"];
    
    statusError = AudioUnitSetProperty(ioUnitInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &myASBD, sizeof(myASBD));
    [self CheckStatusError:statusError errorMessage:@"set the output client format on AURemoteIO"];
    
    // Set the MaximumFramesPerSlice property. This property is used to describe to an audio unit the maximum number
    // of samples it will be asked to produce on any single given call to AudioUnitRender
    UInt32 maxFramesPerSlice = 4096;
    statusError = AudioUnitSetProperty(ioUnitInstance, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(UInt32));
    
    [self CheckStatusError:statusError errorMessage:@"couldn't set max frames per slice on AURemoteIO"];
    
    // Get the property value back from AURemoteIO. We are going to use this value to allocate buffers accordingly
    UInt32 propSize = sizeof(UInt32);
    statusError = AudioUnitGetProperty(ioUnitInstance, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, &propSize);
    
    [self CheckStatusError:statusError errorMessage:@"couldn't get max frames per slice on AURemoteIO"];
    
    // Attach the input render callback to the input scope of the output element
    AURenderCallbackStruct inputCallbackStruct;
    inputCallbackStruct.inputProc = &inputRenderCallback;
    inputCallbackStruct.inputProcRefCon = NULL;
    
    statusError = AUGraphSetNodeInputCallback(processingGraph, ioNode, 0, &inputCallbackStruct);
    [self CheckStatusError:statusError errorMessage:@"enable setting AUGraphSetNodeInputCallback"];
    
    /*//............................................................................
    // Connect the nodes of the audio processing graph
    //Connecting Audio Units using the Audio Processing Graph API
    statusError = AUGraphConnectNodeInput(processingGraph, ioNode, 1, ioNode, 0);
    [self CheckStatusError:statusError errorMessage:@"connet audio units"];*/
    
    //............................................................................
    // Initialize audio processing graph
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
