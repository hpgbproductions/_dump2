// Gaussian/Normal Distribution settings
float stddev = 50;
float max_z = 3.5;

// Tree component settings (try color 255,224,224)
int maxParticles = 800;
color color0 = color(255, 224, 224);
color color1 = color(255, 208, 208);
float radius0 = 10;
float radius1 = 20;

// Other settings
Boolean drawGrid = false;
Boolean smoothing = false;

void setup()
{
  size(512, 512);
  background(192, 224, 255);
  
  translate(width / 2, height / 2);
  
  if (!smoothing)
    noSmooth();
  
  if (drawGrid)
    DrawGrid();
  
  noStroke();
  for (int p = 0; p < maxParticles; p++)
  {
    float randomOffsetAngle = random(2 * PI);
    float randomOffsetDistance = stddev * constrain(randomGaussian(), -max_z, max_z);
    
    fill(lerpColor(color0, color1, random(1)));
    
    pushMatrix();
    rotate(random(2 * PI));
    translate(randomOffsetDistance * sin(randomOffsetAngle), randomOffsetDistance * cos(randomOffsetAngle));
    ellipse(0, 0, random(radius0, radius1), random(radius0, radius1));
    popMatrix();
  }
}

void DrawGrid()
{
  // Middle lines
  strokeWeight(2);
  stroke(255, 0, 0);
  line(-width / 2, 0, width / 2, 0);
  line(0, -height / 2, 0, height/ 2);
  
  // Limiter lines
  noFill();
  circle(0, 0, max_z * stddev * 2);
  
  // Other lines
  strokeWeight(1);
  for (int i = -3; i < 4; i++)
  {
    circle(0, 0, i * stddev * 2);
  }
}
