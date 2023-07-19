#version 330 core

in vec2 texCoord;

out vec4 fragColor;

struct Material {
	sampler2D texture_diffuse1;
};
uniform Material material;

void main()
{
	fragColor = texture(material.texture_diffuse1, texCoord);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}
