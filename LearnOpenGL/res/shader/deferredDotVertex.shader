#version 330 core

layout(location = 0) in vec3 aPos;

out vec2 texCoord;
out mat4 View;//使用观察空间

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
	vec4 position = projection * view * model * vec4(aPos, 1.0f);
	gl_Position = position;
	texCoord = vec2(position.x / position.w, position.y / position.w) * 0.5f + vec2(0.5f);
	View = view;//使用观察空间
}
