#version 330 core

in vec3 localPos;
out vec4 fragColor;

uniform samplerCube envCubeMap;

const float PI = 3.14159265359;

void main()
{
	vec3 normal = normalize(localPos);
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 right = cross(up, normal);
	up = cross(normal, right);
	mat3 RUN = mat3(right, up, normal);

	vec3 irradiance = vec3(0.0);

	float sampleDelta = 0.025;
	float nrSamples = 0.0;

	for (float theta = 0.0; theta < 0.5 * PI; theta += sampleDelta)
	{
		for (float phi = 0.0; phi < 2 * PI; phi += sampleDelta)
		{
			vec3 tangentSample = vec3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));
			vec3 sampleVec = RUN * tangentSample;

			irradiance += texture(envCubeMap, sampleVec).rgb * cos(theta) * sin(theta);

			nrSamples++;
		}
	}

	irradiance = irradiance * (PI * PI) / nrSamples;

	fragColor = vec4(irradiance, 1.0);
}


