#version 330 core

out vec4 fragColor;

in VS_OUT{
	vec3 fragPos;
	vec3 normal;
	vec2 texCoord;
	vec4 fragPosLightSpace;
} fs_in;

uniform vec3 viewPos;

uniform sampler2D satMap;

uniform float lightWidth;
uniform float orthoWidth;
uniform float far_plane;
uniform float near_plane;

uniform int kernelSize;

struct Material {
	//vec3 ambient;
	sampler2D diffuse;
	sampler2D specular;
	float shininess;
};
uniform Material material;

struct PointLight {
	vec3 position;

	vec3 ambient;
	vec3 diffuse;
	vec3 specular;

	float constant;
	float linear;
	float quadratic;
};
uniform PointLight pointlight;

vec3 calcPointLight(PointLight light, vec3 normal, vec3 viewPos, vec3 fragPos);
float ShadowCalculation(vec4 fragPosLightSpace, vec3 normal, vec3 lightDir);

void main()
{
	vec3 result = calcPointLight(pointlight, fs_in.normal, viewPos, fs_in.fragPos);

	fragColor = vec4(vec3(result), 1.0f);
}

vec3 calcPointLight(PointLight light, vec3 normal, vec3 viewPos, vec3 fragPos)
{
	float distance = length(light.position - fragPos);
	float attenuation = 1.0f / (light.constant + light.linear * distance + light.quadratic * distance * distance);
	//ambient
	vec3 ambient = light.ambient * vec3(texture(material.diffuse, fs_in.texCoord));
	//diffuse
	vec3 lightDir = normalize(light.position - fragPos);
	float diff = max(dot(normal, lightDir), 0.0);
	vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, fs_in.texCoord));
	//specular
	vec3 viewDir = normalize(viewPos - fragPos);
	vec3 halfwayDir = normalize(viewDir + lightDir);
	float spec = pow(max(dot(halfwayDir, normal), 0.0), material.shininess);
	vec3 specular = light.specular * spec * vec3(texture(material.specular, fs_in.texCoord));

	float shadow = ShadowCalculation(fs_in.fragPosLightSpace, normal, lightDir);

	return (ambient + (1.0 - shadow) * (diffuse + specular))* attenuation;
}

float ShadowCalculation(vec4 fragPosLightSpace, vec3 normal, vec3 lightDir)
{
	vec3 projCoord = fragPosLightSpace.xyz / fragPosLightSpace.w;
	projCoord = projCoord * 0.5 + 0.5;
	float currentDepth = projCoord.z * (1.0 - 0.00003) + 0.5 * 0.00003;

	vec2 texelSize = 1.0 / textureSize(satMap, 0);

	vec2 left_down = vec2(projCoord.x - kernelSize * texelSize.x, projCoord.y - kernelSize * texelSize.y);
	vec2 right_down = vec2(projCoord.x + kernelSize * texelSize.x, projCoord.y - kernelSize * texelSize.y);
	vec2 left_up = vec2(projCoord.x - kernelSize * texelSize.x, projCoord.y + kernelSize * texelSize.y);
	vec2 right_up = vec2(projCoord.x + kernelSize * texelSize.x, projCoord.y + kernelSize * texelSize.y);

	vec2 depthSum = texture(satMap, left_down).rg - texture(satMap, left_up).rg - texture(satMap, right_down).rg + texture(satMap, right_up).rg;

	float num = float(4 * kernelSize * kernelSize);
	float EX = depthSum.x / num;
	float EX2 = depthSum.y / num;
	float Var = max(EX2 - EX * EX, 0.001);

	float t_EX = currentDepth - EX;
	float Pt = (Var + 0.001) / (Var + t_EX * t_EX + 0.001);
	//Pt = clamp(Pt, 0.0, 1.0);
	Pt = 1.0 - Pt;

	//Ô¶´¦
	if (projCoord.z > 1.0f || projCoord.x > 1.0f || projCoord.y > 1.0f || projCoord.x < 0.0f || projCoord.y < 0.0f)
		Pt = 0.0f;
	if (projCoord.z < 0.0f)
		Pt = 1.0f;

	return Pt;
}


