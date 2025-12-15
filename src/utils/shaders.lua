local shaders = {}

shaders.whiteout = love.graphics.newShader[[
  vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);
    return vec4(1, 1, 1, pixel.a);
  }
]]

shaders.light = love.graphics.newShader[[
  extern vec2 playerPosition;

  vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);
    float distance = length(screen_coords - playerPosition);
    float fade = clamp(distance/250, 0.15, 1.0);

    pixel.a = pixel.a * fade;
    
    return pixel * color;
  }
]]

shaders.multiLight = love.graphics.newShader[[
  extern vec3 lightPositions[16]; // x, y, radius
  extern int numLights;

  vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);
    
    float totalLight = 0.0;
    
    for (int i = 0; i < numLights; i++) {
      vec2 lightPos = lightPositions[i].xy;
      float radius = lightPositions[i].z;
      
      float distance = length(screen_coords - lightPos);
      float fade = clamp(distance / radius, 0.0, 1.0);
      
      float lightAmount = 1.0 - fade;
      totalLight += lightAmount;
    }
    
    totalLight = clamp(totalLight, 0.0, 0.5);
    pixel.a = pixel.a * (1.0 - totalLight);
    
    return pixel * color;
  }
]]

return shaders