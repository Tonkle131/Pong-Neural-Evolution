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
  float mutationRate = 0.5;
  float mutationAcceleration = 0.75;
  float mutationJerk = 1;
  
  //Network saving
  public Boolean printStructure = false;
  final String networkStructurePath = "networkStructure.txt";
  String[] data = new String[5];
  int lineCounter = 0;
  
  //Take variables from game and set them as the inputs to the network
  void UpdateInputs(float[] _inputs){
    println("--------------------------------------------------------");
    inputs = _inputs;
    for(int i = 0; i < inputs.length; i++){
      Math.round(inputs[i]);
    }
   
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
    InheritSingleLayerFromSingleParent(weights1, parent.weights1);
    InheritSingleLayerFromSingleParent(biasHiddenLayer1, parent.biasHiddenLayer1);
    InheritSingleLayerFromSingleParent(weights2, parent.weights2);
    InheritSingleLayerFromSingleParent(biasHiddenLayer2, parent.biasHiddenLayer2);
    InheritSingleLayerFromSingleParent(weights3, parent.weights3);
    
    Mutate();
  }
  
  void InheritSingleLayerFromSingleParent(float[] _ownLayer, float[] _parentLayer){
    for (int i = 0; i < _ownLayer.length; i++){
      _ownLayer[i] = _parentLayer[i];
    }
  }
  
  void Inherit(NeuralNet mother, NeuralNet father){
    InheritLayer(weights1, mother.weights1, father.weights1);
    InheritLayer(biasHiddenLayer1, mother.biasHiddenLayer1, father.biasHiddenLayer1);
    InheritLayer(weights2, mother.weights2, father.weights2);
    InheritLayer(biasHiddenLayer2, mother.biasHiddenLayer2, father.biasHiddenLayer2);
    InheritLayer(weights3, mother.weights3, father.weights3);
    
    Mutate();
  }
  
  void InheritLayer(float[] _ownLayer, float[] _motherLayer, float[] _fatherLayer){
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
  
  void AddFitness(int _val){
    fitness += _val;
    println("==Current fitness: " + fitness + "==");
  }
  
  void Mutate(){
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
  
  void MutateLayer(float[] _layer, boolean isBias){
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
