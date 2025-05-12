    #version 330
    
    in vec2 fragTexCoord;
    in vec4 fragColor;
    
    uniform sampler2D texture0;
    uniform vec4 colDiffuse;
    
    uniform float bloomIntensity;
    uniform float bloomThreshold;
    
    out vec4 finalColor;
    
    void main() {
        vec4 color = texture(texture0, fragTexCoord) * colDiffuse * fragColor;
        
        // Extract bright areas
        float brightness = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
        
        // Apply bloom threshold
        if (brightness > bloomThreshold) {
            // Bloom effect
            vec4 bloomColor = color * bloomIntensity * 0.1;
            finalColor = vec4(color.rgb + bloomColor.rgb, color.a);
        } else {
            finalColor = color;
        }
    }
