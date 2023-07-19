#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNorm;
layout(location = 2) in vec2 aTexCoord;
layout(location = 3) in vec3 aTangent;
layout(location = 4) in vec3 aBiTangent;

uniform vec3 viewPos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

struct DirLight {
	vec3 direction;

	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
};
uniform DirLight dirlight;

struct PointLight {
	vec3 position;

	vec3 ambient;
	vec3 diffuse;
	vec3 specular;

	float constant;
	float linear;
	float quadratic;
};
#define NR_POINT_LIGHTS 4
uniform PointLight pointlights[NR_POINT_LIGHTS];

struct SpotLight {
	vec3 direction;
	vec3 position;

	vec3 ambient;
	vec3 diffuse;
	vec3 specular;

	float cutOff;
	float outerCutOff;
	float constant;
	float linear;
	float quadratic;
};
uniform SpotLight spotlight;

out VS_OUT{
	vec2 texCoord;
	vec3 tangentFragPos;
	vec3 tangentViewPos;
	DirLight tangentDirlight;
	SpotLight tangentSpotlight;
}vs_out;

void main()
{
	gl_Position = projection * view * model * vec4(aPos, 1.0f);

	vs_out.texCoord = aTexCoord;

	vec3 T = normalize(vec3(model * vec4(aTangent, 0.0)));
	//vec3 B = normalize(vec3(model * vec4(aBiTangent, 0.0)));
	vec3 N = normalize(vec3(model * vec4(aNorm, 0.0)));
	T = normalize(T - dot(T, N) * N);
	vec3 B = cross(N,T);
	mat3 TBN = transpose(mat3(T, B, N));

	mat4 normModel = transpose(inverse(model));
	vec3 Tn = normalize(vec3(normModel * vec4(aTangent, 0.0)));
	//vec3 Bn = normalize(vec3(normModel * vec4(aBiTangent, 0.0)));
	vec3 Nn = normalize(vec3(normModel * vec4(aNorm, 0.0)));
	Tn = normalize(Tn - dot(Tn, Nn) * Nn);
	vec3 Bn = cross(Nn, Tn);
	mat3 TBNn = transpose(mat3(Tn, Bn, Nn));

	vec3 fragPos = vec3(model * vec4(aPos, 1.0f));
	vs_out.tangentFragPos = TBN * fragPos;
	vs_out.tangentViewPos = TBN * viewPos;
	vs_out.tangentSpotlight = spotlight;
	vs_out.tangentSpotlight.position = TBN * spotlight.position;
	vs_out.tangentDirlight = dirlight;
	vs_out.tangentDirlight.direction = TBNn * dirlight.direction;
}