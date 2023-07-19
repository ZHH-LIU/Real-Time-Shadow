#version 330 core

in vec2 texCoord;
out vec4 fragColor;

uniform sampler2D texColorBuffer;
uniform bool horizontal;
uniform int kernelSize;

const float weight[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);


void main()
{
	vec2 texOffset = 1.0 / textureSize(texColorBuffer, 0);
	float result = texture(texColorBuffer, texCoord).r * weight[0];
	float weightTotal = weight[0];

	if (horizontal)
	{
		for (int i = 1; i != kernelSize; i++)
		{
			result += texture(texColorBuffer, texCoord + vec2(texOffset.x * i, 0.0)).r * weight[i];
			result += texture(texColorBuffer, texCoord - vec2(texOffset.x * i, 0.0)).r * weight[i];

			weightTotal += 2.0 * weight[i];
		}
	}
	else
	{
		for (int i = 1; i != kernelSize; i++)
		{
			result += texture(texColorBuffer, texCoord + vec2(0.0, texOffset.y * i)).r * weight[i];
			result += texture(texColorBuffer, texCoord - vec2(0.0, texOffset.y * i)).r * weight[i];

			weightTotal += 2.0 * weight[i];
		}
	}

	result /= weightTotal;
	fragColor = vec4(result, 0.0, 0.0, 1.0);
}