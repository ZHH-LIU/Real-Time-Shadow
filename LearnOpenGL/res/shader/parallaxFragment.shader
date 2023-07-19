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
uniform sampler2D depthMap;
uniform float height_scale;

vec3 calcDirLight(DirLight light, vec3 normal, vec3 viewPos, vec3 fragPos, vec2 texCoord);
vec3 calcSpotLight(SpotLight light, vec3 normal, vec3 viewPos, vec3 fragPos, vec2 texCoord);
vec3 calcPointLight(PointLight light, vec3 normal, vec3 viewPos, vec3 fragPos, vec2 texCoord);

vec2 ParallaxMapping(vec2 texCoord, vec3 viewDir);

void main()
{
	vec3 viewDir = fs_in.tangentViewPos - fs_in.tangentFragPos;
	vec2 texCoord =  ParallaxMapping(fs_in.texCoord, viewDir);
	if (texCoord.x > 1.0 || texCoord.y > 1.0 || texCoord.x < 0.0 || texCoord.y < 0.0)
	{
		discard;
	}

	vec3 normal = texture(normalMap, texCoord).rgb;
	normal = normalize(normal * 2.0 - 1.0);

	vec3 result = calcDirLight(fs_in.tangentDirlight, normal, fs_in.tangentViewPos, fs_in.tangentFragPos, texCoord);

	//for (int i = 0; i != NR_POINT_LIGHTS; i++)
	//{
	//	result += calcPointLight(pointlights[i], normal, viewPos, fragPos);
	//}

	result += calcSpotLight(fs_in.tangentSpotlight, normal, fs_in.tangentViewPos, fs_in.tangentFragPos, texCoord);

	fragColor = vec4(result, 1.0f);

	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}

vec3 calcDirLight(DirLight light, vec3 normal, vec3 viewPos, vec3 fragPos, vec2 texCoord)
{
	//ambient
	vec3 ambient = light.ambient * vec3(texture(material.diffuse, texCoord));
	//diffuse
	vec3 lightDir = normalize(-light.direction);
	float diff = max(dot(normal, lightDir), 0.0);
	vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, texCoord));
	//specular
	vec3 viewDir = normalize(viewPos - fragPos);
	vec3 halfwayDir = normalize(viewDir + lightDir);
	float spec = pow(max(dot(halfwayDir, normal), 0.0), material.shininess);
	vec3 specular = light.specular * spec * vec3(texture(material.specular, texCoord));

	return  ambient + diffuse + specular;
}

vec3 calcPointLight(PointLight light, vec3 normal, vec3 viewPos, vec3 fragPos, vec2 texCoord)
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
	vec3 viewDir = normalize(viewPos - fragPos);
	vec3 halfwayDir = normalize(viewDir + lightDir);
	float spec = pow(max(dot(halfwayDir, normal), 0.0), material.shininess);
	vec3 specular = light.specular * spec * vec3(texture(material.specular, texCoord));

	return (ambient + diffuse + specular) * attenuation;
}

vec3 calcSpotLight(SpotLight light, vec3 normal, vec3 viewPos, vec3 fragPos, vec2 texCoord)
{

	//ambient
	vec3 ambient = light.ambient * vec3(texture(material.diffuse, texCoord));
	//diffuse
	vec3 lightDir = normalize(light.position - fragPos);
	float diff = max(dot(normal, lightDir), 0.0);
	vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, texCoord));
	//specular
	vec3 viewDir = normalize(viewPos - fragPos);
	vec3 halfwayDir = normalize(viewDir + lightDir);
	float spec = pow(max(dot(halfwayDir, normal), 0.0), material.shininess);
	vec3 specular = light.specular * spec * vec3(texture(material.specular, texCoord));

	float theta = dot(-lightDir, normalize(light.direction));
	float epsilon = light.cutOff - light.outerCutOff;
	float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);

	float distance = length(light.position - fragPos);
	float attenuation = 1.0f / (light.constant + light.linear * distance + light.quadratic * distance * distance);

	return (ambient + diffuse + specular) * intensity * attenuation;
}

vec2 ParallaxMapping(vec2 texCoord, vec3 viewDir)
{
	const float minLayers = 8.0f;
	const float maxLayers = 32.0f;
	float numLayers = mix(minLayers, maxLayers, abs(viewDir.z));

	float layerDepth = 1.0 / numLayers;
	vec2 p = viewDir.xy / viewDir.z *height_scale;
	vec2 deltaTexCoord = p / numLayers;

	vec2 currentTexCoord = texCoord;
	float currentDepthMapValue = texture(depthMap, currentTexCoord).r;
	float currentLayerDepth = 0.0;

	while (currentDepthMapValue > currentLayerDepth)
	{
		currentLayerDepth += layerDepth;
		currentTexCoord -= deltaTexCoord;
		currentDepthMapValue = texture(depthMap, currentTexCoord).r;
	}
	vec2 beforeTexCoord = currentTexCoord + deltaTexCoord;
	float afterDepth = currentDepthMapValue - currentLayerDepth;
	float beforeDepth = texture(depthMap, beforeTexCoord).r - currentLayerDepth + layerDepth;
	float weight = afterDepth / (afterDepth - beforeDepth);

	vec2 finalTexCoord = mix(currentTexCoord, beforeTexCoord, weight);
	return finalTexCoord;
}