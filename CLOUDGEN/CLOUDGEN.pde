// Test cloud generator
// by hpgbproductions

Boolean ShowDebugLines = false;

int seed;
float noiseScale = 0.006f;

float upScale = 250f;
float downScale = 0f;

int upLod = 4;
int downLod = 4;
float upFalloff = 0.5f;
float downFalloff = 0.5f;
float upSinkFactor = 0.25f;
float downSinkFactor = 0f;

float perlinStartX;
float perlinStartY;

float startX = 0f;
float startY = 360f;
float intervalX = 10f;
float intervalY = 10f;

float upMinParticleSize = 15f;
float upMaxParticleSize = 40f;
float downMinParticleSize = 15f;
float downMaxParticleSize = 25f;

float randomOffsetX = 5f;
float randomOffsetY = 5f;

Boolean goNext = true;
int circles = 0;
int start_ms = 0;

void setup()
{
  size(1920,600);
  
  seed = second() + minute() * 60 + hour() * 3600 + day() * 86400;
  noiseSeed(seed);
  randomSeed(seed);
}

void draw()
{
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
  
  noStroke();
  fill(255, 255, 255);
  
  for (float x = startX; x < width + upMaxParticleSize; x += intervalX)
  {
    noiseDetail(upLod, upFalloff);
    float minY = startY - upScale * (noise(perlinStartX + x * noiseScale, perlinStartY) - upSinkFactor);
    noiseDetail(downLod, downFalloff);
    float maxY = startY + downScale * (noise(perlinStartX + x * noiseScale, perlinStartY) - downSinkFactor);
    
    // Particles above the centerline
    for (float y = startY; y > minY; y -= intervalY)
    {
      circle(
      x + random(-randomOffsetX, randomOffsetX),
      y + random(-randomOffsetY, randomOffsetY),
      random(upMinParticleSize, upMaxParticleSize)
      );
      circles++;
    }
    
    // Particles below the centerline
    for (float y = startY; y < maxY; y += intervalY)
    {
      circle(
      x + random(-randomOffsetX, randomOffsetX),
      y + random(-randomOffsetY, randomOffsetY),
      random(downMinParticleSize, downMaxParticleSize)
      );
      circles++;
    }
  }
  
  if (ShowDebugLines)
  {
    strokeWeight(1);
    stroke(255, 0, 0);
    line(startX, startY, width, startY);
    line(startX, startY - (upScale * (1 - upSinkFactor)), width, startY - (upScale * (1 - upSinkFactor)));
    line(startX, startY + (downScale * (1 - downSinkFactor)), width, startY + (downScale * (1 - downSinkFactor)));
  }
  
  fill(0);
  textAlign(LEFT, TOP);
  text(
  "hpgbproductions test cloud generator - press enter/return to reload\n"
  + circles + " circles drawn in " + (millis() - start_ms) + "ms",
  0, 0);
}

void keyPressed()
{
  if (key == ENTER || key == RETURN)
    {
      goNext = true;
    }
}
