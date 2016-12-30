//
//  FirstViewController.h
//  PlayMusic
//
//  Created by Seongmuk Gang on 28/12/2016.
//  Copyright © 2016 Seongmuk Gang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface FirstViewController : UIViewController <MCBrowserViewControllerDelegate>

@property (strong, nonatomic) id audioHandler;
@property (strong, nonatomic) id connectionHandler;
@property (weak, nonatomic) MCSession *session;

@property (weak, nonatomic) IBOutlet UIButton *audioButton;
@property (weak, nonatomic) IBOutlet UIButton *connectionButton;
@property (weak, nonatomic) IBOutlet UIButton *streamButton;

- (IBAction)audioStartButton:(id)sender;
- (IBAction)connectionStartButton:(id)sender;
- (IBAction)connectedStreamStartButton:(id)sender;


@end

