//
//  MARImgFileBuffer.h
//  mulberryAR
//
//  Created by poloby on 2017/1/10.
//  Copyright © 2017年 polobymulberry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUManager.h"
#import "System.h"

@interface MARImgFileBuffer : NSObject

- (instancetype)initWithGPUManager:(GPUManager *)gpuManager slam:(ORB_SLAM2::System *)slam;
- (void)startFileStream;

@end
