//
//  MARVideoBuffer.h
//  mulberryAR
//
//  Created by poloby on 2016/12/29.
//  Copyright © 2016年 polobymulberry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <opencv2/opencv.hpp>
#import "GPUManager.h"
#import "System.h"

@interface MARVideoBuffer : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
    cv::Mat _imgMat;
}

@property (nonatomic, strong) AVCaptureSession *session;
// 用来录制视频
@property (nonatomic, assign) BOOL isRecord;
@property (nonatomic, assign) BOOL isStop;

- (instancetype)initWithGPUManager:(GPUManager *)gpumanager slam:(ORB_SLAM2::System *)slam;

@end
