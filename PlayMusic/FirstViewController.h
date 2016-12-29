//
//  FirstViewController.h
//  PlayMusic
//
//  Created by Seongmuk Gang on 28/12/2016.
//  Copyright © 2016 Seongmuk Gang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface FirstViewController : UIViewController

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) id audioHandler;

@property (weak, nonatomic) IBOutlet UIButton *audioButton;

- (IBAction)audioStreamStartButton:(id)sender;

@end

