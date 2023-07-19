#version 330 core

layout(triangles) in;
layout(line_strip, max_vertices = 6) out;

in VS_OUT
{
	vec3 normal;
}gs_in[];

uniform mat4 projection;

const float magnitude = 0.3;

void DrawNorm(int index)
{
	gl_Position = projection * gl_in[index].gl_Position;
	EmitVertex();
	gl_Position = projection * (gl_in[index].gl_Position + magnitude * vec4(gs_in[index].normal, 0.0));
	EmitVertex();
	EndPrimitive();
}

void main()
{
	DrawNorm(0);
	DrawNorm(1);
	DrawNorm(2);
}