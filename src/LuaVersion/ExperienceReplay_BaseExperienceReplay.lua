BaseExperienceReplay = {}

BaseExperienceReplay.__index = BaseExperienceReplay

local defaultBatchSize = 32

local defaultMaxBufferSize = 100

local defaultNumberOfExperienceToUpdate = 1

function BaseExperienceReplay.new(batchSize, numberOfExperienceToUpdate, maxBufferSize)
	
	local NewBaseExperienceReplay = {}
	
	setmetatable(NewBaseExperienceReplay, BaseExperienceReplay)

	NewBaseExperienceReplay.batchSize = batchSize or defaultBatchSize

	NewBaseExperienceReplay.numberOfExperienceToUpdate = numberOfExperienceToUpdate or defaultNumberOfExperienceToUpdate

	NewBaseExperienceReplay.maxBufferSize = maxBufferSize or defaultMaxBufferSize
	
	NewBaseExperienceReplay.numberOfExperience = 0
	
	NewBaseExperienceReplay.replayBufferArray = {}
	
	NewBaseExperienceReplay.temporalDifferenceErrorArray = {}
	
	NewBaseExperienceReplay.isTemporalDifferenceErrorRequired = false
	
	return NewBaseExperienceReplay
	
end

function BaseExperienceReplay:setParameters(batchSize, numberOfExperienceToUpdate, maxBufferSize)
	
	self.batchSize = batchSize or self.batchSize

	self.numberOfExperienceToUpdate = numberOfExperienceToUpdate or self.numberOfExperienceToUpdate

	self.maxBufferSize = maxBufferSize or self.maxBufferSize
	
end

function BaseExperienceReplay:extendResetFunction(resetFunction)
	
	self.resetFunction = resetFunction
	
end

function BaseExperienceReplay:reset()
	
	self.numberOfExperience = 0
	
	table.clear(self.replayBufferArray)
	
	table.clear(self.temporalDifferenceErrorArray)
	
	local resetFunction = self.resetFunction
	
	if resetFunction then resetFunction() end
	
end

function BaseExperienceReplay:setSampleFunction(sampleFunction)
	
	self.sampleFunction = sampleFunction
	
end

function BaseExperienceReplay:sample()
	
	local sampleFunction = self.sampleFunction
	
	if not sampleFunction then error("No Sample Function!") end

	return sampleFunction()
	
end

function BaseExperienceReplay:run(updateFunction)
	
	if (self.numberOfExperience < self.numberOfExperienceToUpdate) then return nil end
	
	self.numberOfExperience = 0

	local experienceReplayBatchArray = self:sample()

	for _, experience in ipairs(experienceReplayBatchArray) do -- (s1, a, r, s2)
		
		local previousFeatureVector = experience[1]
		
		local action = experience[2]
		
		local rewardValue = experience[3]
		
		local currentFeatureVector = experience[4]

		updateFunction(previousFeatureVector, action, rewardValue, currentFeatureVector)

	end
	
end

function BaseExperienceReplay:removeLastValueFromArrayIfExceedsBufferSize(targetArray)
	
	if (#targetArray > self.maxBufferSize) then table.remove(targetArray, 1) end
	
end

function BaseExperienceReplay:extendAddExperienceFunction(addExperienceFunction)
	
	self.AddExperienceFunction = addExperienceFunction
	
end

function BaseExperienceReplay:addExperience(previousFeatureVector, action, rewardValue, currentFeatureVector)
	
	local experience = {previousFeatureVector, action, rewardValue, currentFeatureVector}

	table.insert(self.replayBufferArray, experience)
	
	local addExperienceFunction = self.AddExperienceFunction
	
	if (addExperienceFunction) then addExperienceFunction(experience) end

	self:removeLastValueFromArrayIfExceedsBufferSize(self.replayBufferArray)
	
	self.numberOfExperience += 1
	
end

function BaseExperienceReplay:extendAddTemporalDifferenceErrorFunction(addTemporalDifferenceErrorFunction)
	
	self.AddTemporalDifferenceErrorFunction = addTemporalDifferenceErrorFunction
	
end

function BaseExperienceReplay:addTemporalDifferenceError(temporalDifferenceErrorVectorOrValue)
	
	if (not self.isTemporalDifferenceErrorRequired) then return nil end
	
	table.insert(self.temporalDifferenceErrorArray, temporalDifferenceErrorVectorOrValue)
	
	local addTemporalDifferenceErrorFunction = self.AddTemporalDifferenceErrorFunction
	
	if (addTemporalDifferenceErrorFunction) then addTemporalDifferenceErrorFunction(temporalDifferenceErrorVectorOrValue) end
	
	self:removeLastValueFromArrayIfExceedsBufferSize(self.temporalDifferenceErrorArray)
	
end

function BaseExperienceReplay:setIsTemporalDifferenceErrorRequired(option)
	
	self.isTemporalDifferenceErrorRequired = option
	
end

return BaseExperienceReplay
