#version 330 core

in VS_OUT
{
	vec2 texCoord;
}fs_in;

uniform sampler2D texture_floor;

out vec4 fragColor;

void main()
{
	fragColor = texture(texture_floor, fs_in.texCoord);
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}