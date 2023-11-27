local ReinforcementLearningNeuralNetworkBaseModel = require(script.Parent.ReinforcementLearningNeuralNetworkBaseModel)

QLearningNeuralNetworkModel = {}

QLearningNeuralNetworkModel.__index = QLearningNeuralNetworkModel

setmetatable(QLearningNeuralNetworkModel, ReinforcementLearningNeuralNetworkBaseModel)

function QLearningNeuralNetworkModel.new(maxNumberOfIterations, learningRate, targetCost, numberOfReinforcementsPerEpisode, epsilon, epsilonDecayFactor, discountFactor)

	local NewQLearningNeuralNetworkModel = ReinforcementLearningNeuralNetworkBaseModel.new(maxNumberOfIterations, learningRate, targetCost, numberOfReinforcementsPerEpisode, epsilon, epsilonDecayFactor, discountFactor)
	
	setmetatable(NewQLearningNeuralNetworkModel, QLearningNeuralNetworkModel)
	
	NewQLearningNeuralNetworkModel:setUpdateFunction(function(previousFeatureVector, action, rewardValue, currentFeatureVector)

		if (NewQLearningNeuralNetworkModel.ModelParameters == nil) then NewQLearningNeuralNetworkModel:generateLayers() end

		local predictedValue, maxQValue = NewQLearningNeuralNetworkModel:predict(currentFeatureVector)

		local target = rewardValue + (NewQLearningNeuralNetworkModel.discountFactor * maxQValue[1][1])

		local targetVector = NewQLearningNeuralNetworkModel:predict(previousFeatureVector, true)

		local actionIndex = table.find(NewQLearningNeuralNetworkModel.ClassesList, action)

		targetVector[1][actionIndex] = target

		NewQLearningNeuralNetworkModel:train(previousFeatureVector, targetVector)

	end)

	return NewQLearningNeuralNetworkModel

end

function QLearningNeuralNetworkModel:setParameters(maxNumberOfIterations, learningRate, targetCost, numberOfReinforcementsPerEpisode, epsilon, epsilonDecayFactor, discountFactor)
	
	self.maxNumberOfIterations = maxNumberOfIterations or self.maxNumberOfIterations

	self.learningRate = learningRate or self.learningRate

	self.targetCost = targetCost or self.targetCost
	
	self.numberOfReinforcementsPerEpisode = numberOfReinforcementsPerEpisode or self.numberOfReinforcementsPerEpisode

	self.epsilon = epsilon or self.epsilon

	self.epsilonDecayFactor =  epsilonDecayFactor or self.epsilonDecayFactor

	self.discountFactor =  discountFactor or self.discountFactor

	self.currentEpsilon = epsilon or self.currentEpsilon

end

return QLearningNeuralNetworkModel
