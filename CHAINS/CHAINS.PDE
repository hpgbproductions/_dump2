// The worst static chain simulator to ever exist
// by hpgbproductions

class ChainPoint
{
  public PVector position;
  public PVector velocity;
  public Boolean isFixed;
  
  public ChainPoint(float x, float y, Boolean isFixedPoint)
  {
    position = new PVector(x, y);
    velocity = new PVector(0, 0);
    isFixed = isFixedPoint;
  }
}

ArrayList<ChainPoint> Points = new ArrayList<ChainPoint>();

// Physics settings
float unitLength = 1000f;
float segmentLength = 0.064f;
float gravity = -9.81f;
float tensionResistance = 100000f;
float tensionResistanceLimit = 100000f;
float compressionResistance = 100000f;
float compressionResistanceLimit = 100000f;
float drag = 100f;

// Settings
int fps = 60;
int updatesPerFrame = 10000;
float timeScale = 1f;

// Calculation
float deltaTime;
float runTime = 0;

void setup()
{
  size(1000, 1000);
  frameRate(fps);
  
  deltaTime = timeScale / fps / updatesPerFrame;
  
  // Define points
  Points.add(new ChainPoint(0.0f, -0.0f, true));
  Points.add(new ChainPoint(0.2f, -0.1f, false));
  Points.add(new ChainPoint(0.3f, -0.1f, false));
  Points.add(new ChainPoint(0.4f, -0.1f, false));
  Points.add(new ChainPoint(0.23375f, -0.15875f, true));
}

void draw()
{
  // Perform frame updates
  for (int u = 0; u < updatesPerFrame; u++)
  {
    for (int i = 0; i < Points.size(); i++)
    {
      if (Points.get(i).isFixed)
      {
        // Its velocity cannot be changed
        continue;
      }
      
      // Initialize accel with gravity
      PVector accel = new PVector(0, gravity);
      
      if (i > 0)
      {
        // Check distance from previous point
        PVector previousPointRelativePosition = PVector.sub(Points.get(i - 1).position, Points.get(i).position);
        PVector previousPointNormalized = previousPointRelativePosition.copy().normalize();
        float previousPointDistance = previousPointRelativePosition.mag();
        
        if (previousPointDistance > segmentLength)
        {
          // Apply tension force to current point
          float distanceError = previousPointDistance - segmentLength;
          accel.add(PVector.mult(previousPointNormalized, distanceError * tensionResistance / 2).limit(tensionResistanceLimit));
        }
        else
        {
          // Apply compression force to current point
          float distanceError = previousPointDistance - segmentLength;
          accel.add(PVector.mult(previousPointNormalized, distanceError * compressionResistance / 2).limit(compressionResistanceLimit));
        }
      }
      
      if (i < Points.size() - 1)
      {
        // Check distance from next point
        PVector nextPointRelativePosition = PVector.sub(Points.get(i + 1).position, Points.get(i).position);
        PVector nextPointNormalized = nextPointRelativePosition.copy().normalize();
        float nextPointDistance = nextPointRelativePosition.mag();
        
        if (nextPointDistance > segmentLength)
        {
          // Apply tension force to current point
          float distanceError = nextPointDistance - segmentLength;
          accel.add(PVector.mult(nextPointNormalized, distanceError * tensionResistance / 2).limit(tensionResistanceLimit));
        }
        else
        {
          // Apply compression force to current point
          float distanceError = nextPointDistance - segmentLength;
          accel.add(PVector.mult(nextPointNormalized, distanceError * compressionResistance / 2).limit(compressionResistanceLimit));
        }
      }
      
      // Apply drag
      float speed = Points.get(i).velocity.mag();
      PVector normalizedVelocity = Points.get(i).velocity.copy().normalize();
      accel.add(PVector.mult(normalizedVelocity, speed * speed * -drag));
      
      // Modify the velocity of the current point
      Points.get(i).velocity.add(PVector.mult(accel, deltaTime));
    }
    
    for (ChainPoint p : Points)
    {
      if (p.isFixed)
      {
        // Its velocity cannot be changed
        continue;
      }
      
      // Update the position using the velocity
      p.position.add(PVector.mult(p.velocity, deltaTime));
    }
  }
  
  background(255);
  fill(255, 0, 0);
  stroke(0);
  strokeWeight(1);
  
  // Draw points
  for (int i = 0; i < Points.size() - 1; i++)
  {
    line(
      Points.get(i).position.x * unitLength,
      Points.get(i).position.y * -unitLength,
      Points.get(i + 1).position.x * unitLength,
      Points.get(i + 1).position.y * -unitLength);
  }
  
  runTime += deltaTime * updatesPerFrame;
  textAlign(LEFT, TOP);
  text("P to print ChainPoints data...", 0, 0);
  text(runTime, 0, 12);
}

void keyPressed()
{
  if (key == 'p' || key == 'P')
  {
    println("i\tx\ty");
    for (int i = 0; i < Points.size(); i++)
    {
      println(i + "\t" + Points.get(i).position.x + "\t" + Points.get(i).position.y);
    }
  }
}
