//
//  ViewController.h
//  HCaptcha_Objc_Example
//
//  Created by CAMOBAP on 12/27/21.
//  Copyright © 2021 HCaptcha. All rights reserved.
//

@import UIKit;

@interface ViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel* label;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* spinner;
@property (nonatomic, weak) IBOutlet UISegmentedControl *localeSegmentedControl;
@property (nonatomic, weak) IBOutlet UISwitch *visibleChallengeSwitch;
@property (nonatomic, weak) IBOutlet UIButton *validateButton;

@end

