#version 330 core

in vec2 texCoord;
out vec4 fragColor;

uniform sampler2D gPosition;
uniform sampler2D gNormal;
uniform sampler2D gAlbedoSpec;
//uniform vec3 viewPos;//�۲�ռ�
uniform float shininess;
uniform mat4 view;//�۲�ռ�

uniform sampler2D ssao;

struct DirLight {
	vec3 direction;

	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
};
uniform DirLight dirlight;

vec3 calcDirLight(DirLight light, vec3 normal, vec3 fragPos);//ʹ�ù۲�ռ�

void main()
{
	vec3 fragPos = texture(gPosition, texCoord).rgb;
	vec3 normal = texture(gNormal, texCoord).rgb;

	vec3 result = calcDirLight(dirlight, normal, fragPos);//ʹ�ù۲�ռ�

	fragColor = vec4(result, 1.0f);
}

vec3 calcDirLight(DirLight light, vec3 normal, vec3 fragPos)//(DirLight light, vec3 normal, vec3 viewPos, vec3 fragPos)ʹ�ù۲�ռ�
{
	vec3 albedo = texture(gAlbedoSpec, texCoord).rgb;
	float specValue = texture(gAlbedoSpec, texCoord).a;
	float AmbientOcclusion = texture(ssao, texCoord).r;//ssao
	//ambient
	vec3 ambient = light.ambient * albedo * AmbientOcclusion;//ssao
	//diffuse

	mat4 View = transpose(inverse(view));//ʹ�ù۲�ռ�
	vec3 lightDirection = mat3(View) * light.direction;//ʹ�ù۲�ռ�

	vec3 lightDir = normalize(-lightDirection);
	float diff = max(dot(normal, lightDir), 0.0);
	vec3 diffuse = light.diffuse * diff * albedo;
	//specular
	vec3 viewDir = normalize(-fragPos);//normalize(viewPos - fragPos); ʹ�ù۲�ռ�
	vec3 halfwayDir = normalize(viewDir + lightDir);
	float spec = pow(max(dot(halfwayDir, normal), 0.0), shininess);
	vec3 specular = light.specular * spec * vec3(specValue);

	return  ambient + diffuse + specular;
}