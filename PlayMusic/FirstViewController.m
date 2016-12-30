//
//  FirstViewController.m
//  PlayMusic
//
//  Created by Seongmuk Gang on 28/12/2016.
//  Copyright © 2016 Seongmuk Gang. All rights reserved.
//

#import "FirstViewController.h"

@interface FirstViewController (){
    AppDelegate *_appDelegate;
}

@end

@implementation FirstViewController

//@synthesize _appDelegate;
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set AppDelegate delegate
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // set audio handler
    self.audioHandler = [_appDelegate audioInOutHandler];
    
    // set conection handler
    self.connectionHandler = [_appDelegate connectionHandler];
    [self.connectionHandler setPeerAndSessionWithDisplayName:[UIDevice currentDevice].name];
    
    /*
    // set KVO for connection invitation
    [self.connectionHandler addObserver:self
                             forKeyPath:@"invitationAccept"
                                options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                context:nil];
     */
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
# pragma mark KVO for accepted invitation
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"invitationAccept"]) {
        NSLog(@"\n\n\n\n\nInvitation accepted\n\n\n\n\n");
        NSLog(@"%@", change);
    }
}
*/

#pragma mark MCBrowserViewControllerDelegate methods
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
    
    // check the number of connections
    self.session = (MCSession*)[self.connectionHandler session];
    NSLog(@"\n %lu \n", (unsigned long)[[self.session connectedPeers] count]);
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
    
    // check the number of connections
    self.session = (MCSession*)[self.connectionHandler session];
    NSLog(@"\n %lu \n", (unsigned long)[[self.session connectedPeers] count]);
}

# pragma mark button click management
- (IBAction)audioStartButton:(id)sender {
    if (!self.audioButton.selected) {
        
        [self.audioHandler startAUGraph];
        self.audioButton.selected = YES;
    } else {
        
        [self.audioHandler stopAUGraph];
        self.audioButton.selected = NO;
    }
}

- (IBAction)connectionStartButton:(id)sender {
    [self.connectionHandler startAvertising];
    [self.connectionHandler multichannelBrowserSetup:self];
    [self presentViewController:[self.connectionHandler browerViewController] animated:YES completion:nil];
}

- (IBAction)connectedStreamStartButton:(id)sender {
    if (!self.streamButton.selected && ([[self.session connectedPeers] count] > 0)) {
        [self.connectionHandler startStream];
        NSLog(@"\n stream opened \n");
        
        self.streamButton.selected = YES;
    } else if (!self.streamButton.selected && ([[self.session connectedPeers] count] == 0)) {
        UIAlertController *connectionAlert = [UIAlertController alertControllerWithTitle:@"Streaming Error!" message:@"You must have at least one connection to a peer" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *connectionAlertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [connectionAlert addAction:connectionAlertAction];
        [self presentViewController:connectionAlert animated:YES completion:nil];
    } else if (self.streamButton.selected && ([[self.session connectedPeers] count] > 0)){
        NSLog(@"\n stream closed \n");
        self.streamButton.selected = NO;
    }
}
@end
