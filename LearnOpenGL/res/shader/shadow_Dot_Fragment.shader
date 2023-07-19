#version 330 core

out vec4 fragColor;

in VS_OUT{
	vec3 fragPos;
	vec3 normal;
	vec2 texCoord;
} fs_in;

uniform vec3 viewPos;
uniform float far_plane;
uniform samplerCube shadowMap;

struct Material {
	//vec3 ambient;
	sampler2D diffuse;
	sampler2D specular;
	float shininess;
};
uniform Material material;

struct DirLight {
	vec3 direction;

	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
};
uniform DirLight dirlight;

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

struct SpotLight {
	vec3 direction;
	vec3 position;

	vec3 ambient;
	vec3 diffuse;
	vec3 specular;

	float cutOff;
	float outerCutOff;
	float constant;
	float linear;
	float quadratic;
};
uniform SpotLight spotlight;

vec3 sampleOffsetDirections[20] = {
	vec3(1,  1,  1), vec3(1, -1,  1), vec3(-1, -1,  1), vec3(-1,  1,  1),
	vec3(1,  1, -1), vec3(1, -1, -1), vec3(-1, -1, -1), vec3(-1,  1, -1),
	vec3(1,  1,  0), vec3(1, -1,  0), vec3(-1, -1,  0), vec3(-1,  1,  0),
	vec3(1,  0,  1), vec3(-1,  0,  1), vec3(1,  0, -1), vec3(-1,  0, -1),
	vec3(0,  1,  1), vec3(0, -1,  1), vec3(0, -1, -1), vec3(0,  1, -1)
};

vec3 calcSpotLight(SpotLight light, vec3 normal, vec3 viewPos, vec3 fragPos);
vec3 calcPointLight(PointLight light, vec3 normal, vec3 viewPos, vec3 fragPos);
float ShadowCalculation(vec3 fragPos, vec3 lightPos, vec3 normal, vec3 lightDir);

void main()
{
	vec3 result = calcPointLight(pointlight, fs_in.normal, viewPos, fs_in.fragPos);

	fragColor = vec4(result, 1.0f);

	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
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

	float shadow = ShadowCalculation(fragPos, light.position, normal, lightDir);

	return (ambient + (1.0 - shadow) * (diffuse + specular))* attenuation;
}

vec3 calcSpotLight(SpotLight light, vec3 normal, vec3 viewPos, vec3 fragPos)
{

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

	float theta = dot(-lightDir, normalize(light.direction));
	float epsilon = light.cutOff - light.outerCutOff;
	float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);

	float distance = length(light.position - fragPos);
	float attenuation = 1.0f / (light.constant + light.linear * distance + light.quadratic * distance * distance);

	float shadow = ShadowCalculation(fragPos, light.position, normal, lightDir);

	return (ambient + (1.0 - shadow) * (diffuse + specular)) * intensity * attenuation;
}

float ShadowCalculation(vec3 fragPos, vec3 lightPos, vec3 normal, vec3 lightDir)
{

	vec3 fragToLight = fragPos - lightPos;
	float currentDepth = length(fragToLight);

	float shadow = 0.0f;
	float bias =  max(0.5 * (1.0 - dot(normal, lightDir)), 0.05);
	int samples = 20;
	float viewDistance = length(viewPos - fragPos);
	float diskRadius = (1.0 + viewDistance / far_plane) /25.0f;

	for (int i = 0; i != samples; i++)
	{
		float closestDepth = texture(shadowMap, fragToLight + sampleOffsetDirections[i] * diskRadius).r;
		closestDepth *= far_plane;
		shadow += currentDepth - bias > closestDepth ? 1.0 : 0.0;
	}

	shadow /= float(samples);

	return shadow;
}