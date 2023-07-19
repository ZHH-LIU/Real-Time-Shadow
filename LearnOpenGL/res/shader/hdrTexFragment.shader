#version 330 core

in vec3 localPos;
out vec4 fragColor;

uniform sampler2D equirectangularMap;

const float PI = 3.14159265359;

vec2 SampleSphericalMap(vec3 v)
{
	vec2 uv = vec2(atan(v.z, v.x), asin(v.y));
	uv /= vec2(2 * PI, PI);
	uv += 0.5;
	return uv;
}

void main()
{
	vec2 uv = SampleSphericalMap(normalize(localPos));
	vec3 color = texture(equirectangularMap, uv).rgb;
	fragColor = vec4(color, 1.0);
}
