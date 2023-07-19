#ifndef PBR_H
#define PBR_H

#include "ibl.h"
#include "object.h"
#include<vector>
#include "light.h"
using std::vector;
using std::shared_ptr;

class PBR
{
public:
	PBR(string HDR);
	IBL ibl;
	Shader pbrDirectShader = Shader("res/shader/pbrDirectVertex.shader", "res/shader/pbrDirectFragment.shader");
	Shader pbrIBLShader = Shader("res/shader/pbrIBLVertex.shader", "res/shader/pbrIBLFragment.shader");
	Shader pbrDirectTexShader = Shader("res/shader/pbrDirectTexVertex.shader", "res/shader/pbrDirectTexFragment.shader");
	Shader pbrIBLTexShader = Shader("res/shader/pbrIBLTexVertex.shader", "res/shader/pbrIBLTexFragment.shader");

	void DrawPBR_IBL_Tex(Object object, vector<shared_ptr<Light>>lights, glm::vec3 viewPos, glm::mat4 model, glm::mat4 view, glm::mat4 projection);
	void DrawPBR_Direct_Tex(Object object, vector<shared_ptr<Light>>lights, glm::vec3 viewPos, glm::mat4 model, glm::mat4 view, glm::mat4 projection);;
	void DrawPBR_IBL(Object object, vector<shared_ptr<Light>>lights, glm::vec3 viewPos, glm::mat4 model, glm::mat4 view, glm::mat4 projection, glm::vec3 albedo, float ao, float metalness, float roughness);;
	void DrawPBR_Direct(Object object, vector<shared_ptr<Light>>lights, glm::vec3 viewPos, glm::mat4 model, glm::mat4 view, glm::mat4 projection, glm::vec3 albedo, float ao, float metalness, float roughness);

};

PBR::PBR(string HDR)
{
	ibl = IBL(HDR);
}

void PBR::DrawPBR_IBL_Tex(Object object,vector<shared_ptr<Light>>lights, glm::vec3 viewPos, glm::mat4 model, glm::mat4 view, glm::mat4 projection)
{
	pbrIBLTexShader.use();

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, object.PBR.albedoMap);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, object.PBR.normalMap);
	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, object.PBR.metalnessMap);
	glActiveTexture(GL_TEXTURE3);
	glBindTexture(GL_TEXTURE_2D, object.PBR.aoMap);
	glActiveTexture(GL_TEXTURE4);
	glBindTexture(GL_TEXTURE_2D, object.PBR.roughnessMap);
	pbrIBLTexShader.setInt("albedoMap", 0);
	pbrIBLTexShader.setInt("normalMap", 1);
	pbrIBLTexShader.setInt("metalnessMap", 2);
	pbrIBLTexShader.setInt("aoMap", 3);
	pbrIBLTexShader.setInt("roughnessMap", 4);

	glActiveTexture(GL_TEXTURE5);
	glBindTexture(GL_TEXTURE_CUBE_MAP, ibl.IrradianceMap());
	pbrIBLTexShader.setInt("irradianceMap", 5);
	glActiveTexture(GL_TEXTURE6);
	glBindTexture(GL_TEXTURE_CUBE_MAP, ibl.PrefilterMap());
	pbrIBLTexShader.setInt("prefilterMap", 6);
	glActiveTexture(GL_TEXTURE7);
	glBindTexture(GL_TEXTURE_2D, ibl.PrebrdfMap());
	pbrIBLTexShader.setInt("prebrdfMap", 7);

	glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS);

	pbrIBLTexShader.setVec3("viewPos", viewPos);

	for (unsigned int i = 0; i != lights.size(); i++)
	{
		LightInfo info;
		lights[i]->GetLightInfo(info);
		pbrIBLTexShader.setVec3(("lightPositions[" + std::to_string(i) + "]").c_str(), info.Position);
		pbrIBLTexShader.setVec3(("lightColors[" + std::to_string(i) + "]").c_str(), info.Intensity);
	}

	pbrIBLTexShader.setMat4("view", glm::value_ptr(view));
	pbrIBLTexShader.setMat4("projection", glm::value_ptr(projection));

	pbrIBLTexShader.setMat4("model", glm::value_ptr(model));

	glBindVertexArray(object.VAO);
	glDrawElements(GL_TRIANGLES, object.Count, GL_UNSIGNED_INT, 0);

	glBindVertexArray(0);
}

void PBR::DrawPBR_Direct(Object object, vector<shared_ptr<Light>>lights, glm::vec3 viewPos, glm::mat4 model, glm::mat4 view, glm::mat4 projection,glm::vec3 albedo,float ao,float metalness, float roughness)
{
	pbrDirectShader.use();

	pbrDirectShader.setVec3("albedo", albedo);
	pbrDirectShader.setFloat("ao", ao);
	pbrDirectShader.setFloat("metalness", metalness);
	pbrDirectShader.setFloat("roughness", roughness);

	pbrDirectShader.setVec3("viewPos", viewPos);

	for (unsigned int i = 0; i != lights.size(); i++)
	{
		LightInfo info;
		lights[i]->GetLightInfo(info);
		pbrDirectShader.setVec3(("lightPositions[" + std::to_string(i) + "]").c_str(), info.Position);
		pbrDirectShader.setVec3(("lightColors[" + std::to_string(i) + "]").c_str(), info.Intensity);
	}

	pbrDirectShader.setMat4("view", glm::value_ptr(view));
	pbrDirectShader.setMat4("projection", glm::value_ptr(projection));
	pbrDirectShader.setMat4("model", glm::value_ptr(model));

	glBindVertexArray(object.VAO);
	glDrawElements(GL_TRIANGLES, object.Count, GL_UNSIGNED_INT, 0);

	glBindVertexArray(0);
}

void PBR::DrawPBR_IBL(Object object, vector<shared_ptr<Light>>lights, glm::vec3 viewPos, glm::mat4 model, glm::mat4 view, glm::mat4 projection, glm::vec3 albedo, float ao, float metalness, float roughness)
{
	pbrIBLShader.use();

	pbrIBLShader.setVec3("albedo", albedo);
	pbrIBLShader.setFloat("ao", ao);
	pbrIBLShader.setFloat("metalness", metalness);
	pbrIBLShader.setFloat("roughness", roughness);

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_CUBE_MAP, ibl.IrradianceMap());
	pbrIBLShader.setInt("irradianceMap", 0);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_CUBE_MAP, ibl.PrefilterMap());
	pbrIBLShader.setInt("prefilterMap", 1);
	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, ibl.PrebrdfMap());
	pbrIBLShader.setInt("prebrdfMap", 2);
	glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS);

	pbrIBLShader.setVec3("viewPos", viewPos);

	for (unsigned int i = 0; i != lights.size(); i++)
	{
		LightInfo info;
		lights[i]->GetLightInfo(info);
		pbrIBLShader.setVec3(("lightPositions[" + std::to_string(i) + "]").c_str(), info.Position);
		pbrIBLShader.setVec3(("lightColors[" + std::to_string(i) + "]").c_str(), info.Intensity);
	}

	pbrIBLShader.setMat4("view", glm::value_ptr(view));
	pbrIBLShader.setMat4("projection", glm::value_ptr(projection));
	pbrIBLShader.setMat4("model", glm::value_ptr(model));

	glBindVertexArray(object.VAO);
	glDrawElements(GL_TRIANGLES, object.Count, GL_UNSIGNED_INT, 0);

	glBindVertexArray(0);
}

void PBR::DrawPBR_Direct_Tex(Object object, vector<shared_ptr<Light>>lights, glm::vec3 viewPos, glm::mat4 model, glm::mat4 view, glm::mat4 projection)
{
	pbrDirectTexShader.use();

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, object.PBR.albedoMap);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, object.PBR.normalMap);
	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, object.PBR.metalnessMap);
	glActiveTexture(GL_TEXTURE3);
	glBindTexture(GL_TEXTURE_2D, object.PBR.aoMap);
	glActiveTexture(GL_TEXTURE4);
	glBindTexture(GL_TEXTURE_2D, object.PBR.roughnessMap);
	pbrDirectTexShader.setInt("albedoMap", 0);
	pbrDirectTexShader.setInt("normalMap", 1);
	pbrDirectTexShader.setInt("metalnessMap", 2);
	pbrDirectTexShader.setInt("aoMap", 3);
	pbrDirectTexShader.setInt("roughnessMap", 4);

	pbrDirectTexShader.setVec3("viewPos", viewPos);

	for (unsigned int i = 0; i != lights.size(); i++)
	{
		LightInfo info;
		lights[i]->GetLightInfo(info);
		pbrDirectTexShader.setVec3(("lightPositions[" + std::to_string(i) + "]").c_str(), info.Position);
		pbrDirectTexShader.setVec3(("lightColors[" + std::to_string(i) + "]").c_str(), info.Intensity);
	}

	pbrDirectTexShader.setMat4("view", glm::value_ptr(view));
	pbrDirectTexShader.setMat4("projection", glm::value_ptr(projection));
	pbrDirectTexShader.setMat4("model", glm::value_ptr(model));

	glBindVertexArray(object.VAO);
	glDrawElements(GL_TRIANGLES, object.Count, GL_UNSIGNED_INT, 0);

	glBindVertexArray(0);
}

#endif 
