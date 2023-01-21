#include <LiquidCrystal_I2C.h>

// Pin definitions, A4 and A5 reserved for I2C LCD
#define RE_SW 13
#define RE_DT 12
#define RE_CLK 2

// ----------------------------------------------------------------
// Classes

// BEGIN debounced button class
// State changes are only accepted if the state has last changed some time ago,
// hence providing a debounce effect
class DebouncedButton
{
  public:
    DebouncedButton(int pinNum, int dbmillis, int upState);
    DebouncedButton();
    void update();
    int pinNumber;
    int debounceMillis;
    int state;
    int previousState;
    int inactiveState;
    bool isDown;
    // True only on the update right after the button is released or pushed
    bool onButtonUp;
    bool onButtonDown;
    // How long since the last valid state change
    int afterChangedStateMillis;
  private:
    // Time of the last button update
    long lastUpdateMillis;
};

DebouncedButton::DebouncedButton()
{
}

// Constructor
// int pinNum: Button pin. Remember to call pinMode separately.
// int dbMillis: Debounce time in milliseconds.
// int defaultState: {LOW, HIGH} Default state of the button.
DebouncedButton::DebouncedButton(int pinNum, int dbMillis, int defaultState = LOW)
{
  pinNumber = pinNum;
  debounceMillis = dbMillis;
  
  state = inactiveState;
  previousState = defaultState;
  inactiveState = defaultState;
  onButtonUp = false;
  onButtonDown = false;
  isDown = false;
  
  afterChangedStateMillis = 0;
  lastUpdateMillis = millis();
}

void DebouncedButton::update()
{
  int reading = digitalRead(pinNumber);
  afterChangedStateMillis += millis() - lastUpdateMillis;
  lastUpdateMillis = millis();
  
  onButtonUp = false;
  onButtonDown = false;
  
  // Only check for state changes if the last one happened debounceMillis ago
  if (afterChangedStateMillis > debounceMillis)
  {
    if (reading != state)
    {
      // Change the state
      state = reading;
      isDown = state != inactiveState;
      
      // Set edge detection flags
      if (previousState == inactiveState && state != inactiveState)
      {
        onButtonDown = true;
      }
      else if (previousState != inactiveState && state == inactiveState)
      {
        onButtonUp = true;
      }

      // Since the state has changed, reset the timer
      afterChangedStateMillis = 0;
    }
  }
  
  // Update the previous state at the end of the update cycle
  previousState = state;
}
// END debounced button class

// BEGIN rotary encoder (full cycle) class
// This is only for fast programs that don't use delay!
class RotaryEncoder
{
  public:
    RotaryEncoder(int _clkPin, int _dtPin, int dbMillis, int defaultState);
    RotaryEncoder();
    void update();
    int clkPin;
    int dtPin;
    int rotation;    // Position of rotary encoder relative to starting position
    int change;      // Change of position from the last update (-1, 0, or +1)
    int debounceMillis;
    int afterChangedStateMillis;
  private:
    int lastState;
    long lastUpdateMillis;
};

RotaryEncoder::RotaryEncoder()
{
}

// Constructor
// int _clkPin: CLK pin. Remember to call pinMode separately.
// int _clkPin: DT pin. Remember to call pinMode separately.
// int dbMillis: Debounce time in milliseconds.
// int inactiveState: {LOW, HIGH} Default state of the button.
RotaryEncoder::RotaryEncoder(int _clkPin, int _dtPin, int dbMillis, int defaultState)
{
  clkPin = _clkPin;
  dtPin = _dtPin;
  rotation = 0;
  change = 0;
  debounceMillis = dbMillis;
  afterChangedStateMillis = 0;
  lastState = defaultState;
}

void RotaryEncoder::update()
{
  afterChangedStateMillis += millis() - lastUpdateMillis;
  lastUpdateMillis = millis();

  int clkState = digitalRead(clkPin);
  int dtState = digitalRead(dtPin);

  if (lastUpdateMillis < debounceMillis)
  {
    return;
  }
  else if (clkState != lastState)
  {
    // clkPin state has changed
    // If turning clockwise, CLK (interrupt) changes before DT, so they are different
    if (clkState != dtState)
    {
      rotation++;
      change = 1;
    }
    else
    {
      rotation--;
      change = -1;
    }

    // reset
    lastState = clkState;
    afterChangedStateMillis = 0;
  }
  else
  {
    change = 0;
  }
}

// END rotary encoder class

// BEGIN Link2fs input buffer class
// Maximum 16 chars supported
class FsInputBuffer
{
  public:
    FsInputBuffer();
    void add(char c);
    void reset();
    char buf[16];
    int pos;
};

FsInputBuffer::FsInputBuffer()
{
  reset();
}

void FsInputBuffer::add(char c)
{
  if (pos >= 16)
  {
    return;
  }
  
  buf[pos] = c;
  pos++;
}

void FsInputBuffer::reset()
{
  pos = 0;
}
// END input buffer class

// ----------------------------------------------------------------
// Variables

// Initialize the LCD (I2C_address, size_columns, size_rows)
LiquidCrystal_I2C lcd(39, 16, 2);

// Input switches
DebouncedButton RotaryButton(RE_SW, 50, HIGH);
RotaryEncoder Rotary;

// Flight simulator state
FsInputBuffer InputBuffer;
bool ApActive = false;
char ApAltitude[5];
char ApVerticalSpeed[5];
char ApHeading[3];
char ApNavCourse[3];
bool ApHeadingLock = false;
bool ApAltitudeLock = false;
bool ApApproachLock = false;
bool ApBackcourseLock = false;
bool ApNavLock = false;

// Other variables
bool UpdateLcd = true;

// The variable that the rotary encoder modifies
enum class RotaryControlVariables : int { Altitude, VerticalSpeed, Heading, NavCourse };
RotaryControlVariables RotaryControlVariable = RotaryControlVariables::Altitude;

// ----------------------------------------------------------------
// Main

void setup()
{
  Serial.begin(115200);

  pinMode(RE_SW, INPUT);
  pinMode(RE_DT, INPUT);
  pinMode(RE_CLK, INPUT);

  Rotary = RotaryEncoder::RotaryEncoder(RE_CLK, RE_DT, 10, digitalRead(RE_CLK));
  
  lcd.init();
  lcd.backlight();
}

void loop()
{
  // Update input components
  RotaryButton.update();
  Rotary.update();

  while (Serial.available() > 0)
  {
    char c = Serial.read();

    if (c == '=' || c == '>' || c == '?')
    {
      // Detected a function start char
      InputBuffer.reset();
    }
    InputBuffer.add(c);
    UpdateLcd = TryReadInput(InputBuffer.buf);
  }

  // The update process is carried out if an input command was performed,
  // meaning that an autopilot state was sent
  if (UpdateLcd)
  {
    UpdateLcd = false;

    // Left 4 chars on row 0
    // Left 3 chars on row 1
    if (!ApActive)
    {
      lcd.setCursor(0, 0);
      lcd.print("STBY");
      lcd.setCursor(0, 1);
      lcd.print("   ");

      if (RotaryControlVariable == RotaryControlVariables::Heading || RotaryControlVariable == RotaryControlVariables::NavCourse)
      {
        RotaryControlVariable = RotaryControlVariables::Altitude;
      }
    }
    else if (ApHeadingLock)
    {
      lcd.setCursor(0, 0);
      lcd.print("HDG ");
      lcd.setCursor(0, 1);
      lcd.print(ApHeading);

      if (RotaryControlVariable == RotaryControlVariables::NavCourse)
      {
        RotaryControlVariable = RotaryControlVariables::Heading;
      }
    }
    else if (ApNavLock)
    {
      lcd.setCursor(0, 0);
      lcd.print("NAV ");
      lcd.setCursor(0, 1);
      lcd.print(ApNavCourse);

      if (RotaryControlVariable == RotaryControlVariables::Heading)
      {
        RotaryControlVariable = RotaryControlVariables::NavCourse;
      }
    }
    else if (ApApproachLock)
    {
      lcd.setCursor(0, 0);
      lcd.print("APR ");
      lcd.setCursor(0, 1);
      if (ApBackcourseLock)
        lcd.print("REV");
      else
        lcd.print("   ");

      if (RotaryControlVariable == RotaryControlVariables::Heading || RotaryControlVariable == RotaryControlVariables::NavCourse)
      {
        RotaryControlVariable = RotaryControlVariables::Altitude;
      }
    }

    lcd.setCursor(7, 0);
    lcd.print("ALT ");
    lcd.print(ApAltitude);
    lcd.setCursor(7, 1);
    lcd.print("VS  ");
    lcd.print(ApVerticalSpeed);
  }

  // Set RotaryControlVariable according to RotaryButton press
  // Short press: switch between Altitude and VerticalSpeed
  if (RotaryButton.onButtonDown)
  {
    if (RotaryControlVariable == RotaryControlVariables::Altitude)
    {
      RotaryControlVariable = RotaryControlVariables::VerticalSpeed;
    }
    else
    {
      RotaryControlVariable = RotaryControlVariables::Altitude;
    }
  }
  // Long press: switch to Heading or NavCourse
  if (RotaryButton.isDown && RotaryButton.afterChangedStateMillis > 1000)
  {
    if (ApHeadingLock)
    {
      RotaryControlVariable = RotaryControlVariables::Heading;
    }
    else if (ApNavLock)
    {
      RotaryControlVariable = RotaryControlVariables::NavCourse;
    }
  }

  // Rotary encoder input
  if (RotaryControlVariable == RotaryControlVariables::Altitude)
  {
    if (Rotary.change == 1) Serial.println("B11");
    else if (Rotary.change == -1) Serial.println("B12");
  }
  else if (RotaryControlVariable == RotaryControlVariables::VerticalSpeed)
  {
    if (Rotary.change == 1) Serial.println("B13");
    else if (Rotary.change == -1) Serial.println("B14");
  }
  else if (RotaryControlVariable == RotaryControlVariables::Heading)
  {
    if (Rotary.change == 1) Serial.println("A57");
    else if (Rotary.change == -1) Serial.println("A58");
  }
  else if (RotaryControlVariable == RotaryControlVariables::NavCourse)
  {
    if (Rotary.change == 1) Serial.println("A55");
    else if (Rotary.change == -1) Serial.println("A56");
  }
}

// Try to execute a function with the input text
// Returns true if any values were set
bool TryReadInput(char buf[])
{
  if (buf[0] == '=')
  {
    switch (buf[1])
    {
      case 'a':
        if (strlen(buf) == 3)
        {
          ApActive = buf[2] != '0';
          return true;
        }
        break;
      case 'b':
        if (strlen(buf) == 7)
        {
          memcpy(ApAltitude, buf + 2, 5);
          return true;
        }
        break;
      case 'c':
        if (strlen(buf) == 7)
        {
          memcpy(ApVerticalSpeed, buf + 2, 5);
          // Remove leading sign if number is exactly 0000
          if (memcpy(ApVerticalSpeed + 1, "0000", 4) == 0)
          {
            ApVerticalSpeed[0] = ' ';
          }
          return true;
        }
        break;
      case 'd':
        if (strlen(buf) == 5)
        {
          memcpy(ApHeading, buf + 2, 3);
          return true;
        }
        break;
      case 'e':
        if (strlen(buf) == 5)
        {
          memcpy(ApNavCourse, buf + 2, 3);
          return true;
        }
        break;
      case 'j':
        if (strlen(buf) == 3)
        {
          ApHeadingLock = buf[2] != '0';
          return true;
        }
        break;
      case 'k':
        if (strlen(buf) == 3)
        {
          ApAltitudeLock = buf[2] != '0';
          return true;
        }
        break;
      case 'm':
        if (strlen(buf) == 3)
        {
          ApApproachLock = buf[2] != '0';
          return true;
        }
        break;
      case 'n':
        if (strlen(buf) == 3)
        {
          ApBackcourseLock = buf[2] != '0';
          return true;
        }
        break;
      case 'o':
        if (strlen(buf) == 3)
        {
          ApNavLock = buf[2] != '0';
          return true;
        }
        break;
      default:
        break;
    }
  }
  return false;
}
