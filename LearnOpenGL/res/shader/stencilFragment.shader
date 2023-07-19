#version 330 core

in vec2 texCoord;
out vec4 fragColor;

uniform sampler2D texture_diffuse;

void main()
{
	fragColor = vec4(texture(texture_diffuse, texCoord));
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}