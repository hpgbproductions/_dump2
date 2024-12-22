#include <Servo.h>

#define PSERVO 9
#define PLEDL 10
#define PLEDR 11
#define PTRIG 12
#define PECHO 13

#define PBUZZ A0
#define PSENS A5

Servo servo;

int ServoPos = 0;           // Position that corresponds to a certain angle
bool ServoPosDir = true;    // Increase if true, decrease if false

int Sensitivity = 0;        // Value that will trigger a warning

int Distance[13];           // Newest reading at a given position
bool ObstacleNearby[13];    // Positions with obstacles detected

void setup()
{
  // Setup pins
  pinMode(PSERVO, OUTPUT);
  pinMode(PLEDL, OUTPUT);
  pinMode(PLEDR, OUTPUT);
  pinMode(PTRIG, OUTPUT);
  pinMode(PBUZZ, OUTPUT);
  pinMode(PECHO, INPUT);
  
  // Prepare servo and move it to the starting position
  servo.attach(PSERVO);
  servo.write(30);
  
  Serial.begin(9600);
  delay(200);
}

void loop()
{
  UpdateSens();
  RunTest();
  UpdateWarning();
  SetNextPos();
}

void UpdateSens()
{
  // Formula for sensitivity
  Sensitivity = analogRead(A5) / 6 + 30;
}

void RunTest()
{
  long duration;
  int distance;
  
  // Move sensor unit to the defined position
  // The detection arc can be changed by modifying the angle formula
  servo.write(30 + ServoPos * 10);
  
  // Allow the servo to reach the position
  delay(50);
  
  // Send ultrasonic pulse
  digitalWrite(PTRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(PTRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(PTRIG, LOW);
  
  // Get duration
  duration = pulseIn(PECHO, HIGH, 20000);
  
  if (duration == 0)
  {
    // Timed out, use a fixed large distance
    distance = 400;
  }
  else
  {
    // Calculate distance
    distance = duration * 0.034 / 2;
  }
  
  // Write detected distance to array
  Distance[ServoPos] = distance;
  
  // Debug message
  Serial.println(String("Pos. " + String(ServoPos) + ": " + String(distance) + "/" + String(Sensitivity)));
}

void UpdateWarning()
{
  // Whether an obstacle has been detected in the given region
  bool DetectL = false;    // 0-3
  bool DetectM = false;    // 4-8
  bool DetectR = false;    // 9-12
  
  for (int i = 0; i < 13; i++)
  {
    // Obstacle at position i
    if (Distance[i] < Sensitivity)
    {
      // Set flag for the correct region
      if (i <= 3)
        DetectL = true;
      else if (i <= 8)
        DetectM = true;
      else
        DetectR = true;
    }
  }
  
  // Apply warnings
  if (DetectL)
    digitalWrite(PLEDL, HIGH);
  else
    digitalWrite(PLEDL, LOW);
  
  if (DetectM)
    digitalWrite(PBUZZ, HIGH);
  else
    digitalWrite(PBUZZ, LOW);
  
  if (DetectR)
    digitalWrite(PLEDR, HIGH);
  else
    digitalWrite(PLEDR, LOW);
}

void SetNextPos()
{
  if ((ServoPos == 0 && !ServoPosDir) || (ServoPos == 12 && ServoPosDir))
  {
    ServoPosDir = !ServoPosDir;
  }
  else
  {
    ServoPos += ServoPosDir ? 1 : -1;
  }
}
