//
//  MARVideoBuffer.m
//  mulberryAR
//
//  Created by poloby on 2016/12/29.
//  Copyright © 2016年 polobymulberry. All rights reserved.
//

#import "MARVideoBuffer.h"

@interface MARVideoBuffer () {
    GPUManager *_gpuManager;
    ORB_SLAM2::System *_slam;
}

@property (nonatomic, strong) dispatch_queue_t trackQueue;
@property (nonatomic, assign) BOOL isFinished;
@property (nonatomic, copy) NSString *recordPath;
@property (nonatomic, assign) NSInteger recordCount;

@end

@implementation MARVideoBuffer

#pragma mark - init methods
- (instancetype)init
{
    if (self = [super init]) {
        _gpuManager = nil;
        _slam = nil;
        _trackQueue = dispatch_queue_create("track.queue", DISPATCH_QUEUE_SERIAL);
        _isFinished = YES;
        
        _isRecord = NO;
        _isStop = NO;
        
        // record path
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

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.isFinished) {
    
        self.isFinished = NO;
        // 时间戳，以后的文章需要该信息。此处可以忽略
        CMTime time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        double timeStamp = time.value / time.timescale;
        
        // 获取图像缓存区内容
        CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        // 锁定pixelBuffer的基址，与下面解锁基址成对
        // CVPixelBufferLockBaseAddress要传两个参数
        // 第一个参数是你要锁定的buffer的基址,第二个参数目前还未定义,直接传'0'即可
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        
        // 获取图像缓存区的宽高
        int buffWidth = static_cast<int>(CVPixelBufferGetWidth(pixelBuffer));
        int buffHeight = static_cast<int>(CVPixelBufferGetHeight(pixelBuffer));
        
//        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        // 这一步很重要，将图像缓存区的内容转化为C语言中的unsigned char指针
        // 因为我们在相机设置时，图像格式为BGRA，而后面OpenGL ES的纹理格式为RGBA
        // 这里使用OpenCV转换格式，当然，你也可以不用OpenCV，手动直接交换R和B两个分量即可
//        unsigned char* ptr = (unsigned char*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        unsigned char* imageData = (unsigned char*)CVPixelBufferGetBaseAddress(pixelBuffer);
        _imgMat = cv::Mat(buffHeight, buffWidth, CV_8UC4, imageData);
//        NSData *data = [[NSData alloc] initWithBytes:ptr length:buffWidth*buffHeight*4];
        // 解锁pixelBuffer的基址
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
//        CGBitmapInfo bitmapInfo;
//        bitmapInfo = (CGBitmapInfo)kCGImageAlphaNoneSkipFirst;
//        bitmapInfo |= kCGBitmapByteOrder32Little;
//        
//        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
//        
//        CGImageRef imageRef = CGImageCreate(buffWidth, buffHeight, 8, 8 * 4, buffWidth * 4, colorSpace, bitmapInfo, provider, NULL, false, kCGRenderingIntentDefault);
//        _imgMat = cv::Mat(buffHeight, buffWidth, CV_8UC4);
//        CGContextRef contextRef = CGBitmapContextCreate(_imgMat.data, buffWidth, buffHeight, 8, _imgMat.step[0], colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
//        
//        CGContextDrawImage(contextRef, CGRectMake(0, 0, buffWidth, buffHeight), imageRef);
//        CGContextRelease(contextRef);
//        CGImageRelease(imageRef);
//        CGDataProviderRelease(provider);
//        CGColorSpaceRelease(colorSpace);
        
        dispatch_async(_trackQueue, ^{
            cv::Mat colorInput(_imgMat);
            cv::cvtColor(colorInput, colorInput, CV_BGRA2GRAY);
            
            NSDate *trackDate = [NSDate date];
            _slam->TrackMonocular(colorInput, timeStamp);
            double trackDuration = [[NSDate date] timeIntervalSinceDate:trackDate];
            cout << "TrackMonocular time = " << trackDuration * 1000.0 << "ms" << endl;
            
            if (_isRecord && !_isStop) {
                NSString *imageFileName = [NSString stringWithFormat:@"%04ld.png", (long)_recordCount++];
                NSString *recordImageFilePath = [_recordPath stringByAppendingPathComponent:imageFileName];
                
                std::vector<int> compressParams;
                compressParams.push_back(CV_IMWRITE_PNG_COMPRESSION);
                compressParams.push_back(0);
                cv::imwrite([recordImageFilePath cStringUsingEncoding:NSUTF8StringEncoding], _imgMat, compressParams);
            }
            
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
            
            self.isFinished = YES;
        });
    }
}

#pragma mark - getters and setters
- (AVCaptureSession *)session
{
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];
        // 开始对session进行配置，和[_session commitConfiguration];
        // 两者之间填充的就是配置内容，主要是输入输出配置
        // 也就是AVCaptureDeviceInput和AVCaptureVideoDataOutput
        [_session beginConfiguration];
        // 相机输出的分辨率为640x480
        // 后面会利用该相机输出图像做一些处理，所以分辨率过高或者过低都不好。
        [_session setSessionPreset:AVCaptureSessionPreset640x480];
        
        // 构建视频捕捉设备，AVMediaTypeVideo表示的是视频图像的输入
        AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (videoDevice == nil) {
            return nil;
        }
        
        NSError *error = nil;
        
        // 对该捕捉设备进行配置，使用了lockForConfiguration和unlockForConfiguration进行配对
        if ([videoDevice lockForConfiguration:&error]) {
            // 开启自动曝光
            if ([videoDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [videoDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            
            // 开启自动白平衡
            if ([videoDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                [videoDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
            }
            
            // 将焦距设置在最远的位置（接近无限远）以获取最好的color/depth aligment
            [videoDevice setFocusModeLockedWithLensPosition:1.0f completionHandler:nil];
            // 设置帧速率，为了使帧率恒定，将最小和最大帧率设为一样
            // CMTimeMake(1,30)表示帧率为1秒/30帧
            [videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 30)];
            [videoDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 30)];
            
            [videoDevice unlockForConfiguration];
        }
        
        // 将视频设备作为信息输入来源
        // AVCaptureDeviceInput是AVCaptureInput的子类
        // 特别之处在于，它通过捕获设备来获取多媒体信息
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        // 给session添加了输入源，下面要添加输出部分
        [_session addInput:input];
        
        // 输出部分
        // AVCaptureVideoDataOutput是AVCaptureOutput的子类
        // 特别之处在于，它是专门处理视频图像的输出
        AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
        // 下一帧frame之前如果还没有处理好这帧，就丢弃该帧
        [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
        // 使用BGRA作为图像像素格式
        [dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        // 使用AVCaptureVideoDataOutputSampleBufferDelegate代理方法处理每帧图像
        [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        // 给session添加输出源
        [_session addOutput:dataOutput];
        
        // 提交配置
        [_session commitConfiguration];
    }
    
    return _session;
}

@end
