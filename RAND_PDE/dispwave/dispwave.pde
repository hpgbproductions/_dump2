// 3D generation test "DISPWAVE"
// Note that the Y-axis points down, and the Z-axis points out of the screen.

float MAX_DEPTH = 10000;

// Pitch, Yaw, Roll rotation of wave object (radians) (0 < x < PI/2)
float ANGLE_ROTATE_X = PI/4;
float ANGLE_ROTATE_Y = 0;
float ANGLE_ROTATE_Z = 0;

float DEBUG_AXES_LENGTH = 100;
float DEBUG_AXES_WEIGHT = 5;
int DEBUG_TEXT_COLOR = 0xffffffff;

// Orthogonal depth buffer of the wave, pixel [x][y]
// PGraphics WaveDepthBuffer;

// Number of line objects, number of points per line
PVector[][] LinePoints = new PVector[100][150];

// First line
PVector LineStartPosition = new PVector(-2000, 0, -1500);

// Displacement to the next line
PVector LineStartPositionInterval = new PVector(20, 0, 0);

// Angle around the Y axis that the line will start moving towards (radians)
float InitialUpdateDirection = PI/6;

// Distance between points on line
float UpdateDistance = 40;

// Height of maximum Perlin Noise
float MaxHeight = 5;

// Tendency to move towards high areas
float Gravity = -500;

// How much a point is displaced when near points from other lines (UNUSED)
// float RepulsiveForce = 500;

// Number of neighboring lines to consider in each direction (UNUSED)
// int RepulsionNeighbors = 10;

int BgColor = 0xff25384d;
int LineColor = 0xff344b63;
float LineStrokeWeight = 4;

float NoiseOffsetX;
float NoiseOffsetY;
float NoiseOffsetZ;
float NoiseScale = 0.005;

void setup()
{
  size(1000, 1000, P3D);
  // WaveDepthBuffer = createGraphics(width, height, P3D);
  // WaveDepthBuffer.colorMode(RGB, MAX_DEPTH);
  
  noiseDetail(1, 0.5);
  NoiseOffsetX = random(-1000.0, 1000.0);
  NoiseOffsetY = random(-1000.0, 1000.0);
  NoiseOffsetZ = random(-1000.0, 1000.0);
  
  textSize(100);
  
  // Calculate initial lines
  for (int L = 0; L < LinePoints.length; L++)
  {
    LinePoints[L][0] = PVector.add(LineStartPosition, PVector.mult(LineStartPositionInterval, L));
    PVector velocity = PVector.mult(new PVector(sin(InitialUpdateDirection), 0.0, cos(InitialUpdateDirection)), UpdateDistance);
    
    for (int P = 1; P < LinePoints[L].length; P++)
    {
      PVector next = new PVector();
      next.set(LinePoints[L][P - 1]);
      next.add(velocity);
      next.y = noiseAt(next.x, 0.0, next.z) * MaxHeight;
      LinePoints[L][P] = next;
      
      // Update velocity based on Perlin Noise gradient
      float gradX = noiseAt(PVector.add(next, new PVector(0.5, 0.0, 0.0))) - noiseAt(PVector.add(next, new PVector(-0.5, 0.0, 0.0)));
      float gradZ = noiseAt(PVector.add(next, new PVector(0.0, 0.0, 0.5))) - noiseAt(PVector.add(next, new PVector(0.0, 0.0, -0.5)));
      velocity.add(new PVector(Gravity * gradX, 0.0, Gravity * gradZ));
      velocity.setMag(UpdateDistance);
    }
  }
}

void draw()
{
  // Calculate repulsion on self point by other points
  /*
  for (int selfL = 0; selfL < LinePoints.length; selfL++)
  {
    for (int selfP = 1; selfP < LinePoints[selfL].length; selfP++)
    {
      PVector selfDisplacement = new PVector();
      int otherL_min = max(selfL - RepulsionNeighbors, 0);
      int otherL_max = min(selfL + RepulsionNeighbors, LinePoints.length - 1);
      
      for (int otherL = otherL_min; otherL <= otherL_max; otherL++)
      {
        if (otherL == selfL)
        {
          continue;
        }
        
        for (int otherP = 0; otherP < LinePoints[otherL].length; otherP++)
        {
          PVector otherToSelf = PVector.sub(LinePoints[selfL][selfP], LinePoints[otherL][otherP]);
          selfDisplacement.add(PVector.div(otherToSelf, otherToSelf.magSq()));
        }
      }
      
      LinePoints[selfL][selfP].y = noiseAt(LinePoints[selfL][selfP].x, 0, LinePoints[selfL][selfP].z) * MaxHeight;
    }
  }
  */
  
  background(BgColor);
  pushMatrix();
  
  ortho(-width/2, width/2, -height/2, height/2, 0, MAX_DEPTH);
  translate(width/2, height/2, -000);
  rotateX(ANGLE_ROTATE_X);
  rotateY(ANGLE_ROTATE_Y);
  rotateZ(ANGLE_ROTATE_Z);
  
  // WaveDepthBuffer.fill(MAX_DEPTH);
  // WaveDepthBuffer.noStroke();
  // WaveDepthBuffer.rect(0, 0, WaveDepthBuffer.width, WaveDepthBuffer.height);
  
  // 3D object
  /*
  fill(BgColor);
  noStroke();
  for (int L = 1; L < LinePoints.length; L++)
  {
    beginShape(TRIANGLE_STRIP);
    for (int P = 0; P < LinePoints[L].length; P++)
    {
      vertex(LinePoints[L-1][P].x, LinePoints[L-1][P].y, LinePoints[L-1][P].z);
      vertex(LinePoints[L][P].x, LinePoints[L][P].y, LinePoints[L][P].z);
    }
    endShape();
  }
  */
  
  // List triangles and create a corresponding depth buffer
  /*
  WaveDepthBuffer.loadPixels();
  for (int L = 1; L < LinePoints.length; L++)
  {
    
    for (int P = 1; P < LinePoints[L].length; P++)
    {
      PVector screenPosA = GetScreenSpacePosition(LinePoints[L-1][P-1]);
      PVector screenPosB = GetScreenSpacePosition(LinePoints[L-1][P]);
      PVector screenPosC = GetScreenSpacePosition(LinePoints[L][P-1]);
      PVector screenPosD = GetScreenSpacePosition(LinePoints[L][P]);
      
      float depthABC = max(GetScreenSpaceDepth(LinePoints[L-1][P-1]), GetScreenSpaceDepth(LinePoints[L-1][P]), GetScreenSpaceDepth(LinePoints[L][P-1]));
      int boundsABC_minX = constrain(floor(min(screenPosA.x, screenPosB.x, screenPosC.x)), 0, WaveDepthBuffer.width - 1);
      int boundsABC_maxX = constrain(ceil(max(screenPosA.x, screenPosB.x, screenPosC.x)), 0, WaveDepthBuffer.width - 1);
      int boundsABC_minY = constrain(floor(min(screenPosA.y, screenPosB.y, screenPosC.y)), 0, WaveDepthBuffer.height - 1);
      int boundsABC_maxY = constrain(ceil(max(screenPosA.y, screenPosB.y, screenPosC.y)), 0, WaveDepthBuffer.height - 1);
      for (int x = boundsABC_minX; x <= boundsABC_maxX; x++)
      {
        for (int y = boundsABC_minY; y <= boundsABC_maxY; y++)
        {
          if (depthABC < WaveDepthBuffer.pixels[y * WaveDepthBuffer.width + x] && PointInTriangle2D(new PVector(x, y), screenPosA, screenPosB, screenPosC))
          {
            WaveDepthBuffer.pixels[y * WaveDepthBuffer.width + x] = round(depthABC);
          }
        }
      }
      
      float depthBCD = max(GetScreenSpaceDepth(LinePoints[L-1][P]), GetScreenSpaceDepth(LinePoints[L][P-1]), GetScreenSpaceDepth(LinePoints[L][P]));
      int boundsBCD_minX = constrain(floor(min(screenPosB.x, screenPosC.x, screenPosD.x)), 0, WaveDepthBuffer.width - 1);
      int boundsBCD_maxX = constrain(ceil(max(screenPosB.x, screenPosC.x, screenPosD.x)), 0, WaveDepthBuffer.width - 1);
      int boundsBCD_minY = constrain(floor(min(screenPosB.y, screenPosC.y, screenPosD.y)), 0, WaveDepthBuffer.height - 1);
      int boundsBCD_maxY = constrain(ceil(max(screenPosB.y, screenPosC.y, screenPosD.y)), 0, WaveDepthBuffer.height - 1);
      for (int x = boundsBCD_minX; x <= boundsBCD_maxX; x++)
      {
        for (int y = boundsBCD_minY; y <= boundsBCD_maxY; y++)
        {
          if (depthBCD < WaveDepthBuffer.pixels[y * WaveDepthBuffer.width + x] && PointInTriangle2D(new PVector(x, y), screenPosB, screenPosC, screenPosD))
          {
            WaveDepthBuffer.pixels[y * WaveDepthBuffer.width + x] = round(depthABC);
          }
        }
      }
    }
  }
  WaveDepthBuffer.updatePixels();
  */
  
  // Draw all lines
  stroke(LineColor);
  strokeWeight(LineStrokeWeight);
  for (int L = 0; L < LinePoints.length; L++)
  {
    for (int P = 1; P < LinePoints[L].length; P++)
    {
      line(LinePoints[L][P - 1].x, LinePoints[L][P - 1].y + LineStrokeWeight, LinePoints[L][P - 1].z,
      LinePoints[L][P].x, LinePoints[L][P].y + LineStrokeWeight, LinePoints[L][P].z);
      
      // print(LinePoints[L][P]);
    }
  }
  
  // Draw debug axes
  /*
  strokeWeight(DEBUG_AXES_WEIGHT);
  stroke(0xffff0000);
  line(0, 0, 0, DEBUG_AXES_LENGTH, 0, 0);
  stroke(0xff00ff00);
  line(0, 0, 0, 0, DEBUG_AXES_LENGTH, 0);
  stroke(0xff0000ff);
  line(0, 0, 0, 0, 0, DEBUG_AXES_LENGTH);
  fill(0xffffffff);
  text(frameCount, 0, 0, 0);
  */
  
  popMatrix();
}

int sign(float f)
{
  if (f > 0)
    return 1;
  else if (f < 0)
    return -1;
  else
    return 0;
}

float noiseAt(PVector v)
{
  return noiseAt(v.x, v.y, v.z);
}

float noiseAt(float x, float y, float z)
{
  return noise(NoiseOffsetX + x * NoiseScale, NoiseOffsetY + y * NoiseScale, NoiseOffsetZ + z * NoiseScale);
}

PVector GetScreenSpacePosition(PVector v)
{
  return new PVector(screenX(v.x, v.y, v.z), screenY(v.x, v.y, v.z));
}

float GetScreenSpaceDepth(PVector v)
{
  return screenZ(v.x, v.y, v.z);
}

// https://gdbooks.gitbooks.io/3dcollisions/content/Chapter4/point_in_triangle.html
Boolean PointInTriangle2D(PVector p, PVector a, PVector b, PVector c)
{
  a.sub(p);
  b.sub(p);
  c.sub(p);
  
  PVector u = new PVector(); PVector.cross(b, c, u);
  PVector v = new PVector(); PVector.cross(c, a, v);
  PVector w = new PVector(); PVector.cross(a, b, w);
  
  return sign(u.z) == sign(v.z) && sign(u.z) == sign(w.z);
}

void keyPressed()
{
  if (keyCode == ENTER || keyCode == RETURN)
  {
    setup();
  }
}
