#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNorm;
layout(location = 2) in vec2 aTexCoord;
layout(location = 3) in vec3 aTangent;
layout(location = 4) in vec3 aBiTangent;

out VS_OUT{
	vec3 fragPos;
	vec2 texCoord;
	vec3 normal;
	mat3 TBN;
}vs_out;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
	gl_Position = projection * view * model * vec4(aPos, 1.0f);
	vs_out.fragPos = vec3(model * vec4(aPos, 1.0f));
	vs_out.normal = normalize(mat3(transpose(inverse(model))) * aNorm);
	vs_out.texCoord = aTexCoord;

	mat4 normModel = transpose(inverse(model));
	vec3 T = normalize(vec3(normModel * vec4(aTangent, 0.0)));
	//vec3 B = normalize(vec3(normModel * vec4(aBiTangent, 0.0)));
	vec3 N = normalize(vec3(normModel * vec4(aNorm, 0.0)));
	T = normalize(T - dot(T, N) * N);
	vec3 B = cross(N, T);
	
	vs_out.TBN = mat3(T, B, N);
}