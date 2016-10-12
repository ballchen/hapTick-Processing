import processing.net.*; 
import processing.serial.*;
import java.util.Arrays;

Server myServer;
Serial Port;
String dataIn;
PFont f;

boolean debug = true;


// basic struct
class Point {
  double x, y, z;
  Point (double sx, double sy, double sz) {
    x = sx;
    y = sy;
    z = sz;
  }

  double[] getPoint() {
    double[] arr = new double[3];
    arr[0] = x;
    arr[1] = y;
    arr[2] = z;
    return arr;
  }
}

// store front back normalized score
class FBDist {
  double front, back;
  FBDist (double f, double b) {
    front = f;
    back = b;
  }

  double Front() {
    return front;
  }

  double Back() {
    return back;
  }
}

// a 1D coordinate system

class Cord {
  double start, end;
  Cord(double s, double e) {
    start = s;
    end = e;
  }

  //2 8 -> 0 10
  double mapTo(double input, double grad) {
    if(input < start) {
      return 0;
    }
    
    if(input > end) {
      return grad;
    }

    return Math.floor((input - start) / (end - start) * grad);
  }
  
  boolean isOnLine(double input) {
    if(input < start || input > end) {
      return false;
    }
    return true;
  }
}


double[] base  = new double[3];
double[] middle = new double[3];
double[] thumb = new double[3];
double[] top = new double[3];

/////////////////functions return//////////////
double[] vector = new double[3];
double[] unit = new double[3];
double[] scale = new double[3];
double[] add = new double[3];
double[] sub = new double[3];
double[] cross = new double[3];
//////////////////////////////////////////////

//////////////vectors in pnt2line////////////
double[] line_vec = new double[3];
double[] pnt_vec = new double[3];
double[] line_unitvec = new double[3];
double[] pnt_vec_scaled = new double[3];
double[] nearest = new double[3];
double dist;
/////////////////////////////////////////////

/////////////vectors in getposition////////////
double[] nearestPointOnLine  = new double[3];
double[] mv1 = new double[3];
double[] mv2 = new double[3];
double[] movecentral = new double[3];
double[] movecentral_unitvec = new double[3];
double[] movescale = new double[3];
double[] center = new double[3];
double[] yvector = new double[3];
double[] vt = new double[3];
///////////////////////////////////////////////

double[] pointAtfrontLine = new double[3];
double[] pointAtbackLine = new double[3];

double frontDist;
double backDist;

double frontDist_last;
double backDist_last;

int trackmode = 0; //0: nothing, 1: front, 2: center, 3: back;
int trackCounter = 0;

Point[] frontPnts = new Point[100];
Point[] centerPnts = new Point[100];
Point[] backPnts = new Point[100];

FBDist[] frontFBDists = new FBDist[100];
FBDist[] centerFBDists = new FBDist[100];
FBDist[] backFBDists = new FBDist[100];

Point trackFrontPnt;
Point trackCenterPnt;
Point trackBackPnt;

FBDist trackFrontDist;
FBDist trackCenterDist;
FBDist trackBackDist;

Cord fCord;
Cord bCord;


//front back
double[] lastPos = new double[2];
double[] currentPos = new double[2];


//////////////////////////////////////////////


double x = 0, y = 0;
double dans = 18.98, dia = 6.5; //input parameters
int disth = 70; //distance threshold in mm
double ymlwb = 40, ymupb = 120, yblwb = 40, ybupb = 120; //input parameter y upper and lower bounds in middle and base
double y1 = (ymupb + ymlwb)/2, y2 = (ybupb + yblwb)/2;
double m1 = (y2 - y1)/10;
double y3 = ((ymupb - ymlwb)/3) + ymlwb, y4 = ((ybupb - yblwb)/3) + yblwb;
double m2 = (y4 - y3)/10;
double y5 = (((ymupb - ymlwb)/3) * 2) + ymlwb, y6 = (((ybupb - yblwb)/3) * 2) + yblwb;
double m3 = (y6 - y5)/10;
int mode = 0; // mode 0: no segtouch, 1: 3, 2: 4, 3: 4+3, 4: 4+4, 5: 3+3+3

double dot(double ax, double ay, double az, double bx, double by, double bz) {
  return ((ax * bx) + (ay * by) + (az * bz));
}

double length(double ax, double ay, double az) {
  return Math.sqrt((ax * ax) + (ay * ay) + (az * az));
}

void vector(double ax, double ay, double az, double bx, double by, double bz) {
  vector = new double[3];
  vector[0] = bx - ax;
  vector[1] = by - ay;
  vector[2] = bz - az;
}

void unit(double ax, double ay, double az) {
  unit = new double[3];
  double mag = length(ax, ay, az);
  unit[0] = ax/mag;
  unit[1] = ay/mag;
  unit[2] = az/mag;
}

double distance(double ax, double ay, double az, double bx, double by, double bz) {
  vector(ax, ay, az, bx, by, bz);
  return length(vector[0], vector[1], vector[2]);
}

void scale(double ax, double ay, double az, double sc) {
  scale = new double[3];
  scale[0] = ax * sc;
  scale[1] = ay * sc;
  scale[2] = az * sc;
}

void add(double ax, double ay, double az, double bx, double by, double bz) {
  add = new double[3];
  add[0] = ax + bx;
  add[1] = ay + by;
  add[2] = az + bz;
}

void sub(double ax, double ay, double az, double bx, double by, double bz) {
  sub = new double[3];
  sub[0] = ax + bx;
  sub[1] = ay + by;
  sub[2] = az + bz;
}

void pnt2line(double pntx, double pnty, double pntz, double startx, double starty, double startz, double endx, double endy, double endz) {
  line_vec = new double[3];
  pnt_vec = new double[3];
  line_unitvec = new double[3];
  pnt_vec_scaled = new double[3];
  nearest = new double[3];
  dist = 0;

  vector(startx, starty, startz, endx, endy, endz);
  line_vec = vector;

  vector(startx, starty, startz, pntx, pnty, pntz);
  pnt_vec = vector;

  double line_len = length(line_vec[0], line_vec[1], line_vec[2]);

  unit(line_vec[0], line_vec[1], line_vec[2]);
  line_unitvec = unit;

  scale(pnt_vec[0], pnt_vec[1], pnt_vec[2], 1.0/line_len);
  pnt_vec_scaled = scale;

  double t = dot(line_unitvec[0], line_unitvec[1], line_unitvec[2], pnt_vec_scaled[0], pnt_vec_scaled[1], pnt_vec_scaled[2]);    

  scale(line_vec[0], line_vec[1], line_vec[2], t); //projected vector
  nearest = scale;

  dist = distance(nearest[0], nearest[1], nearest[2], pnt_vec[0], pnt_vec[1], pnt_vec[2]); 
  // print("distance: " +dist + "\n");

  add(nearest[0], nearest[1], nearest[2], startx, starty, startz); // normalized x
  nearest = add;
}

double[] pnt2lineVector(double pntx, double pnty, double pntz, double startx, double starty, double startz, double endx, double endy, double endz) {
  line_vec = new double[3];
  pnt_vec = new double[3];
  line_unitvec = new double[3];
  pnt_vec_scaled = new double[3];
  nearest = new double[3];
  dist = 0;

  vector(startx, starty, startz, endx, endy, endz);
  line_vec = vector;

  vector(startx, starty, startz, pntx, pnty, pntz);
  pnt_vec = vector;

  double line_len = length(line_vec[0], line_vec[1], line_vec[2]);

  unit(line_vec[0], line_vec[1], line_vec[2]);
  line_unitvec = unit;

  scale(pnt_vec[0], pnt_vec[1], pnt_vec[2], 1.0/line_len);
  pnt_vec_scaled = scale;

  double t = dot(line_unitvec[0], line_unitvec[1], line_unitvec[2], pnt_vec_scaled[0], pnt_vec_scaled[1], pnt_vec_scaled[2]);    

  scale(line_vec[0], line_vec[1], line_vec[2], t); //projected vector
  nearest = scale;

  dist = distance(nearest[0], nearest[1], nearest[2], pnt_vec[0], pnt_vec[1], pnt_vec[2]); 
  // print("distance: " +dist + "\n");

  add(nearest[0], nearest[1], nearest[2], startx, starty, startz); // normalized x
  nearest = add;
  return add;
}

void cross(double ax, double ay, double az, double bx, double by, double bz) {
  cross = new double[3];
  cross[0] = (ay * bz) - (by * az);
  cross[1] = (bx * az) - (ax * bz);
  cross[2] = (ax * by) - (bx * ay);
}

void getpositionOf2Line() {

  pointAtfrontLine = pnt2lineVector(thumb[0], thumb[1], thumb[2], middle[0], middle[1], middle[2], base[0], base[1], base[2]);
  pointAtbackLine = pnt2lineVector(thumb[0], thumb[1], thumb[2], top[0], top[1], top[2], base[0], base[1], base[2]);
  
  frontDist_last = frontDist;
  backDist_last = backDist;
  
  frontDist = (distance(middle[0], middle[1], middle[2], pointAtfrontLine[0], pointAtfrontLine[1], pointAtfrontLine[2]) / (distance(base[0], base[1], base[2], middle[0], middle[1], middle[2]) /10.0));
  backDist = (distance(top[0], top[1], top[2], pointAtbackLine[0], pointAtbackLine[1], pointAtbackLine[2]) / (distance(base[0], base[1], base[2], top[0], top[1], top[2]) /10.0));
}

void getposition() {
  // middle translation (3)
  // base translation (3)
  // thumb translation (3)
  // object rotation (3)

  nearestPointOnLine = new double[3];
  pnt2line(thumb[0], thumb[1], thumb[2], middle[0], middle[1], middle[2], base[0], base[1], base[2]);
  nearestPointOnLine = nearest;


  //normalized x
  x = (distance(middle[0], middle[1], middle[2], nearestPointOnLine[0], nearestPointOnLine[1], nearestPointOnLine[2]) / (distance(middle[0], middle[1], middle[2], base[0], base[1], base[2]) /10.0));

  //normalized y
  mv1 = new double[3];
  mv2 = new double[3];
  vector(base[0], base[1], base[2], top[0], top[1], top[2]);
  mv1 = vector;
  vector(base[0], base[1], base[2], middle[0], middle[1], middle[2]);
  mv2 = vector;
  movecentral = new double[3];
  cross(mv1[0], mv1[1], mv1[2], mv2[0], mv2[1], mv2[2]);
  movecentral = cross;

  movecentral_unitvec = new double[3];
  unit(movecentral[0], movecentral[1], movecentral[2]);
  movecentral_unitvec = unit;   
  /////////////////////////////////////////////////////////////
  double movelength = (dans + 5) - dia;  //input move length in mm
  /////////////////////////////////////////////////////////////

  movescale = new double[3];
  scale(movecentral_unitvec[0], movecentral_unitvec[1], movecentral_unitvec[2], movelength);
  movescale = scale;

  center = new double[3];
  add(nearestPointOnLine[0], nearestPointOnLine[1], nearestPointOnLine[2], movescale[0], movescale[1], movescale[2]);
  center = add;

  vector(center[0], center[1], center[2], thumb[0], thumb[1], thumb[2]);
  yvector = vector;

  vt = new double[3];
  vector(base[0], base[1], base[2], top[0], top[1], top[2]);
  vt = vector;
  double ydot = dot(yvector[0], yvector[1], yvector[2], vt[0], vt[1], vt[2]);
  y = Math.toDegrees(Math.acos(ydot/(length(yvector[0], yvector[1], yvector[2]) * length(vt[0], vt[1], vt[2]))));
}

int segcursor() {
  int cur = -1;  //no cursor shown
  if (dist <= disth) {
    double yth = y1 + (m1 * x); //y threshold
    double yth1 = y3 + (m2 * x); //y threshold 3 - 1
    double yth2 = y5 + (m3 * x); //y threshold 3 - 2
    if (mode == 0) {
      cur = 0;
    } else if (mode == 1) {  //1D 3 buttons
      double tmp = 10.0/3.0;
      if (x < tmp) {
        cur =  0;
      } else if ((tmp <= x) && (x < (2 * tmp))) {
        cur = 1;
      } else if ((2 * tmp) <= x) {
        cur = 2;
      }
    } else if (mode == 2) {  //1D 4 buttons
      double tmp = 10.0/4.0;
      if (x < tmp) {
        cur =  0;
      } else if ((tmp <= x) && (x < (2 * tmp))) {
        cur = 1;
      } else if (((2 * tmp) <= x) && (x < (3 * tmp))) {
        cur = 2;
      } else if ((3 * tmp) <= x) {
        cur = 3;
      }
    } else if (mode == 3) {  //4+3 buttons
      if (y < yth) {
        double tmp = 10.0/4.0;
        if (x < tmp) {
          cur = 0;
        } else if ((tmp <= x) && (x < (2 * tmp))) {
          cur = 1;
        } else if (((2 * tmp) <= x) && (x < (3 * tmp))) {
          cur = 2;
        } else if ((3 * tmp) <= x) {
          cur = 3;
        }
      } else if (y >= yth) {
        double tmp = 10.0/3.0;
        if (x < tmp) {
          cur = 4;
        } else if ((tmp <= x) && (x < (2 * tmp))) {
          cur = 5;
        } else if ((2 * tmp) <= x) {
          cur = 6;
        }
      }
    } else if (mode == 4) {  //4+4 buttons
      if (y < yth) {
        double tmp = 10.0/4.0;
        if (x < tmp) {
          cur = 0;
        } else if ((tmp <= x) && (x < (2 * tmp))) {
          cur = 1;
        } else if (((2 * tmp) <= x) && (x < (3 * tmp))) {
          cur = 2;
        } else if ((3 * tmp) <= x) {
          cur = 3;
        }
      } else if (y >= yth) {
        double tmp = 10.0/4.0;
        if (x < tmp) {
          cur = 4;
        } else if ((tmp <= x) && (x < (2 * tmp))) {
          cur = 5;
        } else if (((2 * tmp) <= x) && (x < (3 * tmp))) {
          cur = 6;
        } else if ((3 * tmp) <= x) {
          cur = 7;
        }
      }
    } else if (mode == 5) {  //3+3+3
      if (y < yth1) {
        double tmp = 10.0/3.0;
        if (x < tmp) {
          cur = 0;
        } else if ((tmp <= x) && (x < (2 * tmp))) {
          cur = 1;
        } else if ((2 * tmp) <= x) {
          cur = 2;
        }
      } else if (yth1 <= y && y < yth2) {
        double tmp = 10.0/3.0;
        if (x < tmp) {
          cur = 3;
        } else if ((tmp <= x) && (x < (2 * tmp))) {
          cur = 4;
        } else if ((2 * tmp) <= x) {
          cur = 5;
        }
      } else if (yth2 < y) {
        double tmp = 10.0/3.0;
        if (x < tmp) {
          cur = 6;
        } else if ((tmp <= x) && (x < (2 * tmp))) {
          cur = 7;
        } else if ((2 * tmp) <= x) {
          cur = 8;
        }
      }
    }
  } else {
    cur = -1;
  }
  return cur;
}

void trackBasic(int tmode) {
  //mode 1: f, 2: c, 3: b
  trackmode = tmode;
  trackCounter = 0;
  if(tmode == 1) {
    frontPnts = new Point[100];
  } else if(tmode == 2) {
    centerPnts = new Point[100];
  } else if(tmode == 3) {
    backPnts = new Point[100];
  } 
  
}

void trackFront() {
  trackmode = 1;
  trackCounter = 0;
  frontPnts = new Point[100];
}

void trackEnd() {
  trackmode = 0;
}

Point calculateMeanPnt(Point[] pnts) {
  double sumX = 0;
  double sumY = 0; 
  double sumZ = 0;

  for(int i = 0; i < 100; i ++) {
    sumX += pnts[i].getPoint()[0];
    sumY += pnts[i].getPoint()[1];
    sumZ += pnts[i].getPoint()[2];
  }
  double meanX = sumX / 100;
  double meanY = sumY / 100;
  double meanZ = sumZ / 100;

  Point meanPnt = new Point(meanX, meanY, meanZ);
  return meanPnt;
}

FBDist calculateMeanDist(FBDist[] data) {
  double sumFront = 0;
  double sumBack = 0;

  for(int i = 0; i < 100; i ++) {
    sumFront += data[i].Front();
    sumBack += data[i].Back();
  }

  double meanFront = sumFront / 100;
  double meanBack = sumBack / 100;

  FBDist meanDist = new FBDist(meanFront, meanBack);
  return meanDist;
}



void parseInput(String input) {
  String[] inputObjs = input.split(",");
  //print(Arrays.toString(inputObjs));
  if (inputObjs.length == 12) {
    try {
      middle[0] = Double.parseDouble(inputObjs[0]);
      middle[1] = Double.parseDouble(inputObjs[1]);
      middle[2] = Double.parseDouble(inputObjs[2]);

      base[0] = Double.parseDouble(inputObjs[3]);
      base[1] = Double.parseDouble(inputObjs[4]);
      base[2] = Double.parseDouble(inputObjs[5]);

      thumb[0] = Double.parseDouble(inputObjs[6]);
      thumb[1] = Double.parseDouble(inputObjs[7]);
      thumb[2] = Double.parseDouble(inputObjs[8]);

      top[0] = Double.parseDouble(inputObjs[9]);
      top[1] = Double.parseDouble(inputObjs[10]);
      top[2] = Double.parseDouble(inputObjs[11]);
    } catch(Exception e) {
      println(e);
    }
  }
}

void printPoints() {
  println("--");
  println("front: " + Arrays.toString(middle));
  println("back: " + Arrays.toString(top));
  println("center: " + Arrays.toString(base));
  println("thumb: " + Arrays.toString(thumb));
  println("--");
}

void drawPoints() {

  text("front: " + Arrays.toString(middle), 10, 30);
  text("back: " + Arrays.toString(top), 10, 50);
  text("center: " + Arrays.toString(base), 10, 70);
  text("thumb: " + Arrays.toString(thumb), 10, 90);
}

void drawDist() {

  text("frontDist: " + frontDist, 10, 110);
  text("backDist: " + backDist, 10, 130);
  text("frontDist_last: " +frontDist_last, 10, 150);
  text("backDist_last: " + backDist_last, 10, 170);
}

void drawTrackedDists() {

  double[] output;

  if(trackFrontDist != null) {
    String result = String.format("Tracked_front: (%.4f, %.4f)", trackFrontDist.Front(), trackFrontDist.Back());
    text(result, 10, 190);
  }

  if(trackBackDist != null) {
    String result = String.format("Tracked_back: (%.4f, %.4f)", trackBackDist.Front(), trackBackDist.Back());
    text(result, 10, 210);
  }

  if(trackCenterDist != null) {
    String result = String.format("Tracked_center: (%.4f, %.4f)", trackCenterDist.Front(), trackCenterDist.Back());
    text(result, 10, 230);
  }
}

// arduino serial communication functions

void send_vibrate_msg () {
  Port.write("1\n");
}

void send_vibrate_stop_msg () {
  Port.write("0\n");
}

void debug_print_msg() {
  String val = Port.readStringUntil('\n');
  if(val != "") {
    println(val);
  }
}

// arduino end

void setup() {

  // basic setup --start
  size(400, 400);
  frameRate(30);
  f = createFont("Arial", 16, true); 
  textFont(f);       
  fill(255);
  // basic setup --end


  myServer = new Server(this, 4000);

  // init serial port
  Port = new Serial(this, Serial.list()[1], 9600);

  middle[0] = 115.047778;
  middle[1] = -58.291351;
  middle[2] = 761.387865;

  base[0] = 121.028621;
  base[1] = -92.141674;
  base[2] = 804.555237;

  thumb[0] = 74.018567;
  thumb[1] = -74.773294;
  thumb[2] = 768.798023;

  top[0] = 109.604013;
  top[1] = -55.241005;
  top[2] = 839.272695;

  getposition();
  print("x: " + x + "\ny: " + y + "\n");
  mode = 4;
  print("cursor: " + segcursor()+"\n");
}

double getPosOnLine(double[] start, double[] end, double[] pnt) {
  return (distance(start[0], start[1], start[2], pnt[0], pnt[1], pnt[2]) / (distance(end[0], end[1], end[2], start[0], start[1], start[2]) /10.0));
}

double[] getFrontBackLinePos() {
  double[] result = new double[2];
  double[] tempPntFront = pnt2lineVector(thumb[0], thumb[1], thumb[2], middle[0], middle[1], middle[2], base[0], base[1], base[2]);
  double[] tempPntBack = pnt2lineVector(thumb[0], thumb[1], thumb[2], top[0], top[1], top[2], base[0], base[1], base[2]);
  double frontLinePos = getPosOnLine(middle, base, tempPntFront);
  double backLinePos = getPosOnLine(top, base, tempPntBack);

  result[0] = frontLinePos;
  result[1] = backLinePos;

  return result;
}

void draw() {
  background(200);

  stroke(255);
  fill(255);
  rect(10, 30, 70, 30);
  fill(0);
  text("setFront", 15, 50);

  fill(255);
  rect(170, 30, 70, 30);
  fill(0);
  text("setCent", 175, 50);

  fill(255);
  rect(90, 30, 70, 30);
  fill(0);
  text("setBack", 95, 50);


  
  
  
  Client someClient = myServer.available();
  if (someClient != null) {

    String dataInput = someClient.readString();
    parseInput(dataInput);
    //printPoints();
    //drawPoints();
    getpositionOf2Line();
    
    drawDist();

    switch(trackmode) {
      // no tracking
      case 0: 
        text("status: none", 10, 80); 
        break;
      
      // tracking front
      case 1:
        text("status: tracking front...", 10, 80); 
        if(trackCounter >= 100) {
          trackEnd();
          trackFrontDist = calculateMeanDist(frontFBDists);

        }
        else {
          double[] tempPntFront = pnt2lineVector(thumb[0], thumb[1], thumb[2], middle[0], middle[1], middle[2], base[0], base[1], base[2]);
          double[] tempPntBack = pnt2lineVector(thumb[0], thumb[1], thumb[2], top[0], top[1], top[2], base[0], base[1], base[2]);
          double frontLinePos = getPosOnLine(middle, base, tempPntFront);
          double backLinePos = getPosOnLine(top, base, tempPntBack);

          frontFBDists[trackCounter] = new FBDist(frontLinePos, backLinePos);

          trackCounter++;
        }
        break;

      case 2:
        text("status: tracking center...", 10, 80); 
        if(trackCounter >= 100) {
          trackEnd();
          trackCenterDist = calculateMeanDist(centerFBDists);

        }
        else {
          double[] tempPntFront = pnt2lineVector(thumb[0], thumb[1], thumb[2], middle[0], middle[1], middle[2], base[0], base[1], base[2]);
          double[] tempPntBack = pnt2lineVector(thumb[0], thumb[1], thumb[2], top[0], top[1], top[2], base[0], base[1], base[2]);
          double frontLinePos = getPosOnLine(middle, base, tempPntFront);
          double backLinePos = getPosOnLine(top, base, tempPntBack);

          centerFBDists[trackCounter] = new FBDist(frontLinePos, backLinePos);
          trackCounter++;
        }
        break;

      // tracking back
      case 3:
        text("status: tracking back...", 10, 80); 
        if(trackCounter >= 100) {
          trackEnd();
          trackBackDist = calculateMeanDist(backFBDists);
        }
        else {
          double[] tempPntFront = pnt2lineVector(thumb[0], thumb[1], thumb[2], middle[0], middle[1], middle[2], base[0], base[1], base[2]);
          double[] tempPntBack = pnt2lineVector(thumb[0], thumb[1], thumb[2], top[0], top[1], top[2], base[0], base[1], base[2]);
          double frontLinePos = getPosOnLine(middle, base, tempPntFront);
          double backLinePos = getPosOnLine(top, base, tempPntBack);

          backFBDists[trackCounter] = new FBDist(frontLinePos, backLinePos);
          trackCounter++;
        }
        break;
      
    }

    drawTrackedDists();

    //if tracked three dists , new front and back cord
    if(trackFrontDist!=null && trackBackDist!=null && trackCenterDist!=null) {
      fCord = new Cord(trackFrontDist.Front(), trackCenterDist.Front());
      bCord = new Cord(trackBackDist.Back(), trackCenterDist.Back());
      
      lastPos[0] = (currentPos[0]>0) ? currentPos[0]: 0;
      lastPos[1] = (currentPos[1]>0) ? currentPos[1]: 0;
      double[] pos = getFrontBackLinePos();
       
       

      currentPos = new double[2];
      boolean[] currentPntOnLine = new boolean[2];

      currentPos[0] = fCord.mapTo(pos[0], 3);
      currentPos[1] = bCord.mapTo(pos[1], 3);
      
      currentPntOnLine[0] = fCord.isOnLine(pos[0]);
      currentPntOnLine[1] = bCord.isOnLine(pos[1]);
      
      
      text(Arrays.toString(currentPos), 20, 250);
      text(Arrays.toString(currentPntOnLine), 20, 270);

      if((currentPos[0] != lastPos[0] && currentPntOnLine[0]) || 
         (currentPos[1] != lastPos[1] && currentPntOnLine[1])) {
        
        //
        // trigger the ring to buzz
        //
        send_vibrate_msg();
      }

    }

  } else {
    text("status: no connection", 10, 80); 
  }
}

void mouseClicked() {

  // set front 10, 30, 70, 30
  if(mouseX >= 10 && mouseX <= 80 && mouseY >= 30 && mouseY <= 60) {
    // println("front");
    trackBasic(1);
  }
  // set center
  if(mouseX >= 170 && mouseX <= 240 && mouseY >= 30 && mouseY <= 60) {
    // println("center");
    trackBasic(2);
  }
  // set back 
  if(mouseX >= 90 && mouseX <= 160 && mouseY >= 30 && mouseY <= 60) {
    // println("back");
    trackBasic(3);
  }
}

void serverEvent(Server someServer, Client someClient) {
  println("We have a new client: " + someClient.ip());
}