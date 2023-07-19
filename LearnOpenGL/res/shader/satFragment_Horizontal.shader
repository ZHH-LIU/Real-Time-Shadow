#version 330 core

in vec2 texCoord;
out vec4 fragColor;

uniform int r;
uniform int index;

uniform sampler2D satMap;

//uniform bool first;

void main()
{
	vec2 color = vec2(0.0f);

	vec2 texelSize = 1.0 / textureSize(satMap, 0);

	for (int i = 0; i != r; i++)
	{
		vec2 tex = vec2(texCoord.x + i * pow(r, index) * texelSize.x, texCoord.y);
		color += texture(satMap, tex).rg;
		//color += first ? 1.0 - texture(satMap, tex).rg : texture(satMap, tex).rg;
	}

	fragColor = vec4(color, 0.0f, 1.0f);
}