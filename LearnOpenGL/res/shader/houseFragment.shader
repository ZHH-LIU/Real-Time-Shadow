#version 330 core

in vec3 fColor;

out vec4 fragColor;

void main()
{
	fragColor = vec4(fColor, 1.0);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}