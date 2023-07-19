#version 330 core

out vec4 fragColor;

uniform vec3 lightColor;

void main()
{
	fragColor = vec4(lightColor,1.0);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}
