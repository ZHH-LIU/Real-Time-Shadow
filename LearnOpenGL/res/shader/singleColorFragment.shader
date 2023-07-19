#version 330 core

out vec4 fragColor;

void main()
{
	fragColor = vec4(0.0,0.2,0.6,1.0);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}