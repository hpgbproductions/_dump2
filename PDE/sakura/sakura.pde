// Flower shape tool

PGraphics f;
String outName = "sakura.png";
Boolean saved = false;

int petalCount = 5;
float angleStepDegrees = 72;

void setup()
{
  size(256, 256);
  f = createGraphics(width, height);
  
  f.beginDraw();
  f.translate(width / 2, height / 2);
  f.background(0);
  
  for (int p = 0; p < petalCount; p++)
  {
    // BEGIN define petal
    
    f.fill(255);
    f.noStroke();
    f.ellipse(0, -60, 50, 140);
    
    f.fill(0);
    f.noStroke();
    f.triangle(0, -100, -40, -150, 40, -150);
    
    // END define petal
    
    f.rotate(radians(angleStepDegrees));
  }
  
  f.endDraw();
  f.loadPixels();
  loadPixels();
  for (int i = 0; i < f.pixels.length; i++)
  {
    pixels[i] = f.pixels[i];
  }
  updatePixels();
  
  f.save(outName);
}
