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
  scale(0.7f, 0.7f);
  strokeWeight(4.5f);
  drawLayer();
  popMatrix();
  
  fill(0);
  stroke(0);
  strokeWeight(3);
  circle(0, 0, 10);
  for (int i = 0; i < 5; i++)
  {
    line(0, 0, 0, 50);
    circle(0, 50, 10);
    rotate(radians(36));
    line(0, 0, 0, 30);
    rotate(radians(36));
  }
    
  save("out.png");
}

void drawPetal()
{
  float ri = 70;
  float ro = 200;
  float rmy = 180;
  float raw = 100;
  float rav = (ri + ro) / 2;
  float rix = ri * sin(radians(36));
  float riy = ri * cos(radians(36));
  beginShape();
  vertex(-rix, riy);
  quadraticVertex(-raw, rav, -rix, ro);
  vertex(0, rmy);
  vertex(rix, ro);
  quadraticVertex(raw, rav, rix, riy);
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
