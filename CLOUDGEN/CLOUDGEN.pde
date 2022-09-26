// Test cloud generator
// by hpgbproductions

int seed;
float noiseScale = 0.01f;

float upScale = 200f;
float downScale = 30f;

int upLod = 4;
int downLod = 4;
float upFalloff = 0.5f;
float downFalloff = 0.5f;
float upSinkFactor = 0.2f;
float downSinkFactor = 0.4f;

float upPerlinStartX;
float upPerlinStartY;
float downPerlinStartX;
float downPerlinStartY;

float startX = 0f;
float startY = 360f;
float intervalX = 10f;
float intervalY = 10f;

float upMinParticleSize = 10f;
float upMaxParticleSize = 40f;
float downMinParticleSize = 7f;
float downMaxParticleSize = 10f;

Boolean goNext = true;

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
  
  background(128, 192, 255);
  
  upPerlinStartX = random(-9999f, 9999f);
  upPerlinStartY = random(-9999f, 9999f);
  downPerlinStartX = random(-9999f, 9999f);
  downPerlinStartY = random(-9999f, 9999f);
  
  noStroke();
  fill(255, 255, 255);
  
  for (float x = startX; x < width + upMaxParticleSize; x += intervalX)
  {
    noiseDetail(upLod, upFalloff);
    float minY = startY - upScale * (noise(upPerlinStartX + x * noiseScale, upPerlinStartY) - upSinkFactor);
    noiseDetail(downLod, downFalloff);
    float maxY = startY + downScale * (noise(downPerlinStartX + x * noiseScale, downPerlinStartY) - downSinkFactor);
    
    for (float y = startY; y > minY; y -= intervalY)
    {
      circle(x, y, random(upMinParticleSize, upMaxParticleSize));
    }
    
    for (float y = startY; y < maxY; y += intervalY)
    {
      circle(x, y, random(upMinParticleSize, upMaxParticleSize));
    }
  }
  
  strokeWeight(1);
  stroke(255, 0, 0);
  line(startX, startY, width, startY);
  line(startX, startY - (upScale * (1 - upSinkFactor)), width, startY - (upScale * (1 - upSinkFactor)));
  line(startX, startY + (downScale * (1 - downSinkFactor)), width, startY + (downScale * (1 - downSinkFactor)));
  
  fill(0);
  textAlign(LEFT, TOP);
  text("hpgbproductions test cloud generator - press enter/return to reload", 0, 0);
}

void keyPressed()
{
  if (key == ENTER || key == RETURN)
    {
      goNext = true;
    }
}
