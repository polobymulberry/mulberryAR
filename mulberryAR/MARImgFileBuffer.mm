//
//  MARImgFileBuffer.m
//  mulberryAR
//
//  Created by poloby on 2017/1/10.
//  Copyright © 2017年 polobymulberry. All rights reserved.
//

#import "MARImgFileBuffer.h"

@interface MARImgFileBuffer () {
    GPUManager *_gpuManager;
    ORB_SLAM2::System *_slam;
}

@property (nonatomic, strong) dispatch_queue_t trackQueue;
@property (nonatomic, assign) BOOL isFinished;
@property (nonatomic, copy) NSString *recordPath;
@property (nonatomic, assign) NSInteger recordCount;

@end

@implementation MARImgFileBuffer

#pragma mark - init methods
- (instancetype)init
{
    if (self = [super init]) {
        _gpuManager = nil;
        _slam = nil;
        _trackQueue = dispatch_queue_create("trackimg.queue", DISPATCH_QUEUE_SERIAL);
        _isFinished = YES;
        
        _recordPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        _recordPath = [_recordPath stringByAppendingPathComponent:@"Test"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_recordPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:_recordPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        
        _recordCount = 0;
    }
    
    return self;
}

- (instancetype)initWithGPUManager:(GPUManager *)gpuManager slam:(ORB_SLAM2::System *)slam
{
    if (self = [self init]) {
        _gpuManager = gpuManager;
        _slam = slam;
    }
    
    return self;
}

- (void)startFileStream
{
    // 获取一张图片
    dispatch_async(_trackQueue, ^{
        
        while (true) {
            // 提取一张图片
            NSString *imageFileName = [NSString stringWithFormat:@"%04ld.png", (long)_recordCount++];
            NSString *recordImageFilePath = [_recordPath stringByAppendingPathComponent:imageFileName];
            if (![[NSFileManager defaultManager] fileExistsAtPath:recordImageFilePath]) {
                break;
            }
            cv::Mat _imgMat = cv::imread([recordImageFilePath cStringUsingEncoding:NSUTF8StringEncoding]);
            cv::Mat colorInput(_imgMat);
            cv::cvtColor(colorInput, colorInput, CV_BGRA2GRAY);
            
            NSDate *trackDate = [NSDate date];
            _slam->TrackMonocular(colorInput, 0);
            double trackDuration = [[NSDate date] timeIntervalSinceDate:trackDate];
            cout << "TrackMonocular time = " << trackDuration * 1000.0 << "ms" << endl;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // 绘制相机
                bool isOK = false;
                
                switch (_slam->GetTrackingState()) {
                    case ORB_SLAM2::Tracking::SYSTEM_NOT_READY:
                    {
                        cout << "SYSTEM_NOT_READY" << endl;
                        break;
                    }
                    case ORB_SLAM2::Tracking::NOT_INITIALIZED:
                    {
                        cout << "NOT_INITIALIZED" << endl;
                        break;
                    }
                    case ORB_SLAM2::Tracking::LOST:
                    {
                        cout << "LOST" << endl;
                        break;
                    }
                    case ORB_SLAM2::Tracking::NO_IMAGES_YET:
                    {
                        cout << "NO_IMAGES_YET" << endl;
                        break;
                    }
                    case ORB_SLAM2::Tracking::OK:
                    {
                        cout << "OK" << endl;
                        isOK = true;
                        
                        cv::Mat R = _slam->getCurrentPose_R();
                        cv::Mat T = _slam->getCurrentPose_T();
                        
                        float qx,qy,qz,qw;
                        qw = sqrt(1.0 + R.at<float>(0,0) + R.at<float>(1,1) + R.at<float>(2,2)) / 2.0;
                        qx = (R.at<float>(2,1) - R.at<float>(1,2)) / (4*qw);
                        qy = -(R.at<float>(0,2) - R.at<float>(2,0)) / (4*qw);
                        qz = -(R.at<float>(1,0) - R.at<float>(0,1)) / (4*qw);
                        
                        vec4f r1(1 - 2*qy*qy - 2*qz*qz, 2*qx*qy + 2*qz*qw, 2*qx*qz - 2*qy*qw, 0);
                        vec4f r2(2*qx*qy - 2*qz*qw, 1 - 2*qx*qx - 2*qz*qz, 2*qy*qz + 2*qx*qw, 0);
                        vec4f r3(2*qx*qz + 2*qy*qw, 2*qy*qz - 2*qx*qw, 1 - 2*qx*qx - 2*qy*qy, 0);
                        vec4f r4(T.at<float>(0), -T.at<float>(1), -T.at<float>(2), 1);
                        
                        float pose[16] = { r1.x, r1.y, r1.z, r1.w,
                            r2.x, r2.y, r2.z, r2.w,
                            r3.x, r3.y, r3.z, r3.w,
                            r4.x, r4.y, r4.z, r4.w };
                        
                        mat4f poseMatrix(pose);
                        mat4f scaleMatrix = mat4f::createScale(0.3, 0.3, 0.3);
                        poseMatrix = poseMatrix * scaleMatrix;
                        
                        mat4f projMatrix = mat4f::createPerspective(60.0, 640.0/480.0, 0.02, 100);
                        
                        cv::Mat showImage;
                        cv::cvtColor(_imgMat, showImage, CV_BGRA2RGBA);
                        [_gpuManager DrawFrameWithCamera:showImage modelView:poseMatrix projection:projMatrix];
                        break;
                    }
                    default:
                        break;
                }
                
                if (!isOK) {
                    cv::Mat showImage;
                    cv::cvtColor(_imgMat, showImage, CV_BGRA2RGBA);
                    [_gpuManager DrawWithCamera:showImage];
                }
            });
        }
    });
}

@end
