/*
 *  GPUManager.mm
 *  Virtual Vision
 *
 *  Created by Abdallah Dib Abdallah.dib@virtual-vison.net
 *  Copyright 2011 Virtual Vision. All rights reserved.
 *
 */

#import "GPUManager.h"
#import "CacheResourceManager.h"

@interface GPUManager () {
    mat4f _translationX;
    mat4f _translationY;
    mat4f _translationZ;
    mat4f _rotationX;
    mat4f _rotationY;
    mat4f _rotationZ;
    mat4f _scale;
}

@end

@implementation GPUManager

@synthesize  context = _context;
@synthesize contextWidth = _contextWidth;
@synthesize contextHeight = _contextHeight;


CCacheResourceManager& crm_ = CCacheResourceManager::Instance();

-(id) init
{
    self = [super init];
    
    if(self)
    {
        _tutorial = new Tutorial();
	}
	
	return self;
}

- (BOOL) CreateOpenGLESContext
{
    if (self.context != nil)
        return YES;
    
	EAGLContext * aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!aContext)
	{
		NSLog(@"Failed to create ES context");
		return FALSE;
	}
    
	else if (![EAGLContext setCurrentContext:aContext])
	{
		NSLog(@"Failed to set ES context current");
		return FALSE;
	}
	
	self.context = aContext;
    
    return _tutorial->Deploy();
}	

- (void) AttachViewToContext:(UIView*) view
{
	if (view != nil) 
	{
		_glview = (EAGLView*)view;
		[_glview setContext:self.context];
		[_glview setFramebuffer];
		self.contextWidth = [ _glview framebufferWidth ];
		self.contextHeight = [ _glview framebufferHeight ];
	}
}
- (void)dealloc
{
	[self TearOpenGLESContext];
    self.context = nil;
    SAFE_DELETE(_tutorial);
}
- (void) TearOpenGLESContext
{
    // Tear down context.
    if ([EAGLContext currentContext] == self.context)
        [EAGLContext setCurrentContext:nil];	
}

- (void)DrawFrame
{
    if(self.context)
	{
        [EAGLContext setCurrentContext:self.context];
        [_glview setFramebuffer];
    }
    
    //draw frame
    _tutorial->Frame();
    [_glview presentFramebuffer];
}

- (void)DrawWithCamera:(const cv::Mat &)imgData
{
    if (self.context) {
        [EAGLContext setCurrentContext:self.context];
        [_glview setFramebuffer];
    }
    
    // draw frame
    _tutorial->Frame(imgData);
    [_glview presentFramebuffer];
}

- (void)DrawFrameWithCamera:(const cv::Mat &)imgData modelView:(const mat4f&)modelView projection:(const mat4f&)proj
{
    if(self.context)
    {
        [EAGLContext setCurrentContext:self.context];
        [_glview setFramebuffer];
    }
    
    mat4f newModelView;
    newModelView = modelView * _translationX * _translationY * _translationZ * _rotationX * _rotationY * _rotationZ * _scale;
    
    //draw frame
    _tutorial->Frame(imgData, newModelView, proj);
    [_glview presentFramebuffer];
}

- (void)updateTranslationX:(mat4f)translationX
{
    _translationX = translationX;
}

- (void)updateTranslationY:(mat4f)translationY
{
    _translationY = translationY;
}

- (void)updateTranslationZ:(mat4f)translationZ
{
    _translationZ = translationZ;
}

- (void)updateRotationX:(mat4f)rotationX
{
    _rotationX = rotationX;
}

- (void)updateRotationY:(mat4f)rotationY
{
    _rotationY = rotationY;
}

- (void)updateRotationZ:(mat4f)rotationZ
{
    _rotationZ = rotationZ;
}

- (void)updateScale:(mat4f)scale
{
    _scale = scale;
}

@end
