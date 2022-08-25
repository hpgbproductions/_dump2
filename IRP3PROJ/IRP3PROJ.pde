import processing.serial.*;
int marker, roll, pitch, yaw, button;
Serial myPort;

int RollAngle, PitchAngle, YawAngle;
Boolean ButtonState = false;

// Timing
int fps = 30;
float deltaTime;
float RollingDataDeltaTime;

// Physics
float Throttle = 0.2;    // 0..1
float TAS = 100;         // m/s
float IAS;
float IAS_kts;
float Altitude = 1000;
float Altitude_ft;

float SpeedOfSound;
float MachNumber;
float PreviousAltitude_ft;
float VS_ft_min;

RollingData PitchAngles;
RollingData Turnings;
float TurnRateDeg;

// (right, up)
float LateralG;
PVector YawInducedG;    // Lateral component
PVector GravityG;       // Roll-induced component
PVector TwoDimensionalG;

float BaseAccel = 20;
float Drag = 0.0003f;
float BrakeDrag = 0.0015f;
Boolean BrakeActive = false;

// Design constants
int VERTICAL_FOV = 40;
int HDGIND_XSCALE = 4;
int TC_RADIUS = 250;

int LandingHeading = -20;
int LandingPitch = 3;
int LandingSize = 270;

// Drawing
PShape MajorSkyLine;
PShape MinorSkyLine;
color SkyColor;
color GroundColor;
color HudColor;
color BgColor;
float SkyRadius;

void setup()
{
  size(1280, 720);
  
  if (Serial.list().length > 0)
  {
    myPort = new Serial(this, Serial.list()[0], 115200);
  }
  else
  {
    println("No serial ports available!");
  }
  
  frameRate(fps);
  deltaTime = 1.0f / fps;
  
  SkyColor = color(110, 130, 150);
  GroundColor = color(50, 80, 60);
  HudColor = color(0, 255, 0);
  // BgColor = color(0, 0, 0, 128);
  
  SkyRadius = (height / 2) / sin(radians(VERTICAL_FOV));
  
  MajorSkyLine = createShape();
  MajorSkyLine.setStroke(HudColor);
  MajorSkyLine.setStrokeWeight(2);
  MajorSkyLine.beginShape(LINES);
  MajorSkyLine.vertex(-50, 0);
  MajorSkyLine.vertex(-120, 0);
  MajorSkyLine.vertex(-120, -1);
  MajorSkyLine.vertex(-120, -10);
  MajorSkyLine.vertex(50, 0);
  MajorSkyLine.vertex(120, 0);
  MajorSkyLine.vertex(120, -1);
  MajorSkyLine.vertex(120, -10);
  MajorSkyLine.endShape();
  
  MinorSkyLine = createShape();
  MinorSkyLine.setStroke(HudColor);
  MinorSkyLine.setStrokeWeight(1);
  MinorSkyLine.beginShape(LINES);
  MinorSkyLine.vertex(-60, 0);
  MinorSkyLine.vertex(-110, 0);
  MinorSkyLine.vertex(60, 0);
  MinorSkyLine.vertex(110, 0);
  MinorSkyLine.endShape();
  
  // Initialize physics
  Altitude_ft = Altitude * 3.281f;
  IAS = TAS / (1 + Altitude_ft / 1000 * 0.02f);
  YawInducedG = new PVector(0, 0);
  GravityG = new PVector(0, 0);
  TwoDimensionalG = new PVector(0, 0);
  
  // 30 fps
  PitchAngles = new RollingData(15);
  Turnings = new RollingData(30);
}

void draw()
{
  if (myPort != null)
  {
    // BEGIN read data stream
    int ReadData = 0;    // next data in packet to receive (0..3) (set to other values to ignore remaining bytes)
    int ReadByte = 0;    // the read byte is captured for error-checking
    while (myPort.available() > 0)
    {
      ReadByte = myPort.read();
      if (ReadData == 0 && ReadByte == '#')
      {
        marker = ReadByte;
        ReadData = 1;
      }
      else if (ReadData == 1 && ReadByte >= 0)
      {
        roll = ReadByte;
        ReadData = 2;
      }
      else if (ReadData == 2 && ReadByte >= 0)
      {
        pitch = ReadByte;
        ReadData = 3;
      }
      else if (ReadData == 3 && ReadByte >= 0)
      {
        yaw = ReadByte;
        ReadData = 4;
      }
      else if (ReadData == 4 && ReadByte >= 0)
      {
        button = ReadByte;
        ButtonState = (button == 'A');
        ReadData = 5;
      }
    }
    // END read data stream
    
    // BEGIN set angle values
    RollAngle = roll - 90;
    PitchAngle = pitch - 90;
    YawAngle = yaw - 90;
    // END set angle values
  }
  
  // BEGIN physics (remember to use deltaTime)
  Altitude += TAS * sin(radians((float)-PitchAngles.LinearWeightedAverage())) * deltaTime;
  Altitude = constrain(Altitude, 0, 15000);
  Altitude_ft = Altitude * 3.281f;
  VS_ft_min = (Altitude_ft - PreviousAltitude_ft) / deltaTime * 60;
  
  TAS += (Throttle * BaseAccel - IAS * IAS * (BrakeActive ? BrakeDrag : Drag) + 9.81f * sin(radians(PitchAngle))) * deltaTime;
  TAS = max(TAS, 50);
  IAS = TAS / (1 + Altitude_ft / 1000 * 0.02f);
  IAS_kts = IAS * 1.944f;
  
  SpeedOfSound = sqrt(1.4f * 287 * (288.2f - 6.5e-3f * constrain(Altitude, 0, 11000)));
  MachNumber = TAS / SpeedOfSound;
  
  PitchAngles.Add(PitchAngle);
  Turnings.Add(YawAngle);
  
  TurnRateDeg = (float)Turnings.Delta();
  LateralG = radians(TurnRateDeg) * TAS;    // a.c = OMEGA * v
  YawInducedG = new PVector(LateralG, 0).rotate(radians(RollAngle));
  GravityG = new PVector(0, -9.81f).rotate(radians(RollAngle));
  TwoDimensionalG = PVector.add(YawInducedG, GravityG);
  println(TwoDimensionalG);
  // END physics
  
  background(SkyColor);
  
  // BEGIN draw items that move with the horizon
  pushMatrix();
  translate(width / 2, height / 2);
  rotate(-radians(RollAngle));
  
  // Ground
  fill(GroundColor);
  noStroke();
  rect(-width, GetPitchOffset(PitchAngle) , width * 2, height * 2);
  
  // Lines
  fill(HudColor);
  textSize(16);
  for (int angle = PitchAngle - 12; angle <= PitchAngle + 12; angle++)
  {
    if (angle % 10 == 0)
    {
      pushMatrix();
      translate(0, GetPitchOffset(PitchAngle - angle));
      shape(MajorSkyLine, 0, 0);
      rotate(radians(RollAngle));
      textAlign(RIGHT, CENTER);
      text(-angle, -130 * cos(radians(RollAngle)), 130 * sin(radians(RollAngle)));
      textAlign(LEFT, CENTER);
      text(-angle, 130 * cos(radians(RollAngle)), -130 * sin(radians(RollAngle)));
      popMatrix();
      angle += 4;
    }
    else if (angle % 5 == 0)
    {
      shape(MinorSkyLine, 0, GetPitchOffset(PitchAngle - angle));
      angle += 4;
    }
  }
  
  popMatrix();
  // END draw items that move with the horizon
  
  // Landing (button active only)
  if (ButtonState)
  {
    pushMatrix();
    translate(width / 2, height / 2);
    noFill();
    stroke(HudColor);
    strokeWeight(2);
    beginShape();
    vertex(0, -LandingSize);
    vertex(LandingSize, 0);
    vertex(0, LandingSize);
    vertex(-LandingSize, 0);
    endShape(CLOSE);
    int land_x = LandingSize * constrain(YawAngle - LandingHeading, -10, 10) / 10;
    line(land_x, -LandingSize - 20, land_x, LandingSize + 20);
    int land_y = LandingSize * -constrain(PitchAngle - LandingPitch, -10, 10) / 10;
    line(-LandingSize - 20, land_y, LandingSize + 20, land_y);
    popMatrix();
  }
  
  // BEGIN nose position indicator
  pushMatrix();
  translate(width / 2, height / 2);
  noFill();
  stroke(HudColor);
  strokeWeight(2);
  line(-45, 0, -15, 0);
  line(45, 0, 15, 0);
  line(0, -30, 0, -15);
  arc(0, 0, 30, 30, 0, PI);
  strokeWeight(5);
  point(0, 0);
  popMatrix();
  // END nose position indicator
  
  // BEGIN heading indicator
  if (ButtonState)
  {
    pushMatrix();
    translate(width / 2, 35);
    fill(HudColor);
    textSize(32);
    textAlign(CENTER, CENTER);
    String hdgind_displayheading = nf(-YawAngle < 0 ? -YawAngle + 360 : -YawAngle, 3, 0);
    TextMonospace(hdgind_displayheading, -20, 0, 20);
    popMatrix();
  }
  else    // !ButtonState
  {
    pushMatrix();
    translate(width / 2, 70);
    fill(HudColor);
    stroke(HudColor);
    textSize(16);
    textAlign(CENTER, CENTER);
    for (int hdg = YawAngle - 41; hdg <= YawAngle + 41; hdg++)
    {
      if (hdg % 30 == 0)
      {
        strokeWeight(2);
        line((YawAngle - hdg) * HDGIND_XSCALE, 0, (YawAngle - hdg) * HDGIND_XSCALE, -20);
        
        int n = (-hdg / 10);
        if (n < 0) n += 36;
        
        String s = (n == 0 ? "N" : (n == 9 ? "E" : (n == 18 ? "S" : (n == 27 ? "W" : nf(n)))));
        text(s, (YawAngle - hdg) * HDGIND_XSCALE, -35);
      }
      if (hdg % 10 == 0)
      {
        strokeWeight(1);
        line((YawAngle - hdg) * HDGIND_XSCALE, 0, (YawAngle - hdg) * HDGIND_XSCALE, -15);
        hdg += 9;
      }
    }
    noFill();
    stroke(HudColor);
    strokeWeight(2);
    triangle(0, 13, -7, 40, 7, 40);
    fill(HudColor);
    textSize(32);
    textAlign(CENTER, CENTER);
    String hdgind_displayheading = nf(-YawAngle < 0 ? -YawAngle + 360 : -YawAngle, 3, 0);
    TextMonospace(hdgind_displayheading, -20, 55, 20);
    popMatrix();
  }
  // END heading indicator
  
  // BEGIN airspeed indicator
  pushMatrix();
  translate(250, height / 2);
  fill(HudColor);
  textAlign(CENTER, CENTER);
  textSize(32);
  TextMonospace(nf(round(IAS_kts)), -30, -4, 20);
  noFill();
  stroke(HudColor);
  strokeWeight(2);
  beginShape();
  vertex(40, 0);    // pointy part, anticlockwise
  vertex(20, -20);
  vertex(-90, -20);
  vertex(-90, 20);
  vertex(20, 20);
  endShape(CLOSE);
  beginShape();
  vertex(61, -180);
  vertex(41, -180);
  vertex(41, 180);
  vertex(61, 180);
  endShape();
  fill(HudColor);
  stroke(HudColor);
  strokeWeight(1);
  textAlign(LEFT, CENTER);
  textSize(16);
  text("SPEED", 40, -200);
  for (int i = round(IAS_kts - 90); i < round(IAS_kts) + 90; i++)
  {
    if (i % 20 == 0)
    {
      float y = (IAS_kts - i) * 180 / 90;
      if (i >= 60)
      {
        line(41, y, 55, y);
        TextMonospace(nf(round(i)), 60, y - 3, 10);
      }
      if (i == 60)
      {
        SlashedRegion(41, y, 15, 180 - y, 10);
      }
      i += 19;
    }
  }
  textAlign(CENTER, CENTER);
  TextMonospaceRight(String.format("M %1$1.2f", MachNumber), 15, 40, 12);
  TextMonospaceRight(String.format("ENG1 %1$3d%%", round(Throttle * 100)), 15, 60, 12);
  TextMonospaceRight(String.format("ENG2 %1$3d%%", round(Throttle * 100)), 15, 80, 12);
  popMatrix();
  // END airspeed indicator
  
  // BEGIN altitude indicator
  pushMatrix();
  translate(width - 250, height / 2);
  fill(HudColor);
  textAlign(CENTER, CENTER);
  textSize(32);
  // "/10*10" Programming exploit to floor integers to 10
  TextMonospaceRight(String.format("%1$5d", round(Altitude_ft) / 10 * 10), 70, -4, 20);
  noFill();
  stroke(HudColor);
  strokeWeight(2);
  beginShape();
  vertex(-40, 0);    // pointy part, clockwise
  vertex(-20, -20);
  vertex(90, -20);
  vertex(90, 20);
  vertex(-20, 20);
  endShape(CLOSE);
  beginShape();
  vertex(-61, -180);
  vertex(-41, -180);
  vertex(-41, 180);
  vertex(-61, 180);
  endShape();
  fill(HudColor);
  stroke(HudColor);
  strokeWeight(1);
  textAlign(RIGHT, CENTER);
  textSize(16);
  text("ALTITUDE", -40, -200);
  for (int i = round(Altitude_ft - 450); i < round(Altitude_ft) + 450; i++)
  {
    if (i % 100 == 0)
    {
      float y = (Altitude_ft - i) * 180 / 450;
      if (i >= 0)
      {
        line(-41, y, -55, y);
        TextMonospaceRight(String.format("%1$5d", round(i)), -60, y - 3, 10);
      }
      if (i == 0)
      {
        SlashedRegion(-56, y, 15, 180 - y, 10);
      }
      i += 99;
    }
  }
  // BEGIN vertical speed indicator 1000 ft/min per line
  noFill();
  stroke(HudColor);
  strokeWeight(2);
  beginShape();    // upper bar
  vertex(-20, -20);
  vertex(-20, -180);
  vertex(0, -180);
  endShape();
  beginShape();    // lower bar
  vertex(-20, 20);
  vertex(-20, 180);
  vertex(0, 180);
  endShape();
  strokeWeight(1);
  beginShape(LINES);    // VS markings
  vertex(-20, -140); vertex(-5, -140);
  vertex(-20, -100); vertex(-5, -100);
  vertex(-20, -60); vertex(-5, -60);
  vertex(-20, 60); vertex(-5, 60);
  vertex(-20, 100); vertex(-5, 100);
  vertex(-20, 140); vertex(-5, 140);
  endShape();
  fill(HudColor);
  noStroke();
  textSize(16);
  if (VS_ft_min >= 10)
  {
    float h = -constrain(VS_ft_min, -4000, 4000) / 1000 * 40;
    textAlign(LEFT, BOTTOM);
    text(nf(round(VS_ft_min)), -2, -20 + h);
    rect(-20, -20, 12, h);
  }
  else if (VS_ft_min <= -10)
  {
    float h = -constrain(VS_ft_min, -4000, 4000) / 1000 * 40;
    textAlign(LEFT, TOP);
    text(nf(round(VS_ft_min)), -2, 20 + h);
    rect(-20, 20, 12, h);
  }
  // END vertical speed indicator
  popMatrix();
  // END altitude indicator
  
  // BEGIN turn and slip indicator (button inactive only)
  if (!ButtonState)
  {
    pushMatrix();
    translate(width / 2, height / 2 + 50);
    
    // BEGIN inclinometer (ball in a tube)
    pushMatrix();
    noFill();
    stroke(HudColor);
    strokeWeight(2);
    arc(0, 0, TC_RADIUS * 2, TC_RADIUS * 2, radians(60), radians(120));
    for (int a = 60; a <= 120; a += 15)
    {
      line(TC_RADIUS * cos(radians(a)), TC_RADIUS * sin(radians(a)), (TC_RADIUS - 15) * cos(radians(a)), (TC_RADIUS - 15) * sin(radians(a)));
    }
    rotate(constrain(-TwoDimensionalG.heading() - radians(90), radians(-30), radians(30)));
    noFill();
    stroke(HudColor);
    strokeWeight(2);
    triangle(0, TC_RADIUS, -10, TC_RADIUS + 10, 10, TC_RADIUS + 10);
    popMatrix();
    // END inclinometer
    
    // BEGIN turn rate indicator
    translate(0, 200);
    noFill();
    stroke(HudColor);
    strokeWeight(4);
    circle(0, 0, 12);
    line(45 * cos(radians(240)), 45 * sin(radians(240)), 55 * cos(radians(240)), 55 * sin(radians(240)));
    line(45 * cos(radians(300)), 45 * sin(radians(300)), 55 * cos(radians(300)), 55 * sin(radians(300)));
    fill(HudColor);
    textAlign(CENTER, CENTER);
    textSize(16);
    text("L", 70 * cos(radians(240)), 70 * sin(radians(240)));
    text("R", 70 * cos(radians(300)), 70 * sin(radians(300)));
    // Needle
    pushMatrix();
    rotate(radians(map(constrain(TurnRateDeg, -3, 3), -3, 3, 30, -30)));
    stroke(HudColor);
    strokeWeight(2);
    line(0, -6, 0, -40);
    popMatrix();
    popMatrix();
    // END turn rate indicator
  }
  // END turn and slip indicator
  
  // BEGIN post physics
  PreviousAltitude_ft = Altitude_ft;
  // END post physics
}



float GetPitchOffset(float pitchAngle)
{
  return SkyRadius * sin(radians(-pitchAngle));
}

void TextMonospace(String string, float x, float y, float x_off)
{
  float x_current = x;
  for (int i = 0; i < string.length(); i++)
  {
    text(string.charAt(i), x_current, y);
    x_current += x_off;
  }
}

void TextMonospaceRight(String string, float x, float y, float x_off)
{
  float x_current = x;
  for (int i = string.length() - 1; i >= 0; i--)
  {
    text(string.charAt(i), x_current, y);
    x_current -= x_off;
  }
}

// Draw top-right to bottom-left slashes, where (sx,sy) is the top-right of a line
void SlashedRegion(float x, float y, float w, float h, float interval)
{
  float sx = x + w;
  float sy = y - w;
  while (sy < y + h)
  {
    float lsx = sx, lsy = sy, lfx = sx - w, lfy = sy + w;
    if (lsy < y)    // Line starts above the bounding box
    {
      lsy = y;
      lsx = sx - (y - sy);
    }
    if (lfy > y + h)    // Line ends below the bounding box
    {
      lfy = y + h;
      lfx = sx - ((y + h) - sy);
    }
    
    line(lsx, lsy, lfx, lfy);
    sy += interval;
  }
}



class RollingData
{
  public double[] data;
  private int count = 0;
  private int next = 0;
  
  public RollingData(int size)
  {
    data = new double[size];
    count = 0;
    next = 0;
  }
  
  public void Add(double num)
  {
    data[next] = num;
    count += 1;
    next += 1;
    if (next == data.length)
    {
      next = 0;
    }
  }
  
  public double Average()
  {
    double total = 0;
    for (int i = 0; i < min(count, data.length); i++)
    {
      total += data[i];
    }
    
    if (count == 0)
      return 0;
    
    return total / min(count, data.length);
  }
  
  public double LinearWeightedAverage()
  {
    double total = 0;
    int totalWeights = 0;
    
    if (count == 0)
    {
      return 0;
    }
    else if (count < data.length)
    {
      // The data folder is not completely full
      for (int i = 0; i < count; i++)
      {
        total += data[i];
        totalWeights += i + 1;
      }
      return total / totalWeights;
    }
    else
    {
      // The data folder is completely full
      // The oldest number is the one that will be overwritten next
      for (int i = 0; i < data.length; i++)
      {
        total += data[(next + i) % data.length];
        totalWeights += i + 1;
      }
      return total / totalWeights;
    }
  }
  
  public double Delta()
  {
    if (count < 2)
    {
      return 0;
    }
    else if (count < data.length)
    {
      // The data folder is not completely full
      double oldNum = data[0];
      double newNum = data[count - 1];
      return newNum - oldNum;
    }
    else
    {
      // The data folder is completely full
      // The oldest number is the one that will be overwritten next
      int newIndex = next - 1;
      if (newIndex < 0)
      {
        newIndex = data.length - 1;
      }
      
      double oldNum = data[next];
      double newNum = data[newIndex];
      return newNum - oldNum;
    }
  }
}



void keyPressed()
{
  if (myPort == null)
  {
    if (key == 'a')
      RollAngle--;
    if (key == 'd')
      RollAngle++;
    if (key == 's')
      PitchAngle--;
    if (key == 'w')
      PitchAngle++;
    if (key == 'e')
      YawAngle--;
    if (key == 'q')
      YawAngle++;
    if (key == 'p')
      ButtonState = !ButtonState;
      
    RollAngle = constrain(RollAngle, -90, 90);
    PitchAngle = constrain(PitchAngle, -90, 90);
    YawAngle = constrain(YawAngle, -90, 90);
  }
  
  if (key == 'z')
      Throttle -= 0.01f;
  if (key == 'x')
    Throttle += 0.01f;
  if (key == 'c')
    BrakeActive = !BrakeActive;
    
  Throttle = constrain(Throttle, 0, 1);
}
