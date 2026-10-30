//
//  AppDelegate.m
//  HCaptcha_Objc_Example
//
//  Copyright © 2022 HCaptcha. MIT License.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // hCaptcha init
    HCaptchaConfig *config = [[HCaptchaConfig alloc] initWithApiKey:@"a5f74b19-9e45-40e0-b45d-47ff91b7a6c2"
                                                             baseURL:[NSURL URLWithString: @"http://localhost"]];
    self.hCaptcha = [[HCaptcha alloc] initWithConfig:config error:nil];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateInitialViewController];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
