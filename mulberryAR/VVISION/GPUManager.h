/* GPUManager.h
 *
 * Virtual Vision Engine . Copyright (C) 2012 Abdallah DIB.
 * All rights reserved. Email: Abdallah.dib@virtual-vison.net
 * Web: <http://www.virutal-vision.net/>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.*/

#import <Foundation/Foundation.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>
#import "EAGLView.h"
#import "Tutorial.h"
#include <opencv2/opencv.hpp>

@interface GPUManager : NSObject {
@public
	EAGLView* _glview;
	GLuint _contextWidth;
	GLuint _contextHeight;
	EAGLContext *_context;
    Tutorial* _tutorial;
}

@property (nonatomic, strong) EAGLContext *context;
@property GLuint contextWidth;
@property GLuint contextHeight;

- (id) init;
- (void) AttachViewToContext:(UIView*) view;
- (BOOL) CreateOpenGLESContext;
- (void) TearOpenGLESContext;
- (void) DrawFrame;
- (void) DrawWithCamera:(const cv::Mat&)imgData;
- (void) DrawFrameWithCamera:(const cv::Mat &)imgData modelView:(const mat4f&)modelView projection:(const mat4f&)proj;

// update
- (void)updateTranslationX:(mat4f)translationX;
- (void)updateTranslationY:(mat4f)translationY;
- (void)updateTranslationZ:(mat4f)translationZ;
- (void)updateRotationX:(mat4f)rotationX;
- (void)updateRotationY:(mat4f)rotationY;
- (void)updateRotationZ:(mat4f)rotationZ;
- (void)updateScale:(mat4f)scale;

@end
