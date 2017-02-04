//
//  RealTimeCaptureViewController.m
//  mulberryAR
//
//  Created by poloby on 2016/12/29.
//  Copyright © 2016年 polobymulberry. All rights reserved.
//

#import "RealTimeCaptureViewController.h"
#import "GPUManager.h"
#import "MARVideoBuffer.h"
#include <string>

using namespace std;

typedef NS_ENUM(NSInteger, SliderTag) {
    SliderTagPosX = 0,
    SliderTagPosY,
    SliderTagPosZ,
    SliderTagRotX,
    SliderTagRotY,
    SliderTagRotZ,
    SliderTagScale
};

@interface RealTimeCaptureViewController () {
    ORB_SLAM2::System *_slam;
}
@property (nonatomic, strong) GPUManager *gpuManager;
@property (nonatomic, strong) MARVideoBuffer *videoBuffer;

// edit
@property (weak, nonatomic) IBOutlet UISlider *posXSlider;
@property (weak, nonatomic) IBOutlet UISlider *posYSlider;
@property (weak, nonatomic) IBOutlet UISlider *posZSlider;
@property (weak, nonatomic) IBOutlet UISlider *rotXSlider;
@property (weak, nonatomic) IBOutlet UISlider *rotYSlider;
@property (weak, nonatomic) IBOutlet UISlider *rotZSlider;
@property (weak, nonatomic) IBOutlet UISlider *scaleSlider;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation RealTimeCaptureViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // slider
    [self.posXSlider addTarget:self action:@selector(didSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.posYSlider addTarget:self action:@selector(didSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.posZSlider addTarget:self action:@selector(didSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.rotXSlider addTarget:self action:@selector(didSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.rotYSlider addTarget:self action:@selector(didSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.rotZSlider addTarget:self action:@selector(didSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.scaleSlider addTarget:self action:@selector(didSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    
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
    self.videoBuffer = [[MARVideoBuffer alloc] initWithGPUManager:self.gpuManager slam:_slam];
    [self.videoBuffer.session startRunning];
}

#pragma mark - event responses
- (void)didSliderValueChanged:(UISlider *)slider
{
    double floatValue = slider.value;
    switch (slider.tag) {
        case SliderTagPosX:
        {
            mat4f translation = mat4f::createTranslation(floatValue, 0.0, 0.0);
            [self.gpuManager updateTranslationX:translation];
            break;
        }
        case SliderTagPosY:
        {
            mat4f translation = mat4f::createTranslation(0.0, floatValue, 0.0);
            [self.gpuManager updateTranslationY:translation];
            break;
        }
        case SliderTagPosZ:
        {
            mat4f translation = mat4f::createTranslation(0.0, 0.0, floatValue);
            [self.gpuManager updateTranslationZ:translation];
            break;
        }
        case SliderTagRotX:
        {
            mat4f rotation = mat4f::createRotationAroundAxis(floatValue, 0.0, 0.0);
            [self.gpuManager updateRotationX:rotation];
            break;
        }
        case SliderTagRotY:
        {
            mat4f rotation = mat4f::createRotationAroundAxis(0.0, floatValue, 0.0);
            [self.gpuManager updateRotationY:rotation];
            break;
        }
        case SliderTagRotZ:
        {
            mat4f rotation = mat4f::createRotationAroundAxis(0.0, 0.0, floatValue);
            [self.gpuManager updateRotationZ:rotation];
            break;
        }
        case SliderTagScale:
        {
            mat4f scale = mat4f::createScale(floatValue, floatValue, floatValue);
            [self.gpuManager updateScale:scale];
            break;
        }
        
        default:
            break;
    }
}

- (IBAction)backChooseVC:(UIButton *)button {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
