#version 330 core

out vec4 fragColor;

in vec3 fragPos;
in vec3 normal;
in vec2 texCoord;

uniform vec3 objectColor;
uniform vec3 viewPos;

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
#define NR_POINT_LIGHTS 4
uniform PointLight pointlights[NR_POINT_LIGHTS];

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

vec3 calcDirLight(DirLight light, vec3 normal, vec3 viewPos, vec3 fragPos);
vec3 calcSpotLight(SpotLight light, vec3 normal, vec3 viewPos, vec3 fragPos);
vec3 calcPointLight(PointLight light, vec3 normal, vec3 viewPos, vec3 fragPos);

void main()
{
	vec3 result = calcDirLight(dirlight, normal, viewPos, fragPos);
	
	for (int i = 0; i != NR_POINT_LIGHTS; i++)
	{
		result += calcPointLight(pointlights[i], normal, viewPos, fragPos);
	}
	
	result += calcSpotLight(spotlight,  normal, viewPos, fragPos);
	
	fragColor = vec4(result,1.0f);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}

vec3 calcDirLight(DirLight light, vec3 normal, vec3 viewPos, vec3 fragPos)
{
	//ambient
	vec3 ambient = light.ambient * vec3(texture(material.diffuse, texCoord));
	//diffuse
	vec3 lightDir = normalize(-light.direction);
	float diff = max(dot(normal, lightDir), 0.0);
	vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, texCoord));
	//specular
	vec3 reflectDir = normalize(reflect(-lightDir, normal));
	vec3 viewDir = normalize(viewPos - fragPos);
	float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
	vec3 specular = light.specular * spec * vec3(texture(material.specular, texCoord));

	return  ambient + diffuse + specular;
}

vec3 calcPointLight(PointLight light, vec3 normal, vec3 viewPos, vec3 fragPos)
{
	float distance = length(light.position - fragPos);
	float attenuation = 1.0f / (light.constant + light.linear * distance + light.quadratic * distance * distance);
	//ambient
	vec3 ambient = light.ambient * vec3(texture(material.diffuse, texCoord));
	//diffuse
	vec3 lightDir = normalize(light.position - fragPos);
	float diff = max(dot(normal, lightDir), 0.0);
	vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, texCoord));
	//specular
	vec3 reflectDir = normalize(reflect(-lightDir, normal));
	vec3 viewDir = normalize(viewPos - fragPos);
	float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
	vec3 specular = light.specular * spec * vec3(texture(material.specular, texCoord));

	return (ambient + diffuse + specular) * attenuation;
}

vec3 calcSpotLight(SpotLight light, vec3 normal, vec3 viewPos, vec3 fragPos)
{

	//ambient
	vec3 ambient = light.ambient * vec3(texture(material.diffuse, texCoord));
	//diffuse
	vec3 lightDir = normalize(light.position - fragPos);
	float diff = max(dot(normal, lightDir), 0.0);
	vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, texCoord));
	//specular
	vec3 reflectDir = normalize(reflect(-lightDir, normal));
	vec3 viewDir = normalize(viewPos - fragPos);
	float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
	vec3 specular = light.specular * spec * vec3(texture(material.specular, texCoord));

	float theta = dot(-lightDir, normalize(light.direction));
	float epsilon = light.cutOff - light.outerCutOff;
	float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);

	float distance = length(light.position - fragPos);
	float attenuation = 1.0f / (light.constant + light.linear * distance + light.quadratic * distance * distance);

	return (ambient + diffuse + specular) * intensity * attenuation;
}