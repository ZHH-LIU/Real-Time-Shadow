#version 330 core

in vec2 texCoord;

out vec4 fragColor;

uniform sampler2D texColorBuffer;

void main()
{
	fragColor = texture(texColorBuffer, texCoord);
	float average = (fragColor.r + fragColor.g + fragColor.b) / 3.0;
	fragColor = vec4(average, average, average, 1.0);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}