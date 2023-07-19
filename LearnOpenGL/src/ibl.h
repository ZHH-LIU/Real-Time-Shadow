#ifndef IBL_H
#define IBL_H

#include <glad/glad.h> 
#include "shader.h"
#include "image.h"
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <string>
using std::string;

class IBL {
public:
	IBL() = default;
	IBL(string path);
	unsigned int HDRMap()
	{
		return HDR;
	}
	unsigned int CubeMap()
	{
		return envCubeMap;
	}
	unsigned int IrradianceMap()
	{
		return irradianceMap;
	}
	unsigned int PrefilterMap()
	{
		return prefilterMap;
	}
	unsigned int PrebrdfMap()
	{
		return prebrdfMap;
	}
private:
	Shader envCubeShader = Shader("res/shader/envCubeVertex.shader", "res/shader/envCubeFragment.shader");
	Shader irradianceShader = Shader("res/shader/irradianceVertex.shader", "res/shader/irradianceFragment.shader");
	Shader prefilterShader = Shader("res/shader/prefilterVertex.shader", "res/shader/prefilterFragment.shader");
	Shader prebrdfShader = Shader("res/shader/prebrdfVertex.shader", "res/shader/prebrdfFragment.shader");
	void GetVertexArray_Frame();
	void GetVertexArray_Cube();
	unsigned int cubeVAO, cubeVBO, cubeEBO;
	unsigned int frameVAO, frameVBO;
	void GetVertexArray();
	unsigned int HDR;
	void GetHDR(string path);
	unsigned int envCubeFBO, envCubeRBO, envCubeMap;
	void GetCubeMap();
	unsigned int irradianceFBO, irradianceRBO, irradianceMap;
	void GetIrradianceMap();
	unsigned int prefilterFBO, prefilterRBO, prefilterMap;
	void GetPrefilterMap();
	unsigned int prebrdfFBO, prebrdfRBO, prebrdfMap;
	void GetPrebrdfMap();
};

IBL::IBL(string path)
{
	GetVertexArray();
	GetHDR(path);
	GetCubeMap();
	GetIrradianceMap();
	GetPrefilterMap();
	GetPrebrdfMap();
}

void IBL::GetHDR(string path)
{
	stbi_set_flip_vertically_on_load(true);
	int width, height, nrChannels;
	float* data = stbi_loadf(path.c_str(), &width, &height, &nrChannels, 0);
	if (data)
	{
		glGenTextures(1, &HDR);
		glBindTexture(GL_TEXTURE_2D, HDR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, width, height, 0, GL_RGB, GL_FLOAT, data);
	}
	else
	{
		std::cout << "Failed to load HDR " + path << std::endl;
	}
	stbi_image_free(data);
}

void IBL::GetCubeMap()
{
	glGenFramebuffers(1, &envCubeFBO);
	glBindFramebuffer(GL_FRAMEBUFFER, envCubeFBO);

	glGenRenderbuffers(1, &envCubeRBO);
	glBindRenderbuffer(GL_RENDERBUFFER, envCubeRBO);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, 512, 512);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, envCubeRBO);

	glGenTextures(1, &envCubeMap);
	glBindTexture(GL_TEXTURE_CUBE_MAP, envCubeMap);
	for (unsigned int i = 0; i != 6; i++)
	{
		glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_RGB16F, 512, 512, 0, GL_RGB, GL_FLOAT, NULL);
	}
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);


	glm::mat4 projection = glm::perspective(glm::radians(90.0f), 1.0f, 0.1f, 10.0f);
	glm::mat4 views[] =
	{
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(1.0f,  0.0f,  0.0f), glm::vec3(0.0f, -1.0f,  0.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(-1.0f,  0.0f,  0.0f), glm::vec3(0.0f, -1.0f,  0.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f,  1.0f,  0.0f), glm::vec3(0.0f,  0.0f,  1.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, -1.0f,  0.0f), glm::vec3(0.0f,  0.0f, -1.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f,  0.0f,  1.0f), glm::vec3(0.0f, -1.0f,  0.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f,  0.0f, -1.0f), glm::vec3(0.0f, -1.0f,  0.0f))

	};

	envCubeShader.use();
	envCubeShader.setMat4("projection", glm::value_ptr(projection));

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, HDR);
	envCubeShader.setInt("equirectangularMap", 0);

	glViewport(0, 0, 512, 512);
	glEnable(GL_DEPTH_TEST);

	for (unsigned int i = 0; i != 6; i++)
	{
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, envCubeMap, 0);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		envCubeShader.setMat4("view", glm::value_ptr(views[i]));
	
		glBindVertexArray(cubeVAO);
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, (void*)(i * 6 * sizeof(unsigned int)));
	}

	glBindTexture(GL_TEXTURE_CUBE_MAP, envCubeMap);
	glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

	glBindFramebuffer(GL_FRAMEBUFFER, 0);
}


void IBL::GetIrradianceMap()
{
	glGenFramebuffers(1, &irradianceFBO);
	glBindFramebuffer(GL_FRAMEBUFFER, irradianceFBO);

	glGenRenderbuffers(1, &irradianceRBO);
	glBindRenderbuffer(GL_RENDERBUFFER, irradianceRBO);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, 32, 32);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, irradianceFBO);

	glGenTextures(1, &irradianceMap);
	glBindTexture(GL_TEXTURE_CUBE_MAP, irradianceMap);
	for (unsigned int i = 0; i != 6; i++)
	{
		glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_RGB16F, 32, 32, 0, GL_RGB, GL_FLOAT, NULL);
	}
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	glm::mat4 projection = glm::perspective(glm::radians(90.0f), 1.0f, 0.1f, 10.0f);
	glm::mat4 views[] =
	{
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(1.0f,  0.0f,  0.0f), glm::vec3(0.0f, -1.0f,  0.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(-1.0f,  0.0f,  0.0f), glm::vec3(0.0f, -1.0f,  0.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f,  1.0f,  0.0f), glm::vec3(0.0f,  0.0f,  1.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, -1.0f,  0.0f), glm::vec3(0.0f,  0.0f, -1.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f,  0.0f,  1.0f), glm::vec3(0.0f, -1.0f,  0.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f,  0.0f, -1.0f), glm::vec3(0.0f, -1.0f,  0.0f))

	};

	irradianceShader.use();
	irradianceShader.setMat4("projection", glm::value_ptr(projection));

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_CUBE_MAP, envCubeMap);
	irradianceShader.setInt("encCubeMap", 0);

	glViewport(0, 0, 32, 32);
	glEnable(GL_DEPTH_TEST);

	for (unsigned int i = 0; i != 6; i++)
	{
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, irradianceMap, 0);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		irradianceShader.setMat4("view", glm::value_ptr(views[i]));

		glBindVertexArray(cubeVAO);
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, (void*)(i * 6 * sizeof(unsigned int)));
	}

	glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void IBL::GetPrefilterMap()
{
	glGenFramebuffers(1, &prefilterFBO);
	glBindFramebuffer(GL_FRAMEBUFFER, prefilterFBO);

	glGenRenderbuffers(1, &prefilterRBO);
	glBindRenderbuffer(GL_RENDERBUFFER, prefilterRBO);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, 128, 128);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, prefilterRBO);

	glGenTextures(1, &prefilterMap);
	glBindTexture(GL_TEXTURE_CUBE_MAP, prefilterMap);
	for (unsigned int i = 0; i != 6; i++)
	{
		glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_RGB16F, 128, 128, 0, GL_RGB, GL_FLOAT, NULL);
	}
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

	glm::mat4 projection = glm::perspective(glm::radians(90.0f), 1.0f, 0.1f, 10.0f);
	glm::mat4 views[] =
	{
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(1.0f,  0.0f,  0.0f), glm::vec3(0.0f, -1.0f,  0.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(-1.0f,  0.0f,  0.0f), glm::vec3(0.0f, -1.0f,  0.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f,  1.0f,  0.0f), glm::vec3(0.0f,  0.0f,  1.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, -1.0f,  0.0f), glm::vec3(0.0f,  0.0f, -1.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f,  0.0f,  1.0f), glm::vec3(0.0f, -1.0f,  0.0f)),
		   glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f,  0.0f, -1.0f), glm::vec3(0.0f, -1.0f,  0.0f))

	};

	prefilterShader.use();
	prefilterShader.setMat4("projection", glm::value_ptr(projection));

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_CUBE_MAP, envCubeMap);
	prefilterShader.setInt("encCubeMap", 0);

	const unsigned int maxMipLevels = 5;
	for (unsigned int mip = 0; mip != maxMipLevels; mip++)
	{
		unsigned int mipWidth = 128 * pow(0.5, mip);
		unsigned int mipHeight = 128 * pow(0.5, mip);

		glBindRenderbuffer(GL_RENDERBUFFER, prefilterRBO);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, mipWidth, mipHeight);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, prefilterRBO);

		glViewport(0, 0, mipWidth, mipHeight);
		glEnable(GL_DEPTH_TEST);

		float roughness = (float)mip / (float)(maxMipLevels - 1);
		prefilterShader.setFloat("roughness", roughness);

		for (unsigned int i = 0; i != 6; i++)
		{
			glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, prefilterMap, mip);
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

			prefilterShader.setMat4("view", glm::value_ptr(views[i]));

			glBindVertexArray(cubeVAO);
			glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, (void*)(i * 6 * sizeof(unsigned int)));
		}
	}
	glBindFramebuffer(GL_FRAMEBUFFER,0);
}

void IBL::GetPrebrdfMap()
{
	glGenFramebuffers(1, &prebrdfFBO);
	glBindFramebuffer(GL_FRAMEBUFFER, prebrdfFBO);

	glGenRenderbuffers(1, &prebrdfRBO);
	glBindRenderbuffer(GL_RENDERBUFFER, prebrdfRBO);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, 512, 512);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, prebrdfRBO);

	glGenTextures(1, &prebrdfMap);
	glBindTexture(GL_TEXTURE_2D, prebrdfMap);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RG16F, 512, 512, 0, GL_RG, GL_FLOAT, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, prebrdfMap, 0);
	
	glViewport(0, 0, 512, 512);
	glEnable(GL_DEPTH_TEST);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	prebrdfShader.use();

	glBindVertexArray(frameVAO);
	glDrawArrays(GL_TRIANGLES, 0, 6);

	glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void IBL::GetVertexArray()
{
	GetVertexArray_Cube();
	GetVertexArray_Frame();
}

void IBL::GetVertexArray_Cube()
{
	float vertices[] = {
			0.5f, -0.5f, -0.5f,
			0.5f, 0.5f, -0.5f,
			 0.5f, 0.5f,  0.5f,
			 0.5f, -0.5f,  0.5f,

			-0.5f, -0.5f, -0.5f,
			-0.5f, 0.5f, -0.5f,
			 -0.5f, 0.5f,  0.5f,
			 -0.5f, -0.5f,  0.5f,

			-0.5f, 0.5f,-0.5f,
			-0.5f, 0.5f, 0.5f,
			 0.5f, 0.5f, 0.5f,
			0.5f, 0.5f, -0.5f,

			-0.5f, -0.5f,-0.5f,
			-0.5f, -0.5f, 0.5f,
			 0.5f, -0.5f, 0.5f,
			 0.5f, -0.5f, -0.5f,

			 -0.5f, -0.5f, 0.5f,
			 0.5f, -0.5f, 0.5f, 
			 0.5f,  0.5f, 0.5f, 
			-0.5f,  0.5f, 0.5f, 

			-0.5f, -0.5f, -0.5f,
			0.5f, -0.5f, -0.5f, 
			 0.5f,  0.5f, -0.5f,
			-0.5f,  0.5f, -0.5f
	};
	unsigned int indices[] = {
		0, 1, 2, // 第一个三角形
		2, 3, 0,  // 第二个三角形

		6, 5, 4,
		4, 7, 6,

		8, 9, 10,
		10, 11, 8,

		14 ,13, 12,
		12, 15, 14,

		16, 17, 18,
		18, 19, 16,

		22, 21, 20,
		20, 23, 22
	};

	glGenBuffers(1, &cubeVBO);
	glGenBuffers(1, &cubeEBO);
	glGenVertexArrays(1, &cubeVAO);

	glBindVertexArray(cubeVAO);
	glBindBuffer(GL_ARRAY_BUFFER, cubeVBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, cubeEBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
	glEnableVertexAttribArray(0);

	glBindVertexArray(0);

}

void IBL::GetVertexArray_Frame()
{
	float frameVertices[] =
	{
		-1.0, -1.0,  0.0, 0.0,
		 1.0, -1.0,  1.0, 0.0,
		 1.0,  1.0,  1.0, 1.0,
		 1.0,  1.0,  1.0, 1.0,
		-1.0,  1.0,  0.0, 1.0,
		-1.0, -1.0,  0.0, 0.0
	};

	glGenBuffers(1, &frameVBO);
	glGenVertexArrays(1, &frameVAO);

	glBindVertexArray(frameVAO);
	glBindBuffer(GL_ARRAY_BUFFER, frameVBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(frameVertices), frameVertices, GL_STATIC_DRAW);
	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)0);
	glEnableVertexAttribArray(0);
	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)(2 * sizeof(float)));
	glEnableVertexAttribArray(1);
	glBindVertexArray(0);
}
#endif

