int startX = 500;
int startY = 500;
int beaconX = 500;
int beaconY = 100;

// Speed of wind towards the right (pixels/s)
int windSpeed = 20;

// Airspeed of aircraft (pixels/s)
int aircraftSpeed = 100;

// Angle in degrees flown into the wind
float adjustmentDeg = 5;

PVector aircraftPos;
PVector beaconPos;
PVector windVelocity;
PVector aircraftBaseVelocity;
PVector aircraftVelocity;

float aircraftToBeaconHeading;

ArrayList<PVector> aircraftPath;

int fps = 20;
float deltaTime;

void setup()
{
  size(800, 600);
  
  aircraftPos = new PVector(startX, startY);
  beaconPos = new PVector(beaconX, beaconY);
  windVelocity = new PVector(windSpeed, 0);
  aircraftBaseVelocity = new PVector(0, -aircraftSpeed);
  aircraftVelocity = new PVector();
  
  aircraftPath = new ArrayList<PVector>();
  
  frameRate(fps);
  deltaTime = 1.0f / fps;
}

void draw()
{
  background(50, 80, 50);
  
  // waypoints
  stroke(150);
  strokeWeight(3);
  line(startX, startY, beaconX, beaconY);
  stroke(128, 128, 0);
  strokeWeight(3);
  line(aircraftPos.x, aircraftPos.y, beaconX, beaconY);
  stroke(255);
  strokeWeight(10);
  point(startX, startY);
  stroke(255, 70, 70);
  strokeWeight(10);
  point(beaconX, beaconY);
  
  // text
  textSize(20);
  textAlign(RIGHT, CENTER);
  fill(255);
  text("START", startX - 20, startY);
  fill(255, 70, 70);
  text("NDB", beaconX - 20, beaconY);
  fill(255, 255, 0);
  String[] StringsToJoin = { "Wind Speed:", nf(windSpeed), "\nAircraft Speed:", nf(aircraftSpeed), "\nAdjustment (deg):", nf(adjustmentDeg) };
  text(join(StringsToJoin, ' '), 300, 300);
  
  // calculations
  aircraftToBeaconHeading = PVector.sub(aircraftPos, beaconPos).heading();
  if (PVector.dist(aircraftPos, beaconPos) > 10)
  {
    aircraftPos = PVector.add(aircraftPos, PVector.mult(windVelocity, deltaTime));
    aircraftVelocity.set(aircraftBaseVelocity);
    aircraftPos = PVector.add(aircraftPos, PVector.mult(aircraftVelocity.rotate(aircraftToBeaconHeading - radians(90) - radians(adjustmentDeg)), deltaTime));
    
    if (frameCount % 3 == 1) aircraftPath.add(aircraftPos);
  }
  
  // flight path
  noFill();
  stroke(0, 255, 0);
  strokeWeight(1);
  beginShape();
  for (int i = 0; i < aircraftPath.size(); i++)
  {
    vertex(aircraftPath.get(i).x, aircraftPath.get(i).y);
  }
  endShape();
  
  // aircraft
  translate(aircraftPos.x, aircraftPos.y);
  rotate(aircraftToBeaconHeading - radians(90) - radians(adjustmentDeg));
  noFill();
  stroke(255, 255, 0);
  strokeWeight(3);
  triangle(0, 0, -7, 20, 7, 20);
  stroke(255, 255, 0);
  strokeWeight(2);
  line(0, 0, 0, -50);
}
