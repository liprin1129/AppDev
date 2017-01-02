//
//  AudioInOutHandler.m
//  PlayMusic
//
//  Created by Seongmuk Gang on 28/12/2016.
//  Copyright © 2016 Seongmuk Gang. All rights reserved.
//

#import "AudioInOutHandler.h"

struct CallbackData {
    AudioUnit rInOutAudioUnit;
} callbackDataStruct = {NULL};

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
    OSStatus statusError;
    statusError = AudioUnitRender(callbackDataStruct.rInOutAudioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    //printf ("SineWaveRenderProc needs %u frames at %f\n", (unsigned int)inNumberFrames, CFAbsoluteTimeGetCurrent());
    if (statusError != noErr) NSLog(@"Error: AudioUnitRender \n\n");
    
    return statusError;
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
    
    //............................................................................
    // 1. Create a new instance of AURemoteIO
    //............................................................................
    
    // Specify the audio unit component descriptions for the audio units to be
    //    added to the graph.
    AudioComponentDescription ioUnitDescription;        // I/O unit
    ioUnitDescription.componentType         = kAudioUnitType_Output;
    ioUnitDescription.componentSubType      = kAudioUnitSubType_RemoteIO;
    ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioUnitDescription.componentFlags        = 0;
    ioUnitDescription.componentFlagsMask    = 0;
    
    // Finds the next component that matches a specified AudioComponentDescription
    // structure after a specified audio component.
    AudioComponent audioComponent = AudioComponentFindNext(NULL, &ioUnitDescription);
    [self CheckStatusError:AudioComponentInstanceNew(audioComponent, &ioUnitInstance) errorMessage:@"couldn't create a new instance of AURemoteIO"];
    
    
    //............................................................................
    // 2. Enable input and output on AURemoteIO
    //
    //  Input is enabled on the input scope of the input element
    //  Output is enabled on the output scope of the output element
    //............................................................................
    
    UInt32 one = 1;
    [self CheckStatusError:AudioUnitSetProperty(ioUnitInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one)) errorMessage:@"enable input on AURemoteIO"];
    [self CheckStatusError:AudioUnitSetProperty(ioUnitInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one)) errorMessage:@"enalbe output on AURemoteIO"];
    
    //............................................................................
    // 3. Explicitly set the input and output client formats
    //
    // sample rate = 44100, num channels = 1, format = 32 bit floating point
    //............................................................................
    
    [self mAaudioFormat:&myASBD mSampleRate:self.graphSampleRate mFormatID:kAudioFormatLinearPCM mFormatFlags:kAudioFormatFlagIsSignedInteger mBytesPerPacket:2 mFramesPerPacket:1 mBytesPerFrame:2 mChannelsPerFrame:1 mBitsPerChannel:16];
    
    // Set audio stream format for output of input element
    [self CheckStatusError:AudioUnitSetProperty(ioUnitInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &myASBD, sizeof(myASBD)) errorMessage:@"set the input client format on AURemoteIO"];
    
    // Set audio stream format for input of output element
    [self CheckStatusError:AudioUnitSetProperty(ioUnitInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &myASBD, sizeof(myASBD)) errorMessage:@"set the output client format on AURemoteIO"];
    /*
    // Set the MaximumFramesPerSlice property. This property is used to describe to an audio unit the maximum number of samples it will be asked to produce on any single given call to AudioUnitRender.
    UInt32 maxFramesPerSlice = 4096;
    [self CheckStatusError:AudioUnitSetProperty(ioUnitInstance, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(UInt32)) errorMessage:@"set max frames per slice on AURemoteIO"];
    
    // Get the property value back from AURemoteIO. We are going to use this value to allocate buffers accordingly
    UInt32 propSize = sizeof(UInt32);
    [self CheckStatusError:AudioUnitGetProperty(ioUnitInstance, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, &propSize) errorMessage:@"get max frames per slice on AURemoteIO"];
    */
    
    //............................................................................
    // 4. We need references to certain data in the render callback
    //
    // This simple struct is used to hold that information
    //............................................................................
    callbackDataStruct.rInOutAudioUnit = ioUnitInstance;
    
    
    //............................................................................
    // 5. Set the render callback on AURemoteIO
    //
    // Attach the input render callback to the input scope of the output element
    //............................................................................
    AURenderCallbackStruct renderCallbackStruct;
    renderCallbackStruct.inputProc = &inputRenderCallback;
    renderCallbackStruct.inputProcRefCon = NULL;
    [self CheckStatusError:AudioUnitSetProperty(ioUnitInstance, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(renderCallbackStruct)) errorMessage:@"set render callback on AURemoteIO"];
    
    //............................................................................
    // 6. Initialize the AURemoteIO instance
    //............................................................................
    [self CheckStatusError:AudioUnitInitialize(ioUnitInstance) errorMessage:@"initialise AURemoteIO instance"];
}

- (void) startIOUnit{
    [self CheckStatusError:AudioOutputUnitStart(ioUnitInstance) errorMessage:@"start audio IO unit"];
}

- (void) stopIOUnit{
    [self CheckStatusError:AudioOutputUnitStop(ioUnitInstance) errorMessage:@"stop audio IO unit"];
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
