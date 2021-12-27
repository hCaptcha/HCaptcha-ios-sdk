//
//  ViewController.m
//  HCaptcha_Objc_Example
//
//  Created by CAMOBAP on 12/27/21.
//  Copyright © 2021 HCaptcha. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@import HCaptcha;
@import WebKit;

@interface ViewController ()

@property (weak, nonatomic) HCaptcha *hCaptcha;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.hCaptcha = appDelegate.hCaptcha;

    [self.hCaptcha configureWebView:^(WKWebView * _Nonnull webView) {
        webView.frame = self.view.bounds;
    }];
}

- (IBAction) didPressButton:(UIButton *)button {
    [self.hCaptcha validateOn:self.view resetOnError:NO completion:^(HCaptchaResult *result) {
        NSError *error = nil;
        NSString *token = [result dematerializeAndReturnError: &error];
        NSLog(@"DONE token:%@ error:%@", token, [error description]);
    }];
}


@end
