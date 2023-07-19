#version 330 core
layout(location = 0) out vec4 gPositionDepth;
layout(location = 1) out vec3 gNormal;
layout(location = 2) out vec4 gAlbedoSpec;

in vec2 texCoord;
in vec3 fragPos;
in vec3 normal;

uniform sampler2D texture_diffuse;
uniform sampler2D texture_specular;

const float NEAR = 0.1; // 投影矩阵的近平面
const float FAR = 1000.0f; // 投影矩阵的远平面
float LinearizeDepth(float depth)
{
    float z = depth * 2.0 - 1.0; // 回到NDC
    return (2.0 * NEAR * FAR) / (FAR + NEAR - z * (FAR - NEAR));
}


void main()
{

    gPositionDepth.rgb = fragPos;

    gPositionDepth.a = LinearizeDepth(gl_FragCoord.z);

    gNormal = normalize(normal);

    gAlbedoSpec.rgb = texture(texture_diffuse, texCoord).rgb;

    gAlbedoSpec.a = texture(texture_specular, texCoord).r;
}