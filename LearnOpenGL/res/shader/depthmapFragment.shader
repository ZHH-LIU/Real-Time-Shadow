#version 330 core

in vec2 texCoord;

uniform sampler2D depthmap;
uniform float near_plane;
uniform float far_plane;

out vec4 fragColor;

float LinearizeDepth(float depth)
{
	float z = depth * 2.0 - 1.0; // Back to NDC 
	return (2.0 * near_plane * far_plane) / (far_plane + near_plane - z * (far_plane - near_plane));
}

void main()
{
	float depthValue=texture(depthmap, texCoord).r;
	fragColor = vec4(vec3(depthValue), 1.0);
	//fragColor = vec4(vec3(LinearizeDepth(depthValue) / far_plane), 1.0);
		
}