//
//  ConnectionHandler.h
//  PlayMusic
//
//  Created by Seongmuk Gang on 29/12/2016.
//  Copyright © 2016 Seongmuk Gang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

typedef void(^InvitationHandler)(BOOL accept, MCSession *session);

@interface ConnectionHandler : NSObject <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCBrowserViewControllerDelegate>

#pragma mark Session, Peer, Advertiser properties
@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCPeerID *peerID;
@property (strong, nonatomic) MCAdvertiserAssistant *advertivserAssistant;
@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCBrowserViewController *browerViewController;
@property (strong, nonatomic) NSString *kServiceType;

@property (copy, nonatomic) InvitationHandler handler;

/*
// for notification centre
@property (assign, nonatomic) BOOL invitationAccept;
*/

#pragma mark Public methods
- (void)setPeerAndSessionWithDisplayName:(NSString *)peerName;
- (void)multichannelBrowserSetup: (id) objectID;
- (void)startAvertising;
- (void)stopAdvertising;

@end
