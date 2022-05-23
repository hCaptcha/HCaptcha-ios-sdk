//
//  ViewController.m
//  HCaptcha_Objc_Example
//
//  Created by CAMOBAP on 12/27/21.
//  Copyright © 2021 HCaptcha. MIT License.
//

#import "ViewController.h"
#import "AppDelegate.h"

@import HCaptcha;
@import WebKit;

@interface ViewController ()

@property (weak, nonatomic) HCaptcha *hCaptcha;
@property (weak, nonatomic) WKWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.hCaptcha = appDelegate.hCaptcha;

    [self.hCaptcha configureWebView:^(WKWebView * _Nonnull webView) {
        webView.frame = self.view.bounds;
        self.webView = webView;
    }];

    [self.hCaptcha onEvent:^(enum HCaptchaEvent event, id _Nullable _) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"On Event" message: [NSString stringWithFormat:@"%ld", event, nil] preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated: YES completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:YES completion:nil];
            });
        }];
    }];
}

- (IBAction) didPressButton:(UIButton *)button {
    [self.hCaptcha validateOn:self.view resetOnError:NO completion:^(HCaptchaResult *result) {
        NSError *error = nil;
        NSString *token = [result dematerializeAndReturnError: &error];
        NSLog(@"DONE token:%@ error:%@", token, [error description]);
        [self.webView removeFromSuperview];
    }];
}


@end
