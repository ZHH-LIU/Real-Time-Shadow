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
	float currentDepth = projCoord.z;

	float dBlocker = BlockDepth(projCoord.xy, currentDepth);
	float dReceiver = currentDepth;
	float searchWidth = SearchWidth(dReceiver, dBlocker);
	searchWidth /= 2.0;

	vec2 texelSize = 1.0 / textureSize(satMap, 0);
	searchWidth = max(searchWidth, 3.0*texelSize.x);

	vec2 left_down  = vec2(projCoord.x - searchWidth, projCoord.y - searchWidth);
	vec2 right_down = vec2(projCoord.x + searchWidth, projCoord.y - searchWidth);
	vec2 left_up    = vec2(projCoord.x - searchWidth, projCoord.y + searchWidth);
	vec2 right_up   = vec2(projCoord.x + searchWidth, projCoord.y + searchWidth);

	vec2 depthSum = texture(satMap, left_down).rg - texture(satMap, left_up).rg - texture(satMap, right_down).rg + texture(satMap, right_up).rg;

	float singleNum = (searchWidth / texelSize.x) * (searchWidth / texelSize.y);
	float num = singleNum < 1.0 ? 1.0 : 4.0 * singleNum;
	float EX = depthSum.x / num;
	float EX2 = depthSum.y / num;
	float Var = EX2 - EX * EX;

	float bias = 0.005;
	float t_EX = currentDepth - EX;
	float Pt = (Var+0.001) / (Var + t_EX * t_EX+0.001);
	Pt = 1.0 - Pt;

	//Ô¶´¦
	if (projCoord.z > 1.0f || projCoord.x > 1.0f || projCoord.y > 1.0f || projCoord.x < 0.0f || projCoord.y < 0.0f)
		Pt = 0.0f;
	if (projCoord.z < 0.0f)
		Pt = 1.0f;

	return Pt;
}

float BlockDepth(vec2 projCoord, float currentDepth)
{
	float winWidth = 0.5 * lightWidth / orthoWidth;

	vec2 left_down  = vec2(projCoord.x - winWidth, projCoord.y - winWidth);
	vec2 right_down = vec2(projCoord.x + winWidth, projCoord.y - winWidth);
	vec2 left_up    = vec2(projCoord.x - winWidth, projCoord.y + winWidth);
	vec2 right_up   = vec2(projCoord.x + winWidth, projCoord.y + winWidth);

	vec2 depthSum = texture(satMap, left_down).rg - texture(satMap, left_up).rg - texture(satMap, right_down).rg + texture(satMap, right_up).rg;

	vec2 texelSize = 1.0 / textureSize(satMap, 0);
	float singleNum = (winWidth / texelSize.x) * (winWidth / texelSize.y);
	float num = singleNum < 1.0 ? 1.0 : 4.0 * singleNum;
	float EX = depthSum.x / num;
	float EX2 = depthSum.y / num;
	float Var = max(EX2 - EX * EX, 0.001);

	float t_EX = currentDepth - EX;
	float Pt = (Var+0.001) / (Var + t_EX * t_EX+0.001);

	float blockDepth = (EX - Pt * currentDepth) / (1.0 - Pt+0.001);

	//Æ½Ãæ
	if (Pt > 0.95)
		blockDepth = currentDepth*0.99;

	return blockDepth;
}

float SearchWidth(float dReceiver, float dBlocker)
{
	dReceiver = dReceiver * (far_plane - near_plane) + near_plane;
	dBlocker = dBlocker * (far_plane - near_plane) + near_plane;

	float width = (dReceiver - dBlocker) * lightWidth / (dBlocker);
	width /= orthoWidth;

	return width;
}

