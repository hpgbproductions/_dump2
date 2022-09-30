// Test cloud generator
// by hpgbproductions

// Whether to show the reference lines for cloud scale
Boolean ShowDebugLines = true;

// Perlin Noise settings
int seed;
int noiseLod = 4;
float noiseFalloff = 0.5f;
float noiseScale = 0.006f;

// Multi-layer visualization
int Layers = 256;
int LayerColorStart = 0;
int LayerColorInterval = 1;
float depthNoiseScale = 0.002f;

// Cloud generation settings
float cloudType = 0.7f;
float randomOffsetX = 10f;
float randomOffsetY = 10f;
float startX = 0f;
float startY = 800f;
float intervalX = 20f;
float intervalY = 20f;
float intervalZ = 20f;

// Head clouds
float upScale = 400f;
float upLowerHalfScale = 4f;
float upMinParticleSize = 20f;
float upMaxParticleSize = 40f;

// Base clouds
float downScale = 200f;
float downMinParticleSize = 20f;
float downMaxParticleSize = 40f;

// Auto-generated values
float upStartY;
float upSinkFactor = 0.1f;
float upGenerateThreshold = 0.1f;
float downSinkFactor;
float perlinStartX;
float perlinStartY;
int layerGray;

Boolean goNext = true;
Boolean drawLoading = true;
int circles = 0;
int start_ms = 0;

void setup()
{
  size(1920,900);
  
  seed = second() + minute() * 60 + hour() * 3600 + day() * 86400;
  noiseSeed(seed);
  randomSeed(seed);
  
  // Change some values according to cloudType variable
  downScale = map(constrain(cloudType, 0f, 0.5f), 0f, 0.5f, 0.75f * downScale, downScale);
  downSinkFactor = map(constrain(cloudType, 0f, 0.5f), 0f, 0.5f, 0.9f, 0f);
  upScale = map(constrain(cloudType, 0.4f, 0.8f), 0.4f, 0.8f, 0, upScale);
  upStartY = startY - upScale;
  upSinkFactor = map(cloudType, 0f, 1f, 0.8f, 0f);
  upGenerateThreshold = map(cloudType, 0f, 1f, 0.8f, 0f);
}

void draw()
{
  if (drawLoading)
  {
    background(128, 192, 255);
    fill(0);
    textAlign(LEFT, TOP);
    text("hpgbproductions test cloud generator - loading...", 0, 0);
    drawLoading = false;
    return;
  }
  
  if (!goNext)
  {
    return;
  }
  goNext = false;
  circles = 0;
  start_ms = millis();
  
  background(128, 192, 255);
  
  perlinStartX = random(-9999f, 9999f);
  perlinStartY = random(-9999f, 9999f);
  noiseDetail(noiseLod, noiseFalloff);
  
  noStroke();
  layerGray = LayerColorStart;
  
  for (int layer = 0; layer < Layers; layer++)
  {
    fill(min(layerGray, 255));
    
    // BEGIN draw a layer
    for (float x = startX; x < width + downMaxParticleSize; x += intervalX)
    {
      float currentNoise = noise(perlinStartX + x * noiseScale, perlinStartY + layer * intervalZ * depthNoiseScale);
      
      float downMinY = startY - downScale * (currentNoise - downSinkFactor);
      float upMinY = upStartY - upScale * (currentNoise - upSinkFactor * 2);
      float upMaxY = min(downMinY, upStartY + upScale * upLowerHalfScale * (pow(currentNoise, 2f) - upSinkFactor));
      
      // Lower particles
      for (float y = startY; y > downMinY; y -= intervalY)
      {
        circle(
        x + random(-randomOffsetX, randomOffsetX),
        y + random(-randomOffsetY, randomOffsetY),
        random(downMinParticleSize, downMaxParticleSize)
        );
        circles++;
      }
      
      // Only produce upper particles if lower clouds are high enough
      if (currentNoise < upGenerateThreshold)
      {
        continue;
      }
      
      // Upper particles
      for (float y = upMinY; y < upMaxY; y += intervalY)
      {
        circle(
        x + random(-randomOffsetX, randomOffsetX),
        y + random(-randomOffsetY, randomOffsetY),
        random(upMinParticleSize, upMaxParticleSize)
        );
        circles++;
      }
      
    }
    // END draw a layer
    
    // Set the color of the next layer
    layerGray += LayerColorInterval;
  }
  
  if (ShowDebugLines)
  {
    strokeWeight(1);
    
    stroke(255, 0, 0);
    line(0, startY, width, startY);
    line(0, startY - (downScale * (1 - downSinkFactor)), width, startY - (downScale * (1 - downSinkFactor)));
    
    stroke(0, 0, 255);
    line(0, upStartY, width, upStartY);
  }
  
  fill(0);
  textAlign(LEFT, TOP);
  text(
  "hpgbproductions test cloud generator - press enter/return to reload\n" +
  circles + " circles drawn in " + (millis() - start_ms) + "ms",
  0, 0);
}

void keyPressed()
{
  if (key == ENTER || key == RETURN)
  {
    drawLoading = true;
    goNext = true;
  }
}
