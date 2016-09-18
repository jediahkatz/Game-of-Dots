import processing.net.*;

Client client;
int player = -1;
boolean started = false;
boolean looping = true;

int whoseTurn = 1;
int[] playerBoxes = {0, 0};
Grid gameGrid = new Grid();

void setup() {
  client = new Client(this, "public IP of server goes here", 5207);
  size(430, 460);
  strokeWeight(3);
  textSize(12);
  rectMode(CORNERS);
  gameGrid.display();
  requestPlayer();
}

void requestPlayer() {
  client.write("$player*");
}

void toggleTurn() {
  whoseTurn = whoseTurn == 1 ? 2 : 1;
}

void draw() {
  if (started) {
    looping = false;
    display();
  } else {
    pushStyle();
    background(255);
    textAlign(CENTER);
    textSize(18);
    fill(0);
    text("Waiting for another player...", 430/2, 460/2);
    popStyle();
  }
  
  if(!looping) {
    noLoop();
    redraw();
  }
}

void clientEvent(Client client) {
  String msg = client.readStringUntil('*');

  if (msg != null) {
    println(msg, msg.charAt(0) == '^', started);

    if (msg.charAt(0) == '$') { //player assignment
      player = (player == -1 ? int(str(msg.charAt(1))) : player);
    } else if (msg.charAt(0) == '!') { //click update
      if (int(str(msg.charAt(1))) != player && whoseTurn != player) {
        String[] coordinates = msg.split(",");
        println(coordinates[1], coordinates[2]);
        otherPlayerClick(int(coordinates[1]), int(coordinates[2]));
      }
    } else if (msg.charAt(0) == '^' && !started) { //start signal
      started = true;
      client.write("^STARTED*"); //confirm
    }
  }
}

void display() {
  background(255);
  gameGrid.display();
  fill(0);
  noStroke();
  //dots
  for (int i=0; i<6; i++) {
    for (int j=0; j<6; j++) {
      rect(35+j*70, 35+i*70, 45+j*70, 45+i*70);
    }
  }

  text("It's " + (whoseTurn == player ? "your" : "your opponent's") + " turn to pick a line." + (whoseTurn == 1 ? " (Green)" : " (Red)"), 40, 420);
  text((player == 1 ? "You control " : "Your opponent controls ") + playerBoxes[0] + " boxes and " + (player == 1 ? "your opponent controls " : "you control ") + playerBoxes[1] + " boxes.", 40, 440);
}

void otherPlayerClick(int xClick, int yClick) {
  if (whoseTurn != player) {
    if (gameGrid.check(xClick, yClick)) {
      toggleTurn();
    }
  }
}

void mousePressed() {
  println(looping);
  
  if (started) {
    client.write("!" + player + "," + mouseX + "," + mouseY + ",*");

    if (whoseTurn == player) {
      if (gameGrid.check(mouseX, mouseY)) {
        toggleTurn();
      }
    }
  }
}

class Grid {
  Box[][] boxes;
  HLine[][] hLines;
  VLine[][] vLines;

  //create 5 x 5 size grid
  Grid() {
    hLines = new HLine[6][5];
    for (int i=0; i<6; i++) {
      for (int j=0; j<5; j++) {
        hLines[i][j] = new HLine(40+j*70, 110+j*70, 40+i*70);
      }
    }

    vLines = new VLine[5][6];
    for (int i=0; i<5; i++) {
      for (int j=0; j<6; j++) {
        vLines[i][j] = new VLine(40+i*70, 110+i*70, 40+j*70);
      }
    }

    boxes = new Box[5][5];
    for (int i=0; i<5; i++) {
      for (int j=0; j<5; j++) {
        boxes[i][j] = new Box(hLines[i][j], hLines[i+1][j], vLines[i][j], vLines[i][j+1]);
      }
    }
  }

  boolean check(int xClick, int yClick) {
    boolean validMove = false;
    boolean gotSquare = false;

    for (int i=0; i<6; i++) {
      for (int j=0; j<5; j++) {
        if (hLines[i][j].check(xClick, yClick)) {
          validMove = true;

          for (int k=0; k<5; k++) {
            for (int l=0; l<5; l++) {

              if (boxes[k][l].contains(hLines[i][j])) {

                if (boxes[k][l].numLinesClicked++ == 3) {
                  gotSquare=true;
                  boxes[k][l].whoControls = whoseTurn;
                  playerBoxes[whoseTurn-1]++;
                }
              }
            }
          }
        }
      }
    }

    for (int i=0; i<5; i++) {
      for (int j=0; j<6; j++) {
        if (vLines[i][j].check(xClick, yClick)) {
          validMove = true;

          for (int k=0; k<5; k++) {
            for (int l=0; l<5; l++) {
              if (boxes[k][l].contains(vLines[i][j])) {
                if (boxes[k][l].numLinesClicked++ == 3) {
                  gotSquare = true;
                  boxes[k][l].whoControls = whoseTurn;
                  playerBoxes[whoseTurn-1]++;
                }
              }
            }
          }
        }
      }
    }

    if (validMove) {
      redraw();
    }

    return validMove && !gotSquare;
  }

  void display() {
    for (int i=0; i<6; i++) {
      for (int j=0; j<5; j++) {
        hLines[i][j].display();
      }
    }

    for (int i=0; i<5; i++) {
      for (int j=0; j<6; j++) {
        vLines[i][j].display();
      }
    }

    for (int i=0; i<5; i++) {
      for (int j=0; j<5; j++) {
        boxes[i][j].display();
      }
    }
  }
}

class Line {
}

class HLine extends Line {
  int x1, x2, y;
  int whoControls = 0;

  HLine(int x1, int x2, int y) {
    this.x1 = x1;
    this.x2 = x2;
    this.y = y;
  }

  void display() {
    switch(whoControls) {
    case 0:
      stroke(150);
      break;
    case 1:
      stroke(0, 255, 0);
      break;
    case 2:
      stroke(255, 0, 0);
      break;
    }
    line(x1, y, x2, y);
  }

  boolean check(int xClick, int yClick) {
    if (whoControls == 0 && abs(yClick - y) <= 3 && xClick < x2 - 3 && xClick > x1 + 3) {
      whoControls = whoseTurn;
      return true;
    }
    return false;
  }
}

class VLine extends Line {
  int y1, y2, x;
  //0 for nobody; 1 for p1; 2 for p2
  int whoControls = 0;

  VLine(int y1, int y2, int x) {
    this.y1 = y1;
    this.y2 = y2;
    this.x = x;
  }

  void display() {
    switch(whoControls) {
    case 0:
      stroke(150);
      break;
    case 1:
      stroke(0, 255, 0);
      break;
    case 2:
      stroke(255, 0, 0);
      break;
    }
    line(x, y1, x, y2);
  }

  boolean check(int xClick, int yClick) {
    if (whoControls == 0 && abs(xClick - x) <= 3 && yClick < y2 - 3 && yClick > y1 + 3) {
      whoControls = whoseTurn;
      return true;
    }
    return false;
  }
}

class Box {
  HLine[] hLines = new HLine[2];
  VLine[] vLines = new VLine[2];
  //0 for nobody; 1 for p1; 2 for p2
  int whoControls = 0;
  int numLinesClicked = 0;

  Box(HLine top, HLine bottom, VLine left, VLine right) {
    vLines[0] = left;
    vLines[1] = right;
    hLines[0] = top;
    hLines[1] = bottom;
  }

  boolean contains(Line l) {
    for (int i=0; i<2; i++) {
      if (hLines[i] == l || vLines[i] == l) {
        return true;
      }
    }
    return false;
  }

  void display() {
    switch(whoControls) {
    case 0:
      break;
    case 1:
      fill(0, 255, 0);
      stroke(0);
      rect(vLines[0].x, vLines[0].y1, vLines[1].x, vLines[1].y2);
      break;
    case 2:
      fill(255, 0, 0);
      stroke(0);
      rect(vLines[0].x, vLines[0].y1, vLines[1].x, vLines[1].y2);
      break;
    }
  }
}