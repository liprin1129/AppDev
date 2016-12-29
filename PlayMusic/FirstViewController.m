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
    
    // set KVO for connection invitation
    [self.connectionHandler addObserver:self
                             forKeyPath:@"invitationAccept"
                                options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                context:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark KVO for accepted invitation
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"invitationAccept"]) {
        NSLog(@"Invitation accepted\n");
        NSLog(@"%@", change);
    }
}

# pragma mark button click management
- (IBAction)audioStreamStartButton:(id)sender {
    if (!self.audioButton.selected) {
        
        [self.audioHandler startAUGraph];
        self.audioButton.selected = YES;
    } else {
        
        [self.audioHandler stopAUGraph];
        self.audioButton.selected = NO;
    }
}

- (IBAction)connectionStartButton:(id)sender {
    if (!self.connectionButton.selected) {
        [self.connectionHandler startAvertising];
        [self.connectionHandler multichannelBrowserSetup:self];
        [self presentViewController:[self.connectionHandler browerViewController] animated:YES completion:nil];
        self.connectionButton.selected = YES;
    } else {
        [self.connectionHandler stopAdvertising];
        self.connectionButton.selected = NO;
    }
}
@end
