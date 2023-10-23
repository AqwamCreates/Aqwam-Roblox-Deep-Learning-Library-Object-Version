--[[

	--------------------------------------------------------------------

	Author: Aqwam Harish Aiman
	
	YouTube: https://www.youtube.com/channel/UCUrwoxv5dufEmbGsxyEUPZw
	
	LinkedIn: https://www.linkedin.com/in/aqwam-harish-aiman/
	
	--------------------------------------------------------------------
	
	DO NOT SELL, RENT, DISTRIBUTE THIS LIBRARY
	
	DO NOT SELL, RENT, DISTRIBUTE MODIFIED VERSION OF THIS LIBRARY
	
	DO NOT CLAIM OWNERSHIP OF THIS LIBRARY
	
	GIVE CREDIT AND SOURCE WHEN USING THIS LIBRARY IF YOUR USAGE FALLS UNDER ONE OF THESE CATEGORIES:
	
		- USED AS A VIDEO OR ARTICLE CONTENT
		- USED AS COMMERCIAL USE OR PUBLIC USE
	
	--------------------------------------------------------------------
		
	By using this library, you agree to comply with our Terms and Conditions in the link below:
	
	https://github.com/AqwamCreates/DataPredict/blob/main/docs/TermsAndConditions.md
	
	--------------------------------------------------------------------

--]]

ExperienceReplayComponent = {}

ExperienceReplayComponent.__index = ExperienceReplayComponent

local defaultBatchSize = 32

local defaultMaxBufferSize = 100

local defaultNumberOfExperienceToUpdate = 1

function ExperienceReplayComponent.new(batchSize, numberOfExperienceToUpdate, maxBufferSize)
	
	local NewExperienceReplayComponent = {}
	
	setmetatable(NewExperienceReplayComponent, ExperienceReplayComponent)

	NewExperienceReplayComponent.batchSize = batchSize or defaultBatchSize

	NewExperienceReplayComponent.numberOfExperienceToUpdate = numberOfExperienceToUpdate or defaultNumberOfExperienceToUpdate

	NewExperienceReplayComponent.maxBufferSize = maxBufferSize or defaultMaxBufferSize
	
	NewExperienceReplayComponent.numberOfExperience = 0
	
	NewExperienceReplayComponent.replayBufferArray = {}
	
	return NewExperienceReplayComponent
	
end

function ExperienceReplayComponent:setParameters(batchSize, numberOfExperienceToUpdate, maxBufferSize)
	
	self.batchSize = batchSize or self.batchSize

	self.numberOfExperienceToUpdate = numberOfExperienceToUpdate or self.numberOfExperienceToUpdate

	self.maxBufferSize = maxBufferSize or self.maxBufferSize
	
end

function ExperienceReplayComponent:reset()
	
	self.numberOfExperience = 0

	self.replayBufferArray = {}
	
end

function ExperienceReplayComponent:sampleBatch()
	
	local batchArray = {}
	
	local lowestNumberOfBatchSize = math.min(self.batchSize, #self.replayBufferArray)

	for i = 1, lowestNumberOfBatchSize, 1 do

		local index = Random.new():NextInteger(1, #self.replayBufferArray)

		table.insert(batchArray, self.replayBufferArray[index])

	end

	return batchArray
	
end

function ExperienceReplayComponent:run(updateFunction)
	
	if (self.numberOfExperience < self.numberOfExperienceToUpdate) then return nil end
	
	self.numberOfExperience = 0

	local experienceReplayBatchArray = self:sampleBatch()

	for _, experience in ipairs(experienceReplayBatchArray) do -- (s1, a, r, s2)
		
		local previousState = experience[1]
		
		local action = experience[2]
		
		local rewardValue = experience[3]
		
		local currentState = experience[4]

		updateFunction(previousState, action, rewardValue, currentState)

	end
	
end

function ExperienceReplayComponent:addExperience(previousState, action, rewardValue, currentState)
	
	local experience = {previousState, action, rewardValue, currentState}

	table.insert(self.replayBufferArray, experience)

	if (#self.replayBufferArray > self.maxBufferSize) then table.remove(self.replayBufferArray, 1) end
	
	self.numberOfExperience += 1
	
end

return ExperienceReplayComponent
