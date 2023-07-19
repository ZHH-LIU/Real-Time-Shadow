#version 330 core

out vec4 fragColor;


uniform vec4 vexColor;
uniform sampler2D texture1;
uniform sampler2D texture2;

uniform vec3 lightColor;
uniform vec3 objectColor;


void main()
{
	fragColor = vec4(lightColor*objectColor,1.0f);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}