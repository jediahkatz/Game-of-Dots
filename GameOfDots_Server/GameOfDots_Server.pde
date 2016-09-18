/*
Instructions:
  To play this game over the internet with another player,
  you must first configure your ports. Log in to your router
  settings page (usually at 192.168.0.1) and find the section
  called Port Forwarding. Forward the inbound port 5207 to the
  local port 5207 on your private IP. Finally, run the server
  from that computer, and then run the client twice (only twice!)
  and you will see the game start. Restart the server between
  games or if something goes wrong. The client must always be
  run AFTER the server.  
*/

import processing.net.*;

int nplayers = 0;
int nplayersAssigned = 0;
boolean started = false;

Server server;
String incomingMessage;

void setup() {
  server = new Server(this, 5207);
}

void draw() {
  Client client = server.available();
  
  try {
  if(client != null) {
    incomingMessage = client.readStringUntil('*');
    
    if(nplayersAssigned < 2 && incomingMessage.charAt(0) == '$') { //player assignment request
      server.write("$"+nplayers+"*");
      nplayersAssigned++;
      println("hey");
    } else if(incomingMessage.charAt(0) == '!') { //click update, pass it on
      server.write(incomingMessage);
    } else if(!started && incomingMessage.charAt(0) == '^') { //start confirmation
      started = true;
    }
  }
  
  if(nplayersAssigned == 2 && !started) {
    server.write("^READY TO START*");
  }
  } catch (Exception e) {
    println(e);
  }
}

void serverEvent(Server server, Client client) {
  nplayers++;
  println(nplayers);
}