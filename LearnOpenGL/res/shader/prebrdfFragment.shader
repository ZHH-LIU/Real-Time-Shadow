#version 330 core

in vec2 texCoord;
out vec2 fragColor;

float RadicalInverse_VdC(uint bits);
vec2 Hammersley(uint i, uint N);
vec3 ImportanceSampleGGX(vec2 Xi, vec3 N, float roughness);
float GeometrySchlickGGX(float NdotV, float roughness);
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness);
vec2 IntegrateBRDF(float NdotV, float roughness);

const float PI = 3.14159265359;

void main()
{
	vec2 integrateBRDF = IntegrateBRDF(texCoord.x, texCoord.y);
	fragColor = integrateBRDF;
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

float GeometrySchlickGGX(float NdotV, float roughness)
{
	float r = roughness;
	float k = r * r / 2.0;

	float nom = NdotV;
	float denom = NdotV * (1.0 - k) + k;
	return nom / denom;
}

float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
	float NdotV = max(dot(N, V), 0.0);
	float NdotL = max(dot(N, L), 0.0);
	float ggx2 = GeometrySchlickGGX(NdotV, roughness);
	float ggx1 = GeometrySchlickGGX(NdotL, roughness);

	return ggx1 * ggx2;
}

vec2 IntegrateBRDF(float NdotV, float roughness)
{
	vec3 N = vec3(0.0, 0.0, 1.0);
	vec3 V;
	V.x = sqrt(1.0 - NdotV * NdotV);
	V.y = 0.0;
	V.z = NdotV;

	float A = 0.0;
	float B = 0.0;
	const uint SAMPLE_COUNT = 1024u;
	for (uint i = 0u; i != SAMPLE_COUNT; i++)
	{
		vec2 Xi = Hammersley(i, SAMPLE_COUNT);
		vec3 H = ImportanceSampleGGX(Xi, N, roughness);
		vec3 L = normalize(2.0 * dot(V, H) * H - V);

		float HdotV = max(dot(H, V), 0.0);
		float NdotH = max(H.z, 0.0);

		float NdotL = L.z;
		if (NdotL > 0.0)
		{
			float G = GeometrySmith(N, V, L, roughness);
			float G_vis = G * HdotV / (NdotV * NdotH);
			float Fc = pow(1.0 - HdotV, 5.0);
			A += G_vis * (1.0 - Fc);
			B += G_vis * Fc;
		}
	}

	A /= float(SAMPLE_COUNT);
	B /= float(SAMPLE_COUNT);

	return vec2(A, B);
}