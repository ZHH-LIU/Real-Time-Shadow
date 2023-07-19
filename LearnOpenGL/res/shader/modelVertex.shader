#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNorm;
layout(location = 2) in vec2 aTexCoord;
layout(location = 3)in vec3 aTangent;

out vec3 fragPos;
out vec3 normal;
out vec2 texCoord;
out mat3 TBN;

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

	vec3 T = normalize(vec3(normModel * vec4(aTangent, 0.0)));
	vec3 N = normalize(vec3(normModel * vec4(aNorm, 0.0)));

	T = normalize(T - dot(T, N) * N);

	vec3 B = cross(N, T);

	TBN = transpose(mat3(T, B, N));
}
