//
//  ConnectionHandler.m
//  PlayMusic
//
//  Created by Seongmuk Gang on 29/12/2016.
//  Copyright © 2016 Seongmuk Gang. All rights reserved.
//

#import "ConnectionHandler.h"

BOOL const kProgrammaticDiscovery = NO;

@implementation ConnectionHandler

- (id) init {
    self = [super init];
    
    if (self) {
        self.session = nil;
        self.peerID = nil;
        self.advertiserAssistant = nil;
        self.kServiceType = @"rw-audioStream";
        self.streamName = @"aurioStreaming";
    }
    
    return self;
}

#pragma mark Public methods

/*  */
- (void)setPeerAndSessionWithDisplayName:(NSString *)peerName{
    self.peerID = [[MCPeerID alloc] initWithDisplayName:peerName];
    self.session = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionNone];
    self.session.delegate = self;
}

- (void)multichannelBrowserSetup: (id) objectID{
    self.browerViewController = [[MCBrowserViewController alloc] initWithServiceType:self.kServiceType session:self.session];
    self.browerViewController.delegate = objectID;
    self.objectID = objectID;
}
- (void)startAvertising{
    if (kProgrammaticDiscovery) {
        self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:self.kServiceType];
        self.advertiser.delegate = self;
        [self.advertiser startAdvertisingPeer];
    
    } else {
        self.advertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:self.kServiceType discoveryInfo:nil session:self.session];
        [self.advertiserAssistant start];
    }
}

- (void)stopAdvertising{
    if (kProgrammaticDiscovery) {
        [self.advertiser stopAdvertisingPeer];
        self.advertiser = nil;
    
    } else{
        [self.advertiserAssistant stop];
        self.advertiserAssistant = nil;
    }
}

#pragma mark Setup Sending Stream
- (void) startStream{
    NSError *error;
    if ([[self.session connectedPeers] count] == 0) {
        NSLog(@"Connection is required\n");
    } else{
        self.outputStream = [self.session startStreamWithName:self.streamName toPeer:[self.session connectedPeers][0] error:&error];
        self.outputStream.delegate = self.objectID;
        [self.outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream open];
    }
}

#pragma mark MCNearbyServiceAdvertiserDelegate method
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession * _Nullable))invitationHandler{
    
    self.handler = invitationHandler;
    
    self.handler(YES, self.session);
}

#pragma mark MCSessionDelegate methods

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    
}


-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    
}


-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
    
}


-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{

}


-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
    
    stream.delegate = self.objectID;
    [stream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    [stream open];
}

@end
