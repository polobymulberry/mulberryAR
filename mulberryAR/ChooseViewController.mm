//
//  ChooseViewController.m
//  mulberryAR
//
//  Created by poloby on 2017/1/9.
//  Copyright © 2017年 polobymulberry. All rights reserved.
//

#import "ChooseViewController.h"
#import "RealTimeCaptureViewController.h"

@interface ChooseViewController ()

@property (weak, nonatomic) IBOutlet UIButton *realtimeCaptureButton;
@property (weak, nonatomic) IBOutlet UIButton *recordVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *chooseVideoFileButton;

@end

@implementation ChooseViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
