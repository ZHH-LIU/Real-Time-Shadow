#version 330 core

in vec2 texCoord;
out vec4 fragColor;

uniform sampler2D texture_win;

void main()
{
	fragColor = texture(texture_win, texCoord);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}

