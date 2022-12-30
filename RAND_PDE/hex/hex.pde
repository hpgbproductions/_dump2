void setup()
{
  size(1000, 1000);
  background(255);
}

void draw()
{
  translate(500, 500);
  
  stroke(0);
  strokeWeight(10);
  
  drawHexagon(0, 0, 150);
  drawHexagon(260 * cos(radians(30)), 260 * sin(radians(30)), 150);
  drawHexagon(260 * cos(radians(90)), 260 * sin(radians(90)), 150);
  drawHexagon(260 * cos(radians(150)), 260 * sin(radians(150)), 150);
  drawHexagon(260 * cos(radians(210)), 260 * sin(radians(210)), 150);
  drawHexagon(260 * cos(radians(270)), 260 * sin(radians(270)), 150);
  drawHexagon(260 * cos(radians(330)), 260 * sin(radians(330)), 150);
}

void drawHexagon(float x, float y, float side_length)
{
  PVector Position01 = new PVector(side_length * cos(radians(0)), side_length * sin(radians(0)));
  PVector Position02 = new PVector(side_length * cos(radians(60)), side_length * sin(radians(60)));
  PVector Position03 = new PVector(side_length * cos(radians(120)), side_length * sin(radians(120)));
  PVector Position04 = new PVector(side_length * cos(radians(180)), side_length * sin(radians(180)));
  PVector Position05 = new PVector(side_length * cos(radians(240)), side_length * sin(radians(240)));
  PVector Position06 = new PVector(side_length * cos(radians(300)), side_length * sin(radians(300)));
  
  line(x + Position01.x, y + Position01.y, x + Position02.x, y + Position02.y);
  line(x + Position02.x, y + Position02.y, x + Position03.x, y + Position03.y);
  line(x + Position03.x, y + Position03.y, x + Position04.x, y + Position04.y);
  line(x + Position04.x, y + Position04.y, x + Position05.x, y + Position05.y);
  line(x + Position05.x, y + Position05.y, x + Position06.x, y + Position06.y);
  line(x + Position06.x, y + Position06.y, x + Position01.x, y + Position01.y);
}
