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
  for (int i = 0; i < 3; i++)
  {
    fill(255);
    stroke(0);
    strokeWeight(3);
    
    float petalLength = 240 - (i * 48);
    float petalWidth = 60 - (i * 6);
    
    // lower petal
    for (int j = 0; j < 12; j++)
    {
      beginShape();
      vertex(0, 0);
      quadraticVertex(-petalWidth, petalLength, 0, petalLength);
      quadraticVertex(petalWidth, petalLength, 0, 0);
      endShape();
      rotate(radians(30));
    }
    rotate(radians(15));
    
    // upper petal
    for (int j = 0; j < 12; j++)
    {
      beginShape();
      vertex(0, 0);
      quadraticVertex(-petalWidth, petalLength, 0, petalLength);
      quadraticVertex(petalWidth, petalLength, 0, 0);
      endShape();
      rotate(radians(30));
    }
    rotate(radians(7.5f));
  }
  
  circle(0, 0, 80);
  save("out.png");
}
