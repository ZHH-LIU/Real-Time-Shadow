#version 330 core

out vec4 fragColor;

struct DirLight {
	vec3 direction;

	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
};

struct PointLight {
	vec3 position;

	vec3 ambient;
	vec3 diffuse;
	vec3 specular;

	float constant;
	float linear;
	float quadratic;
};

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

in VS_OUT{
	vec2 texCoord;
	vec3 tangentFragPos;
	vec3 tangentViewPos;
	DirLight tangentDirlight;
	SpotLight tangentSpotlight;
}fs_in;

struct Material {
	sampler2D diffuse;
	sampler2D specular;
	float shininess;
};
uniform Material material;

uniform sampler2D normalMap;

vec3 calcDirLight(DirLight light, vec3 normal, vec3 viewPos, vec3 fragPos);
vec3 calcSpotLight(SpotLight light, vec3 normal, vec3 viewPos, vec3 fragPos);
vec3 calcPointLight(PointLight light, vec3 normal, vec3 viewPos, vec3 fragPos);

void main()
{
	vec3 normal = texture(normalMap, fs_in.texCoord).rgb;
	normal = normalize(normal * 2.0 - 1.0);

	vec3 result = calcDirLight(fs_in.tangentDirlight, normal, fs_in.tangentViewPos, fs_in.tangentFragPos);

	//for (int i = 0; i != NR_POINT_LIGHTS; i++)
	//{
	//	result += calcPointLight(pointlights[i], normal, viewPos, fragPos);
	//}

	result += calcSpotLight(fs_in.tangentSpotlight, normal, fs_in.tangentViewPos, fs_in.tangentFragPos);

	fragColor = vec4(result, 1.0f);

	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}

vec3 calcDirLight(DirLight light, vec3 normal, vec3 viewPos, vec3 fragPos)
{
	//ambient
	vec3 ambient = light.ambient * vec3(texture(material.diffuse, fs_in.texCoord));
	//diffuse
	vec3 lightDir = normalize(-light.direction);
	float diff = max(dot(normal, lightDir), 0.0);
	vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, fs_in.texCoord));
	//specular
	vec3 viewDir = normalize(viewPos - fragPos);
	vec3 halfwayDir = normalize(viewDir + lightDir);
	float spec = pow(max(dot(halfwayDir, normal), 0.0), material.shininess);
	vec3 specular = light.specular * spec * vec3(texture(material.specular, fs_in.texCoord));

	return  ambient + diffuse + specular;
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

	return (ambient + diffuse + specular) * attenuation;
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

	return (ambient + diffuse + specular) * intensity * attenuation;
}