#version 330 core

out vec4 fragColor;

in vec2 texCoord;

struct Material {
	//vec3 ambient;
	sampler2D texture_diffuse1;
	sampler2D texture_specular1;
	float shininess;
};
uniform Material material;

void main()
{
	fragColor = texture(material.texture_diffuse1, texCoord);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}