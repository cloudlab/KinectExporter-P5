
PImage texImg;

int xshift = -8;
int yshift = 25;
// Size of kinect image
int w = 640;
int h = 480;
float maxDist = 800;

// We're just going to calculate and draw every 4th pixel (equivalent of 160x120)
int skip = 8;

int[] depth;

boolean foundTexture = false;
boolean foundDepth = false;

void setup() {
  size(720, 480, P3D);
  selectInput("Select a kinect point data:", "pointDataSelected");
}


void pointDataSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } 
  else {
    println("User selected " + selection.getAbsolutePath());
    // Load depth data (text file in directory)
    String[] data = loadStrings(selection.getAbsolutePath());

    depth = new int[data.length];
    for (int i = 0; i < data.length; i++) {
      depth[i] = Integer.parseInt(data[i]);
    }

    foundDepth = true;

    selectInput("Select a kinect texture data:", "textureDataSelected");
  }
}

void textureDataSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } 
  else {
    println("User selected " + selection.getAbsolutePath());

    // Load texture (image file in directory)
    texImg = loadImage(selection.getAbsolutePath());

    foundTexture = true;
  }
}


void draw() {

  if (foundDepth && foundTexture) {
    background(255);
    // Define a camera
    float az = map(mouseX, 0, width, 0, TWO_PI);
    float al = map(mouseY, 0, height, -HALF_PI, HALF_PI);
    float zm = 500;
    camera(zm*cos(az)*cos(al), zm*sin(az)*cos(al), zm*sin(al), 0, 0, 0, 0, 0, -1);

    // Draw a xyz axis indicator
    stroke(255, 0, 0);
    line(0, 0, 0, 10, 0, 0);
    stroke(0, 255, 0);
    line(0, 0, 0, 0, 10, 0);
    stroke(0, 0, 255);
    line(0, 0, 0, 0, 0, 10);

    // Rotate the geometry and draw
    rotateX(-HALF_PI);
    translate(-w/2, -h/2, 800);
    drawBody();
  }
}


void drawBody() {
  stroke(255, 10);
  for (int x=0; x<(w-skip); x+=skip) {
    for (int y=0; y<(h-skip); y+=skip) {

      int offset = x+y*w;
      int offset2 = (x+skip)+y*w;
      int offset3 = (x+skip)+(y+skip)*w;
      int offset4 = x+(y+skip)*w;

      // Convert kinect data to world xyz coordinate
      int rawDepth = depth[offset];
      PVector v = new PVector(x, y, rawDepth);

      int rawDepth2 = depth[offset2];
      PVector v2 = new PVector((x+skip), y, rawDepth2);

      int rawDepth3 = depth[offset3];
      PVector v3 = new PVector((x+skip), (y+skip), rawDepth3);

      int rawDepth4 = depth[offset4];
      PVector v4 = new PVector(x, (y+skip), rawDepth4);

      float factor = 1.f;
      if (rawDepth4 < maxDist && rawDepth3 < maxDist && rawDepth2 < maxDist && rawDepth < maxDist) {
        beginShape(QUAD); 
        texture(texImg);
        vertex(v.x*factor, v.y*factor, factor-v.z*factor, x +xshift, y+yshift);
        vertex(v2.x*factor, v2.y*factor, factor-v2.z*factor, (x+skip)+xshift, y+yshift);
        vertex(v3.x*factor, v3.y*factor, factor-v3.z*factor, x+skip+xshift, y+skip+yshift);
        vertex(v4.x*factor, v4.y*factor, factor-v4.z*factor, x+xshift, (y+skip)+yshift);
        endShape();
      }
    }
  }
}

