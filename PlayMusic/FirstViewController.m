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
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


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
