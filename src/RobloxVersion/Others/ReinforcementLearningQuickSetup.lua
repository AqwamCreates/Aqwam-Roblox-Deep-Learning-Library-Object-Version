local AqwamMatrixLibrary = require(script.Parent.Parent.AqwamMatrixLibraryLinker.Value)

ReinforcementLearningQuickSetup = {}

ReinforcementLearningQuickSetup.__index = ReinforcementLearningQuickSetup

local defaultNumberOfReinforcementsPerEpisode = 500

local defaultEpsilon = 0

local defaultEpsilonDecayFactor = 0

local defaultActionSelectionFunction = "Maximum"

local function sampleAction(actionProbabilityVector)

	local totalProbability = 0

	for _, probability in ipairs(actionProbabilityVector[1]) do

		totalProbability += probability

	end

	local randomValue = math.random() * totalProbability

	local cumulativeProbability = 0

	local actionIndex = 1

	for i, probability in ipairs(actionProbabilityVector[1]) do

		cumulativeProbability += probability

		if (randomValue > cumulativeProbability) then continue end

		actionIndex = i

		break

	end

	return actionIndex

end

local function calculateProbability(outputMatrix)

	local meanVector = AqwamMatrixLibrary:horizontalMean(outputMatrix)

	local standardDeviationVector = AqwamMatrixLibrary:horizontalStandardDeviation(outputMatrix)

	local zScoreVectorPart1 = AqwamMatrixLibrary:subtract(outputMatrix, meanVector)

	local zScoreVector = AqwamMatrixLibrary:divide(zScoreVectorPart1, standardDeviationVector)

	local zScoreSquaredVector = AqwamMatrixLibrary:power(zScoreVector, 2)

	local probabilityVectorPart1 = AqwamMatrixLibrary:multiply(-0.5, zScoreSquaredVector)

	local probabilityVectorPart2 = AqwamMatrixLibrary:applyFunction(math.exp, probabilityVectorPart1)

	local probabilityVectorPart3 = AqwamMatrixLibrary:multiply(standardDeviationVector, math.sqrt(2 * math.pi))

	local probabilityVector = AqwamMatrixLibrary:divide(probabilityVectorPart2, probabilityVectorPart3)

	return probabilityVector

end

function ReinforcementLearningQuickSetup.new(numberOfReinforcementsPerEpisode, epsilon, epsilonDecayFactor, actionSelectionFunction)
	
	local NewReinforcementLearningQuickSetup = {}
	
	setmetatable(NewReinforcementLearningQuickSetup, ReinforcementLearningQuickSetup)
	
	NewReinforcementLearningQuickSetup.numberOfReinforcementsPerEpisode = numberOfReinforcementsPerEpisode or defaultNumberOfReinforcementsPerEpisode

	NewReinforcementLearningQuickSetup.epsilon = epsilon or defaultEpsilon

	NewReinforcementLearningQuickSetup.epsilonDecayFactor = epsilonDecayFactor or defaultEpsilon
	
	NewReinforcementLearningQuickSetup.currentEpsilon = epsilon or defaultEpsilon
	
	NewReinforcementLearningQuickSetup.actionSelectionFunction = actionSelectionFunction or defaultActionSelectionFunction
	
	NewReinforcementLearningQuickSetup.Model = nil
	
	NewReinforcementLearningQuickSetup.ExperienceReplay = nil
	
	NewReinforcementLearningQuickSetup.previousFeatureVector = nil
	
	NewReinforcementLearningQuickSetup.currentNumberOfReinforcements = 0

	NewReinforcementLearningQuickSetup.currentNumberOfEpisodes = 0
	
	NewReinforcementLearningQuickSetup.ClassesList = {}
	
	NewReinforcementLearningQuickSetup.updateFunction = nil
	
	NewReinforcementLearningQuickSetup.episodeUpdateFunction = nil
	
	return NewReinforcementLearningQuickSetup
	
end

function ReinforcementLearningQuickSetup:setParameters(numberOfReinforcementsPerEpisode, epsilon, epsilonDecayFactor, actionSelectionFunction)
	
	self.numberOfReinforcementsPerEpisode = numberOfReinforcementsPerEpisode or self.numberOfReinforcementsPerEpisode

	self.epsilon = epsilon or self.epsilon 

	self.epsilonDecayFactor = epsilonDecayFactor or self.epsilonDecayFactor
	
	self.currentEpsilon = epsilon or self.currentEpsilon
	
	self.actionSelectionFunction = actionSelectionFunction or self.actionSelectionFunction
	
end

function ReinforcementLearningQuickSetup:setExperienceReplay(ExperienceReplay)

	self.ExperienceReplay = ExperienceReplay

end

function ReinforcementLearningQuickSetup:setModel(Model)

	self.Model = Model or self.Model

end

function ReinforcementLearningQuickSetup:setClassesList(classesList)

	self.ClassesList = classesList

end

function ReinforcementLearningQuickSetup:extendUpdateFunction(updateFunction)

	self.updateFunction = updateFunction

end

function ReinforcementLearningQuickSetup:extendEpisodeUpdateFunction(episodeUpdateFunction)

	self.episodeUpdateFunction = episodeUpdateFunction

end

local function getBooleanOrDefaultOption(boolean, defaultBoolean)

	if (type(boolean) == "nil") then return defaultBoolean end

	return boolean

end

function ReinforcementLearningQuickSetup:setPrintReinforcementOutput(option)

	self.printReinforcementOutput = getBooleanOrDefaultOption(option, self.printReinforcementOutput)

end

function ReinforcementLearningQuickSetup:fetchHighestValueInVector(outputVector)

	local highestValue, classIndex = AqwamMatrixLibrary:findMaximumValue(outputVector)

	if (classIndex == nil) then return nil, highestValue end

	local predictedLabel = self.ClassesList[classIndex[2]]

	return predictedLabel, highestValue

end

function ReinforcementLearningQuickSetup:getLabelFromOutputMatrix(outputMatrix)

	local predictedLabelVector = AqwamMatrixLibrary:createMatrix(#outputMatrix, 1)

	local highestValueVector = AqwamMatrixLibrary:createMatrix(#outputMatrix, 1)

	local highestValue

	local outputVector

	local classIndex

	local predictedLabel

	for i = 1, #outputMatrix, 1 do

		outputVector = {outputMatrix[i]}

		predictedLabel, highestValue = self:fetchHighestValueInVector(outputVector)

		predictedLabelVector[i][1] = predictedLabel

		highestValueVector[i][1] = highestValue

	end

	return predictedLabelVector, highestValueVector

end

function ReinforcementLearningQuickSetup:selectAction(currentFeatureVector, classesList, childModelNumber)
	
	local allOutputsMatrix = self.Model:predict(currentFeatureVector, true, childModelNumber)
	
	local actionSelectionFunction = self.actionSelectionFunction
	
	local action
	
	local selectedValue
	
	if (actionSelectionFunction == "Maximum") then
		
		local actionVector, selectedValueVector = self:getLabelFromOutputMatrix(allOutputsMatrix)
		
		action = actionVector[1][1]

		selectedValue = selectedValueVector[1][1]
		
	elseif (actionSelectionFunction == "Sample") then
		
		local actionProbabilityVector = calculateProbability(allOutputsMatrix)
		
		local actionIndex = sampleAction(actionProbabilityVector)
		
		action = classesList[actionIndex]
		
		selectedValue = allOutputsMatrix[1][actionIndex]
		
	end
	
	return action, selectedValue, allOutputsMatrix
	
end

function ReinforcementLearningQuickSetup:reinforce(currentFeatureVector, rewardValue, returnOriginalOutput, childModelNumber)

	if (self.Model == nil) then error("No model!") end
	
	local randomProbability = Random.new():NextNumber()
	
	local ExperienceReplay = self.ExperienceReplay
	
	local previousFeatureVector = self.previousFeatureVector
	
	local Model = self.Model
	
	local classesList = self.ClassesList
	
	local updateFunction = self.updateFunction

	local action

	local selectedValue

	local allOutputsMatrix

	local temporalDifferenceError

	self.currentNumberOfReinforcements += 1

	if (randomProbability < self.currentEpsilon) then

		local numberOfClasses = #classesList

		local randomNumber = Random.new():NextInteger(1, numberOfClasses)

		action = classesList[randomNumber]

		allOutputsMatrix = AqwamMatrixLibrary:createMatrix(1, numberOfClasses)

		allOutputsMatrix[1][randomNumber] = randomProbability

	else

		action, selectedValue, allOutputsMatrix = self:selectAction(currentFeatureVector, classesList, childModelNumber)

	end

	if (previousFeatureVector) then 

		temporalDifferenceError = Model:update(previousFeatureVector, action, rewardValue, currentFeatureVector, childModelNumber) 

	end

	if (self.currentNumberOfReinforcements >= self.numberOfReinforcementsPerEpisode) then
		
		local episodeUpdateFunction = self.episodeUpdateFunction
		
		self.currentNumberOfReinforcements = 0

		Model:episodeUpdate(childModelNumber)
		
		if episodeUpdateFunction then episodeUpdateFunction(childModelNumber) end

	end

	if (ExperienceReplay) and (previousFeatureVector) then

		ExperienceReplay:addExperience(previousFeatureVector, action, rewardValue, currentFeatureVector)

		ExperienceReplay:addTemporalDifferenceError(temporalDifferenceError)

		ExperienceReplay:run(function(storedPreviousFeatureVector, storedAction, storedRewardValue, storedCurrentFeatureVector)

			return Model:update(storedPreviousFeatureVector, storedAction, storedRewardValue, storedCurrentFeatureVector)

		end)

	end
	
	if updateFunction then updateFunction(childModelNumber) end

	self.previousFeatureVector = currentFeatureVector

	if (self.printReinforcementOutput) then print("Episode: " .. self.currentNumberOfEpisodes .. "\t\tEpsilon: " .. self.currentEpsilon .. "\t\tReinforcement Count: " .. self.currentNumberOfReinforcements) end

	if (returnOriginalOutput) then return allOutputsMatrix end

	return action, selectedValue

end

function ReinforcementLearningQuickSetup:getCurrentNumberOfEpisodes()

	return self.currentNumberOfEpisodes

end

function ReinforcementLearningQuickSetup:getCurrentNumberOfReinforcements()

	return self.currentNumberOfReinforcements

end

function ReinforcementLearningQuickSetup:getCurrentEpsilon()

	return self.currentEpsilon

end

function ReinforcementLearningQuickSetup:getModel()
	
	return self.Model
	
end

function ReinforcementLearningQuickSetup:getClassesList()
	
	return self.ClassesList
	
end

function ReinforcementLearningQuickSetup:getExperienceReplay()
	
	return self.ExperienceReplay
	
end

function ReinforcementLearningQuickSetup:reset()
	
	self.currentNumberOfReinforcements = 0

	self.currentNumberOfEpisodes = 0

	self.previousFeatureVector = nil

	self.currentEpsilon = self.epsilon
	
	if (self.ExperienceReplay) then self.ExperienceReplay:reset() end
	
end

return ReinforcementLearningQuickSetup
