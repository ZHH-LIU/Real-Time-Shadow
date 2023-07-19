#version 330 core

out vec4 fragColor;

in vec3 Position;
in vec3 Normal;

uniform samplerCube skybox;
uniform vec3 cameraPos;

void main()
{
	vec3 I = normalize(Position - cameraPos);
	vec3 R = reflect(I, normalize(Normal));
	fragColor = texture(skybox, R);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}