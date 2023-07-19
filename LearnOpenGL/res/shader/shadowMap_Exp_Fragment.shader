#version 330 core

in vec2 texCoord;
out vec4 fragColor;

uniform float c;
uniform sampler2D depthMap;

void main()
{
	float depthExp = exp(c * texture(depthMap, texCoord).r);
	fragColor = vec4(depthExp, 0.0, 0.0, 1.0);
}