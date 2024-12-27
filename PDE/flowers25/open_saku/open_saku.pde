Boolean drawn = false;

PShape outer;

void setup()
{
  size(512, 512);
  background(255);
}

void draw()
{
  if (drawn)
  {
    return;
  }
  drawn = true;
  
  translate(width/2, height/2);
  pushMatrix();
  
  fill(255);
  stroke(0);
  strokeWeight(3f);
  drawLayer();
  popMatrix();
    
  save("out.png");
}

void drawPetal()
{
  float iy = 15;
  float cx = 45;
  float cy = 60;
  float ex = 16;
  float ey = 100;
  float cuty = 90;
  
  beginShape();
  vertex(0, iy);
  quadraticVertex(-cx, cy, -ex, ey);
  vertex(0, cuty);
  vertex(ex, ey);
  quadraticVertex(cx, cy, 0, iy);
  endShape();
}

void drawLayer()
{
  for (int i = 0; i < 5; i++)
  {
    drawPetal();
    rotate(radians(72));
  }
}
