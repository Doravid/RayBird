#version 330
// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;
// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;
// Output fragment color
out vec4 finalColor;

// Pixelation parameters
const float renderWidth = 1920;
const float renderHeight = 1080;
uniform float pixelWidth = 2.0;
uniform float pixelHeight = 2.0;

// Blur parameters
float offset[3] = float[](0.0, 1.3846153846, 3.2307692308);
float weight[3] = float[](0.2270270270, 0.3162162162, 0.0702702703);

void main() {
    // Step 1: Pixelate coordinates
    float dx = pixelWidth * (1.0 / renderWidth);
    float dy = pixelHeight * (1.0 / renderHeight);
    vec2 pixelCoord = vec2(dx * floor(fragTexCoord.x / dx), dy * floor(fragTexCoord.y / dy));

    // Step 2: Apply blur using the pixelated coordinates
    vec4 texelColor = texture(texture0, pixelCoord) * weight[0];

    for(int i = 1; i < 3; i++) {
        texelColor += texture(texture0, pixelCoord + vec2(offset[i]) / renderWidth, 0.0) * weight[i];
        texelColor += texture(texture0, pixelCoord - vec2(offset[i]) / renderWidth, 0.0) * weight[i];
    }

    finalColor = texelColor;
}