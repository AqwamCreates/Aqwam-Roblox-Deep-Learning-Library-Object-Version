# [API Reference](../../API.md) - [Models](../Models.md) - DuelingQLearning

DuelingQLearning is a base class for reinforcement learning.

## Notes:

* The Advantage and Value models must be created separately. Then use setAdvantageModel() and setValueModel() to put it inside the DuelingQLearning model.

* Advantage and Value models must be a part of NeuralNetwork model. If you decide to use linear regression or logistic regression, then it must be constructed using NeuralNetwork model. 

* Ensure the final layer of the Value model has only one neuron. It is the default setting for all Value models in research papers.

## Constructors

### new()

Create new model object. If any of the arguments are nil, default argument values for that argument will be used.

```
DuelingQLearning.new(discountFactor: number): ModelObject
```

#### Parameters:

* discountFactor: The higher the value, the more likely it focuses on long-term outcomes. The value must be set between 0 and 1.

#### Returns:

* ModelObject: The generated model object.

## Functions

### setParameters()

Set model's parameters. When any of the arguments are nil, previous argument values for that argument will be used.

```
DuelingQLearning:setParameters(discountFactor: number)
```

#### Parameters:

* discountFactor: The higher the value, the more likely it focuses on long-term outcomes. The value must be set between 0 and 1.

### setAdvantageModel()

```
DuelingQLearning:setAdvantageModel(Model: ModelObject)
```

#### Parameters:

* Model: The model to be used as an Advantage model.

### setValueModel()

```
DuelingQLearning:setValueModel(Model: ModelObject)
```

#### Parameters:

* Model: The model to be used as a Value model.

### setExperienceReplay()

Set model's settings for experience replay capabilities. When any parameters are set to nil, then it will use previous settings for that particular parameter.

```
DuelingQLearning:setExperienceReplay(ExperienceReplay: ExperienceReplayObject)
```

### setClassesList()

```
DuelingQLearning:setClassesList(classesList: [])
```

#### Parameters:

* classesList: A list of classes. The index of the class relates to which the neuron at output layer belong to. For example, {3, 1} means that the output for 3 is at first neuron, and the output for 1 is at second neuron.

#### Parameters:

* ExperienceReplay: The experience replay object.

### reinforce()

Reward or punish model based on the current state of the environment.

```
DuelingQLearning:reinforce(currentFeatureVector: Matrix, rewardValue: number, returnOriginalOutput: boolean): integer, number -OR- Matrix
```

#### Parameters:

* currentFeatureVector: Matrix containing data from the current state.

* rewardValue: The reward value added/subtracted from the current state (recommended value between -1 and 1, but can be larger than these values). 

* returnOriginalOutput: Set whether or not to return predicted vector instead of value with highest probability.

#### Returns:

* predictedLabel: A label that is predicted by the model.

* value: The value of predicted label.

-OR-

* predictedVector: A matrix containing all predicted values from all classes.

### setPrintReinforcementOutput()

Set whether or not to show the current number of episodes and current epsilon.

```
DuelingQLearning:setPrintReinforcementOutput(option: boolean)
```
#### Parameters:

* option: A boolean value that determines the reinforcement output to be printed or not.

### update()

Updates the model parameters.

```
DuelingQLearning:update(previousFeatiureVector: featureVector, action: number/string, rewardValue: number, currentFeatureVector: featureVector)
```

#### Parameters:

* previousFeatiureVector: The previous state of the environment.

* action: The action selected.

* rewardValue: The reward gained at current state.

* currentFeatureVector: The currrent state of the environment.

### reset()

Reset model's stored values (excluding the parameters).

```
DuelingQLearning:reset()
```

### destroy()

Destroys the model object.

```
ActorCritic:destroy()
```

## References

* [Dueling Deep Q Networks by Chris Yoon](https://towardsdatascience.com/dueling-deep-q-networks-81ffab672751)
