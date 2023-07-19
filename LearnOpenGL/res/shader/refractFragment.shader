#version 330 core

out vec4 fragColor;

in vec3 Position;
in vec3 Normal;

uniform samplerCube skybox;
uniform vec3 cameraPos;

void main()
{
	float ratio = 1.00 / 1.52;
	vec3 I = normalize(Position - cameraPos);
	vec3 R = refract(I, normalize(Normal),ratio);
	fragColor = texture(skybox, R);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}