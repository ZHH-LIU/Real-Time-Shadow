#version 330 core

in vec2 texCoord;

out vec4 fragColor;

uniform sampler2D texColorBuffer;

void main()
{
	fragColor = vec4(1.0-vec3(texture(texColorBuffer, texCoord)),1.0);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}