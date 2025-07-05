#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

// NOTE: Add your custom variables here
// Bloom settings
const vec2 size = vec2(1920, 1080); // Framebuffer size
const float samples = 9.5; // Pixels per axis; higher = bigger glow, worse performance
const float quality = 2.5; // Defines size factor: Lower = smaller glow, better quality

// Pixelation settings
// NOTE: Render size values must be passed from code
const float renderWidth = 800;
const float renderHeight = 450;
uniform float pixelWidth = 2.5;
uniform float pixelHeight = 2.5;

void main() {
    // Step 1: Apply pixelation effect
    float dx = pixelWidth / renderWidth;
    float dy = pixelHeight / renderHeight;
    vec2 pixelCoord = vec2(dx * floor(fragTexCoord.x / dx), dy * floor(fragTexCoord.y / dy));

    // Step 2: Apply bloom effect to the pixelated coordinates
    vec4 sum = vec4(0);
    vec2 sizeFactor = vec2(1) / size * quality;

    // Get the pixelated source color
    vec4 source = texture(texture0, pixelCoord);

    const int range = 2; 

    // Sample surrounding pixels for bloom effect using pixelated coordinates
    for(int x = -range; x <= range; x++) {
        for(int y = -range; y <= range; y++) {
            // Apply pixelation to each bloom sample coordinate
            vec2 sampleCoord = pixelCoord + vec2(x, y) * sizeFactor;

            // Re-pixelate the sample coordinates to maintain pixel consistency
            float sampleDx = pixelWidth * (1.0 / renderWidth);
            float sampleDy = pixelHeight * (1.0 / renderHeight);
            vec2 pixelatedSampleCoord = vec2(sampleDx * floor(sampleCoord.x / sampleDx), sampleDy * floor(sampleCoord.y / sampleDy));

            sum += texture(texture0, pixelatedSampleCoord);
        }
    }

    // Calculate final fragment color
    finalColor = ((sum / (samples * samples)) + source) * colDiffuse;
}