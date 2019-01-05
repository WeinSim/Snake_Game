import processing.sound.*;
SqrOsc Sm = new SqrOsc(this);
SqrOsc Se = new SqrOsc(this);
SawOsc Sf = new SawOsc(this);

int [] [] tilemap = new int [32] [18];  //normal tilemap || 0-63: normal size (20x20), 64: miature size (10x10); see mtilemap
int [] [] mtilemap = new int [64] [36];  //miniature tilemap
boolean [] [] otilemap = new boolean [32] [18];  //opacity tilemap || false -> normal; true -> grey instead of brown
int hx;  //head x
int hy;  //head y
int tx;  //tail x
int ty;  //tail y
int fx;  //food x
int fy;  //food y
int dir = 0;  //direction the snake is facing (0=r, 1=u, 2=l, 3=d)
int td = 0;  //direction the tail is going (same as above)
boolean u;  //  \
boolean d;  //   \
boolean l;  //    > input variables
boolean r;  //   /
boolean p;  //  /
boolean pu; //  \
boolean pd; //   \  
boolean pr; //    > input variables on the previous frame
boolean pl; //   /
boolean pp; //  /
boolean eat;  //wether or not a fruit is being eaten at the current frame
boolean showscore;  //wether the most recent achieved score is shown on screen 2 or not
boolean pause;  //wether the game is in pause mode
int mode;  //gamemode (0=play, 1=startPlaying 2=dead 3=gameComplete)
int len;  //snake length
int speed;  //how many frames per move (3=easy, 2=medium, 1=hard)
int pspeed;  //mode of the last game
int pscore;  //score of the last game
int [] highscore = new int [3];  //overall highscore
int FC;  //frame counter
int quality;  //quality (0=low, 1=high)
int Smtimer;  //timer for move sound
int Setimer;  //timer for eat sound
int Sftimer;  //timer for fail sound
int ctimer;  //timer for when you can play again after you die
int stimer;  //timer for when you can change the settings after you die
int selSet;  //the index of the selected setting (0=quality, 1=speed, 2=play)

color brown = color(136, 0, 21);
color green = color(20, 230, 20);

BM [] dirs = {new BM(1, 0), new BM(0, -1), new BM(-1, 0), new BM(0, 1)};  //Array for player movement
BM [] xyoff = {new BM(0, 0), new BM(1, 0), new BM(0, 1), new BM(1, 1)};  //Array for miniature tile offset

ArrayList<BM> moves;  //all moves
ArrayList<BM> body;  //all body pieces

ArrayList<String> scores = new ArrayList<String> ();  //all scores
//the names of all graphics:
String [] names = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "bodyud", "bodyrl", "curveur", "curvedr", "curvedl", "curveul", "food", "headu", "headr", "headd", "headl", "tailu", "tailr", "taild", "taill", "edgeu", "edger", "edged", "edgel", "cornerur", "cornerdr", "cornerdl", "cornerul", "_", "!", ";", "oob", "_m", "oobm", "pause"};

String [] dls = {" ", "HARD", "MEDIUM", "EASY"};  //difficulty levels
String [] qls = {"HIGH", "LOW"};  //qualities

PImage [] images = new PImage [names.length];  //Array with all graphics

void setup() {  //size, load graphics and initialize moves
  size(1280, 720);
  for (int a=0; a<images.length; a++) {
    images[a] = loadImage(names[a]+".png");
  }
  reset();
  showscore = false;
  speed = 2;

  String [] hs = loadStrings("highscore.txt");
  for (int u=0; u<3; u++) {
    highscore[u] = StI(hs[u]);
  }
  scores = AtAL(loadStrings("scores.txt"));
  frameRate(10);
}

void draw() {  //get inputs
  if (body.size()+2 == 30*16) {
    mode = 3;
    int msize = moves.size();
    int bsize = body.size();
    for (int o=0; o<msize; o++) {
      moves.remove(0);
      if (o < bsize) {
        body.remove(0);
      }
    }
    ctimer = 30;
    eat = false;
  }
  if (p && !pp) {
    boolean ppau = pause;
    if (ppau) {
      pause = false;
    } else {
      pause = true;
      FC = -1;
    }
  } else {
    if (pause) {
      if ((u && !pu) || (d && !pd) || (r && !pr) || (l && !pl)) {
        pause = false;
        FC = 0;
      }
    }
  }
  if (mode == 0) {
    if (FC % speed == 0) {
      game();
    }
  } else {
    if ((u && !pu) || (d && !pd) || (r && !pr) || (l && !pl)) {
      if (mode == 3) {
        if (ctimer == 0) {
          reset();
          spawnFood();
          Setimer = 3;
        }
      } else if (mode == 2) {
        if (r && !pr) {
          if (selSet < 2 && selSet >= 0) {
            if (stimer == 0) {
              selSet ++;
              Smtimer = 1;
            }
          } else if (selSet == 2) {
            if (ctimer == 0) {
              mode = 1;
              Setimer = 3;
            }
          }
        }
        if (l && !pl) {
          if (selSet > 0) {
            if (stimer == 0) {
              selSet --;
              Smtimer = 1;
            }
          }
        }
        if (d && !pd) {
          if (selSet == 0) {
            if (stimer == 0) {
              selSet = -1;
              Smtimer = 1;
            }
          }
          if (selSet == 1) {
            if (speed < 3) {
              if (stimer == 0) {
                speed ++;
                Smtimer = 1;
              }
            }
          }
        }
        if (u && !pu) {
          if (selSet == -1) {
            if (stimer == 0) {
              selSet = 0;
              Smtimer = 1;
            }
          }
          if (selSet == 1) {
            if (speed > 1) {
              if (stimer == 0) {
                speed --;
                Smtimer = 1;
              }
            }
          }
        }
      } else if (mode == 1) {
        mode = 0;
        FC = 0;
        Smtimer = 1;
        pause = false;
      }
    }
  }
  render();  //render everything
  if (!keyPressed) {
    u = false;
    d = false;
    r = false;
    l = false;
    p = false;
  }

  if (Smtimer >= 0) {
    if (Smtimer == 1) {
      Sm.play(440, 0.3);
    }
    Smtimer --;
  }

  if (Setimer >= 0) {
    if (Setimer == 3) {
      Se.play(784, 0.3);
    }
    if (Setimer == 2) {
      Se.play(1046.5, 0.3);
    }
    Setimer --;
    Sm.stop();
  }
  if (Sftimer >= 0) {
    if (Sftimer == 4) {
      Sf.play(329.6*0.5, 0.3);
    }
    if (Sftimer == 3) {
      Sf.play(246.9*0.5, 0.3);
    }
    if (Sftimer == 2) {
      Sf.play(196*0.5, 0.3);
    }
    Sftimer --;
    Smtimer = -1;
  }
  if (Smtimer < 0) {
    Sm.stop();
  }
  if (Setimer < 0) {
    Se.stop();
  }
  if (Sftimer < 0) {
    Sf.stop();
  }
  if (ctimer > 0) {
    ctimer --;
  }
  if (stimer > 0) {
    stimer --;
  }
  pu = u;
  pd = d;
  pr = r;
  pl = l;
  pp = p;
  if (!pause) {
    FC ++;
  }
  mtilemap = new int [64] [72];
}

void keyPressed() {
  if (keyCode == 38) {
    u = true;
  } else {
    u = false;
  }
  if (keyCode == 40) {
    d = true;
  } else {
    d = false;
  }
  if (keyCode == 39) {
    r = true;
  } else {
    r = false;
  }
  if (keyCode == 37) {
    l = true;
  } else {
    l = false;
  }
  if (key == 'r' || key == 'R') {
    reset();
    showscore = false;
    speed = 2;
  }
  if (key == 'p' || key == 'P') {
    p = true;
  } else {
    p = false;
  }
}

void game() {
  boolean playSound = false;
  if ((u && !d) && dir != 3 && dir != 1) {  //direction change
    dir = 1;
    playSound = true;
  }
  if ((d && !u) && dir != 1 && dir != 3) {
    dir = 3;
    playSound = true;
  }
  if ((r && !l) && dir != 2 && dir != 0) {
    dir = 0;
    playSound = true;
  }
  if ((l && !r) && dir != 0 && dir != 2) {
    dir = 2;
    playSound = true;
  }

  if (playSound && Smtimer == -1) {
    Smtimer = 1;
  }

  body.add(new BM(hx, hy));  //head leaves a body piece behind and then moves
  hx += dirs[dir].x;
  hy += dirs[dir].y;
  if (!eat) {  //tail movement
    BM mov = moves.get(1);
    if (mov.x == 0) {
      if (mov.y == 1) {
        td = 3;
      } else {
        td = 1;
      }
    } else {
      if (mov.x == 1) {
        td = 0;
      } else {
        td = 2;
      }
    }
    tx += moves.get(0).x;
    ty += moves.get(0).y;
    moves.remove(0);
    body.remove(0);
  }
  boolean die = false;  //then it can die either because of the edge or the body
  for (int l=0; l<body.size(); l++) {
    BM bo = body.get(l);
    if (bo.x == hx && bo.y == hy) {
      die = true;
      l = body.size();
    }
  }
  if (hx < 1 || hx > 30 || hy < 3 || hy > 16 || (hx == tx && hy == ty) || die) {
    pscore = len-3;
    pspeed = speed;
    ctimer = 15;
    stimer = 8;
    String d = str(day());
    String m = str(month());
    String y = str(year());
    String h = str(hour());
    String mi = str(minute());
    String s = str(second());
    if (d.length() < 2) {
      char o = d.charAt(0);
      d = str(0)+o;
    }
    if (m.length() < 2) {
      char o = m.charAt(0);
      m = str(0)+o;
    }
    if (h.length() < 2) {
      char o = h.charAt(0);
      h = str(0)+o;
    }
    if (mi.length() < 2) {
      char o = mi.charAt(0);
      mi = str(0)+o;
    }
    if (s.length() < 2) {
      char o = s.charAt(0);
      s = str(0)+o;
    }
    String mode = dls[speed].toLowerCase();
    if (mode.equals("easy")) {
      mode = " easy ";
    }
    if (mode.equals("hard")) {
      mode = " hard ";
    }
    scores.add(d + "." + m + "." + y + " - " + h + ":" + mi + ":" + s + " - " + mode + " mode" + " - Score: " + str(pscore));
    saveStrings("scores.txt", ALtA(scores));
    if (pscore > highscore[3-speed]) {
      highscore[3-speed] = pscore;
      saveStrings("highscore.txt", new String [] {str(highscore[0]), str(highscore[1]), str(highscore[2])});
    }
    reset();
    Sftimer = 4;
  }
  if (hx == fx && hy == fy) {  //eat code
    eat = true;
    len ++;
    spawnFood();

    Setimer = 3;
  } else {
    eat = false;
  }
  if (mode == 0) {
    moves.add(dirs[dir]);  //save the move in an ArrayList
  }
}

void render() {
  drawBG();  //draw the background
  if (mode < 2) {  //if currently playing, draw the score, the snake and the food
    drawScore();
    drawHighscore();
    drawSnake();
    drawFood();
    if (mode == 0) {
      if (pause) {
        drawT("pause", 14, 1, false);
        updateMT(new String [] {" ", " ", " ", "cornerdr"}, 13, 0);
        updateMT(new String [] {" ", " ", "edgeu", "edgeu"}, 14, 0);
        updateMT(new String [] {" ", " ", "cornerdl", " "}, 15, 0);
        updateMT(new String [] {"edger", " ", "edger", " "}, 15, 1);
        updateMT(new String [] {"cornerul", " ", " ", " "}, 15, 2);
        updateMT(new String [] {"edged", "edged", " ", " "}, 14, 2);
        updateMT(new String [] {" ", "cornerur", " ", " "}, 13, 2);
        updateMT(new String [] {" ", "edgel", " ", "edgel"}, 13, 1);
      }
    }
  }
  if (mode == 2) {  //else draw the text
    if (showscore) {  //a file name may not contain a ":", so the file with the ":" is saved as ";.png", hence the ";" instead of ":"
      drawScoreCenter();
    } else {
      drawText("SNAKE", 13, 4, false);
    }
    if (selSet >= 0) {
      int yoff = 0;
      if (showscore) {
        yoff = 1;
      }
      drawText("ADJUST_THE_SETTINGS_WITH_THE", 2, 7+yoff, false);
      drawText("UP_AND_DOWN_ARROW_KEYS", 5, 8+yoff, false);
      drawText("SELECT_SETTNGS_WITH_THE", 4, 10+yoff, false);
      drawText("RIGHT_AND_LEFT_ARROW_KEYS", 3, 11+yoff, false);
    }
    int deltax = 3;
    int cxu = 8;
    int cxd = 10;
    int clu = 17;
    int dx = 8;
    int dl = 18;
    int px = 7;
    if (selSet == -1) {
      int yoff = 0;
      if (showscore) {
        yoff = 1;
      }
      drawText("MOVE_WITH_THE_ARROW_KEYS", 4, 8+yoff, false);
      drawText("PAUSE_WITH_P", 10, 10+yoff, false);
      drawText("EXIT_PAUSE_WITH_ANY_KEY", 4, 11+yoff, false);
      drawText("PRESS_UP_TO_GO_BACK", 6, 14+yoff, false);
    }
    if (selSet == 0) {
      drawText("PRESS_DOWN_TO_SEE", cxu, 14, false);
      drawText("THE_CONTROLS", cxd, 15, false);
      drawTextWB("DIFFICULTY;_" + dls[speed], cxu+clu+deltax, 14, true, -1, 30);
    } else if (selSet == 1) {
      drawTextWB("PRESS_DOWN_TO_SEE", dx-deltax-clu, 14, true, 1, -1);
      drawTextWB("THE_CONTROLS", dx-deltax-clu-cxu+cxd, 15, true, 1, -1);
      drawText("DIFFICULTY;_" + dls[speed], dx, 14, false);
      drawTextWB("PRESS_RIGHT_TO_PLAY", dx+dl+deltax, 14, true, -1, 30);
    } else if (selSet == 2) {
      drawTextWB("DIFFICULTY;_" + dls[speed], px-deltax-dl, 14, true, 1, -1);
      drawText("PRESS_RIGHT_TO_PLAY", px, 14, false);
    }
  }
  if (mode == 3) {
    drawText("CONGRATULATIONS!", 8, 7, false);
    drawText("YOU_BEAT_THE_GAME!", 7, 8, false);
  }

  for (int y=0; y<18; y++) {  //iterate through the entier tilemap and display the corresponding graphic, first drawing the normal tile and then (if necessary) each of the 4 miniature tiles
    for (int x=0; x<32; x++) {
      if (tilemap[x][y] == -1) {
        noStroke();
        fill(0);
        rect(x*40, y*40, 40, 40);
      } else {
        PImage ri = images[tilemap[x][y]];
        if (otilemap[x][y]) {
          ri.loadPixels();
          for (int yi=0; yi<ri.height; yi++) {
            for (int xi=0; xi<ri.width; xi++) {
              if (ri.pixels[yi*ri.width+xi] == brown) {
                ri.pixels[yi*ri.width+xi] = color(125, 140, 110);
              }
            }
          }
          ri.updatePixels();
        }
        image(ri, x*40, y*40);
        ri.loadPixels();
        for (int yi=0; yi<ri.height; yi++) {
          for (int xi=0; xi<ri.width; xi++) {
            if (ri.pixels[yi*ri.width+xi] == color(125, 140, 110)) {
              ri.pixels[yi*ri.width+xi] = brown;
            }
          }
        }
        ri.updatePixels();
      }
      for (int k=0; k<4; k++) {
        int index = mtilemap[x*2+xyoff[k].x][y*2+xyoff[k].y];
        if (index != 0) {
          image(images[index], x*40+xyoff[k].x*20, y*40+xyoff[k].y*20);
        }
      }
    }
  }

  //stroke(0);
  //for (int p=0; p<width/40; p++) {
  //  strokeWeight(2);
  //  line(p*40, 0, p*40, height);
  //  strokeWeight(0.8);
  //  line((p+0.5)*40, 0, (p+0.5)*40, height);
  //}
  //for (int q=0; q<height/40; q++) {
  //  strokeWeight(1.5);
  //  line(0, q*40, width, q*40);
  //  strokeWeight(0.7);
  //  line(0, (q+0.5)*40, width, (q+0.5)*40);
  //}
}

void drawScoreCenter() {
  int scdig = 1;  //figure out the number of digits for the score
  if (pscore >= 10) {
    scdig = floor(log(pscore)/log(10))+1;
  }
  int curBX = floor((32-(scdig+21))/2);  //set the starting position of the cursor
  drawText("YOU_GOT_A_SCORE_OF", curBX+1, 4, false);  //draw "YOU GOT A SCORE OF"
  drawT("_", curBX+19, 7, false);  //draw the blank space after it
  for (int h=0; h<scdig; h++) {
    drawText(str(floor((pscore)/pow(10, scdig-h-1))%10), curBX+20+h, 4, false);  //draw the number
  }
  drawText("IN_" + dls[pspeed] + "_MODE", floor((32-(dls[pspeed].length()+8))/2)-1, 5, false);
}

void drawScore() {
  int score = len-3;
  int scdig = 1;  //figure out the number of digits for the score
  if (score >= 10) {
    scdig = floor(log(score)/log(10))+1;
  }
  int curBX = floor((16-(scdig+8))/2);  //set the starting position of the cursor
  if (curBX < 0) {
    curBX = 0;
  }
  updateMT(new String [] {"oobm", "edgel", "oobm", "edgel"}, curBX, 1);  //draw the tile before "SCORE"
  drawText("SCORE", curBX+1, 1, false);  //draw the word "SCORE"
  drawT("_", curBX+6, 1, false);  //draw the blank space after it
  for (int h=0; h<scdig; h++) {
    drawText(str(floor((score)/pow(10, scdig-h-1))%10), curBX+7+h, 1, false);  //draw the number
  }
  updateMT(new String [] {"edger", "oobm", "edger", "oobm"}, curBX+7+scdig, 1);  //draw the tile after the number

  updateMT(new String [] {"oobm", "oobm", "oobm", "cornerdr"}, curBX, 0);  //draw the tile on the top left
  for (int j=0; j<scdig+6; j++) {
    updateMT(new String [] {"oobm", "oobm", "edgeu", "edgeu"}, curBX+j+1, 0);  //draw the tiles above
  }
  updateMT(new String [] {"oobm", "oobm", "cornerdl", "oobm"}, curBX+scdig+7, 0);  //draw the tile on the top right
  updateMT(new String [] {"oobm", "cornerur", " ", " "}, curBX, 2);  //draw the top half of the tile on the bottom left
  for (int k=0; k<scdig+6; k++) {
    updateMT(new String [] {"edged", "edged", " ", " "}, curBX+k+1, 2);  //draw the top halves of the tiles on the bottom
  }
  updateMT(new String [] {"cornerul", "oobm", " ", " "}, curBX+scdig+7, 2);  //draw the top half of the bottom right
}

void drawHighscore() {
  int score = highscore[3-speed];
  int scdig = 1;  //figure out the number of digits for the score
  if (score >= 10) {
    scdig = floor(log(score)/log(10))+1;
  }
  int curBX = ceil((48-(scdig+12))/2);  //set the starting position of the cursor
  if (curBX > 20-scdig) {
    curBX = 20-scdig;
  }
  updateMT(new String [] {"oobm", "edgel", "oobm", "edgel"}, curBX, 1);  //draw the tile before "HIGHSCORE"
  drawText("HIGHSCORE", curBX+1, 1, false);  //draw the word "SCORE"
  drawT("_", curBX+10, 1, false);  //draw the blank space after it
  for (int h=0; h<scdig; h++) {
    drawText(str(floor((score)/pow(10, scdig-h-1))%10), curBX+11+h, 1, false);  //draw the number
  }
  updateMT(new String [] {"edger", "oobm", "edger", "oobm"}, curBX+11+scdig, 1);  //draw the tile after the number

  updateMT(new String [] {"oobm", "oobm", "oobm", "cornerdr"}, curBX, 0);  //draw the tile on the top left
  for (int j=0; j<scdig+10; j++) {
    updateMT(new String [] {"oobm", "oobm", "edgeu", "edgeu"}, curBX+j+1, 0);  //draw the tiles above
  }
  updateMT(new String [] {"oobm", "oobm", "cornerdl", "oobm"}, curBX+scdig+11, 0);  //draw the tile on the top right
  updateMT(new String [] {"oobm", "cornerur", " ", " "}, curBX, 2);  //draw the top half of the tile on the bottom left
  for (int k=0; k<scdig+10; k++) {
    updateMT(new String [] {"edged", "edged", " ", " "}, curBX+k+1, 2);  //draw the top halves of the tiles on the bottom
  }
  updateMT(new String [] {"cornerul", "oobm", " ", " "}, curBX+scdig+11, 2);  //draw the top half of the bottom right
}

void drawBG() {  //draw the background
  for (int y=0; y<18; y++) {
    for (int x=0; x<32; x++) {
      if (y < 2) {
        drawT("oob", x, y, false);
      } else if (y == 2) {
        if (x == 0) {
          updateMT(new String [] {"oobm", "oobm", "oobm", "cornerdr"}, x, y);
        } else if (x == 31) {
          updateMT(new String [] {"oobm", "oobm", "cornerdl", "oobm"}, x, y);
        } else {
          updateMT(new String [] {"oobm", "oobm", "edgeu", "edgeu"}, x, y);
        }
      } else if (y == 17) {
        if (x == 0) {
          updateMT(new String [] {"oobm", "cornerur", "oobm", "oobm"}, x, y);
        } else if (x == 31) {
          updateMT(new String [] {"cornerul", "oobm", "oobm", "oobm"}, x, y);
        } else {
          updateMT(new String [] {"edged", "edged", "oobm", "oobm"}, x, y);
        }
      } else {
        if (x == 0) {
          updateMT(new String [] {"oobm", "edgel", "oobm", "edgel"}, x, y);
        } else if (x == 31) {
          updateMT(new String [] {"edger", "oobm", "edger", "oobm"}, x, y);
        } else {
          drawT("_", x, y, false);
        }
      }
      otilemap[x][y] = false;
    }
  }
}

void drawSnake() {  //draw the snake
  String [] stdirs = {"r", "u", "l", "d"};
  for (int n=0; n<body.size(); n++) {
    BM mov0 = moves.get(n);
    BM mov1 = moves.get(n+1);
    if (mov0.x == mov1.x && mov0.y == mov1.y) {
      String bd = " ";
      if (mov0.x == 0) {
        bd = "ud";
      } else {
        bd = "rl";
      }
      drawT("body"+bd, body.get(n).x, body.get(n).y, false);
    } else {
      String cd = "0";
      if (mov0.x == 0) {
        if (mov0.y == 1) {
          if (mov1.x == 1) {
            cd = "ur";
          } else {
            cd = "ul";
          }
        } else {
          if (mov1.x == 1) {
            cd = "dr";
          } else {
            cd = "dl";
          }
        }
      } else {
        if (mov0.x == 1) {
          if (mov1.x == 0) {
            if (mov1.y == 1) {
              cd = "dl";
            } else {
              cd = "ul";
            }
          }
        } else {
          if (mov1.y == 1) {
            cd = "dr";
          } else {
            cd = "ur";
          }
        }
      }
      drawT("curve"+cd, body.get(n).x, body.get(n).y, false);
    }
  }

  drawT("head"+stdirs[dir], hx, hy, false);
  drawT("tail"+stdirs[td], tx, ty, false);
}

void drawFood() {  //draw the food
  drawT("food", fx, fy, false);
}

void drawT(String Stext, int x, int y, boolean grey) {  //how to draw a tile (aka a graphic whose name is more than one character long)
  ArrayList<Integer> ints = new ArrayList<Integer> ();
  ints.add(findIndex(Stext, names));  //find the corresponding index of names and add that to the tilemap
  adraw(ints, x, y, grey);
}

void drawText(String Stext, int x, int y, boolean grey) {  //how to draw text (aka every character corresponds to one graphic / tile)
  ArrayList<Integer> ints = new ArrayList<Integer> ();
  for (int f=0; f<Stext.length(); f++) {  //go through all the chars and add the corresponding index to the tilemap
    ints.add(findIndex(str(Stext.charAt(f)), names));
  }
  adraw(ints, x, y, grey);
}

void drawTextWB(String Stext, int x, int y, boolean grey, int le, int re) {  //how to draw text (aka every character corresponds to one graphic / tile) with left and right boundsd | set to -1 to deactivate
  ArrayList<Integer> ints = new ArrayList<Integer> ();
  for (int f=0; f<Stext.length(); f++) {  //go through all the chars and add the corresponding index to the tilemap
    ints.add(findIndex(str(Stext.charAt(f)), names));
  }
  adrawWB(ints, x, y, grey, le, re);
}

void updateMT(String [] mtiles, int x, int y) {  //how to draw a miniature tile
  for (int i=0; i<4; i++) {
    int nextI = findIndex(mtiles[i], names);
    if (!mtiles[i].equals(" ")) {
      mtilemap[x*2+xyoff[i].x][y*2+xyoff[i].y] = nextI;  //only if the corresponding miniature tile should be overwritten (hence update and not draw)
    }                                                    //add the information to the miniature tilemap
  }
}

void adraw(ArrayList<Integer> ints, int x, int y, boolean grey) {  //how to add a list of ints to the tilemap
  int cursorX = x;
  int cursorY = y;
  for (int g=0; g<ints.size(); g++) {
    cursorX = cursorX%32;
    tilemap[cursorX][cursorY] = ints.get(g);         //self-explanatory
    otilemap[cursorX][cursorY] = grey;
    cursorX ++;
  }
}

void adrawWB(ArrayList<Integer> ints, int x, int y, boolean grey, int le, int re) {  //how to add a list of ints to the tilemap
  int cursorX = x;
  int cursorY = y;
  for (int g=0; g<ints.size(); g++) {
    boolean drawt = true;
    if (le != -1 && cursorX < le) {
      drawt = false;
    }
    if (re != -1 && cursorX > re) {
      drawt = false;
    }
    if (drawt) {
      tilemap[cursorX][cursorY] = ints.get(g);         //self-explanatory
      otilemap[cursorX][cursorY] = grey;
    }
    cursorX ++;
  }
}

void spawnFood() {
  int b = 0;
  while (b == 0) {
    int nfx = int(random(1, 30));
    int nfy = int(random(3, 16));
    if (!(nfx == hx && nfy == hy)) {
      if (!(nfx == fx && nfy == fy)) {
        if (!(nfx == tx && nfy == ty)) {
          boolean sf = true;
          for (int m=0; m<body.size(); m++) {
            if (nfx == body.get(m).x && nfy == body.get(m).y) {
              sf = false;
              m = body.size();
            }
          }
          if (sf) {
            fx = nfx;
            fy = nfy;
            b = 1;
          }
        }
      }
    }
  }
}

int findIndex(String find, String [] list) {  //still self-explanatory
  int ret = -1;
  for (int c=0; c<list.length; c++) {
    if (find.equals(list[c])) {
      ret = c;
      c = list.length;
    }
  }
  return(ret);
}

int StI(String input) {
  int ret = 0;
  String [] ints = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"};
  for (int r=0; r<input.length(); r++) {
    ret += findIndex(str(input.charAt(r)), ints)*pow(10, input.length()-r-1);
  }
  return(ret);
}

ArrayList<String> AtAL (String [] input) {
  ArrayList<String> ret = new ArrayList<String> ();
  for (int s=0; s<input.length; s++) {
    ret.add(input[s]);
  }
  return(ret);
}

String [] ALtA (ArrayList<String> input) {
  String [] ret = new String [input.size()];
  for (int t=0; t<ret.length; t++) {
    ret[t] = input.get(t);
  }
  return(ret);
}

void reset() {
  hx = 18;
  hy = 8;
  tx = 14;
  ty = 8;
  mode = 2;
  selSet = 0;
  showscore = true;
  pause = false;
  moves = new ArrayList<BM> ();
  body = new ArrayList<BM> ();
  for (int b=0; b<4; b++) {
    moves.add(new BM(1, 0));
    if (b < 3) {
      body.add(new BM(15+b, 8));
    }
  }
  tilemap = new int [32] [18];
  mtilemap = new int [64] [36];
  len = 3;
  dir = 0;
  td = 0;
  quality = 0;
  spawnFood();
}

class BM {  // a body piece and move simultaneously
  int x;
  int y;

  BM(int inputX, int inputY) {
    x = inputX;
    y = inputY;
  }
}
