#version 330 core

in vec2 texCoord;
in mat4 View;//ʹ�ù۲�ռ�
out vec4 fragColor;

uniform sampler2D gPositionDepth;
uniform sampler2D gNormal;
uniform sampler2D gAlbedoSpec;
//uniform vec3 viewPos; //ʹ�ù۲�ռ�
uniform float shininess;

uniform sampler2D ssao;

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

vec3 calcPointLight(PointLight light, vec3 normal, vec3 fragPos);//(DirLight light, vec3 normal, vec3 viewPos, vec3 fragPos)ʹ�ù۲�ռ�

void main()
{
	vec3 fragPos = texture(gPositionDepth, texCoord).rgb;
	vec3 normal = texture(gNormal, texCoord).rgb;

	vec3 result = calcPointLight(pointlight, normal, fragPos);//(DirLight light, vec3 normal, vec3 viewPos, vec3 fragPos)ʹ�ù۲�ռ�

	fragColor = vec4(result, 1.0f);
}

vec3 calcPointLight(PointLight light, vec3 normal, vec3 fragPos)//(DirLight light, vec3 normal, vec3 viewPos, vec3 fragPos)ʹ�ù۲�ռ�
{
	vec3 albedo = texture(gAlbedoSpec, texCoord).rgb;
	float specValue = texture(gAlbedoSpec, texCoord).a;
	float AmbientOcclusion = texture(ssao, texCoord).r;//ssao

	vec3 lightPosition = vec3(View * vec4(light.position, 1.0));//ʹ�ù۲�ռ�

	float distance = length(lightPosition - fragPos);//lightPosition, ʹ�ù۲�ռ�
	float attenuation = 1.0f / (light.constant + light.linear * distance + light.quadratic * distance * distance);
	//ambient
	vec3 ambient = light.ambient * albedo * AmbientOcclusion;
	//diffuse
	vec3 lightDir = normalize(lightPosition - fragPos);//lightPosition, ʹ�ù۲�ռ�
	float diff = max(dot(normal, lightDir), 0.0);
	vec3 diffuse = light.diffuse * diff * albedo;
	//specular
	vec3 viewDir = normalize(-fragPos); //normalize(viewPos - fragPos); ʹ�ù۲�ռ�
	vec3 halfwayDir = normalize(viewDir + lightDir);
	float spec = pow(max(dot(halfwayDir, normal), 0.0), shininess);
	vec3 specular = light.specular * spec * vec3(specValue);

	return (ambient + diffuse + specular) * attenuation;
}