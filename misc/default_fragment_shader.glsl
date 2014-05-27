#version 130
smooth in vec4 diffuseColor;
smooth in vec4 vertexNormal;
smooth in vec4 cameraSpacePosition;
//smooth in vec4 realPosition;

out vec4 outputColor;

uniform mat4 perspectiveMatrix;
uniform vec3 lightPos;
uniform vec3 lightColor;
//uniform int lightType;
//uniform vec3 lightFaceDir;
uniform float lightAttenuation;
uniform vec4 specularColor;
uniform float roughnessValue;
uniform float refIndex;

void main() {
    
    vec4 lightDifference = vec4(lightPos, 1) - cameraSpacePosition;
    
    vec4 lightDirection = lightDifference * inversesqrt(dot(lightDifference, lightDifference));
    
    vec4 attenIntensity = (1/(1.0+lightAttenuation*sqrt(dot(lightDifference, lightDifference)))) * vec4(lightColor,1);
    
    //if (lightType == 1) {
    //    float n = clamp(dot(realPosition.xyz,lightFaceDir), 0, 1);
    //    attenIntensity *= n;
    //}
    
    
    vec3 viewer = vec3(normalize(-cameraSpacePosition));
    vec3 halfVector = normalize(vec3(lightDirection) + viewer);
    float NdotL = clamp(dot(vertexNormal, lightDirection), 0, 1);
    float NdotH = clamp(dot(vec3(vertexNormal), halfVector), 0, 1);
    float NdotV = clamp(dot(vec3(vertexNormal), viewer), 0, 1);
    float VdotH = clamp(dot(viewer, halfVector), 0, 1);
    float r_sq = roughnessValue * roughnessValue;
    float beckmannConstant = 4.0;
    
    float geoNumerator = 2.0f * NdotH;
    float geoDenominator = VdotH;
    float geoB = (geoNumerator * NdotV) / geoDenominator;
    float geoC = (geoNumerator * NdotL) / geoDenominator;
    float geo = min(1.0f, min(geoB, geoC));
    
    float roughnessA = 1.0f / (beckmannConstant * r_sq * pow(NdotH, beckmannConstant));
    float roughnessB = NdotH * NdotH - 1.0f;
    float roughnessC = r_sq * NdotH * NdotH;
    float roughness = roughnessA * exp(roughnessB / roughnessC);
    
    float fresnel = pow(1.0f - VdotH, 5.0f);
    fresnel = fresnel * (1.0f - refIndex);
    fresnel = fresnel + refIndex;
    
    float Rs = (fresnel * geo * roughness) / (NdotV * NdotL);
    
    float cai = clamp(dot(vertexNormal, lightDirection), 0, 1);
                        
    outputColor = cai * (specularColor * attenIntensity * Rs + diffuseColor * attenIntensity);
    
}
