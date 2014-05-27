#version 130
in vec3 position;
in vec3 color;
in vec3 normal;
//in vec3 normal;
//in vec3 color;
//in vec3 position;

smooth out vec4 diffuseColor;
smooth out vec4 vertexNormal;
smooth out vec4 cameraSpacePosition;
//smooth out vec4 realPosition;

uniform mat4 perspectiveMatrix;
uniform mat4 rotationMatrix;
uniform mat4 translationMatrix;

//uniform mat4 rawRotationMatrix;
//uniform mat4 rawTranslationMatrix;

void main() {
    mat4 fragmentMatrix = rotationMatrix * translationMatrix;
    cameraSpacePosition = vec4(position, 1) * fragmentMatrix;
    gl_Position = cameraSpacePosition * perspectiveMatrix;
    vertexNormal = normalize(vec4(normal, 1) * rotationMatrix);
    diffuseColor = vec4(color, 1);
    //realPosition = vec4(position,1) * rawRotationMatrix * rawTranslationMatrix;
}
