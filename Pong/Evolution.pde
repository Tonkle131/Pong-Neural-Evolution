import java.util.Collections;

public class Evolution{
  
  public int topFitnessOfGen = -99999999;
  public NeuralNet topNetOfGen = networks[0];
  
  final Boolean singleParent = true;
  
  void Evolve(NeuralNet[] networks){
    SortByFitness(networks);
  }
  
  void SortByFitness(NeuralNet[] networks){
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
  
  void GenerateGeneration(NeuralNet[] networks){
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
