#version 330
in vec2 fragTexCoord;
in vec4 fragColor;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
out vec4 finalColor;
uniform vec2 size;
const float samples = 9.5;
const float quality = 2.5;

uniform float renderWidth = 1920;
uniform float renderHeight = 1080;
const float pixelWidth = 5.;
const float pixelHeight = 5.;
void main() {
    float dx = pixelWidth / renderWidth;
    float dy = pixelHeight / renderHeight;
    vec2 pixelCoord = vec2(dx * floor(fragTexCoord.x / dx), dy * floor(fragTexCoord.y / dy));

    vec4 sum = vec4(0);
    vec2 sizeFactor = vec2(1) / size * quality;
    vec4 source = texture(texture0, pixelCoord);

    const int range = 2;
    for(int x = -range; x <= range; x++) {
        for(int y = -range; y <= range; y++) {
            vec2 sampleCoord = pixelCoord + vec2(x, y) * sizeFactor;
            float sampleDx = pixelWidth * (1.0 / renderWidth);
            float sampleDy = pixelHeight * (1.0 / renderHeight);
            vec2 pixelatedSampleCoord = vec2(sampleDx * floor(sampleCoord.x / sampleDx), sampleDy * floor(sampleCoord.y / sampleDy));
            sum += texture(texture0, pixelatedSampleCoord);
        }
    }

    finalColor = ((sum / (samples * samples)) + source) * colDiffuse;
}