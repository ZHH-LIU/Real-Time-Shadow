#version 330 core

in vec3 texCoord;

out vec4 fragColor;

uniform samplerCube skybox;

uniform float mip;

void main()
{
	fragColor = vec4(textureLod(skybox, texCoord, mip).rgb,1.0);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}
