#version 330 core

in vec2 texCoord;

out vec4 fragColor;

uniform sampler2D texColorBuffer;

const float offset = 1.0 / 300.0;

void main()
{
	vec2 offsets[9] =
	{
		vec2(-offset,offset),//左上
		vec2(0.0,offset),//上
		vec2(offset,offset),//右上
		vec2(-offset,0.0),//左
		vec2(0.0,0.0),//中
		vec2(offset,0.0),//右
		vec2(-offset,-offset),//左下
		vec2(0.0,-offset),//下
		vec2(offset,-offset),//左上
	};

	//锐化
	/*
	float kernal[9] =
	{
		-1, -1, -1,
		-1, 9, -1,
		-1, -1, -1
	};
	*/

	//模糊
	/*
	float kernal[9] =
	{
		1.0 / 16, 2.0 / 16, 1.0 / 16,
		2.0 / 16, 4.0 / 16, 2.0 / 16,
		1.0 / 16, 2.0 / 16, 1.0 / 16
	};
	*/
	//边缘检测
	float kernal[9] =
	{
		1, 1, 1,
		1, -8, 1,
		1, 1, 1
	};

	vec3 samples[9];
	for (int i = 0; i != 9; i++)
	{
		samples[i] = vec3(texture(texColorBuffer, texCoord+offsets[i]));
	}
	vec3 col = vec3(0.0);

	for (int i = 0; i != 9; i++)
	{
		col += samples[i] * kernal[i];
	}

	fragColor = vec4(col, 1.0);
	//gamma
	//float gamma = 2.2;
	//fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / gamma));
}