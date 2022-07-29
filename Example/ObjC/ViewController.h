//
//  ViewController.h
//  HCaptcha_Objc_Example
//
//  Copyright © 2022 HCaptcha. All rights reserved.
//

@import UIKit;

@interface ViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel* label;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* spinner;
@property (nonatomic, weak) IBOutlet UISegmentedControl *localeSegmentedControl;
@property (nonatomic, weak) IBOutlet UISwitch *visibleChallengeSwitch;
@property (nonatomic, weak) IBOutlet UIButton *validateButton;

@end

