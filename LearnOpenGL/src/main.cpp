#include <glad/glad.h> 
#include <GLFW/glfw3.h>
#include <iostream>

#include "shader.h"
#include "image.h"
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include "camera.h"
#include <map> 
#include "object.h"
#include "pbr.h"
#include "shadow.h"
#include "font.h"
#include "fps.h"

using std::map;

void getFps(GLFWwindow* window, float currentTime, float deltaTime);
void processInput(GLFWwindow* window);
void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void mouse_callback(GLFWwindow* window, double xpos, double ypos);
void scroll_callback(GLFWwindow* window, double xoffset, double yoffset);

const unsigned int SCR_WIDTH = 800;
const unsigned int SCR_HEIGHT = 600;

//camera
Camera camera(glm::vec3(0.0f, 0.0f, -20.0f), glm::vec3(0.0f, 0.0f, -1.0f), glm::vec3(0.0f, 1.0f, 0.0f));

float lastTime = 0.0f, deltaTime = 0.0f;
double lastX, lastY;
bool firstMouse=true;

//FPS
FPS_COUNTER ourFPS;

int main() {
	//GLFW初始化
	glfwInit();
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE,GLFW_OPENGL_CORE_PROFILE);
	//glfwWindowHint(GLFW_SAMPLES, 4);//多重采样缓冲
	
	//GLFW窗口
	GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL", NULL, NULL);
	if (window == NULL)
	{
		std::cout<< "Failed to create GLFW window" << std::endl;
		glfwTerminate();
		return -1;
	}
	glfwMakeContextCurrent(window);

	//GLAD初始化
	if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
	{
		std::cout << "Failed to initialize GLAD" << std::endl;
		return -1;
	}

	//callback
	//glViewport(0, 0, 400, 300);
	glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
	glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
	glfwSetCursorPosCallback(window, mouse_callback);
	glfwSetScrollCallback(window, scroll_callback);

	//VAO VBO EBO
	float vertices[] = {
		//     ---- 位置 ----       ---- 颜色 ----     - 纹理坐标 -   ----法线----
			 -0.5f, -0.5f, 0.5f,   0.0f, 0.0f, 1.0f,   0.0f, 0.0f,   0.0f, 0.0f, 1.0f,// 左下
			 0.5f, -0.5f, 0.5f,   0.0f, 1.0f, 0.0f,   1.0f, 0.0f,   0.0f, 0.0f, 1.0f,// 右下
			 0.5f,  0.5f, 0.5f,   1.0f, 0.0f, 0.0f,   1.0f, 1.0f,   0.0f, 0.0f, 1.0f,// 右上
			-0.5f,  0.5f, 0.5f,   1.0f, 1.0f, 0.0f,   0.0f, 1.0f,   0.0f, 0.0f, 1.0f, // 左上

		//     ---- 位置 ----       ---- 颜色 ----     - 纹理坐标 -   ----法线----
			-0.5f, -0.5f, -0.5f,   0.0f, 0.0f, 1.0f,   0.0f, 0.0f,   0.0f, 0.0f, -1.0f,// 左下
			0.5f, -0.5f, -0.5f,   0.0f, 1.0f, 0.0f,   1.0f, 0.0f,   0.0f, 0.0f, -1.0f,// 右下
			 0.5f,  0.5f, -0.5f,   1.0f, 0.0f, 0.0f,   1.0f, 1.0f,   0.0f, 0.0f, -1.0f,// 右上
			-0.5f,  0.5f, -0.5f,   1.0f, 1.0f, 0.0f,   0.0f, 1.0f,   0.0f, 0.0f, -1.0f,// 左上

		//     ---- 位置 ----       ---- 颜色 ----     - 纹理坐标 -   ----法线----
			-0.5f, 0.5f,-0.5f,    0.0f, 0.0f, 1.0f,   0.0f, 0.0f,   0.0f, 1.0f, 0.0f,// 左下
			-0.5f, 0.5f, 0.5f,    1.0f, 1.0f, 0.0f,   1.0f, 0.0f,   0.0f, 1.0f, 0.0f, // 右下
			 0.5f, 0.5f, 0.5f,    1.0f, 0.0f, 0.0f,   1.0f, 1.0f,   0.0f, 1.0f, 0.0f,// 右上
			0.5f, 0.5f, -0.5f,    0.0f, 1.0f, 0.0f,   0.0f, 1.0f,  0.0f, 1.0f, 0.0f, // 左上

		//     ---- 位置 ----       ---- 颜色 ----     - 纹理坐标 -   ----法线----
			-0.5f, -0.5f,-0.5f,    0.0f, 0.0f, 1.0f,   0.0f, 0.0f,   0.0f, -1.0f, 0.0f,// 左下
			-0.5f, -0.5f, 0.5f,    1.0f, 1.0f, 0.0f,   1.0f,0.0f,   0.0f, -1.0f, 0.0f, // 右下
			 0.5f, -0.5f, 0.5f,    1.0f, 0.0f, 0.0f,   1.0f, 1.0f,   0.0f, -1.0f, 0.0f,// 右上
			 0.5f, -0.5f, -0.5f,    0.0f, 1.0f, 0.0f,   0.0f, 1.0f,  0.0f, -1.0f, 0.0f, // 左上

		//     ---- 位置 ----       ---- 颜色 ----     - 纹理坐标 -   ----法线----
			0.5f, -0.5f, -0.5f,   0.0f, 0.0f, 1.0f,   0.0f, 0.0f,   1.0f, 0.0f, 0.0f,// 左下
			0.5f, 0.5f, -0.5f,   0.0f, 1.0f, 0.0f,   1.0f, 0.0f,    1.0f, 0.0f, 0.0f,// 右下
			 0.5f, 0.5f,  0.5f,    1.0f, 0.0f, 0.0f,   1.0f, 1.0f,   1.0f, 0.0f, 0.0f,// 右上
			 0.5f, -0.5f,  0.5f,   1.0f, 1.0f, 0.0f,   0.0f, 1.0f,   1.0f, 0.0f, 0.0f,// 左上

		//     ---- 位置 ----       ---- 颜色 ----     - 纹理坐标 -   ----法线----
			-0.5f, -0.5f, -0.5f,   0.0f, 0.0f, 1.0f,   0.0f, 0.0f,   -1.0f, 0.0f, 0.0f,// 左下
			-0.5f, 0.5f, -0.5f,   0.0f, 1.0f, 0.0f,   1.0f, 0.0f,    -1.0f, 0.0f, 0.0f,// 右下
			 -0.5f, 0.5f,  0.5f,    1.0f, 0.0f, 0.0f,   1.0f, 1.0f,   -1.0f, 0.0f, 0.0f,// 右上
			 -0.5f, -0.5f,  0.5f,   1.0f, 1.0f, 0.0f,   0.0f, 1.0f,   -1.0f, 0.0f, 0.0f // 左上
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

	unsigned int VBO;
	glGenBuffers(1, &VBO);
	unsigned int EBO;
	glGenBuffers(1, &EBO);
	unsigned int skyVAO;
	glGenVertexArrays(1, &skyVAO);

	glBindVertexArray(skyVAO);
	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 11 * sizeof(float), (void*)0);
	glEnableVertexAttribArray(0);	



	//program
	Shader frameShader("res/shader/hdrVertex.shader", "res/shader/hdrFragment.shader");
	Shader skyboxShader("res/shader/skyboxVertex.shader", "res/shader/skyboxFragment.shader");

	//帧缓冲
	unsigned int FBO;
	glGenFramebuffers(1, &FBO);
	glBindFramebuffer(GL_FRAMEBUFFER, FBO);

	unsigned int texColorBuffer;
	glGenTextures(1, &texColorBuffer);
	glBindTexture(GL_TEXTURE_2D, texColorBuffer);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, 800, 600, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glBindTexture(GL_TEXTURE_2D, 0);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texColorBuffer, 0);

	unsigned int RBO;
	glGenRenderbuffers(1, &RBO);
	glBindRenderbuffer(GL_RENDERBUFFER, RBO);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, 800, 600);
	glBindRenderbuffer(GL_RENDERBUFFER, 0);

	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, RBO);

	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
		std::cout << "ERROR::FRAMEBUFFER:: Framebuffer is not complete!" << std::endl;
	}
	glBindFramebuffer(GL_FRAMEBUFFER, 0);

	float frameVertices[] =
	{
		-1.0, -1.0,  0.0, 0.0,
		 1.0, -1.0,  1.0, 0.0,
		 1.0,  1.0,  1.0, 1.0,
		 1.0,  1.0,  1.0, 1.0,
		-1.0,  1.0,  0.0, 1.0,
		- 1.0, -1.0,  0.0, 0.0
	};

	unsigned int frameVBO;
	glGenBuffers(1, &frameVBO);
	unsigned int frameVAO;
	glGenVertexArrays(1, &frameVAO);

	glBindVertexArray(frameVAO);
	glBindBuffer(GL_ARRAY_BUFFER, frameVBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(frameVertices), frameVertices, GL_STATIC_DRAW);
	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)0);
	glEnableVertexAttribArray(0);
	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)(2 * sizeof(float)));
	glEnableVertexAttribArray(1);
	
	//shadow map
	
	glm::vec3 ourDirShadowPosition = glm::vec3(40.0f, 10.0f, 40.0f);
	glm::vec3 ourDirShadowDirection = glm::vec3(-10.0f, -7.0f, -10.0f);
	glm::vec3 ourDirShadowAmbient = glm::vec3(0.05f, 0.05f, 0.05f);
	glm::vec3 ourDirShadowDiffuse = glm::vec3(1.0f, 1.0f, 1.0f);
	glm::vec3 ourDirShadowSpecular = glm::vec3(0.4f, 0.4f, 0.4f);

	DirLight ourDirShadowLight(ourDirShadowDirection, ourDirShadowAmbient, ourDirShadowDiffuse, ourDirShadowSpecular);
	DirShadow ourDirShadow(ourDirShadowLight, ourDirShadowPosition);

	const char* ourDirShadowCubeTex = "res/texture/gold.png";
	const char* ourDirShadowSquareTex = "res/texture/brick.jpg";
	Cube ourDirShadowCube0(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourDirShadowCube0.SetModel(glm::vec3(24.0, 3.0, 39.0), 4.0);
	Cube ourDirShadowCube1(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourDirShadowCube1.SetModel(glm::vec3(30.0, 6.0, 33.0), 4.0);
	Cube ourDirShadowCube2(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourDirShadowCube2.SetModel(glm::vec3(37.0, 4.0, 23.0), 4.0);
	Square ourDirShadowSquare(ourDirShadowSquareTex, ourDirShadowSquareTex, 3);
	ourDirShadowSquare.SetModel(glm::vec3(30.0, 1.0, 30.0), 50.0);

	vector<Object>ourDirShadowObjects;
	ourDirShadowObjects.push_back(ourDirShadowCube0);
	ourDirShadowObjects.push_back(ourDirShadowCube1);
	ourDirShadowObjects.push_back(ourDirShadowCube2);
	ourDirShadowObjects.push_back(ourDirShadowSquare);
	
	//立方体阴影贴图
	glm::vec3 ourDotShadowPosition = glm::vec3(-30.0f, -10.0f, 20.0f);
	glm::vec3 ourDotShadowAmbient = glm::vec3(0.05f, 0.05f, 0.05f);
	glm::vec3 ourDotShadowDiffuse = glm::vec3(1.0f, 1.0f, 1.0f);
	glm::vec3 ourDotShadowSpecular = glm::vec3(0.4f, 0.4f, 0.4f);

	DotLight ourDotShadowLight(ourDotShadowPosition, ourDotShadowAmbient, ourDotShadowDiffuse, ourDotShadowSpecular);
	DotShadow ourDotShadow(ourDotShadowLight);

	glm::vec3 goldPositions[] = {
	glm::vec3(-10.0f,0.0f,5.0f),
	glm::vec3(-13.0f,6.0f,17.0f),
	glm::vec3(8.0f,-9.0f,3.0f),
	glm::vec3(16.0f,5.0f,12.0f),
	glm::vec3(-14.0f,13.0f,6.0f),
	glm::vec3(10.0f,9.0f,10.0f)
	};

	Cube ourDotShadowCube0(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourDotShadowCube0.SetModel(goldPositions[0]+ glm::vec3(-30.0, -5.0, 30.0), 5.0);
	Cube ourDotShadowCube1(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourDotShadowCube1.SetModel(goldPositions[1]+ glm::vec3(-30.0, -5.0, 30.0), 5.0);
	Cube ourDotShadowCube2(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourDotShadowCube2.SetModel(goldPositions[2]+ glm::vec3(-30.0, -5.0, 30.0), 5.0);
	Cube ourDotShadowCube3(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourDotShadowCube3.SetModel(goldPositions[3]+ glm::vec3(-30.0, -5.0, 30.0), 5.0);
	Cube ourDotShadowCube4(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourDotShadowCube4.SetModel(goldPositions[4]+ glm::vec3(-30.0, -5.0, 30.0), 5.0);
	Cube ourDotShadowCube5(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourDotShadowCube5.SetModel(goldPositions[5]+ glm::vec3(-30.0, -5.0, 30.0), 5.0);

	Cube ourDotShadowCube6(ourDirShadowSquareTex, ourDirShadowSquareTex,false);
	ourDotShadowCube6.SetModel(glm::vec3(-30.0, -5.0, 30.0), 50.0);

	vector<Object>ourDotShadowObjects;
	ourDotShadowObjects.push_back(ourDotShadowCube0);
	ourDotShadowObjects.push_back(ourDotShadowCube1);
	ourDotShadowObjects.push_back(ourDotShadowCube2);
	ourDotShadowObjects.push_back(ourDotShadowCube3);
	ourDotShadowObjects.push_back(ourDotShadowCube4);
	ourDotShadowObjects.push_back(ourDotShadowCube5);
	ourDotShadowObjects.push_back(ourDotShadowCube6);

	//spot shadow
	glm::vec3 ourSpotShadowPosition = glm::vec3(50.0f, 15.0f, 50.0f) + glm::vec3(50.0, 0, 50.0);
	glm::vec3 ourSpotShadowDirection = glm::vec3(-10.0f, -7.0f, -10.0f);
	glm::vec3 ourSpotShadowAmbient = glm::vec3(0.2f, 0.2f, 0.2f);
	glm::vec3 ourSpotShadowDiffuse = glm::vec3(10.0f, 10.0f, 10.0f);
	glm::vec3 ourSpotShadowSpecular = glm::vec3(5.4f, 5.4f, 5.4f);
	SpotLight ourSpotShadowLight(ourSpotShadowPosition, ourSpotShadowDirection, ourSpotShadowAmbient, ourSpotShadowDiffuse, ourSpotShadowSpecular);
	SpotShadow ourSpotShadow(ourSpotShadowLight);

	Cube ourSpotShadowCube0(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourSpotShadowCube0.SetModel(glm::vec3(24.0, 3.0, 39.0)+ glm::vec3(50.0, 0, 50.0), 4.0);
	Cube ourSpotShadowCube1(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourSpotShadowCube1.SetModel(glm::vec3(30.0, 6.0, 33.0) + glm::vec3(50.0, 0, 50.0), 4.0);
	Cube ourSpotShadowCube2(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourSpotShadowCube2.SetModel(glm::vec3(37.0, 4.0, 23.0) + glm::vec3(50.0, 0, 50.0), 4.0);
	Square ourSpotShadowSquare(ourDirShadowSquareTex, ourDirShadowSquareTex, 3);
	ourSpotShadowSquare.SetModel(glm::vec3(30.0, 1.0, 30.0) + glm::vec3(50.0, 0, 50.0), 50.0);

	vector<Object>ourSpotShadowObjects;
	ourSpotShadowObjects.push_back(ourSpotShadowCube0);
	ourSpotShadowObjects.push_back(ourSpotShadowCube1);
	ourSpotShadowObjects.push_back(ourSpotShadowCube2);
	ourSpotShadowObjects.push_back(ourSpotShadowSquare);

	//PCSS shadow
	glm::vec3 ourPcssShadwDeltaPosition = glm::vec3(-10.0, 0, 60.0);
	glm::vec3 ourPcssShadowPosition = glm::vec3(55.0f, 16.0f, 55.0f) + ourPcssShadwDeltaPosition;
	glm::vec3 ourPcssShadowAmbient = glm::vec3(0.5f, 0.5f, 0.5f);
	glm::vec3 ourPcssShadowDiffuse = glm::vec3(30.0f, 30.0f, 30.0f);
	glm::vec3 ourPcssShadowSpecular = glm::vec3(24.0f, 24.0f, 24.0f);

	glm::vec3 ourPcssShadowDirection = glm::vec3(-10.0f, -7.0f, -10.0f);
	DotLight ourPcssShadowLight(ourPcssShadowPosition, ourPcssShadowAmbient, ourPcssShadowDiffuse, ourPcssShadowSpecular);
	float ourPcssShadowLightWidth = 4.0f;
	PCSSShadow ourPcssShadow(ourPcssShadowLight, ourPcssShadowDirection, ourPcssShadowLightWidth);

	Cube ourPcssShadowCube0(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourPcssShadowCube0.SetModel(glm::vec3(24.0, 8.0, 39.0)+ ourPcssShadwDeltaPosition, glm::vec3(2.0,16.0,2.0));
	Cube ourPcssShadowCube1(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourPcssShadowCube1.SetModel(glm::vec3(30.0, 6.0, 33.0)+ ourPcssShadwDeltaPosition, 4.0);
	Cube ourPcssShadowCube2(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourPcssShadowCube2.SetModel(glm::vec3(37.0, 4.0, 23.0)+ ourPcssShadwDeltaPosition, 4.0);
	Square ourPcssShadowSquare(ourDirShadowSquareTex, ourDirShadowSquareTex, 3);
	ourPcssShadowSquare.SetModel(glm::vec3(30.0, 0.0, 30.0)+ ourPcssShadwDeltaPosition, 60.0);

	vector<Object>ourPcssShadowObjects;
	ourPcssShadowObjects.push_back(ourPcssShadowCube0);
	ourPcssShadowObjects.push_back(ourPcssShadowCube1);
	ourPcssShadowObjects.push_back(ourPcssShadowCube2);
	ourPcssShadowObjects.push_back(ourPcssShadowSquare);

	//VSSM shadow
	glm::vec3 ourVssmShadwDeltaPosition = glm::vec3(-70.0, 0, 140.0);
	glm::vec3 ourVssmShadowPosition = glm::vec3(55.0f, 16.0f, 55.0f) + ourVssmShadwDeltaPosition;
	glm::vec3 ourVssmShadowAmbient = glm::vec3(0.05f, 0.05f, 0.05f);
	glm::vec3 ourVssmShadowDiffuse = glm::vec3(30.0f, 30.0f, 30.0f);
	glm::vec3 ourVssmShadowSpecular = glm::vec3(24.0f, 24.0f, 24.0f);

	glm::vec3 ourVssmShadowDirection = glm::vec3(-10.0f, -7.0f, -10.0f);
	DotLight ourVssmShadowLight(ourVssmShadowPosition, ourVssmShadowAmbient, ourVssmShadowDiffuse, ourVssmShadowSpecular);
	float ourVssmShadowLightWidth = 4.0f;
	VSSMShadow ourVssmShadow(ourVssmShadowLight, ourVssmShadowDirection, ourVssmShadowLightWidth);

	Cube ourVssmShadowCube0(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourVssmShadowCube0.SetModel(glm::vec3(24.0, 8.0, 39.0) + ourVssmShadwDeltaPosition, glm::vec3(2.0, 16.0, 2.0));
	Cube ourVssmShadowCube1(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourVssmShadowCube1.SetModel(glm::vec3(30.0, 6.0, 33.0) + ourVssmShadwDeltaPosition, 4.0);
	Cube ourVssmShadowCube2(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourVssmShadowCube2.SetModel(glm::vec3(37.0, 4.0, 23.0) + ourVssmShadwDeltaPosition, 4.0);
	Square ourVssmShadowSquare(ourDirShadowSquareTex, ourDirShadowSquareTex, 3);
	ourVssmShadowSquare.SetModel(glm::vec3(30.0, 0.0, 30.0) + ourVssmShadwDeltaPosition, 70.0);

	vector<Object>ourVssmShadowObjects;
	ourVssmShadowObjects.push_back(ourVssmShadowCube0);
	ourVssmShadowObjects.push_back(ourVssmShadowCube1);
	ourVssmShadowObjects.push_back(ourVssmShadowCube2);
	ourVssmShadowObjects.push_back(ourVssmShadowSquare);

	//ESM shadow
	glm::vec3 ourEsmShadwDeltaPosition = glm::vec3(60.0, 0, 140.0);
	glm::vec3 ourEsmShadowPosition = glm::vec3(55.0f, 16.0f, 55.0f) + ourEsmShadwDeltaPosition;
	glm::vec3 ourEsmShadowAmbient = glm::vec3(0.5f, 0.5f, 0.5f);
	glm::vec3 ourEsmShadowDiffuse = glm::vec3(30.0f, 30.0f, 30.0f);
	glm::vec3 ourEsmShadowSpecular = glm::vec3(24.0f, 24.0f, 24.0f);

	glm::vec3 ourEsmShadowDirection = glm::vec3(-10.0f, -7.0f, -10.0f);
	DotLight ourEsmShadowLight(ourEsmShadowPosition, ourEsmShadowAmbient, ourEsmShadowDiffuse, ourEsmShadowSpecular);
	float ourEsmShadowLightWidth = 4.0f;
	ESMShadow ourEsmShadow(ourEsmShadowLight, ourEsmShadowDirection, ourEsmShadowLightWidth, 80.0f, 2);

	Cube ourEsmShadowCube0(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourEsmShadowCube0.SetModel(glm::vec3(24.0, 8.0, 39.0) + ourEsmShadwDeltaPosition, glm::vec3(2.0, 16.0, 2.0));
	Cube ourEsmShadowCube1(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourEsmShadowCube1.SetModel(glm::vec3(30.0, 6.0, 33.0) + ourEsmShadwDeltaPosition, 4.0);
	Cube ourEsmShadowCube2(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourEsmShadowCube2.SetModel(glm::vec3(37.0, 4.0, 23.0) + ourEsmShadwDeltaPosition, 4.0);
	Square ourEsmShadowSquare(ourDirShadowSquareTex, ourDirShadowSquareTex, 3);
	ourEsmShadowSquare.SetModel(glm::vec3(30.0, 0.0, 30.0) + ourEsmShadwDeltaPosition, 70.0);

	vector<Object>ourEsmShadowObjects;
	ourEsmShadowObjects.push_back(ourEsmShadowCube0);
	ourEsmShadowObjects.push_back(ourEsmShadowCube1);
	ourEsmShadowObjects.push_back(ourEsmShadowCube2);
	ourEsmShadowObjects.push_back(ourEsmShadowSquare);

	//MSM shadow
	glm::vec3 ourMsmShadwDeltaPosition = glm::vec3(130.0, 0, 70.0);
	glm::vec3 ourMsmShadowPosition = glm::vec3(55.0f, 16.0f, 55.0f) + ourMsmShadwDeltaPosition;
	glm::vec3 ourMsmShadowAmbient = glm::vec3(0.5f, 0.5f, 0.5f);
	glm::vec3 ourMsmShadowDiffuse = glm::vec3(30.0f, 30.0f, 30.0f);
	glm::vec3 ourMsmShadowSpecular = glm::vec3(24.0f, 24.0f, 24.0f);

	glm::vec3 ourMsmShadowDirection = glm::vec3(-10.0f, -7.0f, -10.0f);
	DotLight ourMsmShadowLight(ourMsmShadowPosition, ourMsmShadowAmbient, ourMsmShadowDiffuse, ourMsmShadowSpecular);
	float ourMsmShadowLightWidth = 4.0f;
	MSMShadow ourMsmShadow(ourMsmShadowLight, ourMsmShadowDirection, ourMsmShadowLightWidth, 2);

	Cube ourMsmShadowCube0(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourMsmShadowCube0.SetModel(glm::vec3(24.0, 8.0, 39.0) + ourMsmShadwDeltaPosition, glm::vec3(2.0, 16.0, 2.0));
	Cube ourMsmShadowCube1(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourMsmShadowCube1.SetModel(glm::vec3(30.0, 6.0, 33.0) + ourMsmShadwDeltaPosition, 4.0);
	Cube ourMsmShadowCube2(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourMsmShadowCube2.SetModel(glm::vec3(37.0, 4.0, 23.0) + ourMsmShadwDeltaPosition, 4.0);
	Square ourMsmShadowSquare(ourDirShadowSquareTex, ourDirShadowSquareTex, 3);
	ourMsmShadowSquare.SetModel(glm::vec3(30.0, 0.0, 30.0) + ourMsmShadwDeltaPosition, 70.0);

	vector<Object>ourMsmShadowObjects;
	ourMsmShadowObjects.push_back(ourMsmShadowCube0);
	ourMsmShadowObjects.push_back(ourMsmShadowCube1);
	ourMsmShadowObjects.push_back(ourMsmShadowCube2);
	ourMsmShadowObjects.push_back(ourMsmShadowSquare);

	//vsm shadow
	glm::vec3 ourVsmShadwDeltaPosition = glm::vec3(130.0, 0, 70.0);
	glm::vec3 ourVsmShadowPosition = glm::vec3(55.0f, 16.0f, 55.0f) + ourVsmShadwDeltaPosition;
	glm::vec3 ourVsmShadowAmbient = glm::vec3(0.05f, 0.05f, 0.05f);
	glm::vec3 ourVsmShadowDiffuse = glm::vec3(30.0f, 30.0f, 30.0f);
	glm::vec3 ourVsmShadowSpecular = glm::vec3(24.0f, 24.0f, 24.0f);

	glm::vec3 ourVsmShadowDirection = glm::vec3(-10.0f, -7.0f, -10.0f);
	DotLight ourVsmShadowLight(ourVsmShadowPosition, ourVsmShadowAmbient, ourVsmShadowDiffuse, ourVsmShadowSpecular);
	float ourVsmShadowLightWidth = 4.0f;
	VSMShadow ourVsmShadow(ourVsmShadowLight, ourVsmShadowDirection, ourVsmShadowLightWidth);

	Cube ourVsmShadowCube0(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourVsmShadowCube0.SetModel(glm::vec3(24.0, 8.0, 39.0) + ourVsmShadwDeltaPosition, glm::vec3(2.0, 16.0, 2.0));
	Cube ourVsmShadowCube1(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourVsmShadowCube1.SetModel(glm::vec3(30.0, 6.0, 33.0) + ourVsmShadwDeltaPosition, 4.0);
	Cube ourVsmShadowCube2(ourDirShadowCubeTex, ourDirShadowCubeTex);
	ourVsmShadowCube2.SetModel(glm::vec3(37.0, 4.0, 23.0) + ourVsmShadwDeltaPosition, 4.0);
	Square ourVsmShadowSquare(ourDirShadowSquareTex, ourDirShadowSquareTex, 3);
	ourVsmShadowSquare.SetModel(glm::vec3(30.0, 0.0, 30.0) + ourVsmShadwDeltaPosition, 70.0);

	vector<Object>ourVsmShadowObjects;
	ourVsmShadowObjects.push_back(ourVsmShadowCube0);
	ourVsmShadowObjects.push_back(ourVsmShadowCube1);
	ourVsmShadowObjects.push_back(ourVsmShadowCube2);
	ourVsmShadowObjects.push_back(ourVsmShadowSquare);

	//Font
	Font ourFont;

	//PBR
	string HDRMap = "res/texture/IBL/christmas.hdr";
	PBR ourPBR(HDRMap);

	//GLFW渲染循环
	while (!glfwWindowShouldClose(window))
	{
		//输入
		processInput(window);

		//MSAA
		//glEnable(GL_MULTISAMPLE);

		//view projection
		glm::mat4 view = camera.ViewMatrix();
		glm::mat4 projection = glm::perspective(glm::radians(camera.Fov), (float)SCR_WIDTH / (float)SCR_HEIGHT, 0.1f, 1000.0f);

		//framebuffer
		glBindFramebuffer(GL_FRAMEBUFFER, FBO);
		glEnable(GL_DEPTH_TEST);
		glClearColor(0.1f, 0.0f, 0.0f, 1.0f);
		glClear(GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT| GL_DEPTH_BUFFER_BIT);
		glEnable(GL_CULL_FACE);
		glCullFace(GL_BACK);
		glFrontFace(GL_CCW);

		//skybox
		glDisable(GL_CULL_FACE);
		glDepthMask(GL_FALSE);
		skyboxShader.use();
		
		skyboxShader.setFloat("mip", 0.0);
		//skyboxShader.setFloat("mip", glm::sin((float)glfwGetTime()) * 2.0 + 2.0);
		
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_CUBE_MAP, ourPBR.ibl.CubeMap());// cubemapTexture);
		skyboxShader.setInt("skybox", 0);
		
		glm::mat4 viewSky = glm::mat4(glm::mat3(view));
		skyboxShader.setMat4("view", glm::value_ptr(viewSky));
		skyboxShader.setMat4("projection", glm::value_ptr(projection));
		
		glDepthFunc(GL_LEQUAL);
		
		glBindVertexArray(skyVAO);
		glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_INT, 0);
		glDepthMask(GL_TRUE);
		glDepthFunc(GL_LESS);

		//dir shadowmap
		ourDirShadow.DrawShadowMap(ourDirShadowObjects);
		ourDirShadow.DrawObjects(ourDirShadowObjects, FBO, camera.Position, view, projection);

		//dot shadowmap
		ourDotShadow.DrawShadowMap(ourDotShadowObjects);
		ourDotShadow.DrawObjects(ourDotShadowObjects,FBO,camera.Position,view,projection);
	
		//spot shadowmap
		ourSpotShadow.DrawShadowMap(ourSpotShadowObjects);
		ourSpotShadow.DrawObjects(ourSpotShadowObjects, FBO, camera.Position, view, projection);

		//esm shadowmap
		ourEsmShadow.DrawShadowMap(ourEsmShadowObjects);
		ourEsmShadow.DrawExpMap();
		ourEsmShadow.DrawGaussMaps();
		ourEsmShadow.DrawObjects(ourEsmShadowObjects, FBO, camera.Position, view, projection);

		//msm shadowmap
		ourMsmShadow.DrawShadowMap(ourMsmShadowObjects);
		ourMsmShadow.DrawMomentMaps();
		ourMsmShadow.DrawObjects(ourMsmShadowObjects, FBO, camera.Position, view, projection);

		//vsm shadowmap
		ourVsmShadow.DrawMaps(ourVsmShadowObjects,32);
		ourVsmShadow.DrawObjects(ourVsmShadowObjects, FBO, camera.Position, view, projection);

		//Pcss shadowmap
		ourPcssShadow.DrawShadowMap(ourPcssShadowObjects);
		ourPcssShadow.DrawObjects(ourPcssShadowObjects, FBO, camera.Position, view, projection);

		//vssm shadowmap
		ourVssmShadow.DrawMaps(ourVssmShadowObjects);
		ourVssmShadow.DrawObjects(ourVssmShadowObjects, FBO, camera.Position, view, projection);

		//time
		float currentTime = (float)glfwGetTime();
		deltaTime = currentTime - lastTime;
		lastTime = currentTime;
		ourFPS.Update();

		//Font: 放在最后，以便混合
		std::stringstream ss;
		ss << "FPS:" << ourFPS.GetFps();
		ourFont.RenderText(ss.str().substr(0,9), 10.0f, 550.0f, 0.8f, glm::vec3(0.0, 0.5, 0.0));

		//后处理
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
		glDisable(GL_DEPTH_TEST);
		glDisable(GL_STENCIL_TEST);
		glDisable(GL_BLEND);
		glClearColor(0.0f, 0.0f, 0.1f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);
		glViewport(0, 0, SCR_WIDTH, SCR_HEIGHT);

		frameShader.use();

		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, texColorBuffer);// ourBloom.bloomColorBuffer);
		frameShader.setInt("texColorBuffer", 0);

		frameShader.setFloat("exposure", 1.0f);
		glBindVertexArray(frameVAO);
		glDrawArrays(GL_TRIANGLES, 0, 6);

		//事件检查、缓冲交换
		glfwSwapBuffers(window);
		glfwPollEvents();
	}

	glDeleteVertexArrays(1, &frameVAO);
	glDeleteBuffers(1, &VBO);
	//释放资源
	glfwTerminate();
	return 0;
}

void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
	glViewport(0, 0, width, height);
}

void processInput(GLFWwindow* window)
{
	if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
		glfwSetWindowShouldClose(window, true);

	if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
		camera.PositionMove(FORWARD, deltaTime);
	if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
		camera.PositionMove(BACKWARD, deltaTime);
	if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
		camera.PositionMove(LEFT, deltaTime);
	if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
		camera.PositionMove(RIGHT, deltaTime);
	if (glfwGetKey(window, GLFW_KEY_SPACE) == GLFW_PRESS)
		camera.PositionMove(UP, deltaTime);
	if (glfwGetKey(window, GLFW_KEY_LEFT_ALT) == GLFW_PRESS)
		camera.PositionMove(DOWN, deltaTime);
}

void mouse_callback(GLFWwindow* window, double xpos, double ypos)
{
	if (firstMouse)
	{
		lastX = xpos;
		lastY = ypos;
		firstMouse = false;
	}
	double xoffset = xpos - lastX;
	double yoffset = lastY - ypos;
	lastX = xpos;
	lastY = ypos;

	camera.ViewMove(xoffset, yoffset);
}

void scroll_callback(GLFWwindow* window, double xoffset, double yoffset)
{
	camera.FovMove(yoffset);
}	