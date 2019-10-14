import ddf.minim.*;

import SimpleOpenNI.*;
import java.util.*;

// The kinect stuff is happening in another class
SimpleOpenNI ctx;
KinectTracker tracker;

ArrayList<Fireball> fireballs = new ArrayList<Fireball>();
int startTime;
int lastDrawTime;
int lastDotReleaseTime;
int lastArrowCheckTime;
boolean isBreathing = false;
int breathTime = 0;
int breathX;
float releaseThreshold; // ms
boolean gameOver = false;
boolean justEnded = false;
PVector gameOverPos;
int gameOverTime = 0;
int pauseStartTime = -1;
PVector pausePos;

PImage bgImage;
PImage fireballImage;
PImage bobOmbImage;
PImage breathImage;
Minim minim;
AudioPlayer bgMusic;
AudioPlayer explodeFX;

float origFireballReleaseThreshold = 1000;
float minReleaseThreshold = 100;
float decreaseFactor = 6; // ms/s
float fireballSpeed = 200; // px/s
int maxGameOverTime = 5000;
int arrowInterval = 1000;
int arrowDuration = 3000;
int breathDuration = 14000;
float arrowChance = (float)1 / 5;
boolean useKinect = false;

float playerHeight = 50;
float playerWidth = playerHeight * 180 / 226;
int fireWidth = 60;
int fireHeight = fireWidth * 810 / 60;

void initializeVariables() {
  int currTime = millis();
  startTime = currTime;
  lastDrawTime = currTime;
  lastDotReleaseTime = currTime;
  lastArrowCheckTime = currTime;
  releaseThreshold = origFireballReleaseThreshold;
  fireballs.clear();
  isBreathing = false;
  
  bgMusic.rewind();
  bgMusic.loop();
}

void setup() {
  size(800, 600);
  if (useKinect) {
    ctx = new SimpleOpenNI(this);
    ctx.enableDepth();
    tracker = new KinectTracker();
  }
  bgImage = loadImage("Background.png");
  fireballImage = loadImage("Fireball.png");
  bobOmbImage = loadImage("Bob-omb.png");
  breathImage = loadImage("Breath.png");
  
  minim = new Minim(this);
  bgMusic = minim.loadFile("Music.mp3");
  bgMusic.loop();
  
  explodeFX = minim.loadFile("Explode.mp3");
  
  initializeVariables();
}

void draw() {
  image(bgImage, 0, 0, width, height);
  if (useKinect) {
    tracker.track();
  }
  
  PVector currPos;
  if (useKinect) {
    currPos = tracker.getPos();
  } else {
    currPos = new PVector((float)mouseX, (float)mouseY);
  }
  
  PVector pos = gameOver ? gameOverPos : (pausePos != null) ? pausePos : currPos;
  
  image(bobOmbImage, pos.x - playerWidth / 2, pos.y - playerHeight / 2, playerWidth, playerHeight);
  
  int currTime = millis();
  
  boolean needsPause = (currPos.x < 15 || currPos.x > (width - 15) || currPos.y < 15 || currPos.y > (height - 15));
  
  if (needsPause && pauseStartTime == -1) {
    pauseStartTime = currTime;
    pausePos = currPos;
    bgMusic.pause();
  } else if (!needsPause && pauseStartTime != -1) {
    int pauseTimeDiff = (currTime - pauseStartTime);
    breathTime += pauseTimeDiff;
    if (!gameOver && !justEnded) {
      startTime += pauseTimeDiff;
      bgMusic.play();
    }
    pauseStartTime = -1;
    pausePos = null;
  }
  boolean isPaused = (pauseStartTime != -1);
  
  // end in the frame after the one in which the user dies
  if (justEnded) {
    gameOver = true;
    gameOverTime = currTime;
    gameOverPos = pos;

    fireballs.clear();
    releaseThreshold = Integer.MAX_VALUE;
    bgMusic.pause();
    
    explodeFX.rewind();
    explodeFX.play();

    justEnded = false;
  }
  
  if (gameOver) {
    fill(249, 177, 9);
    textSize(40);
    textAlign(CENTER, CENTER);
    text("Game over!", width / 2, height / 2);
    if (!isPaused && (currTime - gameOverTime) > maxGameOverTime) {
      gameOver = false;
      initializeVariables();
    }
  }
  
  // draw breath/arrow if needed
  if (isBreathing && !gameOver) {
    int timeSinceBreathStart;
    if (isPaused) {
      timeSinceBreathStart = pauseStartTime - breathTime;
    } else {
      timeSinceBreathStart = currTime - breathTime;
    }
    if (timeSinceBreathStart < arrowDuration) {
      int x = (int)map(timeSinceBreathStart, 0, arrowDuration, width / 2, breathX);
      int arrowWidth = 20;
      fill(255, 0, 0);
      triangle(x, arrowWidth, x - arrowWidth / 2, arrowWidth / 2, x + arrowWidth / 2, arrowWidth / 2);
    } else if (timeSinceBreathStart < (arrowDuration + breathDuration)) {
      int timeSinceFireStart = timeSinceBreathStart - arrowDuration;
      int breathOffset = (int)map(timeSinceFireStart, 0, breathDuration, 0, fireHeight + height);
      
      float fireLeft = breathX - fireWidth / 2;
      float fireRight = fireLeft + fireWidth;
      float fireTop = breathOffset - fireHeight;
      float fireBottom = fireTop + fireHeight;
      image(breathImage, fireLeft, fireTop);
      
      float playerTop = pos.y;
      float playerBottom = pos.y + playerHeight;
      float playerLeft = pos.x;
      float playerRight = pos.x + playerWidth;
      
      if (fireLeft <= playerRight && fireRight >= playerLeft && fireTop <= playerBottom && fireBottom >= playerTop) {
        justEnded = true;
      }
    } else {
      isBreathing = false;
      lastArrowCheckTime = currTime;
    }
  } else if (!isPaused && (currTime - lastArrowCheckTime) > arrowInterval) {
    lastArrowCheckTime = currTime;
    if (random(1) < arrowChance) {
      isBreathing = true;
      breathTime = currTime;
      breathX = (int)constrain(random(pos.x - 60, pos.x + 60), 100, width - 100);
    }
  }
  
  // draw fireballs
  int timeChangeMS = isPaused ? 0 : currTime - lastDrawTime;
  float timeChangeS = (float)timeChangeMS / 1000;
  
  if (!isPaused && currTime - lastDotReleaseTime > releaseThreshold) {
    if (releaseThreshold > minReleaseThreshold) {
      releaseThreshold -= (decreaseFactor / 1000) * (currTime - lastDotReleaseTime); 
    }
    lastDotReleaseTime = currTime;
    int numFireballs = 1 + (int)random(0, 2);
    for (int i = 1; i <= numFireballs; i++) {
      fireballs.add(new Fireball(fireballImage, pos));
    }
  }
  
  float dist = fireballSpeed * timeChangeS;
  Iterator<Fireball> fIterator = fireballs.iterator();
  while (fIterator.hasNext()) {
    Fireball f = fIterator.next();

    f.drawFireball();
    f.updatePos(dist);
    
    if (!f.intersectsWithRect(new PVector(0, 0), width, height)) {
      fIterator.remove();
    } else if (f.intersectsWithRect(new PVector(pos.x - 4, pos.y), playerWidth - 12, playerHeight - 15)) {
      justEnded = true;
      break;
    }
  }
  
  lastDrawTime = currTime;
  
  fill(249, 177, 9);
  textSize(20);
  int timeToUse;
  if (gameOver) timeToUse = gameOverTime;
  else if (isPaused) timeToUse = pauseStartTime;
  else timeToUse = currTime;
  textAlign(LEFT);
  text("Time: " + ((timeToUse - startTime) / 1000) + "s", 10, 25);
}
