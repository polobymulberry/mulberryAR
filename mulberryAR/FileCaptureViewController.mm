//
//  FileCaptureViewController.m
//  mulberryAR
//
//  Created by poloby on 2017/1/10.
//  Copyright © 2017年 polobymulberry. All rights reserved.
//

#import "FileCaptureViewController.h"
#import "GPUManager.h"
#import "MARImgFileBuffer.h"

@interface FileCaptureViewController () {
    ORB_SLAM2::System *_slam;
}

@property (nonatomic, strong) GPUManager *gpuManager;
@property (nonatomic, strong) MARImgFileBuffer *imgFileBuffer;

@property (weak, nonatomic) IBOutlet UIButton *backChooseVCButton;

@end

@implementation FileCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.gpuManager = [[GPUManager alloc] init];
    
    if (![self.gpuManager CreateOpenGLESContext]) {
        NSLog(@"Failed to initialize context or missing resources. Application will exit..");
        return;
    }
    
    EAGLView *glView = [[EAGLView alloc] initWithFrame:CGRectMake(0, 0, 320*4.0/3.0, 320)];
    [self.view addSubview:glView];
    [self.gpuManager AttachViewToContext:glView];
    
    // slam
    // ORBvoc.txt
    const char *ORBvoc = [[[NSBundle mainBundle] pathForResource:@"ORBvoc" ofType:@"bin"] cStringUsingEncoding:[NSString defaultCStringEncoding]];
    // Settings.yaml
    const char *settings = [[[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"yaml"] cStringUsingEncoding:[NSString defaultCStringEncoding]];
    _slam = new ORB_SLAM2::System(string(ORBvoc), string(settings), ORB_SLAM2::System::MONOCULAR, false); // bUseViewer = false
    // videoBuffer
    self.imgFileBuffer = [[MARImgFileBuffer alloc] initWithGPUManager:self.gpuManager slam:_slam];
    [self.imgFileBuffer startFileStream];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backChooseVC:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
