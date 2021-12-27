//
//  AppDelegate.m
//  HCaptcha_Objc_Example
//
//  Created by CAMOBAP on 12/27/21.
//  Copyright © 2021 HCaptcha. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // hCaptcha init
    self.hCaptcha = [[HCaptcha alloc] initWithApiKey:@"a5f74b19-9e45-40e0-b45d-47ff91b7a6c2"
                                             baseURL:[NSURL URLWithString: @"http://localhost"]
                                               error:nil];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateInitialViewController];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
