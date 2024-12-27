Boolean drawn = false;

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
  
  // layer
  for (int i = 0; i < 1; i++)
  {
    fill(255);
    stroke(0);
    strokeWeight(3);
    
    float petalLength = 140;
    float petalWidth = 50;
    
    // lower petal
    for (int j = 0; j < 8; j++)
    {
      beginShape();
      vertex(0, 0);
      quadraticVertex(-petalWidth, petalLength, 0, petalLength);
      quadraticVertex(petalWidth, petalLength, 0, 0);
      endShape();
      rotate(radians(45));
    }
    rotate(radians(22.5));
    
    // upper petal
    for (int j = 0; j < 8; j++)
    {
      beginShape();
      vertex(0, 0);
      quadraticVertex(-petalWidth, petalLength, 0, petalLength);
      quadraticVertex(petalWidth, petalLength, 0, 0);
      endShape();
      rotate(radians(45));
    }
    rotate(radians(11.25));
  }
  
  circle(0, 0, 80);
  save("out.png");
}
