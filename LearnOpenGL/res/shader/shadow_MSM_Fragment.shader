#version 330 core
out vec4 fragColor;

uniform sampler2D momentMap;
const float alpha = 0.00003;

in VS_OUT{
	vec3 fragPos;
	vec3 normal;
	vec2 texCoord;
	vec4 fragPosLightSpace;
} fs_in;

uniform vec3 viewPos;

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
vec4 InvEntropy(vec4 moment);

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
	float zf = projCoord.z;
	float bias = 0.0;
	zf -= bias;

	//b
	vec4 b = InvEntropy(texture(momentMap, projCoord.xy));
	b = mix(b, vec4(0.5, 0.5, 0.5, 0.5), alpha);

	//L
	float L11 = 1.0;
	float L21 = b.x;
	float L22 = sqrt(b.y - L21 * L21);
	float L31 = b.y;
	float L32 = (b.z - L21 * L31) / L22;
	float L33 = sqrt(b.w - L31 * L31 - L32 * L32);

	//c
	vec3 c;
	c.x = 1.0;
	c.y = (zf - L21 * c.x) / L22;
	c.z = (zf * zf - L31 * c.x - L32 * c.y) / L33;

	c.z = c.z / L33;
	c.y = (c.y - L32 * c.z) / L22;
	c.x = (c.x - L21 * c.y - L31 * c.z) / L11;

	//z2 z3
	float delta = sqrt(c.y * c.y - 4 * c.x * c.z);
	float z2 = clamp((-c.y - delta) / (2.0 * c.z), 0.0, 1.0);
	float z3 = clamp((-c.y + delta) / (2.0 * c.z), 0.0, 1.0);
	if (z3 < z2)
	{
		float zint = z3;
		z3 = z2;
		z2 = zint;
	}

	//G
	vec4 pars;
	if (zf <= z2)
		pars = vec4(0.0, 0.0, 0.0, 0.0);
	else if (zf <= z3)
		pars = vec4(zf, z2, 0.0, 1.0);
	else
		pars = vec4(z2, zf, 1.0, 1.0);
	float G = pars.z + pars.w * (pars.x * z3 - b.x * (pars.x + z3) + b.y) / ((zf - z2) * (z3 - pars.y));
	G = clamp(G, 0.0, 1.0);

	float shadow = G;

	//if (projCoord.z >= 1.0f || projCoord.x >= 1.0f || projCoord.y >= 1.0f || projCoord.x <= 0.0f || projCoord.y <= 0.0f)
	//	shadow = 0.0f;

	return shadow;
}

vec4 InvEntropy(vec4 moment)
{
	vec4 inv = moment;
	inv.x -= 0.0359558848;
	mat4 invMat = mat4(
		0.222774414,  0.154967927,  0.145198897,  0.163127446,
		0.0771972849, 0.139462944,  0.212020218,  0.259143230,
		0.792698661,  0.796341590,  0.725869459,  0.653909266,
		0.0319417572, -0.172282318, -0.275801483, -0.337613176);
	inv = invMat * inv;

	return inv;
}


