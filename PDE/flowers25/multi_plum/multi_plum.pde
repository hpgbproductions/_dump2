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
  strokeWeight(3);
  
  //drawLayer();
  scale(0.9f, 0.9f);
  drawLayer();
  popMatrix();
  
  fill(0);
  stroke(0);
  strokeWeight(3);
  for (int i = 0; i < 5; i++)
  {
    line(0, 0, 0, 50);
    circle(0, 50, 10);
    rotate(radians(36));
    line(0, 0, 0, 30);
    rotate(radians(36));
  }
  
  fill(255);
  circle(0, 0, 20);
    
  save("out_s.png");
}

void drawPetal()
{
  float ri = 60;
  float cx = 85;
  float cy = 125;
  
  float rix = ri * sin(radians(36));
  float riy = ri * cos(radians(36));
  
  beginShape();
  vertex(-rix, riy);
  bezierVertex(-cx, cy, cx, cy, rix, riy);
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
