import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.text.SimpleDateFormat; 
import java.util.Date; 
import java.lang.reflect.Array; 
import java.util.List; 
import java.util.Comparator; 
import java.util.Arrays; 
import java.util.Random; 
import java.util.Collections; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Pong extends PApplet {









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
float paddleSpeed = ballStartSpeed * 1.33333333f;
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
final int networkAmount = 60;
NeuralNet[] networks = new NeuralNet[networkAmount];
int currentNetworkCount = 0;
int generation = 1;
float[] networkInputs = new float[5];
boolean injectNetwork = false;
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
public void setup(){
  
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
public void SetupGame(){
  //Place a paddle on each side of the screen
  rect((sWidth / 80), (sHeight / 2 - paddleHeight / 2), paddleWidth, paddleHeight);
  rect((sWidth - sWidth / 80 - paddleWidth), (sHeight - sHeight / 2 - paddleHeight / 2), paddleWidth, paddleHeight);
  //Place the ball
  ellipse(ballX, ballY, ballWidth, ballHeight);
}

//Give ball random x and y velocities
public void PrepareBallVelocities(){
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
public void draw(){
  background(128);//Clear the frame before drawing
  
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

public void GetInputs(){
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

public void SaveCurrentNetworkToPath(){
  Date date = new Date();
  SimpleDateFormat ft = new SimpleDateFormat("hh-mm-dd-yyyy");
  String path = ft.format(date) + "-" + currentNetworkCount + "-" + networks[currentNetworkCount].fitness + ".txt";
  networks[currentNetworkCount].WriteStructureToFile(path);
}

//Draw all elements that should never change
public void DrawStaticObjects(){
  //Dividing line
  line(sWidth / 2, 0, sWidth / 2, sHeight);
}

//Apply movement to all objects on screen
public void MoveObjects(){
  MoveUserPaddle();//Moves the left paddle
  MoveCPUPaddle();//Moves the right paddle
  MoveBall();
}

//Move location of the left paddle based on inputs
public void MoveUserPaddle(){
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

public void MoveCPUPaddle(){
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

public void MoveBall(){
  //Move the ball
  ballX = ballX + ballXSpeed;
  ballY = ballY + ballYSpeed;
  
  //First check if any collisions have happened
  DetectBallCollision();
}

public void DetectBallCollision(){
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
public void DrawText(){
  //Score
  text("NeuralNet: " + str(userScore), sWidth / 2 - 80, 30); 
  text("CPU: " + str(cpuScore), sWidth / 2 + 10, 30); 
}

public void DrawDebug(){
  //Debug
  text("Generation: " + generation + "  -  Network: " + (currentNetworkCount + 1), 100, sHeight - 130);
  text("Fitness: " + networks[currentNetworkCount].fitness, 100, sHeight - 110);
  text("Highest fitness of generation: " + evolve.topFitnessOfGen, 100, sHeight - 90);
  text("Current mutation rate: " + mutationRateDisplay, 100, sHeight - 70);
  text("Inputs: " + Arrays.toString(networkInputs), 100, sHeight - 50);
  text("Output: " + Arrays.toString(networks[currentNetworkCount].output), 100, sHeight - 30);
}

public void DrawGraph(){
  //Draw y-axis
  line(50, sHeight - 50, 50, sHeight - 250);
  //Draw x-axis
  line(50, sHeight - 50, 250, sHeight - 50);
  
  //Draw points
  for(int i = 0; i < topFitnesses.size(); i++){
    ellipse(50 + 100 / topFitnesses.size() * i, 50, 2, 2);
  }
}

public void DrawNetwork(int netX, int netY){
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

public void DrawObjects(){
  //Draw the objects with the variables that have been changed in the MoveObjects function
  rect(userPaddleX, userPaddleY, paddleWidth, paddleHeight);
  rect(cpuPaddleX, cpuPaddleY, paddleWidth, paddleHeight);
  ellipse(ballX, ballY, ballWidth, ballHeight);
}

public void IncreaseBallSpeed(){
  //Increase ball speed on each hit
  ballSpeed += speedIncrease;
  ballXSpeed = sqrt(ballSpeed * ballSpeed - ballYSpeed * ballYSpeed);
  paddleSpeed = ballSpeed * 1.15f;
}

public void GameOver(){
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
public void ResetGame(){
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


public class Evolution{
  
  public int topFitnessOfGen = -99999999;
  public NeuralNet topNetOfGen = networks[0];
  
  final Boolean singleParent = false;
  
  public void Evolve(NeuralNet[] networks){
    SortByFitness(networks);
  }
  
  public void SortByFitness(NeuralNet[] networks){
    //Sort networks by fitness
    Arrays.sort(networks, new FitnessComparator());
    
    //Reverse sorted networks
    for (int i = 0; i < networks.length / 2; i++){
      NeuralNet temp = networks[i];
      networks[i] = networks[networks.length - i - 1];
      networks[networks.length - i - 1] = temp;
    }
    
    //Print fitnesses
    for (int i = 0; i < networks.length; i++){
      println(networks[i].fitness);
    }
    topFitnessOfGen = networks[0].fitness;
    topNetOfGen = networks[0];
    
    println("Generating new networks");
    
    GenerateGeneration(networks);
    topFitnessOfGen = -999999;
  }
  
  public void GenerateGeneration(NeuralNet[] networks){
    //Create arrays and list to do operations on
    NeuralNet[] topNets = new NeuralNet[networks.length / 2];
    List<NeuralNet> topNetsList;
    NeuralNet[] bottomNets = new NeuralNet[networks.length / 2];
    List<NeuralNet> bottomNetsList;
    
    //--Sort the top and bottom half of the networks based on their fitnesses--
    for (int i = 0; i < networks.length / 2; i++){
      topNets[i] = networks[i];
      if (i == 0){//If the best network is selected
        networks[i].WriteStructureToFile("");//Write the best network structure of generation to a file
        println("Fitness of topnet: " + networks[i].fitness);
      }
    }
    for (int j = (networks.length / 2); j < networks.length; j++){
      bottomNets[j - (networks.length / 2)] = networks[j];
    }
    
    //Convert arrays to lists so that more operations can be performed on it
    topNetsList = Arrays.asList(topNets);
    bottomNetsList = Arrays.asList(bottomNets);
    //Shuffle the lists and convert them back to arrays
    Collections.shuffle(topNetsList);
    topNetsList.toArray(topNets);
    Collections.shuffle(bottomNetsList);
    bottomNetsList.toArray(bottomNets);
    
    if(!singleParent){//Two parents
      //Create new generation in place of the bottom half of the population
      for(int i = 0; i < topNets.length; i += 2){
        int mother = i;
        int father = i + 1;
        int child1 = i;
        int child2 = i + 1;
        bottomNets[child1].Inherit(topNets[mother], topNets[father]);
        bottomNets[child1].Mutate();
        bottomNets[child2].Inherit(topNets[mother], topNets[father]);
        bottomNets[child2].Mutate();
      }
    }
    else{//One parent
      for(int i = 0; i < topNets.length; i++){
        bottomNets[i].InheritSingleParent(topNets[i]);//This already mutates the new network
      }
    }
    
    //Update original array and reset the fitnesses
    for (int i = 0; i < networks.length; i++){
      if (i < topNets.length){
        networks[i] = topNets[i];
      }
      else{
        networks[i] = bottomNets[i-topNets.length];
      }
      
      networks[i].fitness = 0;
    }
  }
}

//Class to sort the fitnesses of the networks
class FitnessComparator implements Comparator<NeuralNet>{
  public int compare(NeuralNet a, NeuralNet b){
    return a.fitness < b.fitness ? -1 : a.fitness == b.fitness ? 0 : 1;
  }
}
public class NeuralNet{
  public float[] inputs = new float[5];
  public float[] biasInputs = new float[5];
  public float[] weights1 = new float[30];
  public float[] hiddenLayer1 = new float[6];
  public float[] biasHiddenLayer1 = new float[6];
  public float[] weights2 = new float[36];
  public float[] hiddenLayer2 = new float[6];
  public float[] biasHiddenLayer2 = new float[6];
  public float[] weights3 = new float[6];
  public float[] output = new float[1];
  
  int fitness = 0;
  float mutationRate = 0.5f;
  float mutationAcceleration = 0.75f;
  float mutationJerk = 1;
  
  //Network saving
  public Boolean printStructure = false;
  final String networkStructurePath = "networkStructure.txt";
  String[] data = new String[5];
  int lineCounter = 0;
  
  //Take variables from game and set them as the inputs to the network
  public void UpdateInputs(float[] _inputs){
    println("--------------------------------------------------------");
    inputs = _inputs;
    for(int i = 0; i < inputs.length; i++){
      Math.round(inputs[i]);
    }
   
    //Start feed forward
    CalculateOutput();
  }
  
  public void CalculateOutput(){//Go through each layer to calculate the output
    println();
    CalculateNextLayer(inputs, weights1, hiddenLayer1, biasHiddenLayer1);
    CalculateNextLayer(hiddenLayer1, weights2, hiddenLayer2, biasHiddenLayer1);
    CalculateNextLayer(hiddenLayer2, weights3, output, new float[] {0});
    
    output[0] = SigmoidActivationFunction(output[0]);
    
    println("Output: " + output[0]);
    println("--------------------------------------------------------");
  }
  
  //Calculate a single layer
  public void CalculateNextLayer(float[] _startLayer, float[] _weights, float[] _endLayer, float[] bias){
    int weightCounter = 0;//Weight counter
    float average = 0;//Number to do operations on
    
    //Loop through all output nodes
    for(int i = 0; i < _endLayer.length; i++){
      weightCounter = i;//Set weight equal to the node that is being calculated
      
      //Loop through all input nodes
      for(int j = 0; j < _startLayer.length; j++){
        average += _startLayer[j] * _weights[weightCounter];
        weightCounter += _endLayer.length - 1;//Skip the correct amount of weights for it to corrospond to the correct input and output nodes
      }
      
      //Average the output of the nodes and add the bias
      _endLayer[i] = average / _startLayer.length + bias[i];
    }
  }
  
  public float SigmoidActivationFunction(float _num){
    return 2 / (1 + pow(2.71828f, 5 * (_num))) - 1;
  }
  
  public void WriteStructureToFile(String path){
    lineCounter = 0;
    StoreLayer(weights1);
    StoreLayer(biasHiddenLayer1);
    StoreLayer(weights2);
    StoreLayer(biasHiddenLayer2);
    StoreLayer(weights3);
    
    if(path == ""){ 
      saveStrings(networkStructurePath, data);
    }
    else{
      saveStrings(path, data);
    }
  }
  
  public void StoreLayer(float[] values){
    String line = "";
    for(int i = 0; i < values.length; i++){
      line += Float.toString(values[i]);
      if(i < values.length - 1){
        line += ',';
      }
    }
    data[lineCounter] = line;
    lineCounter++;
  }
  
  public void InheritSingleParent(NeuralNet parent){//Includes mutation
    InheritSingleLayerFromSingleParent(weights1, parent.weights1);
    InheritSingleLayerFromSingleParent(biasHiddenLayer1, parent.biasHiddenLayer1);
    InheritSingleLayerFromSingleParent(weights2, parent.weights2);
    InheritSingleLayerFromSingleParent(biasHiddenLayer2, parent.biasHiddenLayer2);
    InheritSingleLayerFromSingleParent(weights3, parent.weights3);
    
    Mutate();
  }
  
  public void InheritSingleLayerFromSingleParent(float[] _ownLayer, float[] _parentLayer){
    for (int i = 0; i < _ownLayer.length; i++){
      _ownLayer[i] = _parentLayer[i];
    }
  }
  
  public void Inherit(NeuralNet mother, NeuralNet father){
    InheritLayer(weights1, mother.weights1, father.weights1);
    InheritLayer(biasHiddenLayer1, mother.biasHiddenLayer1, father.biasHiddenLayer1);
    InheritLayer(weights2, mother.weights2, father.weights2);
    InheritLayer(biasHiddenLayer2, mother.biasHiddenLayer2, father.biasHiddenLayer2);
    InheritLayer(weights3, mother.weights3, father.weights3);
    
    Mutate();
  }
  
  public void InheritLayer(float[] _ownLayer, float[] _motherLayer, float[] _fatherLayer){
    Random rd = new Random();
    for (int i = 0; i < _ownLayer.length; i++){
      if(rd.nextBoolean()){
        _ownLayer[i] = _motherLayer[i];
      }
      else{
        _ownLayer[i] = _fatherLayer[i];
      }
    }
  }
  
  public void AddFitness(int _val){
    fitness += _val;
    println("==Current fitness: " + fitness + "==");
  }
  
  public void Mutate(){
    MutateLayer(biasInputs, true);
    MutateLayer(weights1, false);
    MutateLayer(biasHiddenLayer1, true);
    MutateLayer(weights2, false);
    MutateLayer(biasHiddenLayer2, true);
    MutateLayer(weights3, false);
    
    mutationRate *= mutationAcceleration;
    mutationAcceleration *= mutationJerk;
    mutationRateDisplay = mutationRate;
  }
  
  public void MutateLayer(float[] _layer, boolean isBias){
    Random rd = new Random();
    for(int i = 0; i < _layer.length; i++){
      if(rd.nextBoolean()){
        _layer[i] += mutationRate;
      }
      else{
        _layer[i] -= mutationRate;
      }
      
      if(!isBias){
        if(_layer[i] < -1f){
          _layer[i] = -1f;
        }
        else if (_layer[i] > 1f){
          _layer[i] = 1f;
        }
      }
    }
  }
  
  //Randomize the weights and biases
  public void RandomizeNetwork(){
    mutationRateDisplay = mutationRate;
    println("Randomizing network...");
    RandomizeLayer(weights1);
    RandomizeLayer(biasHiddenLayer1);
    RandomizeLayer(weights2);
    RandomizeLayer(biasHiddenLayer2);
    RandomizeLayer(weights3);
    println("Done randomizing");
  }
  
  //Randomize a set of weights or biases
  public void RandomizeLayer(float[] _layer){
    for(int i = 0; i < _layer.length; i++){
      _layer[i] = random(-1f, 1f);
      print(_layer[i] + ", ");
    }
    println(";");
  }
  
  public int GetFitness(){
    return fitness;
  }
  
  public void InjectNetwork(String[] _layers){    
    for(int i = 0; i < _layers.length; i++){
      //Split text file into layers
      String currentLayer = _layers[i];
      //Split layer into seperate values stored in strings
      String[] values = split(currentLayer, ',');
      //Populate network with these seperated values
      switch(i){
        case 0:
          for(int j = 0; j < weights1.length; j++){
            weights1[j] = Float.parseFloat(values[j]);
            println(weights1[j]);
          }
          break;
        case 1:
          for(int j = 0; j < biasHiddenLayer1.length; j++){
            biasHiddenLayer1[j] = Float.parseFloat(values[j]);
            println(biasHiddenLayer1[j]);
          }
          break;
        case 2:
          for(int j = 0; j < weights2.length; j++){
            weights2[j] = Float.parseFloat(values[j]);
            println(weights2[j]);
          }
          break;
        case 3:
          for(int j = 0; j < biasHiddenLayer2.length; j++){
            biasHiddenLayer2[j] = Float.parseFloat(values[j]);
            println(biasHiddenLayer2[j]);
          }
          break;
        case 4:
          for(int j = 0; j < weights3.length; j++){
            weights3[j] = Float.parseFloat(values[j]);
            println(weights3[j]);
          }
          break;
      }
    }
  }
  
}
  public void settings() {  size(1200, 800); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "Pong" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
