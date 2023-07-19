#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aColor;
layout(location = 2) in vec2 aCoord;
layout(location = 3) in vec3 aNorm;

out vec3 vexColor;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform mat4 normModel;

uniform vec3 lightColor;
uniform vec3 objectColor;
uniform vec3 lightPos;
uniform vec3 viewPos;

void main()
{
	gl_Position = projection * view * model * vec4(aPos, 1.0f);
	vec3 fragPos = vec3(model * vec4(aPos, 1.0f));
	vec3 normal = normalize(mat3(normModel) * aNorm);

	//ambient
	float ambientStrength = 0.1;
	vec3 ambient = ambientStrength * lightColor;
	//diffuse
	vec3 lightDir = normalize(lightPos - fragPos);
	float diff = max(dot(normal, lightDir), 0.0);
	vec3 diffuse = diff * lightColor;
	//specular
	float specularStrength = 0.5;
	vec3 reflectDir = normalize(reflect(-lightDir, normal));
	vec3 viewDir = normalize(viewPos - fragPos);
	float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
	vec3 specular = specularStrength * spec * lightColor;

	vexColor = (ambient + diffuse + specular) * objectColor;
}