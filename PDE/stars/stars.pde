Boolean drawn = false;

void setup()
{
  size(1920, 1080);
  background(0);
}

void draw()
{
  if (drawn)
  {
    return;
  }
  drawn = true;
  
  fill(255);
  noStroke();
  
  for (int i = 0; i < 300; i++)
  {
    float px = random(width);
    float py = random(height);
    float size = random(1f, 4f);
    
    beginShape();
    vertex(px, py-size);
    vertex(px+size, py);
    vertex(px, py+size);
    vertex(px-size, py);
    endShape();
  }
  
  save("out.png");
}
