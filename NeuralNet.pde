public class NeuralNet{
  float[] inputs = new float[5];
  float[] weights1 = new float[30];
  float[] hiddenLayer1 = new float[6];
  float[] biasHiddenLayer1 = new float[6];
  float[] weights2 = new float[36];
  float[] hiddenLayer2 = new float[6];
  float[] biasHiddenLayer2 = new float[6];
  float[] weights3 = new float[6];
  float[] output = new float[1];
  
  int fitness = 0;
  float mutationRate = 0.5;
  float mutationAcceleration = 0.95;
  float mutationJerk = 0.99;
  
  //Network saving
  public Boolean printStructure = false;
  String networkStructurePath = "networkStructure.txt";
  String[] data = new String[5];
  int lineCounter = 0;
  
  //Take variables from game and set them as the inputs to the network
  void UpdateInputs(float[] _inputs){
    println("--------------------------------------------------------");
    inputs = _inputs;
   
    //Start feed forward
    CalculateOutput();
  }
  
  void CalculateOutput(){//Go through each layer to calculate the output
    println();
    CalculateNextLayer(inputs, weights1, hiddenLayer1, biasHiddenLayer1);
    CalculateNextLayer(hiddenLayer1, weights2, hiddenLayer2, biasHiddenLayer1);
    CalculateNextLayer(hiddenLayer2, weights3, output, new float[] {0});
    
    output[0] = SigmoidActivationFunction(output[0]);
    
    println("Output: " + output[0]);
    println("--------------------------------------------------------");
  }
  
  //Calculate a single layer
  void CalculateNextLayer(float[] _startLayer, float[] _weights, float[] _endLayer, float[] bias){
    int x = 0;//Weight counter
    float total = 0;//Number to do operations on
    //println("In, Weight, Out----------");
    
    //Loop through all output nodes
    for(int i = 0; i < _endLayer.length; i++){
      //println("Node: " + (i + 1));//Display which node is being calculated
      x = i;//Set weight equal to the node that is being calculated
      
      //Loop through all input nodes
      for(int j = 0; j < _startLayer.length; j++){
        total += _startLayer[j] * _weights[x];
        //println(_startLayer[j] + ", " + _weights[x] + ", " + (_startLayer[j] * _weights[x]));//Print current operation
        x += _endLayer.length - 1;//Skip the correct amount of weights for it to corrospond to the correct input and output nodes
      }
      //Average the output of the nodes and add the bias
      _endLayer[i] = total / (i + 1) + bias[i];
    }
  }
  
  float SigmoidActivationFunction(float _num){
    return 2 / (1 + pow(2.71828, 5 * (_num))) - 1;
  }
  
  void WriteStructureToFile(String path){
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
  
  void StoreLayer(float[] values){
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
  
  void InheritSingleParent(NeuralNet parent){//Includes mutation
    InheritSingleLayer(weights1, parent.weights1);
    InheritSingleLayer(biasHiddenLayer1, parent.biasHiddenLayer1);
    InheritSingleLayer(weights2, parent.weights2);
    InheritSingleLayer(biasHiddenLayer2, parent.biasHiddenLayer2);
    InheritSingleLayer(weights3, parent.weights3);
    
    mutationRate *= mutationAcceleration;
    mutationAcceleration *= mutationJerk;
    mutationRateDisplay = mutationRate;
  }
  
  void InheritSingleLayer(float[] _ownLayer, float[] _parentLayer){
    for (int i = 0; i < _ownLayer.length; i++){
      _ownLayer[i] = _parentLayer[i] + random(-mutationRate, mutationRate);
    }
  }
  
  void Inherit(NeuralNet mother, NeuralNet father){
    InheritLayer(weights1, mother.weights1, father.weights1);
    InheritLayer(biasHiddenLayer1, mother.biasHiddenLayer1, father.biasHiddenLayer1);
    InheritLayer(weights2, mother.weights2, father.weights2);
    InheritLayer(biasHiddenLayer2, mother.biasHiddenLayer2, father.biasHiddenLayer2);
    InheritLayer(weights3, mother.weights3, father.weights3);
    
    mutationRate *= mutationAcceleration;
    mutationAcceleration *= mutationJerk;
    mutationRateDisplay = mutationRate;
  }
  
  void InheritLayer(float[] _ownLayer, float[] _motherLayer, float[] _fatherLayer){
    for (int i = 0; i < _ownLayer.length; i++){
      _ownLayer[i] = random(_motherLayer[i], _fatherLayer[i]);
    }
  }
  
  void AddFitness(int _val){
    fitness += _val;
    println("==Current fitness: " + fitness + "==");
  }
  
  void Mutate(){
    MutateLayer(weights1);
    MutateLayer(biasHiddenLayer1);
    MutateLayer(weights2);
    MutateLayer(biasHiddenLayer2);
    MutateLayer(weights3);
    
    mutationRate *= mutationAcceleration;
    mutationAcceleration *= mutationJerk;
    mutationRateDisplay = mutationRate;
  }
  
  void MutateLayer(float[] _layer){
    for(int i = 0; i < _layer.length; i++){
      if(random(0,100) < 10){
        _layer[i] += random(-mutationRate, mutationRate);
      }
      
      if(_layer[i] < -1f){
        _layer[i] = -1f;
      }
      else if (_layer[i] > 1f){
        _layer[i] = 1f;
      }
    }
  }
  
  //Randomize the weights and biases
  void RandomizeNetwork(){
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
  void RandomizeLayer(float[] _layer){
    for(int i = 0; i < _layer.length; i++){
      _layer[i] = random(-1f, 1f);
      print(_layer[i] + ", ");
    }
    println(";");
  }
  
  int GetFitness(){
    return fitness;
  }
  
  void InjectNetwork(String[] _layers){    
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
