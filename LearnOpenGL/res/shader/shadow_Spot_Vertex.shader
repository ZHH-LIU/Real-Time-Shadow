#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec2 aTexCoord;
layout(location = 2) in vec3 aNorm;

out VS_OUT{
	vec3 fragPos;
	vec3 normal;
	vec2 texCoord;
} vs_out;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
	gl_Position = projection * view * model * vec4(aPos, 1.0f);
	vs_out.fragPos = vec3(model * vec4(aPos, 1.0f));
	vs_out.normal = normalize(mat3(transpose(inverse(model))) * aNorm);
	vs_out.texCoord = aTexCoord;
}