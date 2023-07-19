#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 2) in vec2 aTexCoord;
layout(location = 3) in mat4 ainstanceMatrix;

uniform mat4 view;
uniform mat4 projection;
uniform mat4 rotate;

out vec2 texCoord;

void main()
{
	gl_Position = projection * view * rotate * ainstanceMatrix * vec4(aPos, 1.0);
	texCoord = aTexCoord;
}
