#version 330 core

in vec2 texCoord;

out float fragColor;

uniform sampler2D ssaoColorBuffer;

void main()
{
	vec2 offset = 1.0f / vec2(textureSize(ssaoColorBuffer, 0));
	float result = 0.0f;

	for (int i = -2; i != 2; i++)
	{
		for (int j = -2; j != 2; j++)
		{
			vec2 texOffset = vec2(float(i), float(j)) * offset;
			result += texture(ssaoColorBuffer, texCoord + texOffset).r;
		}
	}

	fragColor = result / 16.0f;
}