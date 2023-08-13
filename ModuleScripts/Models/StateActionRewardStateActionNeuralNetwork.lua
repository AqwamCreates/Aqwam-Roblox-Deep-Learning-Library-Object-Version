local NeuralNetworkModel = require(script.Parent.NeuralNetwork)

StateActionRewardStateActionNeuralNetworkModel = {}

StateActionRewardStateActionNeuralNetworkModel.__index = StateActionRewardStateActionNeuralNetworkModel

local AqwamMatrixLibrary = require(script.Parent.Parent.AqwamRobloxMatrixLibraryLinker.Value)

setmetatable(StateActionRewardStateActionNeuralNetworkModel, NeuralNetworkModel)

local defaultMaxNumberOfEpisode = 500

local defaultEpsilon = 0.5

local defaultEpsilonDecayFactor = 0.999

local defaultDiscountFactor = 0.95

local defaultMaxNumberOfIterations = 1

function StateActionRewardStateActionNeuralNetworkModel.new(maxNumberOfIterations, learningRate, targetCost, maxNumberOfEpisodes, epsilon, epsilonDecayFactor, discountFactor)
	
	maxNumberOfIterations = maxNumberOfIterations or defaultMaxNumberOfIterations

	local NewStateActionRewardStateActionNeuralNetworkModel = NeuralNetworkModel.new(maxNumberOfIterations, learningRate, targetCost)
	
	NewStateActionRewardStateActionNeuralNetworkModel:setPrintOutput(false)

	setmetatable(NewStateActionRewardStateActionNeuralNetworkModel, StateActionRewardStateActionNeuralNetworkModel)

	NewStateActionRewardStateActionNeuralNetworkModel.maxNumberOfEpisodes = maxNumberOfEpisodes or defaultMaxNumberOfEpisode

	NewStateActionRewardStateActionNeuralNetworkModel.epsilon = epsilon or defaultEpsilon

	NewStateActionRewardStateActionNeuralNetworkModel.epsilonDecayFactor =  epsilonDecayFactor or defaultEpsilonDecayFactor

	NewStateActionRewardStateActionNeuralNetworkModel.discountFactor =  discountFactor or defaultDiscountFactor

	NewStateActionRewardStateActionNeuralNetworkModel.currentNumberOfEpisodes = 0

	NewStateActionRewardStateActionNeuralNetworkModel.currentEpsilon = epsilon or defaultEpsilon

	NewStateActionRewardStateActionNeuralNetworkModel.previousFeatureVector = nil
	
	NewStateActionRewardStateActionNeuralNetworkModel.printReinforcementOutput = true

	return NewStateActionRewardStateActionNeuralNetworkModel

end

function StateActionRewardStateActionNeuralNetworkModel:setPrintReinforcementOutput(option)

	self.printReinforcementOutput = self:getBooleanOrDefaultOption(option, self.printReinforcementOutput)

end

function StateActionRewardStateActionNeuralNetworkModel:setParameters(maxNumberOfIterations, learningRate, targetCost, maxNumberOfEpisodes, epsilon, epsilonDecayFactor, discountFactor)
	
	self.maxNumberOfIterations = maxNumberOfIterations or self.maxNumberOfIterations

	self.learningRate = learningRate or self.learningRate

	self.targetCost = targetCost or self.targetCost
	
	self.maxNumberOfEpisodes = maxNumberOfEpisodes or self.maxNumberOfEpisodes

	self.epsilon = epsilon or self.epsilon

	self.epsilonDecayFactor =  epsilonDecayFactor or self.epsilonDecayFactor

	self.discountFactor =  discountFactor or self.discountFactor

	self.currentEpsilon = epsilon or self.currentEpsilon

end

function StateActionRewardStateActionNeuralNetworkModel:update(previousFeatureVector, currentFeatureVector, rewardValue)

	if (self.ModelParameters == nil) then self:generateLayers() end

	local predictedVector = self:predict(previousFeatureVector, true)
	
	local targetVector = self:predict(currentFeatureVector, true)
	
	local rewardVectorPart1 = AqwamMatrixLibrary:multiply(self.discountFactor, targetVector)
	
	local rewardVector = AqwamMatrixLibrary:add(rewardValue, rewardVectorPart1)
	
	local calculatedReward = AqwamMatrixLibrary:subtract(rewardVector, predictedVector)
	
	local newTargetVector = AqwamMatrixLibrary:add(predictedVector, calculatedReward)
	
	self:train(previousFeatureVector, newTargetVector)

end

function StateActionRewardStateActionNeuralNetworkModel:reset()
	
	self.currentNumberOfEpisodes = 0
	
	self.previousFeatureVector = nil

	self.currentEpsilon = self.epsilon
	
	for i, Optimizer in ipairs(self.OptimizerTable) do

		if Optimizer then Optimizer:reset() end

	end

end

function StateActionRewardStateActionNeuralNetworkModel:reinforce(currentFeatureVector, rewardValue)
	
	if (self.ModelParameters == nil) then self:generateLayers() end
	
	if (self.previousFeatureVector == nil) then

		self.previousFeatureVector = currentFeatureVector

		return nil

	end
	
	if (self.currentNumberOfEpisodes == 0) then

		self.currentEpsilon *= self.epsilonDecayFactor

	end

	self.currentNumberOfEpisodes = (self.currentNumberOfEpisodes + 1) % self.maxNumberOfEpisodes

	local currentAction
	
	local highestProbability

	local randomProbability = Random.new():NextNumber()
	
	if (randomProbability < self.epsilon) then

		local randomNumber = Random.new():NextInteger(1, #self.ClassesList)

		currentAction = self.ClassesList[randomNumber]
		
		highestProbability = randomProbability

	else

		currentAction, highestProbability = self:predict(currentFeatureVector)

	end

	self:update(self.previousFeatureVector, currentFeatureVector, rewardValue)
	
	if (self.printReinforcementOutput == true) then print("Current Number Of Episodes: " .. self.currentNumberOfEpisodes .. "\t\tCurrent Epsilon: " .. self.currentEpsilon) end
	
	return currentAction, highestProbability

end

return StateActionRewardStateActionNeuralNetworkModel
