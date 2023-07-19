#version 330 core

in vec2 texCoord;
out vec4 fragColor;

uniform sampler2D texture_grass;

void main()
{
	vec4 texColor = vec4(texture(texture_grass, texCoord));
	if (texColor.a < 0.1)
	{
		discard;
	}
	fragColor = texColor;
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}
