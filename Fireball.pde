public class Fireball {
  PVector pos;
  float angle; // radians
  PImage img;
  
  float fireballWidth = 30;
  float fireballHeight = fireballWidth * 188 / 178;
  
  Fireball(PImage img, PVector playerPos) {
    this.img = img;
    
    int side = (int)random(4);
    float x, y;
    switch (side) {
    case 0:
      // top
      x = random(width);
      pos = new PVector(x, 0);
      break;
    case 1:
      // bottom
      x = random(width);
      pos = new PVector(x, height);
      break;
    case 2:
      // left
      y = random(height);
      pos = new PVector(0, y);
      break;
    case 3:
      // right
      y = random(height);
      pos = new PVector(width, y);
      break;
    default:
      return;
    }
    
    float centerAngle = atan2(playerPos.y - pos.y, playerPos.x - pos.x);
    this.angle = centerAngle + random((float)-Math.PI/7, (float)Math.PI/7);
  }
  
  void updatePos(float len) {
    float dx = len * cos(angle);
    float dy = len * sin(angle);
    this.pos = new PVector(pos.x + dx, pos.y + dy);
  }
  
  void drawFireball() {
    noStroke();
    image(img, pos.x - fireballWidth / 2, pos.y - fireballHeight / 2, fireballWidth, fireballHeight);
  }
  
  boolean intersectsWithRect(PVector rectPos, float wid, float hei) {
    float closestX = constrain(pos.x, rectPos.x, rectPos.x + wid);
    float closestY = constrain(pos.y, rectPos.y, rectPos.y + hei);
    
    double distanceSq = Math.pow(pos.x - closestX, 2) + Math.pow(pos.y - closestY, 2);
    return distanceSq < Math.pow((fireballWidth + fireballHeight) / 4, 2);
  }
}
