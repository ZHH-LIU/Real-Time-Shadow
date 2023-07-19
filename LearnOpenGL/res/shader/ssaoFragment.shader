#version 330 core

in vec2 texCoord;
out float fragColor;

uniform sampler2D gPositionDepth;
uniform sampler2D gNormal;
uniform sampler2D ssaoNoise;
uniform vec3 samples[64];
uniform mat4 projection;

const vec2 noiseScale = vec2(800.0f, 600.0f) / 4.0f;
const int kernalSize = 64;
const float randius = 5.0f;
const float power = 5.0f;
void main()
{
	vec3 fragPos = texture(gPositionDepth, texCoord).rgb;
	vec3 normal = texture(gNormal, texCoord).rgb;
	vec3 randomVec = texture(ssaoNoise, texCoord * noiseScale).rgb;

	vec3 tangent = normalize(randomVec - dot(randomVec, normal) * normal);
	vec3 bitangent = cross(normal, tangent);
	mat3 TBN = mat3(tangent, bitangent, normal);

	float occlusion = 0.0f;
	for (int i = 0; i != kernalSize; i++)
	{
		vec3 sample = TBN * samples[i];
		sample = fragPos + sample * randius;
		vec4 offset = projection * vec4(sample, 1.0f);
		offset.xyz = offset.xyz / offset.w;
		offset.xyz = offset.xyz * 0.5f + 0.5f;
		float sampleDepth = -texture(gPositionDepth, offset.xy).a;
		float rangeCheck = smoothstep(0.0f, 1.0f, randius / abs(fragPos.z - sampleDepth));
		occlusion += (sampleDepth >= sample.z ? 1.0f : 0.0f) * rangeCheck;
	}
	occlusion = 1.0f - occlusion /kernalSize;
	fragColor = pow(occlusion,power);
}