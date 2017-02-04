//
//  RecordVideoViewController.m
//  mulberryAR
//
//  Created by poloby on 2017/1/9.
//  Copyright © 2017年 polobymulberry. All rights reserved.
//

#import "RecordVideoViewController.h"
#import "GPUManager.h"
#import "MARVideoBuffer.h"

@interface RecordVideoViewController () {
    ORB_SLAM2::System *_slam;
}

@property (nonatomic, strong) GPUManager *gpuManager;
@property (nonatomic, strong) MARVideoBuffer *videoBuffer;

@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;

@end

@implementation RecordVideoViewController

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
    
    // 初始只有recordButton能使用
    self.recordButton.enabled = YES;
    self.stopButton.enabled = NO;
    
    // slam
    // ORBvoc.txt
    const char *ORBvoc = [[[NSBundle mainBundle] pathForResource:@"ORBvoc" ofType:@"bin"] cStringUsingEncoding:[NSString defaultCStringEncoding]];
    // Settings.yaml
    const char *settings = [[[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"yaml"] cStringUsingEncoding:[NSString defaultCStringEncoding]];
    _slam = new ORB_SLAM2::System(string(ORBvoc), string(settings), ORB_SLAM2::System::MONOCULAR, false); // bUseViewer = false
    // videoBuffer
    self.videoBuffer = [[MARVideoBuffer alloc] initWithGPUManager:self.gpuManager slam:_slam];
    [self.videoBuffer.session startRunning];
}

- (IBAction)startRecord:(UIButton *)button {
    
    // 清空Test文件夹下所有的图片
    NSString *recordPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    recordPath = [recordPath stringByAppendingPathComponent:@"Test"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:recordPath]) {
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:recordPath error:nil];
        for (NSString *filename in contents) {
            if ([[filename pathExtension] isEqualToString:@"png"]) {
                [[NSFileManager defaultManager] removeItemAtPath:[recordPath stringByAppendingPathComponent:filename] error:nil];
            }
        }
    }
    
    self.videoBuffer.isRecord = YES;
    self.videoBuffer.isStop = NO;
    self.recordButton.enabled = NO;
    self.stopButton.enabled = YES;
}

- (IBAction)stopRecord:(UIButton *)button {
    self.videoBuffer.isRecord = NO;
    self.videoBuffer.isStop = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
