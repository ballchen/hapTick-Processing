int s0 = 11;
int s1 = 12;
int s2 = 13;
int vibrateTime = 50;
String sensorValue;
boolean vibrating = false;

void vibrate() {

  vibrating = true;
  digitalWrite(s0, 0);
  digitalWrite(s1, 0);
  digitalWrite(s2, 0);

  delay(vibrateTime);

  vibrating = false;
  digitalWrite(s0, 1);
  digitalWrite(s1, 1);
  digitalWrite(s2, 1);
}

void vibrateStop() {
  digitalWrite(s0, 1);
  digitalWrite(s1, 1);
  digitalWrite(s2, 1);
}

void vibrateStart() {
  digitalWrite(s0, 0);
  digitalWrite(s1, 0);
  digitalWrite(s2, 0);
}

void setup() {
  // put your setup code here, to run once:
  pinMode(s0, OUTPUT); 
  pinMode(s1, OUTPUT); 
  pinMode(s2, OUTPUT);
  digitalWrite(s0, HIGH);
  digitalWrite(s1, HIGH);
  digitalWrite(s2, HIGH);

  Serial.begin(9600);
}

void loop() {
  if(Serial.available()) {
    sensorValue = Serial.readStringUntil('\n');
    Serial.println(sensorValue);  
    if(sensorValue == "1") {
      if(!vibrating) {
        vibrate();
      }
      
    } else if (sensorValue == "0") {
      vibrateStop();
    }
  }
}
