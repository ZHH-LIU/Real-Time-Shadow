#version 330 core
in vec3 fragPos;
in vec3 normal;
in vec2 texCoord;

out vec4 fragColor;

uniform vec3 viewPos;

uniform vec3 albedo;
uniform float metalness;
uniform float ao;
uniform float roughness;

uniform samplerCube irradianceMap;
uniform samplerCube prefilterMap;
uniform sampler2D prebrdfMap;

uniform vec3 lightPositions[4];
uniform vec3 lightColors[4];

float D_GGX_TR(vec3 N, vec3 H, float roughness);
float GeometrySchlickGGX(float NdotV, float roughness);
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness);
vec3 FresnelSchlick(float cosTheta, vec3 F0);
vec3 FresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness);

const float PI = 3.14159265359;

void main()
{
	vec3 N = normalize(normal);
	vec3 V = normalize(viewPos - fragPos);

	vec3 Lo = vec3(0.0f);
	for (int i = 0; i != 4; i++)
	{
		vec3 L = normalize(lightPositions[i] - fragPos);
		vec3 H = normalize(L + V);

		float distance = length(lightPositions[i] - fragPos);
		float attenuation = 1.0 / (distance * distance);
		vec3 radiance = lightColors[i] * attenuation;

		//Fresnel
		vec3 F0 = vec3(0.04);
		F0 = mix(F0, albedo, metalness);
		float HdotV = max(dot(H, V), 0.0);
		vec3 F = FresnelSchlick(HdotV, F0);

		//Normal
		float NDF = D_GGX_TR(N, H, roughness);

		//Geometry
		float G = GeometrySmith(N, V, L, roughness);

		//Cook-Torrance Specular
		vec3 nom = NDF * F * G;
		float denom = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
		vec3 specular = nom / denom;

		//Lambert Diffuse
		vec3 kS = F;
		vec3 kD = vec3(1.0) - kS;
		kD = kD * (1.0 - metalness);

		vec3 diffuse = kD * albedo / PI;

		//Cook-Torance Refection Equation
		float NdotL = max(dot(N, L), 0.0);
		Lo += (diffuse + specular) * radiance * NdotL;
	}

	//ambient
	vec3 F0 = vec3(0.04);
	F0 = mix(F0, albedo, metalness);
	float NdotV = max(dot(N, V), 0.0);
	vec3 F = FresnelSchlickRoughness(NdotV, F0, roughness);

	const float MAX_REFLECTION_LOD = 4.0;
	vec3 R = reflect(-V, N);
	vec3 preFilterColor = textureLod(prefilterMap, R, roughness * MAX_REFLECTION_LOD).rgb;
	vec2 preBRDF = texture(prebrdfMap, vec2(NdotV, roughness)).rg;
	vec3 specular = preFilterColor * (F * preBRDF.x + preBRDF.y);

	vec3 kS = F;
	vec3 kD = 1 - kS;
	kD *= 1.0 - metalness;
	vec3 irradiance = texture(irradianceMap, N).rgb;
	vec3 diffuse = kD * (albedo / PI) * irradiance;

	vec3 ambient = (diffuse + specular) * ao;

	//total color
	vec3 color = ambient + Lo;

	//Reinhard HDR and Gamma correction
	//color = color / (color + vec3(1.0));
	//color = pow(color, vec3(1.0 / 2.2));

	fragColor = vec4(color, 1.0);
}

float D_GGX_TR(vec3 N, vec3 H, float roughness)
{
	float a = roughness * roughness;
	float a2 = a * a;
	float NdotH = max(dot(N, H), 0.0);
	float NdotH2 = NdotH * NdotH;

	float nom = a2;
	float denom = NdotH2 * (a2 - 1.0) + 1.0;
	denom = PI * denom * denom;

	return nom / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
	float r = roughness + 1.0;
	float k = r * r / 8.0;

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

vec3 FresnelSchlick(float cosTheta, vec3 F0)
{
	return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5);
}

vec3 FresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness)
{
	return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}