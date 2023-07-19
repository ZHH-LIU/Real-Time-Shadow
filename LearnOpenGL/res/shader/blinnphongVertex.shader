#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aColor;
layout(location = 2) in vec2 aTexCoord;
layout(location = 3) in vec3 aNorm;

out vec3 fragPos;
out vec3 normal;
out vec2 texCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform mat4 normModel;

void main()
{
	gl_Position = projection * view * model * vec4(aPos, 1.0f);
	fragPos = vec3(model * vec4(aPos, 1.0f));
	normal = normalize(mat3(normModel) * aNorm);
	texCoord = aTexCoord;
}