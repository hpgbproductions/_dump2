// Manhattan Distance Spiral Generator

int startX = 400;
int startY = 400;
int squareLength = 5;

int ctr = 0;
int colorStep = 2;
int direction = 0;
int distance = 1;

TwoInt[] GridValues = new TwoInt[100000];

void setup()
{
  size(800, 800);
  frameRate(60);
  
  GridValues[0] = new TwoInt(0, 0);
  ctr = 1;
  
  while (ctr < GridValues.length)
  {
    if (direction == 0)
    {
      // +Y direction to +X direction
      for (int i = 0; i < distance; i++)
      {
        GridValues[ctr] = new TwoInt(i, distance - i);
        ctr++;
        if (ctr == GridValues.length) break;
      }
      direction = 1;
    }
    else if (direction == 1)
    {
      // +X direction to -Y direction
      for (int i = 0; i < distance; i++)
      {
        GridValues[ctr] = new TwoInt(distance - i, -i);
        ctr++;
        if (ctr == GridValues.length) break;
      }
      direction = 2;
    }
    else if (direction == 2)
    {
      // -Y direction to -X direction
      for (int i = 0; i < distance; i++)
      {
        GridValues[ctr] = new TwoInt(-i, -distance + i);
        ctr++;
        if (ctr == GridValues.length) break;
      }
      direction = 3;
    }
    else if (direction == 3)
    {
      // -X to +Y direction
      for (int i = 0; i < distance; i++)
      {
        GridValues[ctr] = new TwoInt(-distance + i, i);
        ctr++;
        if (ctr == GridValues.length) break;
      }
      direction = 0;
      distance++;
    }
  }
  
  for (int i = 0; i < GridValues.length; i++)
  {
    fill((i * colorStep) % 256);
    rect(startX + GridValues[i].x * squareLength, startY + GridValues[i].y * squareLength, squareLength, squareLength);
  }
}

void draw()
{
  
}

class TwoInt
{
  public int x;
  public int y;
  
  public TwoInt(int x_new, int y_new)
  {
    x = x_new;
    y = y_new;
  }
}
