#version 330 core

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

in VS_OUT{
    vec2 TexCoord;
} gs_in[];

uniform float time;
uniform mat4 projection;
out vec2 texCoord;

vec3 GetNormal()
{
    vec3 a = vec3(gl_in[0].gl_Position) - vec3(gl_in[1].gl_Position);
    vec3 b = vec3(gl_in[2].gl_Position) - vec3(gl_in[1].gl_Position);

    return normalize(cross(b, a));
}

vec4 explode(vec4 position, vec3 normal)
{
    float magnitude = 6.0;
    vec3 direction = (sin(time) + 1.0) / 2.0 * magnitude * normal;
    return projection * (position + vec4(direction, 0.0));
}


void main()
{
    vec3 normal = GetNormal();

    texCoord = gs_in[0].TexCoord;
    gl_Position = explode(gl_in[0].gl_Position, normal);    // 1:вСоб
    EmitVertex();
    texCoord = gs_in[1].TexCoord;
    gl_Position = explode(gl_in[1].gl_Position, normal);    // 2:сроб
    EmitVertex();
    texCoord = gs_in[2].TexCoord;
    gl_Position = explode(gl_in[2].gl_Position, normal);   // 3:вСио
    EmitVertex();

    EndPrimitive();
}
