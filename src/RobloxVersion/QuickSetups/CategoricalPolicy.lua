--[[

	--------------------------------------------------------------------

	Aqwam's Machine And Deep Learning Library (DataPredict)

	Author: Aqwam Harish Aiman
	
	Email: aqwam.harish.aiman@gmail.com
	
	YouTube: https://www.youtube.com/channel/UCUrwoxv5dufEmbGsxyEUPZw
	
	LinkedIn: https://www.linkedin.com/in/aqwam-harish-aiman/
	
	--------------------------------------------------------------------
		
	By using this library, you agree to comply with our Terms and Conditions in the link below:
	
	https://github.com/AqwamCreates/DataPredict/blob/main/docs/TermsAndConditions.md
	
	--------------------------------------------------------------------
	
	DO NOT REMOVE THIS TEXT!
	
	--------------------------------------------------------------------

--]]

local AqwamMatrixLibrary = require(script.Parent.Parent.AqwamMatrixLibraryLinker.Value)

CategoricalPolicyQuickSetup = {}

CategoricalPolicyQuickSetup.__index = CategoricalPolicyQuickSetup

local defaultNumberOfReinforcementsPerEpisode = 500

local defaultEpsilon = 0

local defaultActionSelectionFunction = "Maximum"

local function selectActionWithHighestValue(actionOutputVector)
	
	local selectedActionIndex = 1
	
	local highestActionValue = -math.huge
	
	for actionIndex, actionValue in ipairs(actionOutputVector[1]) do

		if (highestActionValue > actionValue) then

			highestActionValue = actionValue

			selectedActionIndex = actionIndex

		end

	end
	
	return selectedActionIndex
	
end

local function calculateProbability(vector)

	local meanVector = AqwamMatrixLibrary:horizontalMean(vector)

	local standardDeviationVector = AqwamMatrixLibrary:horizontalStandardDeviation(vector)

	local zScoreVectorPart1 = AqwamMatrixLibrary:subtract(vector, meanVector)

	local zScoreVector = AqwamMatrixLibrary:divide(zScoreVectorPart1, standardDeviationVector)

	local zScoreSquaredVector = AqwamMatrixLibrary:power(zScoreVector, 2)

	local probabilityVectorPart1 = AqwamMatrixLibrary:multiply(-0.5, zScoreSquaredVector)

	local probabilityVectorPart2 = AqwamMatrixLibrary:applyFunction(math.exp, probabilityVectorPart1)

	local probabilityVectorPart3 = AqwamMatrixLibrary:multiply(standardDeviationVector, math.sqrt(2 * math.pi))

	local probabilityVector = AqwamMatrixLibrary:divide(probabilityVectorPart2, probabilityVectorPart3)

	return probabilityVector

end

local function sampleAction(actionOutputVector)
	
	local actionProbabilityVector = calculateProbability(actionOutputVector)

	local totalProbability = 0

	for _, probability in ipairs(actionProbabilityVector[1]) do

		totalProbability += probability

	end

	local randomValue = math.random() * totalProbability

	local cumulativeProbability = 0

	local selectedActionIndex = 1

	for i, probability in ipairs(actionProbabilityVector[1]) do

		cumulativeProbability += probability

		if (randomValue > cumulativeProbability) then continue end

		selectedActionIndex = i

		break

	end

	return selectedActionIndex

end

function CategoricalPolicyQuickSetup.new(numberOfReinforcementsPerEpisode, epsilon, actionSelectionFunction)
	
	local NewCategoricalPolicyQuickSetup = {}
	
	setmetatable(NewCategoricalPolicyQuickSetup, CategoricalPolicyQuickSetup)
	
	NewCategoricalPolicyQuickSetup.isOutputPrinted = true
	
	NewCategoricalPolicyQuickSetup.numberOfReinforcementsPerEpisode = numberOfReinforcementsPerEpisode or defaultNumberOfReinforcementsPerEpisode

	NewCategoricalPolicyQuickSetup.epsilon = epsilon or defaultEpsilon
	
	NewCategoricalPolicyQuickSetup.currentEpsilon = epsilon or defaultEpsilon
	
	NewCategoricalPolicyQuickSetup.actionSelectionFunction = actionSelectionFunction or defaultActionSelectionFunction
	
	NewCategoricalPolicyQuickSetup.Model = nil
	
	NewCategoricalPolicyQuickSetup.ExperienceReplay = nil
	
	NewCategoricalPolicyQuickSetup.EpsilonValueScheduler = nil
	
	NewCategoricalPolicyQuickSetup.previousFeatureVector = nil
	
	NewCategoricalPolicyQuickSetup.currentNumberOfReinforcements = 0

	NewCategoricalPolicyQuickSetup.currentNumberOfEpisodes = 0
	
	NewCategoricalPolicyQuickSetup.ClassesList = {}
	
	NewCategoricalPolicyQuickSetup.updateFunction = nil
	
	NewCategoricalPolicyQuickSetup.episodeUpdateFunction = nil
	
	return NewCategoricalPolicyQuickSetup
	
end

function CategoricalPolicyQuickSetup:setParameters(numberOfReinforcementsPerEpisode, epsilon, actionSelectionFunction)
	
	self.numberOfReinforcementsPerEpisode = numberOfReinforcementsPerEpisode or self.numberOfReinforcementsPerEpisode

	self.epsilon = epsilon or self.epsilon 
	
	self.currentEpsilon = epsilon or self.currentEpsilon
	
	self.actionSelectionFunction = actionSelectionFunction or self.actionSelectionFunction
	
end

function CategoricalPolicyQuickSetup:extendUpdateFunction(updateFunction)

	self.updateFunction = updateFunction

end

function CategoricalPolicyQuickSetup:extendEpisodeUpdateFunction(episodeUpdateFunction)

	self.episodeUpdateFunction = episodeUpdateFunction

end

local function getBooleanOrDefaultOption(boolean, defaultBoolean)

	if (type(boolean) == "nil") then return defaultBoolean end

	return boolean

end

function CategoricalPolicyQuickSetup:setPrintOutput(option)

	self.isOutputPrinted = getBooleanOrDefaultOption(option, self.isOutputPrinted)

end

function CategoricalPolicyQuickSetup:fetchHighestValueInVector(outputVector)

	local highestValue, classIndex = AqwamMatrixLibrary:findMaximumValue(outputVector)

	if (classIndex == nil) then return nil, highestValue end

	local predictedLabel = self.ClassesList[classIndex[2]]

	return predictedLabel, highestValue

end

local selectActionFunctionList = {
	
	["Maximum"] = selectActionWithHighestValue,
	
	["Sample"] = sampleAction
	
}

function CategoricalPolicyQuickSetup:reinforce(currentFeatureVector, rewardValue, returnOriginalOutput, childModelNumber)

	if (self.Model == nil) then error("No model!") end
	
	local currentNumberOfReinforcements = self.currentNumberOfReinforcements
	
	local currentNumberOfEpisodes = self.currentNumberOfEpisodes
	
	local ExperienceReplay = self.ExperienceReplay
	
	local EpsilonValueScheduler = self.EpsilonValueScheduler
	
	local currentEpsilon = self.currentEpsilon
	
	local previousFeatureVector = self.previousFeatureVector
	
	local Model = self.Model
	
	local ClassesList = self.ClassesList
	
	local updateFunction = self.updateFunction
	
	local randomProbability = Random.new():NextNumber()
	
	local actionVector = Model:predict(currentFeatureVector, true, childModelNumber)
	
	local actionIndex
	
	local action

	local actionValue

	local temporalDifferenceError

	if (randomProbability < currentEpsilon) then
		
		actionIndex = Random.new():NextInteger(1, #ClassesList)

	else
		
		actionIndex = selectActionFunctionList[self.actionSelectionFunction](actionVector)

	end
	
	action = ClassesList[actionIndex]

	actionValue = actionVector[1][actionIndex]

	if (previousFeatureVector) then
		
		currentNumberOfReinforcements = currentNumberOfReinforcements + 1

		temporalDifferenceError = Model:categoricalUpdate(previousFeatureVector, action, rewardValue, currentFeatureVector, childModelNumber)
		
		if (updateFunction) then updateFunction(childModelNumber) end

	end

	if (currentNumberOfReinforcements >= self.numberOfReinforcementsPerEpisode) then
		
		local episodeUpdateFunction = self.episodeUpdateFunction
		
		currentNumberOfReinforcements = 0
		
		currentNumberOfEpisodes = currentNumberOfEpisodes + 1

		Model:categoricalEpisodeUpdate(childModelNumber)
		
		if episodeUpdateFunction then episodeUpdateFunction(childModelNumber) end

	end

	if (ExperienceReplay) and (previousFeatureVector) then

		ExperienceReplay:addExperience(previousFeatureVector, action, rewardValue, currentFeatureVector)

		ExperienceReplay:addTemporalDifferenceError(temporalDifferenceError)

		ExperienceReplay:run(function(storedPreviousFeatureVector, storedAction, storedRewardValue, storedCurrentFeatureVector)

			return Model:update(storedPreviousFeatureVector, storedAction, storedRewardValue, storedCurrentFeatureVector)

		end)

	end
	
	if (EpsilonValueScheduler) and (previousFeatureVector) then
		
		currentEpsilon = EpsilonValueScheduler:calculate(currentEpsilon)
		
		self.currentEpsilon = currentEpsilon
		
	end
	
	self.currentNumberOfReinforcements = currentNumberOfReinforcements
	
	self.currentNumberOfEpisodes = currentNumberOfEpisodes
	
	self.previousFeatureVector = currentFeatureVector

	if (self.isOutputPrinted) then print("Episode: " .. currentNumberOfEpisodes .. "\t\tEpsilon: " .. currentEpsilon .. "\t\tReinforcement Count: " .. currentNumberOfReinforcements) end

	if (returnOriginalOutput) then return actionVector end

	return action, actionValue

end

function CategoricalPolicyQuickSetup:setExperienceReplay(ExperienceReplay)

	self.ExperienceReplay = ExperienceReplay

end

function CategoricalPolicyQuickSetup:setModel(Model)

	self.Model = Model

end

function CategoricalPolicyQuickSetup:setEpsilonValueScheduler(EpsilonValueScheduler)

	self.EpsilonValueScheduler = EpsilonValueScheduler

end

function CategoricalPolicyQuickSetup:setClassesList(ClassesList)

	self.ClassesList = ClassesList

end

function CategoricalPolicyQuickSetup:getCurrentNumberOfEpisodes()

	return self.currentNumberOfEpisodes

end

function CategoricalPolicyQuickSetup:getCurrentNumberOfReinforcements()

	return self.currentNumberOfReinforcements

end

function CategoricalPolicyQuickSetup:getCurrentEpsilon()

	return self.currentEpsilon

end

function CategoricalPolicyQuickSetup:getModel()
	
	return self.Model
	
end

function CategoricalPolicyQuickSetup:getExperienceReplay()

	return self.ExperienceReplay

end

function CategoricalPolicyQuickSetup:getEpsilonValueScheduler()

	return self.EpsilonValueScheduler

end


function CategoricalPolicyQuickSetup:getClassesList()
	
	return self.ClassesList
	
end

function CategoricalPolicyQuickSetup:reset()
	
	self.currentNumberOfReinforcements = 0

	self.currentNumberOfEpisodes = 0

	self.previousFeatureVector = nil

	self.currentEpsilon = self.epsilon
	
	local Model = self.Model
	
	local ExperienceReplay = self.ExperienceReplay
	
	if (Model) then Model:categoricalReset() end
	
	if (ExperienceReplay) then ExperienceReplay:reset() end
	
end

return CategoricalPolicyQuickSetup