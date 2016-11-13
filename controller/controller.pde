import processing.serial.*;
import controlP5.*;

ControlP5 cp5;
controlP5.Button button;

Serial Port;
boolean debug = false;
int areaNum = 10;
int barHeight = 50;
int columnWidth = 50;

//define boundary
int barBoundaryLeft    = 30; 
int barBoundaryRight   = 30 + columnWidth*areaNum;
int barBoundaryTop     = 20;
int barBoundaryBottom  = 20 + barHeight;

boolean isMouseInBar = false;

// -1: outside
int position = -1;


void send_vibrate_msg () {
  Port.write("1\n");
}

void send_vibrate_stop_msg () {
  Port.write("0\n");
}

void setup() {
  frameRate(60);
  Port = new Serial(this, Serial.list()[0], 9600);
  println(Serial.list()[0]);
  Port.write("0\n");
  
  cp5 = new ControlP5(this);
  
  cp5.addButton("button")
     .setValue(10)
     .setPosition(20,90)
     .setSize(100,30)
     .setId(1);
  
  
  size(600, 200);
  background(255);
  drawBar();
}

void debug_print_msg() {
  String val = Port.readStringUntil('\n');
  if(val != "") {
    println(val);
  }
}

void drawBar() {
  
  stroke(155);
  fill(255);
  
  for(int i = 0; i < areaNum; i ++) {
     rect(barBoundaryLeft + columnWidth*i, barBoundaryTop, columnWidth, barHeight);
  }
}

void updateColumn() {
  if(!updateMouse()) {
    position = -1;
    return;
  }
  
  float axisX = (mouseX-barBoundaryLeft);
  int newPos = floor(axisX/columnWidth);
  if(newPos != position) {
    send_vibrate_msg();
  }
  position = newPos;
}

boolean updateMouse() {
  if(mouseX > barBoundaryLeft && mouseX < barBoundaryRight
    && mouseY > barBoundaryTop && mouseY < barBoundaryBottom) {
    return true; 
  }
  else {
    return false;
  }
}

void VibrationTriggerListener() {
  if(isMouseInBar != updateMouse()) {
     //trigger vibration
     send_vibrate_msg();
  }
  
  //update isMouseInBar
  isMouseInBar = updateMouse();
}

void draw() {
  //VibrationTriggerListener();
  updateColumn();
  if(debug) {
    debug_print_msg();
  }
  
}
  