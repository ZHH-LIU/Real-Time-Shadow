#version 330 core

in vec2 texCoord;
out vec4 fragColor;

uniform sampler2D texColorBuffer;
uniform sampler2D blurColorBuffer;

void main()
{
	vec3 result = texture(texColorBuffer, texCoord).rgb;
	vec3 blur = texture(blurColorBuffer, texCoord).rgb;
	result=result+blur;
	fragColor = vec4(result, 1.0);
}
