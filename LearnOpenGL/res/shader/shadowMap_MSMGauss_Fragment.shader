#version 330 core

in vec2 texCoord;
out vec4 fragColor;

uniform sampler2D depthMap;
uniform bool horizontal;
uniform int kernelSize;

const float weight[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

uniform bool last;

vec4 Entropy(vec4 moment)
{
	vec4 ent = moment;
	mat4 Mat = mat4(
		-2.07224649, 13.7948857, 0.105877704, 9.79240621,
		32.2370378, -59.4683976, -1.90774663, -33.76521106,
		-68.5710746, 82.035975, 9.34965551, 47.9456097,
		39.3703274, -35.3649032, -6.65434907, -23.9728048);
	ent = Mat * ent;
	ent.x += 0.0359558848;

	return ent;
}

void main()
{
	vec2 texOffset = 1.0 / textureSize(depthMap, 0);

	float depth = texture(depthMap, texCoord).r;
	float depth2 = depth * depth;
	vec4 depthVec = vec4(depth, depth2, depth * depth2, depth2 * depth2);

	vec4 result = depthVec * weight[0];
	float weightTotal = weight[0];

	if (horizontal)
	{
		for (int i = 1; i != kernelSize; i++)
		{
			depth = texture(depthMap, texCoord + vec2(texOffset.x * i, 0.0)).r;
			depth2 = depth * depth;
			depthVec = vec4(depth, depth2, depth * depth2, depth2 * depth2);
			result += depthVec * weight[i];

			depth = texture(depthMap, texCoord - vec2(texOffset.x * i, 0.0)).r;
			depth2 = depth * depth;
			depthVec = vec4(depth, depth2, depth * depth2, depth2 * depth2);
			result += depthVec * weight[i];

			weightTotal += 2.0 * weight[i];
		}
	}
	else
	{
		for (int i = 1; i != kernelSize; i++)
		{
			depth = texture(depthMap, texCoord + vec2(0.0, texOffset.y * i)).r;
			depth2 = depth * depth;
			depthVec = vec4(depth, depth2, depth * depth2, depth2 * depth2);
			result += depthVec * weight[i];

			depth = texture(depthMap, texCoord - vec2(0.0, texOffset.y * i)).r;
			depth2 = depth * depth;
			depthVec = vec4(depth, depth2, depth * depth2, depth2 * depth2);
			result += depthVec * weight[i];

			weightTotal += 2.0 * weight[i];
		}
	}

	result /= weightTotal;
	fragColor = last ? Entropy(result) : result;
}