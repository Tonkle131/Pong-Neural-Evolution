import java.text.SimpleDateFormat;
import java.util.Date;
import java.lang.reflect.Array;
import java.util.List;
import java.util.Comparator;
import java.util.Arrays;
import java.util.Random;

//Settings
boolean showDebug = false;
boolean doOptimization = false;
boolean testAI = false;
boolean pauseGame = false;

//Window setup
//Be careful changing these
final int sHeight = 800;
final int sWidth = 1200;

//Framerate
final int trainingFrameRate = 999999;
final int playFrameRate = 200;
int frameRate = 200;

//Ball variables
final float ballStartSpeed = 3f;
final float speedIncrease = .2f;
float ballSpeed = ballStartSpeed;
final float ballWidth = 25;
final float ballHeight = 25;
final float ballRadius = ballHeight / 2;
float ballX = sWidth / 2;
float ballY = sHeight / 2;
float ballXSpeed = 0;
float ballYSpeed = 0;

//Declare paddle size and positions
//Standard
final int paddleWidth = 20;
final int paddleHeight = 120;
float paddleSpeed = ballStartSpeed * 1.33333333;
//User (AI)
float userPaddleX = sWidth / 80;
float userPaddleY = sHeight / 2 - paddleHeight / 2;
//CPU
float cpuPaddleX = sWidth - sWidth / 80 - paddleWidth;
float cpuPaddleY = sHeight - sHeight / 2 - paddleHeight / 2;
int moveTime = 20;
int cpuDifficulty = 30; //Amount of frames between decisions
boolean moveUp = false;
boolean moveDown = false;

//Game mechanics
int userScore, cpuScore;

//Networks
//WARNING: networkAmount must be divisable by 4
final int networkAmount = 20;
NeuralNet[] networks = new NeuralNet[networkAmount];
int currentNetworkCount = 0;
int generation = 1;
float[] networkInputs = new float[5];
boolean injectNetwork = true;
String[] lines = new String[] {"","","","",""};

//Evolution
final Evolution evolve = new Evolution();
public float mutationRateDisplay;

//Fitness data
List avgFitnesses = new ArrayList();
public List topFitnesses = new ArrayList();
final int graphX = 100;
final int graphY = sHeight - 20;
HashMap<Integer, int[]> networkFitnesses = new HashMap<Integer, int[]>();

//Window setup
void setup(){
  size(1200, 800);
  frameRate(frameRate);
  
  //Create first generation
  for(int i = 0; i < networkAmount; i++){
    println(i);
    
    networks[i] = new NeuralNet();
    
    if(injectNetwork && i == 0){
      //Read network values from file and put them into the network
      lines = loadStrings("injectNetwork.txt");
      networks[i].InjectNetwork(lines);
    }
    else{
      networks[i].RandomizeNetwork();
      //networks[i].Mutate();
    }
    
    networks[i].WriteStructureToFile("");
  }
  
  SetupGame();
  PrepareBallVelocities();
}

//First time setup
void SetupGame(){
  //Place a paddle on each side of the screen
  rect((sWidth / 80), (sHeight / 2 - paddleHeight / 2), paddleWidth, paddleHeight);
  rect((sWidth - sWidth / 80 - paddleWidth), (sHeight - sHeight / 2 - paddleHeight / 2), paddleWidth, paddleHeight);
  //Place the ball
  ellipse(ballX, ballY, ballWidth, ballHeight);
}

//Give ball random x and y velocities
void PrepareBallVelocities(){
  //Give ball random starting y-velocity that is between -1.25 and -0.4 or 0.4 and 1.25
  while(ballYSpeed > -0.4f && ballYSpeed < 0.4f){
    ballYSpeed = random(-1.25f, 1.25f);
  }
  //Give ball an x-velocity based on the random y-velocity so that the total speed is constant between games
  ballXSpeed = sqrt(ballSpeed * ballSpeed - ballYSpeed * ballYSpeed);
  
  //Randomly decide whether the ball will go left or right
  Random rnd = new Random();
  if(rnd.nextBoolean() == true){
    ballXSpeed *= -1;
  }
}

//Draw loop (runs each frame)
void draw(){
  background(0, 117, 119);//Clear the frame before drawing
  
  //Get inputs before drawing the next frame
  GetInputs();
  
  if(!pauseGame){
    MoveObjects();//Moves ball and paddles
    
    //Runs every 25 frames
    if(frameCount % 25 == 0){
      if(userPaddleY < ballY && userPaddleY + paddleHeight > ballY){
        networks[currentNetworkCount].AddFitness(2);//Add fitness for having same y coordinate as the ball
      }
      networkInputs = new float[] {ballX / 10, ballY / 10, ballXSpeed, ballYSpeed, userPaddleY};
      networks[currentNetworkCount].UpdateInputs(networkInputs);
    }
  }
  //Draw it
  if(!doOptimization){
    DrawStaticObjects();
    DrawObjects();//Draws ball and paddles4
    DrawText();//Draws score
    
    if(showDebug){
      DrawDebug();
      //DrawGraph();//TODO
      DrawNetwork(150, 50);
    }
  }
}

void GetInputs(){
  switch(keyCode){
    //--Toggle user control over the paddle
    case 84://T
      testAI = !testAI;
      keyCode = 0;
      break;
    //--Toggle framerate between slow and unlimited mode
    case 70://F
      if(frameRate == playFrameRate){
        frameRate = trainingFrameRate;
      }
      else{
        frameRate = playFrameRate;
      }
      frameRate(frameRate);
      keyCode = 0;
      break;
    //--Toggle debug information
    case 68://D
      showDebug = !showDebug;
      keyCode = 0;
      break;
    //--Toggle object drawing
    case 79://O
      doOptimization = !doOptimization;
      keyCode = 0;
      break;
    //--Kill current network
    case 75://K
      GameOver();
      keyCode = 0;
      break;
    //--Save current network to file
    case 83://S
      SaveCurrentNetworkToPath();
      keyCode = 0;
      break;
    case 80://P
      pauseGame = !pauseGame;
      if(pauseGame){
        frameRate(10);
      }
      else{
        frameRate(playFrameRate);
      }
      keyCode = 0;
      break;
  }
}

void SaveCurrentNetworkToPath(){
  Date date = new Date();
  SimpleDateFormat ft = new SimpleDateFormat("hh-mm-dd-yyyy");
  String path = ft.format(date) + "-" + currentNetworkCount + "-" + networks[currentNetworkCount].fitness + ".txt";
  networks[currentNetworkCount].WriteStructureToFile(path);
}

//Draw all elements that should never change
void DrawStaticObjects(){
  //Dividing line
  line(sWidth / 2, 0, sWidth / 2, sHeight);
}

//Apply movement to all objects on screen
void MoveObjects(){
  MoveUserPaddle();//Moves the left paddle
  MoveCPUPaddle();//Moves the right paddle
  MoveBall();
}

//Move location of the left paddle based on inputs
void MoveUserPaddle(){
  //Network controls
  if (networks[currentNetworkCount].output[0] > .5f){
    if(userPaddleY > 0){
         userPaddleY -= paddleSpeed;
       }
  }
  if (networks[currentNetworkCount].output[0] < -.5f){
   if(userPaddleY < sHeight - paddleHeight){
         userPaddleY += paddleSpeed;
     } 
  }
}

void MoveCPUPaddle(){
  //User is not in control
  if (!testAI){
    //Moves the paddle so that it is always folowing the ball
    //cpuPaddleY = ballY - paddleHeight / 2;
    //
    
    //Make decisions at the rate of the cpuDifficulty
    if(frameCount % cpuDifficulty == 0){
      if(ballY < cpuPaddleY + 10){
        moveUp = true;
        moveDown = false;
      }
      else if (ballY > cpuPaddleY + paddleHeight - 10){
        moveDown = true;
        moveUp = false;
      }
      else{
        moveDown = false;
        moveUp = false;
      }
    }
    //Move paddle based on decision
    if(moveTime > 0){
      if(moveUp){
        cpuPaddleY -= paddleSpeed;
      }
      if(moveDown){
        cpuPaddleY += paddleSpeed;
      }
    }
  }
  //User is in control
  else{
    if(keyPressed){//Check if a key is still being held down
       //Check which key is being held down
       //Move the paddle accordingly
       switch(keyCode){
         case 38://up
           if(cpuPaddleY > 0){
             cpuPaddleY -= paddleSpeed;
           }
           break;
         case 40://down
           if(cpuPaddleY < sHeight - paddleHeight){
             cpuPaddleY += paddleSpeed;
           }
           break;
         default:
           break;
      }
     }
  }
}

void MoveBall(){
  //Move the ball
  ballX = ballX + ballXSpeed;
  ballY = ballY + ballYSpeed;
  
  //First check if any collisions have happened
  DetectBallCollision();
}

void DetectBallCollision(){
  //Check collision with upper and lower walls
  if(ballY < 0 + ballRadius && ballYSpeed < 0){//Upper
     ballYSpeed = abs(ballYSpeed);
  }
  if(ballY > sHeight - ballRadius && ballYSpeed > 0){//Lower
    ballYSpeed = abs(ballYSpeed) * -1;
  }
  
  if(ballXSpeed < 0){//Ball is moving left
    //Check collision with userPaddle
    if (ballX < paddleWidth + sWidth / 80 + ballRadius && ballX > sWidth / 80 + paddleWidth / 2 && ballY > userPaddleY & ballY < userPaddleY + paddleHeight){
      println("Hit userPaddle");
      
      IncreaseBallSpeed();
      
      //Make ball go to the right
      ballXSpeed = abs(ballXSpeed);
      
      //Check where ball has hit paddle
      //  Top: YSpeed = +
      //  Middle: YSpeed = YSpeed
      //  Bottom: YSpeed = -
      if(ballY > userPaddleY & ballY < userPaddleY + paddleHeight / 3 && ballYSpeed > 0){//Hit top?
        println("Hit top of userPaddle");
        ballYSpeed *= -1;
        
      }
      if(ballY > userPaddleY + paddleHeight - paddleHeight / 3 & ballY < userPaddleY + paddleHeight && ballYSpeed < 0){//Hit bottom?
        println("Hit bottom of userPaddle");
        ballYSpeed *= -1;
      }
      
      //Increase fitness of network
      networks[currentNetworkCount].AddFitness(200);
    }
    
    //Detect point score
    if(ballX < 0){//Ball hit left side
      networks[currentNetworkCount].AddFitness(-100);
      cpuScore++;
      if(cpuScore >= 5){
        GameOver();
      }
      else{
        ResetGame();
      }
    }
  }
  else{//Ball is moving right
    //Check collision with cpuPaddle
    if (ballX > sWidth - sWidth / 80 - paddleWidth - ballRadius && ballX < sWidth - sWidth / 80 - paddleWidth / 2 & ballY > cpuPaddleY & ballY < cpuPaddleY + paddleHeight){
      println("Hit cpuPaddle");
      
      IncreaseBallSpeed();
      
      //Make ball go to the left
      ballXSpeed = abs(ballXSpeed) * -1 ;
      
      //Check where ball has hit paddle
      //  Top: YSpeed = +
      //  Middle: YSpeed = YSpeed
      //  Bottom: YSpeed = -
      if(ballY > cpuPaddleY & ballY < cpuPaddleY + paddleHeight / 3){//Hit top?
        println("Hit top of cpuPaddle");
        if(ballYSpeed > 0){
           ballYSpeed *= -1;
        }
      }
      if(ballY > cpuPaddleY + paddleHeight - paddleHeight / 3 & ballY < cpuPaddleY + paddleHeight){//Hit bottom?
        println("Hit bottom of cpuPaddle");
        
        if(ballYSpeed < 0){
           ballYSpeed *= -1;
        }
      }
    }
    //Detect point score
    if(ballX > sWidth){//Ball hit right side
      networks[currentNetworkCount].AddFitness(600);
      userScore++;
      if (userScore >= 5){
        //Add fitness for winning
        networks[currentNetworkCount].fitness += 1000;
        GameOver();
      }
      else{
        ResetGame();
      }
    }
  }
}

//Display text on screen
void DrawText(){
  //Score
  text("NeuralNet: " + str(userScore), sWidth / 2 - 80, 30); 
  text("CPU: " + str(cpuScore), sWidth / 2 + 10, 30); 
}

void DrawDebug(){
  //Debug
  text("Generation: " + generation + "  -  Network: " + (currentNetworkCount + 1), 100, sHeight - 130);
  text("Fitness: " + networks[currentNetworkCount].fitness, 100, sHeight - 110);
  text("Highest fitness of generation: " + evolve.topFitnessOfGen, 100, sHeight - 90);
  text("Current mutation rate: " + mutationRateDisplay, 100, sHeight - 70);
  text("Inputs: " + Arrays.toString(networkInputs), 100, sHeight - 50);
  text("Output: " + Arrays.toString(networks[currentNetworkCount].output), 100, sHeight - 30);
}

void DrawGraph(){
  //Draw y-axis
  line(50, sHeight - 50, 50, sHeight - 250);
  //Draw x-axis
  line(50, sHeight - 50, 250, sHeight - 50);
  
  //Draw points
  for(int i = 0; i < topFitnesses.size(); i++){
    ellipse(50 + 100 / topFitnesses.size() * i, 50, 2, 2);
  }
}

void DrawNetwork(int netX, int netY){
  NeuralNet currentNet = networks[currentNetworkCount];
  
  //Inputs
  for(int i = 0; i < currentNet.inputs.length; i++){
    int nodeY = netY + (i + 1) * 50 + 25;
    
    //Weights
    for(int j = 0; j < currentNet.hiddenLayer1.length; j++){
      line(netX, nodeY, netX + 100, netY + (j + 1) * 50);
    }
    //Nodes
    circle(netX, nodeY, 20);
    //Values
    text(currentNet.inputs[i], netX - 50, nodeY);
  }
  
  //Hidden 1
  for(int i = 0; i < currentNet.hiddenLayer1.length; i++){
    int nodeY = netY + (i + 1) * 50;
    
    //Weights
    for(int j = 0; j < currentNet.hiddenLayer2.length; j++){
      line(netX + 100, nodeY, netX + 200, netY + (j + 1) * 50);
    }
    //Nodes
    circle(netX + 100, nodeY, 20);
    //Values
    text(currentNet.hiddenLayer1[i], netX + 50, netY + (i + 1) * 50 - 10);
  }
  
  //Hidden 2
  for(int i = 0; i < currentNet.hiddenLayer2.length; i++){
    int nodeY = netY + (i + 1) * 50;
    
    //Weights
    for(int j = 0; j < currentNet.output.length; j++){
      line(netX + 200, nodeY, netX + 300, netY + 175);
    }
    //Nodes
    circle(netX + 200, nodeY, 20);
    //Values
    text(currentNet.hiddenLayer2[i], netX + 150, netY + (i + 1) * 50 - 10);
  }
  
  //Output
  circle(netX + 300, netY + 175, 20);
  text(currentNet.output[0], netX + 280, netY + 160);
}

void DrawObjects(){
  //Draw the objects with the variables that have been changed in the MoveObjects function
  rect(userPaddleX, userPaddleY, paddleWidth, paddleHeight);
  rect(cpuPaddleX, cpuPaddleY, paddleWidth, paddleHeight);
  ellipse(ballX, ballY, ballWidth, ballHeight);
}

void IncreaseBallSpeed(){
  //Increase ball speed on each hit
  ballSpeed += speedIncrease;
  ballXSpeed = sqrt(ballSpeed * ballSpeed - ballYSpeed * ballYSpeed);
  paddleSpeed = ballSpeed * 1.15;
}

void GameOver(){
  if(networks[currentNetworkCount].fitness >= evolve.topFitnessOfGen){
    evolve.topFitnessOfGen = networks[currentNetworkCount].fitness;
  }
  
  cpuDifficulty = Math.round(cpuDifficulty * 0.9f);
  moveTime = Math.round(moveTime * 0.9f);
  currentNetworkCount++;
  userScore = 0;
  cpuScore = 0;
  println("xxxxGAME OVERxxxx");
  println("Network#: " + currentNetworkCount);
  
  if(currentNetworkCount >= networkAmount){
    topFitnesses.add(evolve.topFitnessOfGen);
    
    println("Saving fitnesses");
    //Save average fitnesses
    float tmpAverageFitnesses = 0;
    for(int i = 0; i < networks.length; i++){
      tmpAverageFitnesses += networks[i].fitness;
    }
    tmpAverageFitnesses /= networks.length;
    avgFitnesses.add(tmpAverageFitnesses);
    String[] data = new String[avgFitnesses.size()];
    for(int i = 0; i < avgFitnesses.size(); i++){
      data[i] = avgFitnesses.get(i).toString();
    }
    saveStrings("avgFitnesses.txt", data);
    
    //Save top fitnesses
    for(int i = 0; i < topFitnesses.size(); i++){
      data[i] = topFitnesses.get(i).toString();
    }
    data = new String[topFitnesses.size()];
    for(int i = 0; i < topFitnesses.size(); i++){
      data[i] = topFitnesses.get(i).toString();
    }
    saveStrings("topFitnesses.txt", data);
    
    println("Saved fitnesses");
    
    delay(500);
    evolve.Evolve(networks);
    currentNetworkCount = 0;
    generation++;
  }
  
  ResetGame();
}

//Resets the game except for the scores
void ResetGame(){
   //Reset speeds
   ballXSpeed = 0;
   ballYSpeed = 0;
   ballSpeed = ballStartSpeed;
   paddleSpeed = ballSpeed;
   
   //Place everyting in starting posisition
   userPaddleX = sWidth / 80;
   userPaddleY = sHeight / 2 - paddleHeight / 2;
   cpuPaddleX = sWidth - sWidth / 80 - paddleWidth;
   cpuPaddleY = sHeight - sHeight / 2 - paddleHeight / 2;
   ballX = sWidth / 2;
   ballY = sHeight / 2;
   
   PrepareBallVelocities();
}
