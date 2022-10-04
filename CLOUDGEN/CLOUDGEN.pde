/*
    Test cloud generator (release 6)
    by hpgbproductions
    
    * About 15m per pixel
    * Use finer generation for lower clouds
    * The cloudType will be controlled by another Perlin Noise pattern in real application
*/

// Displays some height markings
Boolean ShowDebugLines = false;

// The amount to change the cloud generation mode with up/down arrows
float cloudTypeStep = 0.02f;

// Perlin Noise settings
int seed;
int noiseLod = 4;
float noiseFalloff = 0.5f;
float noiseScale = 0.003f;

// Multi-layer visualization
int Layers = 64;
int LayerColorStart = 0;
int LayerColorInterval = 4;
float depthNoiseScale = 0.003f;
int targetFps = 120;

// Cloud generation settings
float cloudType = 0.5f;
float randomOffsetX = 10f;
float randomOffsetY = 10f;
float startX = 0f;
float startY = 800f;
float intervalX = 20f;
float intervalY = 20f;
float intervalZ = 20f;

// Head clouds
float upScale = 400f;
float upLowerHalfScale = 5f;
float upUpperHalfScale = 1.5f;
float upMinParticleSize = 20f;
float upMaxParticleSize = 60f;

// Base clouds
float downScale = 250f;
float downMinParticleSize = 20f;
float downMaxParticleSize = 40f;

// Auto-generated values
float upStartY;
float upHeight;
float upSinkFactor;
float upGenerateThreshold;
float downHeight;
float downSinkFactor;
float perlinStartX;
float perlinStartY;
int layerGray;
Boolean ReloadNoise = true;

int layer = 0;
int circles = 0;
int start_ms = 0;

void setup()
{
  size(1920,900);
  
  seed = second() + minute() * 60 + hour() * 3600 + day() * 86400;
  noiseSeed(seed);
  randomSeed(seed);
  
  frameRate(targetFps);
  layer = 0;
  circles = 0;
  start_ms = millis();
}

void draw()
{
  if (layer >= Layers)
  {
    return;
  }
  else if (layer == 0)
  {
    background(128, 192, 255);
    layerGray = LayerColorStart;
  }
  
  // Change some values according to cloudType variable
  downHeight = map(constrain(cloudType, 0f, 0.5f), 0f, 0.5f, 3f * downScale, downScale);
  downSinkFactor = map(constrain(cloudType, 0f, 0.7f), 0f, 0.5f, 0.9f, 0.3f);
  upHeight = map(constrain(cloudType, 0.3f, 0.7f), 0.3f, 0.7f, 0.5f * upScale, upScale);
  upStartY = startY - upHeight;
  upSinkFactor = map(cloudType, 0f, 1f, 0.7f, 0.2f);
  upGenerateThreshold = map(cloudType, 0f, 1f, 1f, 0.3f);
  
  // Set a new random origin for the Perlin Noise
  if (ReloadNoise)
  {
    perlinStartX = random(-9999f, 9999f);
    perlinStartY = random(-9999f, 9999f);
    noiseDetail(noiseLod, noiseFalloff);
    ReloadNoise = false;
  }
  
  noStroke();
  fill(min(layerGray, 255));
  
  // BEGIN draw a layer
  for (float x = startX; x < width + downMaxParticleSize; x += intervalX)
  {
    float currentNoise = noise(perlinStartX + x * noiseScale, perlinStartY + layer * intervalZ * depthNoiseScale);
    
    float downMinY = startY - downHeight * (currentNoise - downSinkFactor);
    float upMinY = upStartY - upHeight * upUpperHalfScale * (pow(currentNoise, 1f) - upSinkFactor * 2);
    float upMaxY = min(downMinY, upStartY + upHeight * upLowerHalfScale * (pow(currentNoise, 2f) - upSinkFactor));
    
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
  
  // Set data of the next layer
  layer++;
  layerGray += LayerColorInterval;
  
  // The debug marking draws a small vertical bar according to the fill color
  rect(layerGray, height - 20, 1, 3);
  
  // Only draw the following after all layers are completed
  if (layer == Layers)
  {
    if (ShowDebugLines)
    {
      strokeWeight(1);
      
      stroke(255, 0, 0);
      line(0, startY, width, startY);
      line(0, startY - (downHeight * (1 - downSinkFactor)), width, startY - (downHeight * (1 - downSinkFactor)));
      
      stroke(0, 0, 255);
      line(0, upStartY, width, upStartY);
      line(0, upStartY - upHeight * upUpperHalfScale * (1 - upSinkFactor * 2), width, upStartY - upHeight * upUpperHalfScale * (1 - upSinkFactor * 2));
    }
    
    fill(0);
    textAlign(LEFT, TOP);
    text(
    "hpgbproductions test cloud generator\n" +
    "UP/DOWN ARROWS to change weather intensity (now " + nf(cloudType, 0, 3) + ")\n" +
    "ENTER/RETURN to create new patterns\n",
    2, 2);
    
    text(circles + " circles drawn in " + (millis() - start_ms) + "ms\n", 2, height - 15);
  }
}

void keyPressed()
{
  layer = 0;
  circles = 0;
  start_ms = millis();
  
  if (keyCode == ENTER || keyCode == RETURN)
    ReloadNoise = true;
  
  if (keyCode == UP)
    cloudType += cloudTypeStep;
  else if (keyCode == DOWN)
    cloudType -= cloudTypeStep;
    
  cloudType = constrain(cloudType, 0f, 1f);
}
