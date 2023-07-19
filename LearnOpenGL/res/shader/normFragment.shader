#version 330 core

out vec4 fragColor;

void main()
{
	fragColor = vec4(0.5, 0.8, 0.5, 1.0);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}