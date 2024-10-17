// INTE4A by hpgbproductions
// This is an educational tool that performs discrete integration over a domain.
// It can be used to check approximate answers.

// BEGIN integration settings
// The bounds is the area that is observed.
// The domain is defined with equations.
// Only the volume that is within BOTH the bounds and domain will be considered for integration.

// Domain and integration settings for x
float xBoundsStart = -1;
float xBoundsEnd = 1;
float xDomainStart(float y)
{
  return -1;
}
float xDomainEnd(float y)
{
  return 1;
}
int xResolution = 5000;

// Domain and integration settings for y
float yBoundsStart = -1;
float yBoundsEnd = 1;
float yDomainStart(float x)
{
  return 0;
}
float yDomainEnd(float x)
{
  return sqrt(1 - x*x);
}
int yResolution = 5000;

float ScaleMaxValue = 5;
float ScaleMidValue = 0;
float ScaleMinValue = -5;

// Function z = f(x,y)
float f(float x, float y)
{
  return 5 - sqrt(1 + x*x + y*y);
}

// Known form of the result of integration, where each answer value is an integer
// CAUTION: Answers are integers, and will be treated incorrectly if divided by another integer. Please divide with casts to floats.
int NumAnswerConstants = 2;
int AnswerMinValue = 1;
int AnswerMaxValue = 100;
float AnswerForm(int[] k)
{
  return (float)k[0] / k[1];
}

// END integration settings

int GraphStartX = 250;
int GraphStartY = 50;
int GraphSize = 500;

Boolean UpdateNeeded = true;

void setup()
{
  colorMode(HSB, 1.0);
  size(800, 600);
  background(0.75);
}

void draw()
{
  if (!UpdateNeeded)
  {
    return;
  }
  UpdateNeeded = false;
  
  fill(0.0);
  noStroke();
  rect(GraphStartX, GraphStartY, GraphSize, GraphSize);
  
  // Graph drawing indexes
  int xPixelsDrawn = -1;
  int yPixelsDrawn = -1;
  float xDrawInterval = xResolution / GraphSize;
  float yDrawInterval = yResolution / GraphSize;
  
  double dx = (xBoundsEnd - xBoundsStart) / xResolution;
  double dy = (yBoundsEnd - yBoundsStart) / yResolution;
  double IntegrationResult = 0;
  
  for (int yi = 0; yi < yResolution; yi++)
  {
    Boolean DrawGraphRow = false;
    int CurrentGraphY = floor(yi / yDrawInterval);
    if (CurrentGraphY > yPixelsDrawn)
    {
      DrawGraphRow = true;
      yPixelsDrawn = CurrentGraphY;
    }
    int CurrentWindowY = GraphStartY + GraphSize - 1 - CurrentGraphY;
    
    for (int xi = 0; xi < xResolution; xi++)
    {
      Boolean DrawPoint = false;
      int CurrentGraphX = floor(xi / xDrawInterval);
      if (DrawGraphRow && CurrentGraphX > xPixelsDrawn)
      {
        DrawPoint = true;
      }
      xPixelsDrawn = CurrentGraphX;
      int CurrentWindowX = GraphStartX + CurrentGraphX;
      
      float x = xBoundsStart + (xBoundsEnd - xBoundsStart) * xi / xResolution;
      float y = yBoundsStart + (yBoundsEnd - yBoundsStart) * yi / yResolution;
      Boolean IsInDomain = xDomainStart(y) <= x && x <= xDomainEnd(y) && yDomainStart(x) <= y && y <= yDomainEnd(x);
      
      if (IsInDomain)
      {
        float z = f(x, y);
        IntegrationResult += z * dx * dy;
      
        if (DrawPoint)
        {
          float DrawHue = 0;
          if (z < ScaleMidValue)
          {
            float LerpAmount = constrain((z - ScaleMinValue) / (ScaleMidValue - ScaleMinValue), 0f, 1f);
            DrawHue = lerp(0.1667f, 0.0000f, LerpAmount);
          }
          else
          {
            float LerpAmount = constrain((z - ScaleMidValue) / (ScaleMaxValue - ScaleMidValue), 0f, 1f);
            DrawHue = lerp(1.0000f, 0.6667f, LerpAmount);
          }
          set(CurrentWindowX, CurrentWindowY, color(DrawHue, 1f, 1f));
        }
      }
    }
    
    xPixelsDrawn = -1;
  }
  
  // BEGIN answer bruteforce
  int ValuesPerAnswer = AnswerMaxValue - AnswerMinValue + 1;
  int answersSize = 1;
  int[] nextConstants = new int[NumAnswerConstants];
  int[] BestConstants = new int[NumAnswerConstants];
  
  for (int i = 0; i < NumAnswerConstants; i++)
  {
    nextConstants[i] = AnswerMinValue;
    BestConstants[i] = AnswerMinValue;
    answersSize *= ValuesPerAnswer;
  }
  
  float BestValue = AnswerForm(nextConstants);
  float BestAbsDiff = abs(BestValue - (float)IntegrationResult);
  
  float[] answers = new float[answersSize];
  
  for (int a = 1; a < answers.length; a++)
  {
    nextConstants[0] += 1;
    for (int ci = 0; ci < nextConstants.length - 1; ci++)
    {
      if (nextConstants[ci] > AnswerMaxValue)
      {
        // Overflow carries to the next constant
        nextConstants[ci] = AnswerMinValue;
        nextConstants[ci + 1] += 1;
      }
    }
    
    float value = AnswerForm(nextConstants);
    float absDiff = abs(value - (float)IntegrationResult);
    if (Float.isNaN(BestAbsDiff) || absDiff < BestAbsDiff)
    {
      arrayCopy(nextConstants, BestConstants);
      BestValue = value;
      BestAbsDiff = absDiff;
    }
  }
  // END answer bruteforce
  
  fill(0, 0, 0);
  textSize(16);
  textAlign(CENTER, CENTER);
  text(xBoundsStart, GraphStartX, GraphStartY + GraphSize + 20);
  text(xBoundsEnd, GraphStartX + GraphSize, GraphStartY + GraphSize + 20);
  textAlign(RIGHT, CENTER);
  text(yBoundsStart, GraphStartX - 16, GraphStartY + GraphSize);
  text(yBoundsEnd, GraphStartX - 16, GraphStartY);
  
  int ResultWholeDigits = floor(log((float)IntegrationResult));
  int DisplayResultDecimals = constrain(7 - ResultWholeDigits, 0, 7);
  textAlign(LEFT, CENTER);
  text("Final result of integration:", 25, 100);
  text(nf((float)IntegrationResult, 0, DisplayResultDecimals), 25, 120);
  
  int FormWholeDigits = floor(log(BestValue));
  int DisplayFormDecimals = constrain(7 - FormWholeDigits, 0, 7);
  text("Form result:", 25, 160);
  text(nf(BestValue, 0, DisplayFormDecimals), 25, 180);
  for (int i = 0; i < NumAnswerConstants; i++)
  {
    text("[" + i + "] = " + BestConstants[i], 25, 200 + 20*i);
  }
}
