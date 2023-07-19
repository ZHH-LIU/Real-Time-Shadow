#version 330 core

in VS_OUT{
	vec2 texCoord;
}fs_in;

out vec4 fragColor;

uniform sampler2D texture_gold;
	
void main()
{
	fragColor = texture(texture_gold, fs_in.texCoord);
}