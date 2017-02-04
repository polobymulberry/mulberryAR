//
//  NoLighting.vsh
//  Virtual Vision
//
//  Created by Abdallah Dib on 4/10/11.
//  Copyright 2011 Virtual Vision. All rights reserved.
//

attribute vec4 position;
attribute vec2 texCoord0;
attribute vec4 normal;

varying vec2 v_texCoord;
varying vec4 v_normal;

uniform mat4 matProjViewModel;
uniform mat4 matNormal;

void main()
{
	v_texCoord = texCoord0;
    v_normal = matNormal * normal;
	gl_Position = matProjViewModel * position;
}
