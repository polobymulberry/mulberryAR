//
//  NoLighting.fsh
//  Virtual Vision
//
//  Created by Abdallah Dib on 4/10/11.
//  Copyright 2011 Virtual Vision. All rights reserved.
//

precision highp float;

uniform sampler2D texture0;
varying vec2 v_texCoord;
varying vec4 v_normal;

void main()
{
    gl_FragColor =  texture2D( texture0, v_texCoord);
    vec3 lightDir = vec3(0.0, 0.0, 1.0);
    float dotRes = dot(normalize(v_normal.xyz), normalize(lightDir));
    float diffuse = min(max(dotRes, 0.0), 1.0);
    gl_FragColor.rgb = vec3(diffuse * gl_FragColor.rgb);
}
