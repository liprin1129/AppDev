//
//  ConnectionHandler.m
//  PlayMusic
//
//  Created by Seongmuk Gang on 29/12/2016.
//  Copyright © 2016 Seongmuk Gang. All rights reserved.
//

#import "ConnectionHandler.h"

@implementation ConnectionHandler

- (id) init {
    self = [super init];
    
    if (self) {
        self.session = nil;
        self.peerID = nil;
        self.advertivserAssistant = nil;
        self.kServiceType = @"rw-audioStream";
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
}
- (void)startAvertising{
    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:self.kServiceType];
    self.advertiser.delegate = self;
    [self.advertiser startAdvertisingPeer];
}

- (void)stopAdvertising{
    [self.advertiser stopAdvertisingPeer];
    self.advertiser = nil;
}

#pragma mark MCNearbyServiceAdvertiserDelegate method
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession * _Nullable))invitationHandler{
    
    self.handler = invitationHandler;
    
    self.invitationAccept = YES;
    self.handler(self.invitationAccept, self.session);
}

#pragma mark MCBrowserViewControllerDelegate methods
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
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
    
}

@end
