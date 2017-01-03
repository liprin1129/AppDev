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
    AudioBufferList rAudioBufferList;
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
    //statusError = AudioUnitRender(callbackDataStruct.rInOutAudioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    //if (statusError != noErr) NSLog(@"Error: AudioUnitRender \n\n");
    
    //printf ("SineWaveRenderProc needs %u frames at %f\n", (unsigned int)inNumberFrames, CFAbsoluteTimeGetCurrent());
    
    return statusError;
}

static OSStatus streamInputRenderCallback (void *inRefCon,
                                     AudioUnitRenderActionFlags *ioActionFlags,
                                     const AudioTimeStamp*inTimeStamp,
                                     UInt32 inBusNumber,
                                     UInt32 inNumberFrames,
                                     AudioBufferList *ioData){
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
    // Create a new audio processing graph.
    [self CheckStatusError:NewAUGraph (&processingGraph) errorMessage:@"create NewAUGraph"];
    
    //............................................................................
    // Specify the audio unit component descriptions for the audio units to be
    //    added to the graph.
    
    // I/O unit
    AudioComponentDescription iOUnitDescription;
    iOUnitDescription.componentType          = kAudioUnitType_Output;
    iOUnitDescription.componentSubType       = kAudioUnitSubType_RemoteIO;
    iOUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    iOUnitDescription.componentFlags         = 0;
    iOUnitDescription.componentFlagsMask     = 0;
    
    // Multichannel mixer unit
    AudioComponentDescription MixerUnitDescription;
    MixerUnitDescription.componentType          = kAudioUnitType_Mixer;
    MixerUnitDescription.componentSubType       = kAudioUnitSubType_MultiChannelMixer;
    MixerUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    MixerUnitDescription.componentFlags         = 0;
    MixerUnitDescription.componentFlagsMask     = 0;
    
    //............................................................................
    // Add nodes to the audio processing graph.
    NSLog (@"Adding nodes to audio processing graph");
    
    AUNode   iONode;         // node for I/O unit
    AUNode   mixerNode;      // node for Multichannel Mixer unit
    
    // Add the nodes to the audio processing graph
    [self CheckStatusError:AUGraphAddNode (processingGraph, &iOUnitDescription, &iONode) errorMessage:@"add AUGraphNewNode for I/O unit"];
    [self CheckStatusError:AUGraphAddNode (processingGraph, &MixerUnitDescription, &mixerNode) errorMessage:@"add AUGraphNewNode fir Mixer unit"];
    
    
    //............................................................................
    // Open the audio processing graph
    
    // Following this call, the audio units are instantiated but not initialized
    //    (no resource allocation occurs and the audio units are not in a state to
    //    process audio).
    [self CheckStatusError:AUGraphOpen (processingGraph) errorMessage:@"open AUGraph"];
    
    
    //............................................................................
    // Obtain the mixer unit instance from its corresponding node.
    [self CheckStatusError:AUGraphNodeInfo (processingGraph, mixerNode, NULL, &_mixerUnit) errorMessage:@"obtain mixer AUGraphNodeInfo"];
    // Obtain the IO unit instance from its corresponding node.
    [self CheckStatusError:AUGraphNodeInfo (processingGraph, iONode, NULL, &_ioUnit) errorMessage:@"obtain IO AUGraphNodeInfo"];
    
    //............................................................................
    // Multichannel Mixer unit Setup
    
    UInt32 busCount   = 2;    // bus count for mixer unit input
    UInt32 streamBus   = 0;    // mixer unit bus 0 will be mono and will take the stream sound
    UInt32 micBus  = 1;    // mixer unit bus 1 will be mono and will take the mic sound
    
    
    NSLog (@"Setting mixer unit input bus count to: %u", (unsigned int)busCount);
    [self CheckStatusError:AudioUnitSetProperty (self.mixerUnit, kAudioUnitProperty_ElementCount,kAudioUnitScope_Input, 0, &busCount, sizeof (busCount)) errorMessage:@"set AudioUnitSetProperty for mixer unit bus count"];
    
    
    NSLog (@"Setting kAudioUnitProperty_MaximumFramesPerSlice for mixer unit global scope");
    // Increase the maximum frames per slice allows the mixer unit to accommodate the
    //    larger slice size used when the screen is locked.
    UInt32 maximumFramesPerSlice = 4096;
    [self CheckStatusError:AudioUnitSetProperty (self.mixerUnit,kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, sizeof (maximumFramesPerSlice)) errorMessage:@"set AudioUnitSetProperty mixer unit input stream format"];
    
    // Enable input and output on AURemoteIO
    // Input is enabled on the input scope of the input element
    // Output is enabled on the output scope of the output element
    UInt32 one = 1;
    [self CheckStatusError:AudioUnitSetProperty(self.ioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one)) errorMessage:@"enable input on AURemoteIO"];
    [self CheckStatusError:AudioUnitSetProperty(self.ioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one)) errorMessage:@"enalbe output on AURemoteIO"];
    
    // Set output audio stream format description of input element
    [self mAaudioFormat:&myASBD mSampleRate:44100.0 mFormatID:kAudioFormatLinearPCM mFormatFlags:kAudioFormatFlagIsSignedInteger mBytesPerPacket:2 mFramesPerPacket:1 mBytesPerFrame:2 mChannelsPerFrame:1 mBitsPerChannel:16];
    /* !!!!!!!!!!!!!! Mic bus is 1 */
    [self CheckStatusError:AudioUnitSetProperty(self.ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, micBus, &myASBD, sizeof(myASBD)) errorMessage:@"set format on AURemoteIO output"];
    
    // Attach the input render callback and context to one input bus
    AURenderCallbackStruct streamInputCallbackStruct;
    streamInputCallbackStruct.inputProc = &streamInputRenderCallback;
    streamInputCallbackStruct.inputProcRefCon = nil;
    
    NSLog (@"Registering the stream render callback with mixer unit input bus 0");
    [self CheckStatusError:AUGraphSetNodeInputCallback(processingGraph, mixerNode, streamBus, &streamInputCallbackStruct) errorMessage:@"set AUGraphSetNodeInputCallback to mixer input bus 0"];
    
    NSLog (@"Setting mono stream format for mixer unit \"stream\" input bus");
    [self CheckStatusError:AudioUnitSetProperty(self.mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, streamBus, &myASBD, sizeof(myASBD)) errorMessage:@"set AudioUnitSetProperty mixer unit stream input bus stream format"];
    
    // Set the mixer unit's output sample rate format. This is the only aspect of the output stream format that must be explicitly set.
    NSLog (@"Setting sample rate for mixer unit output scope");
    [self CheckStatusError:AudioUnitSetProperty(self.mixerUnit, kAudioUnitProperty_SampleRate, kAudioUnitScope_Output, 0, &_graphSampleRate, sizeof(_graphSampleRate)) errorMessage:@"set AudioUnitSetProperty mixer unit output stream format)"];
    
    //............................................................................
    //Connecting Audio Units using the Audio Processing Graph API
    [self CheckStatusError:AUGraphConnectNodeInput(processingGraph, iONode, 1, mixerNode, 1) errorMessage:@"connet audio unit -> mixer"];
    [self CheckStatusError:AUGraphConnectNodeInput(processingGraph, mixerNode, 0, iONode, 0) errorMessage:@"connect mixer -> audio unit"];

    //............................................................................
    // 6. Initialize the AURemoteIO instance
    //............................................................................
    [self CheckStatusError:AUGraphInitialize(processingGraph) errorMessage:@"initialise AURemoteIO instance"];
}

- (void) startIOUnit{
    [self CheckStatusError:AudioOutputUnitStart(self.ioUnit) errorMessage:@"start audio IO unit"];
}

- (void) stopIOUnit{
    [self CheckStatusError:AudioOutputUnitStop(self.ioUnit) errorMessage:@"stop audio IO unit"];
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
/*
- (OSStatus) inputRenderCallback: (void*) inRefCon flags:(AudioUnitRenderActionFlags*)ioActionFlags time:(const AudioTimeStamp*)inTimeStamp  num:(UInt32)inBusNumber frame:(UInt32)                      inNumberFrames list:(AudioBufferList*) ioData{
    OSStatus statusError;
    statusError = AudioUnitRender(ioUnitInstance, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    
    //printf ("SineWaveRenderProc needs %u frames at %f\n", (unsigned int)inNumberFrames, CFAbsoluteTimeGetCurrent());
    if (statusError != noErr) NSLog(@"Error: AudioUnitRender \n\n");
    
    return statusError;
}
 */
@end
