#version 330 core

out vec4 fragColor;

in vec3 vexColor;

void main()
{
	fragColor = vec4(vexColor, 1.0f);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}