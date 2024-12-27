// "Hemp leaf" pattern generator

float slen = 400;
float weightHeavy = 20;
float weightLight = 10;

void setup()
{
  size(1000, 1000);
  background(255);
}

void draw()
{
  translate(500, 500);
  
  PVector point0 = new PVector(0f, 0f);
  PVector point1 = new PVector(slen * cos(radians(-30f)), slen * sin(radians(-30f)));
  PVector point2 = new PVector(slen * cos(radians(30f)), slen * sin(radians(30f)));
  PVector point3 = new PVector(slen * cos(radians(30f)) - (slen / 2f * sin(radians(30f) / sin(radians(60f)))), 0f);
  
  noFill();
  stroke(0);
  
  for (int i = 0; i < 6; i++)
  {
    strokeWeight(weightHeavy);
    drawLine(point0, point3);
    drawLine(point1, point3);
    drawLine(point2, point3);
    
    strokeWeight(weightLight);
    drawLine(point0, point1);
    drawLine(point1, point2);
    drawLine(point2, point0);
    
    rotate(radians(60f));
  }
}

void drawLine(PVector a, PVector b)
{
  line(a.x, a.y, b.x, b.y);
}
