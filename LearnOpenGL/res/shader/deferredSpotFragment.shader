#version 330 core

in vec2 texCoord;
out vec4 fragColor;

uniform sampler2D gPosition;
uniform sampler2D gNormal;
uniform sampler2D gAlbedoSpec;
uniform vec3 viewPos;
uniform float shininess;

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

vec3 calcSpotLight(SpotLight light, vec3 normal, vec3 viewPos, vec3 fragPos);

void main()
{
	vec3 fragPos = texture(gPosition, texCoord).rgb;
	vec3 normal = texture(gNormal, texCoord).rgb;

	vec3 result = calcSpotLight(spotlight, normal, viewPos, fragPos);

	fragColor = vec4(result, 1.0f);
}

vec3 calcSpotLight(SpotLight light, vec3 normal, vec3 viewPos, vec3 fragPos)
{
	vec3 albedo = texture(gAlbedoSpec, texCoord).rgb;
	float specValue = texture(gAlbedoSpec, texCoord).a;

	//ambient
	vec3 ambient = light.ambient * albedo;
	//diffuse
	vec3 lightDir = normalize(light.position - fragPos);
	float diff = max(dot(normal, lightDir), 0.0);
	vec3 diffuse = light.diffuse * diff * albedo;
	//specular
	vec3 viewDir = normalize(viewPos - fragPos);
	vec3 halfwayDir = normalize(viewDir + lightDir);
	float spec = pow(max(dot(halfwayDir, normal), 0.0), shininess);
	vec3 specular = light.specular * spec * vec3(specValue);

	float theta = dot(-lightDir, normalize(light.direction));
	float epsilon = light.cutOff - light.outerCutOff;
	float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);

	float distance = length(light.position - fragPos);
	float attenuation = 1.0f / (light.constant + light.linear * distance + light.quadratic * distance * distance);

	return (ambient + diffuse + specular) * intensity * attenuation;
}