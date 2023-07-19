#version 330 core

in vec2 texCoord;
out vec4 fragColor;

uniform sampler2D depthMap;

void main()
{
	float depth = texture(depthMap, texCoord).r;
	fragColor = vec4(depth, depth * depth, 0.0, 1.0);
}