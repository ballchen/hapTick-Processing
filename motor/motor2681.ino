int s0 = 11;
int s1 = 12;
int s2 = 13;
int vibrateTime = 50;
String sensorValue;
boolean vibrating = false;

void vibrate() {

  vibrating = true;
  digitalWrite(s2, 0);

  delay(vibrateTime);

  vibrating = false;
  digitalWrite(s2, 1);
}

void vibrateStop() {
  digitalWrite(s2, 1);
}

void vibrateStart() {
  digitalWrite(s2, 0);
}

void setup() {
  // put your setup code here, to run once: 
  pinMode(s2, OUTPUT);
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
