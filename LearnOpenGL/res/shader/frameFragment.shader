#version 330 core

in vec2 texCoord;

out vec4 fragColor;

uniform sampler2D texColorBuffer;

void main()
{
	fragColor = vec4(texture(texColorBuffer, texCoord).rgb,1.0f);
	//gamma
	float gamma = 2.2;
	fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}