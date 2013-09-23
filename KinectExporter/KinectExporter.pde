import processing.dxf.*;
PrintWriter output;
import org.openkinect.*;
import org.openkinect.processing.*;
String prefix = "export";

// Kinect Library object
Kinect kinect;
int recordTimer = 0;
boolean record = false;
float a = 0;
int xshift = -8;
int yshift = 25;
// Size of kinect image
int w = 640;
int h = 480;
float maxDist = 0;

// We'll use a lookup table so that we don't have to repeat the math over and over
float[] depthLookUp = new float[2048];

void setup() {
  
  size(1024, 768, P3D);
  
  kinect = new Kinect(this);
  kinect.start();
  kinect.enableDepth(true);
  kinect.enableRGB(true);
  kinect.processDepthImage(false);

  for (int i = 0; i < depthLookUp.length; i++) {
    depthLookUp[i] = rawDepthToMeters(i);
  }
}

void draw() {

  PImage img = kinect.getVideoImage();
  if (record) img.save(prefix+"_texture.png");

  //image(img,0,0);
  maxDist = 800;

  background(0);
  
  int[] depth = kinect.getRawDepth();
  if (record) {
    output = createWriter(prefix+"_positions.txt"); 
    for (int i=0; i<depth.length; i++) {
      output.println(depth[i]);  // Write the coordinate to the file
    }
    output.flush();  // Writes the remaining data to the file
    output.close();  // Finishes the file
  }
  int skip = 8;

  translate(width/2, height/2, -50);
  rotateY(mouseX/90.0f);
  scale(4);

  if (record)
    beginRaw(DXF, prefix+"_geometry.dxf"); 

  for (int x=0; x<(w-skip); x+=skip) {

    for (int y=0; y<(h-skip); y+=skip) {

      int offset = x+y*w;
      int offset2 = (x+skip)+y*w;
      int offset3 = (x+skip)+(y+skip)*w;
      int offset4 = x+(y+skip)*w;

      // Convert kinect data to world xyz coordinate
      int rawDepth = depth[offset];
      PVector v = depthToWorld(x, y, rawDepth);

      int rawDepth2 = depth[offset2];
      PVector v2 = depthToWorld((x+skip), y, rawDepth2);

      int rawDepth3 = depth[offset3];
      PVector v3 = depthToWorld((x+skip), (y+skip), rawDepth3);

      int rawDepth4 = depth[offset4];
      PVector v4 = depthToWorld(x, (y+skip), rawDepth4);
      if (record)noStroke();
      else
        stroke(100);
      float factor = 200;
      if (rawDepth4 < maxDist && rawDepth3 < maxDist && rawDepth2 < maxDist && rawDepth < maxDist) {
        beginShape(QUAD); 
        texture(img);

        vertex(v.x*factor, v.y*factor, factor-v.z*factor, x +xshift, y+yshift);
        vertex(v2.x*factor, v2.y*factor, factor-v2.z*factor, (x+skip)+xshift, y+yshift);
        vertex(v3.x*factor, v3.y*factor, factor-v3.z*factor, x+skip+xshift, y+skip+yshift);
        vertex(v4.x*factor, v4.y*factor, factor-v4.z*factor, x+xshift, (y+skip)+yshift);
        endShape();
      }
    }
  }

  if (record) {
    endRaw();
    saveFrame(prefix+"_render.png");
    record = false;
  }

  recordTimer++;
  // Rotate
  a += 0.015f;
}

// These functions come from: http://graphics.stanford.edu/~mdfisher/Kinect.html
float rawDepthToMeters(int depthValue) {
  if (depthValue < 2047) {
    return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
  }
  return maxDist;
}

PVector depthToWorld(int x, int y, int depthValue) {

  final double fx_d = 1.0 / 5.9421434211923247e+02;
  final double fy_d = 1.0 / 5.9104053696870778e+02;
  final double cx_d = 3.3930780975300314e+02;
  final double cy_d = 2.4273913761751615e+02;

  PVector result = new PVector();
  double depth =  depthLookUp[depthValue];//rawDepthToMeters(depthValue);
  result.x = (float)((x - cx_d) * depth * fx_d);
  result.y = (float)((y - cy_d) * depth * fy_d);
  result.z = (float)(depth);
  return result;
}

void mousePressed() {
  if (recordTimer > 30) {
    record = true;
    recordTimer = 0;
  }
}

void stop() {
  kinect.quit();
  super.stop();
}

