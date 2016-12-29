//
//  FirstViewController.m
//  PlayMusic
//
//  Created by Seongmuk Gang on 28/12/2016.
//  Copyright © 2016 Seongmuk Gang. All rights reserved.
//

#import "FirstViewController.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _audioHandler = [(AppDelegate *)[[UIApplication sharedApplication] delegate] audioInOutHandler];
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
@end
