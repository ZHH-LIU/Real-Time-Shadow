#version 330 core

out vec4 fragColor;

in VS_OUT{
	vec3 fragPos;
	vec3 normal;
	vec2 texCoord;
	vec4 fragPosLightSpace;
} fs_in;

uniform vec3 viewPos;

uniform sampler2D shadowMap;

uniform float lightWidth;
uniform float orthoWidth;
uniform float far_plane;
uniform float near_plane;

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
float BlockDepth(vec2 projCoord, float currentDepth);
float SearchWidth(float dReceiver, float dBlocker);

void main()
{
	vec3 result = calcPointLight(pointlight, fs_in.normal, viewPos, fs_in.fragPos);

	fragColor = vec4(result, 1.0f);
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
	float closestDepth = texture(shadowMap, projCoord.xy).r;
	float currentDepth = projCoord.z;
	float shadow = 0.0f;

	float bias = 0.0;// max(0.05 * (1.0 - dot(normal, lightDir)), 0.005);

	//PCSS
	float dBlocker = BlockDepth(projCoord.xy, currentDepth);
	float dReceiver = currentDepth;
	float searchWidth = SearchWidth(dReceiver, dBlocker);

	vec2 texelSize = 1.0 / textureSize(shadowMap, 0);
	int searchStep = max(int(searchWidth / texelSize.x), 2);
	int count = 0;
	//PCF
	for (int i = -searchStep/2; i != searchStep/2; i++)
	{
		for (int j = 0; j != searchStep; j++)
		{
			float pcfDepth = texture(shadowMap, projCoord.xy + vec2(i, j) * texelSize).r;
			shadow += currentDepth - bias > pcfDepth ? 1.0 : 0.0;
			count++;
		}
	}

	shadow /= float(count);

	//Ô¶´¦
	if (projCoord.z > 1.0f)
		shadow = 0.0f;
	if (projCoord.z < 0.0f)
		shadow = 1.0f;

	return shadow;
}

float BlockDepth(vec2 projCoord, float currentDepth)
{
	float ratio = lightWidth / (2.0 * orthoWidth);
	float blockDepth = 0.0;
	int num = 0;
	for (int i = -3; i != 4; i++)
	{
		for (int j = -3; j != 4; j++)
		{
			vec2 offset = vec2(i / 6.0 * ratio, j / 6.0 * ratio);
			float depth = texture(shadowMap, projCoord + offset).r;

			if (depth < currentDepth)
			{
				blockDepth += depth;
				num++;
			}
		}
	}
	
	return num == 0 ? currentDepth : blockDepth / float(num);
}

float SearchWidth(float dReceiver,float dBlocker)
{
	dReceiver = dReceiver * (far_plane - near_plane) + near_plane;
	dBlocker = dBlocker * (far_plane - near_plane) + near_plane;

	float width = (dReceiver - dBlocker) * lightWidth / dBlocker;
	width /= orthoWidth;

	return width;
}

