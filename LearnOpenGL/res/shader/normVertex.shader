#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNorm;
layout(location = 2) in vec2 aTexCoord;//没用，为了不再建立一个新的VAO，就保留在这了

out VS_OUT{
	vec3 normal;
}vs_out;

uniform mat4 model;
uniform mat4 view;

void main()
{
	gl_Position = view * model * vec4(aPos, 1.0f);
	vs_out.normal = normalize(mat3(transpose(inverse(view * model))) * aNorm);
}
