//
//  AppDelegate.h
//  PlayMusic
//
//  Created by Seongmuk Gang on 28/12/2016.
//  Copyright © 2016 Seongmuk Gang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioInOutHandler.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) AudioInOutHandler *audioInOutHandler;

@end

