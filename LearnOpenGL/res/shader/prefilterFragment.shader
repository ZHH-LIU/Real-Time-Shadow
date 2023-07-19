#version 330 core

in vec3 localPos;
out vec4 fragColor;

uniform samplerCube envCubeMap;
uniform float roughness;

const float PI = 3.14159265359;
const uint SAMPLE_COUNT = 1024u;

float RadicalInverse_VdC(uint bits);
vec2 Hammersley(uint i, uint N);
vec3 ImportanceSampleGGX(vec2 Xi, vec3 N, float roughness);
float DistributionGGX(float NdotH, float roughness);
float GetMipLevel(float NdotH, float roughness);

void main()
{
	vec3 N = normalize(localPos);
	vec3 R = N;
	vec3 V = R;

	float totalWeight = 0.0;
	vec3 prefilterColor = vec3(0.0);

	for (uint i = 0u; i != SAMPLE_COUNT; i++)
	{
		vec2 Xi = Hammersley(i, SAMPLE_COUNT);
		vec3 H = ImportanceSampleGGX(Xi, N, roughness);
		vec3 L = normalize(2 * dot(V, H) * H - V);

		float NdotH = max(dot(N, H), 0.0);
		float mipLevel = GetMipLevel(NdotH, roughness);

		float NdotL_origon = dot(N, L);
		float NdotL = max(NdotL_origon, 0.0);
		if (NdotL_origon > 0.0)
		{
			prefilterColor += textureLod(envCubeMap, L, mipLevel).rgb * NdotL;
			totalWeight += NdotL;
		}
	}

	prefilterColor /= totalWeight;

	fragColor = vec4(prefilterColor, 1.0);
}


float RadicalInverse_VdC(uint bits)
{
	bits = (bits << 16u) | (bits >> 16u);
	bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
	bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
	bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
	bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
	return float(bits) * 2.3283064365386963e-10; // / 0x100000000
}

vec2 Hammersley(uint i, uint N)
{
	return vec2(float(i) / float(N), RadicalInverse_VdC(i));
}

vec3 ImportanceSampleGGX(vec2 Xi, vec3 N, float roughness)
{
	float a = roughness * roughness;

	//Sampling H vector
	float phi = Xi.x * 2 * PI;
	float cosTheta = sqrt((1.0 - Xi.y) / ((a * a - 1.0) * Xi.y + 1.0));
	float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

	vec3 H;
	H.x = sinTheta * cos(phi);
	H.y = sinTheta * sin(phi);
	H.z = cosTheta;

	//TBN convert
	vec3 normal = normalize(N);
	vec3 tangent = normal.z > 0.001 ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 1.0);
	vec3 bitangent = cross(normal, tangent);
	tangent = cross(bitangent, normal);
	mat3 TBN = mat3(tangent, bitangent, normal);
	vec3 sampleVec = normalize(TBN * H);

	return sampleVec;
}

float DistributionGGX(float NdotH, float roughness)
{
	float a = roughness * roughness;
	float a2 = a * a;

	float NdotH2 = NdotH * NdotH;

	float nom = a2;
	float denom = NdotH2 * (a2 - 1.0) + 1.0;
	denom = PI * denom * denom;

	return nom / denom;
}

float GetMipLevel(float NdotH, float roughness)
{
	float HdotV = NdotH;
	float pdf = DistributionGGX(NdotH, roughness) * NdotH / (4.0 * HdotV) + 0.0001;

	float resolution = 512.0;
	float saTexel = 4.0 * PI / (6 * resolution * resolution);
	float saSample = 1.0 / (float(SAMPLE_COUNT) * pdf + 0.0001);

	float mip = roughness == 0.0 ? 0.0 : 0.5 * log2(saSample / saTexel);
	return mip;
}
