#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec2 aTexCoord;
layout(location = 2) in vec3 aNorm;

out vec3 fragPos;
out vec3 normal;
out vec2 texCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
	gl_Position = projection * view * model * vec4(aPos, 1.0f);
	fragPos = vec3(view * model * vec4(aPos, 1.0f));
	mat3 normModel = transpose(inverse(mat3(view * model)));
	normal = normalize(normModel * aNorm);
	texCoord = aTexCoord;
}