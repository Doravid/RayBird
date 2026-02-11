#version 100
precision mediump float;

// Input vertex attributes (from vertex shader)
varying vec2 fragTexCoord;
varying vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Bloom settings
uniform vec2 size; 

// Constants are fine, but uniforms cannot have default values here
const float samples = 9.5;
const float quality = 2.5; 

// Pixelation settings
uniform float renderWidth;
uniform float renderHeight;
const float pixelWidth = 5.0;
const float pixelHeight = 5.0;

void main() {
    float dx = pixelWidth / renderWidth;
    float dy = pixelHeight / renderHeight;
    vec2 pixelCoord = vec2(dx * floor(fragTexCoord.x / dx), dy * floor(fragTexCoord.y / dy));

    vec4 sum = vec4(0.0);
    vec2 sizeFactor = vec2(1.0) / size * quality;

    vec4 source = texture2D(texture0, pixelCoord);
    const int range = 2;

    // Sample surrounding pixels
    for(int x = -range; x <= range; x++) {
        for(int y = -range; y <= range; y++) {
            // Apply pixelation to each bloom sample coordinate
            vec2 sampleCoord = pixelCoord + vec2(float(x), float(y)) * sizeFactor;

            // Re-pixelate the sample coordinates
            float sampleDx = pixelWidth * (1.0 / renderWidth);
            float sampleDy = pixelHeight * (1.0 / renderHeight);

            vec2 pixelatedSampleCoord = vec2(sampleDx * floor(sampleCoord.x / sampleDx), sampleDy * floor(sampleCoord.y / sampleDy));

            sum += texture2D(texture0, pixelatedSampleCoord);
        }
    }

    // Calculate final fragment color
    gl_FragColor = ((sum / (samples * samples)) + source) * colDiffuse;
}