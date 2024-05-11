local BaseModel = require(script.Parent.BaseModel)

local AffinityPropagationModel = {}

AffinityPropagationModel.__index = AffinityPropagationModel

setmetatable(AffinityPropagationModel, BaseModel)

local AqwamMatrixLibrary = require(script.Parent.Parent.AqwamMatrixLibraryLinker.Value)

local defaultMaxNumberOfIterations = 500

local defaultDamping = 0.5

local defaultSimilarityFunction = "Euclidean"

local defaultNumberOfIterationsToConfirmConvergence = math.huge

local distanceFunctionList = {

	["Manhattan"] = function (x1, x2)

		local part1 = AqwamMatrixLibrary:subtract(x1, x2)

		part1 = AqwamMatrixLibrary:applyFunction(math.abs, part1)

		local distance = AqwamMatrixLibrary:sum(part1)

		return distance 

	end,

	["Euclidean"] = function (x1, x2)

		local part1 = AqwamMatrixLibrary:subtract(x1, x2)

		local part2 = AqwamMatrixLibrary:power(part1, 2)

		local part3 = AqwamMatrixLibrary:sum(part2)

		local distance = math.sqrt(part3)

		return distance 

	end,
	
	["CosineDistance"] = function(x1, x2)

		local dotProductedX = AqwamMatrixLibrary:dotProduct(x1, AqwamMatrixLibrary:transpose(x2))

		local x1MagnitudePart1 = AqwamMatrixLibrary:power(x1, 2)

		local x1MagnitudePart2 = AqwamMatrixLibrary:sum(x1MagnitudePart1)

		local x1Magnitude = math.sqrt(x1MagnitudePart2, 2)

		local x2MagnitudePart1 = AqwamMatrixLibrary:power(x2, 2)

		local x2MagnitudePart2 = AqwamMatrixLibrary:sum(x2MagnitudePart1)

		local x2Magnitude = math.sqrt(x2MagnitudePart2, 2)

		local normX = x1Magnitude * x2Magnitude

		local similarity = dotProductedX / normX

		local cosineDistance = 1 - similarity

		return cosineDistance

	end,

}

local function calculateDistance(vector1, vector2, distanceFunction)

	return distanceFunctionList[distanceFunction](vector1, vector2) 

end

local function createDistanceMatrix(matrix1, matrix2, distanceFunction)

	local numberOfData1 = #matrix1

	local numberOfData2 = #matrix2

	local distanceMatrix = AqwamMatrixLibrary:createMatrix(numberOfData1, numberOfData2)

	for i = 1, numberOfData1, 1 do

		for j = 1, numberOfData2, 1 do

			distanceMatrix[i][j] = calculateDistance({matrix1[i]}, {matrix2[j]} , distanceFunction)

		end

	end

	return distanceMatrix

end

local function initializePreferences(featureMatrix, similarityFunction)
	
	local numberOfData = #featureMatrix
	
	local numberOfFeatures = #featureMatrix[1]
	
	local distanceMatrix = createDistanceMatrix(featureMatrix, featureMatrix, similarityFunction)
	
	local preferencesVector = AqwamMatrixLibrary:horizontalSum(distanceMatrix)
	
	preferencesVector = AqwamMatrixLibrary:divide(preferencesVector, -(numberOfData * numberOfFeatures))

	return preferencesVector

end

local function calculateSimilarityMatrix(featureMatrix, similarityMatrix, preferenceVector)
	
	local numberOfData = #featureMatrix
	
	local numberOfFeatures = #featureMatrix[1]

	for i = 1, numberOfData do

		for j = 1, numberOfData do

			local similarity = -math.huge

			for k = 1, numberOfFeatures do

				similarity = math.max(similarity, featureMatrix[i][k] * featureMatrix[j][k])

			end

			similarityMatrix[i][j] = similarity + preferenceVector[i][1]

		end

	end
	
	return similarityMatrix

end

local function calculateResponsibilityMatrix(responsibilityMatrix, similarityMatrix, availabilityMatrix)
	
	local numberOfData = #responsibilityMatrix

	for i = 1, numberOfData do

		for j = 1, numberOfData do

			local maxResponsibility = -math.huge

			for k = 1, numberOfData do

				if k ~= j then

					maxResponsibility = math.max(maxResponsibility, similarityMatrix[i][k] + availabilityMatrix[k][j])

				end

			end

			responsibilityMatrix[i][j] = similarityMatrix[i][j] - maxResponsibility

		end

	end
	
	return responsibilityMatrix

end

local function calculateAvailibilityMatrix(availibilityMatrix, responsibilityMatrix, damping)
	
	local numberOfData = #availibilityMatrix

	for i = 1, numberOfData, 1 do

		for j = 1, numberOfData, 1 do

			if (i ~= j) then
				
				local sumMaxAvailability = 0

				for k = 1, numberOfData, 1 do

					if (k == i) and (k == j) then continue end

					local maxAvailability = math.max(0, responsibilityMatrix[k][j])
					
					sumMaxAvailability = sumMaxAvailability + maxAvailability

				end
				
				local availability = damping * (responsibilityMatrix[j][j] + sumMaxAvailability) + (1 - damping) * availibilityMatrix[i][j]

				availibilityMatrix[i][j] = math.max(0, availability)

			end

		end

	end
	
	return availibilityMatrix

end

local function calculateCost(clusters, responsibilityMatrix)

	local totalCost = 0

	for i = 1, #clusters do

		totalCost += responsibilityMatrix[i][clusters[i][1]]

	end

	return totalCost

end

local function assignClusters(availibilityMatrix, responsibilityMatrix)
	
	local calculatedValuesMatrix = AqwamMatrixLibrary:add(responsibilityMatrix, availibilityMatrix)
	
	local clusterVector = AqwamMatrixLibrary:createMatrix(#responsibilityMatrix, 1)
	
	for i = 1, #calculatedValuesMatrix, 1 do
		
		local calculatedValuesVector = {calculatedValuesMatrix[i]}
		
		local _, clusterIndex = AqwamMatrixLibrary:findMaximumValueInMatrix(calculatedValuesVector)

		if (clusterIndex == nil) then continue end

		local clusterNumber = clusterIndex[2]

		clusterVector[i][1] = clusterNumber
		
	end

	return clusterVector

end

function AffinityPropagationModel.new(maxNumberOfIterations, similarityFunction, damping)

	local NewAffinityPropagationModel = BaseModel.new()

	setmetatable(NewAffinityPropagationModel, AffinityPropagationModel)

	NewAffinityPropagationModel.maxNumberOfIterations = maxNumberOfIterations or defaultMaxNumberOfIterations
	
	NewAffinityPropagationModel.similarityFunction = similarityFunction or defaultSimilarityFunction

	NewAffinityPropagationModel.damping = damping or defaultDamping

	return NewAffinityPropagationModel

end

function AffinityPropagationModel:setParameters(maxNumberOfIterations, similarityFunction, damping)

	self.maxNumberOfIterations = maxNumberOfIterations or self.maxNumberOfIterations
	
	self.similarityFunction = similarityFunction or self.similarityFunction

	self.damping = damping or self.damping

end

function AffinityPropagationModel:train(featureMatrix)
	
	if (self.ModelParameters) then
		
		local storedFeatureMatrix = self.ModelParameters[1]

		if (#storedFeatureMatrix[1] ~= #featureMatrix[1]) then error("The previous and current feature matrices do not have the same number of features.") end 

		featureMatrix = AqwamMatrixLibrary:verticalConcatenate(featureMatrix, storedFeatureMatrix)
		
	end

	local numberOfData = #featureMatrix

	local numberOfFeatures = #featureMatrix[1]

	--local preferenceVector = initializePreferences(featureMatrix, self.similarityFunction)

	local similarityMatrix = createDistanceMatrix(featureMatrix, featureMatrix, self.similarityFunction)
	
	similarityMatrix = AqwamMatrixLibrary:multiply(-1, similarityMatrix)

	local responsibilityMatrix = AqwamMatrixLibrary:createMatrix(numberOfData, numberOfData)

	local availabilityMatrix = AqwamMatrixLibrary:createMatrix(numberOfData, numberOfData)

	local numberOfIterations = 0

	local clusterVector
	
	local previousClusterVector

	local isConverged = false

	local costArray = {}

	local cost

	repeat
		
		numberOfIterations += 1
		
		self:iterationWait()

		--similarityMatrix = calculateSimilarityMatrix(featureMatrix, similarityMatrix, preferenceVector)

		responsibilityMatrix = calculateResponsibilityMatrix(responsibilityMatrix, similarityMatrix, availabilityMatrix)

		availabilityMatrix = calculateAvailibilityMatrix(availabilityMatrix, responsibilityMatrix, self.damping)
		
		clusterVector = assignClusters(availabilityMatrix, responsibilityMatrix)
		
		previousClusterVector = clusterVector
		
		cost = self:calculateCostWhenRequired(numberOfIterations, function()
			
			return calculateCost(clusterVector, responsibilityMatrix)
			
		end) 
		
		if cost then
			
			table.insert(costArray, cost)

			self:printCostAndNumberOfIterations(cost, numberOfIterations)
			
		end
		
	until (numberOfIterations >= self.maxNumberOfIterations) or self:checkIfTargetCostReached(cost) or self:checkIfConverged(cost)

	if (cost == math.huge) then warn("The model diverged! Please repeat the experiment again or change the argument values.") end

	self.ModelParameters = {featureMatrix, clusterVector}

	return costArray

end

function AffinityPropagationModel:predict(featureMatrix)

	local maxSimilarityVector = AqwamMatrixLibrary:createMatrix(#featureMatrix, 1)
	
	local predictedClusterVector = AqwamMatrixLibrary:createMatrix(#featureMatrix, 1)
	
	local storedFeatureMatrix, clusterVector = table.unpack(self.ModelParameters)
	
	local distanceMatrix = createDistanceMatrix(featureMatrix, storedFeatureMatrix, self.similarityFunction)
	
	for i = 1, #featureMatrix, 1 do
		
		local distanceVector = {distanceMatrix[i]}
		
		local _, index = AqwamMatrixLibrary:findMinimumValueInMatrix(distanceVector)
		
		if (index == nil) then continue end
		
		local storedFeatureMatrixRowIndex = index[2]
		
		predictedClusterVector[i][1] = clusterVector[storedFeatureMatrixRowIndex][1]
		
		maxSimilarityVector[i][1] = distanceVector[1][storedFeatureMatrixRowIndex]
		
	end
	
	return predictedClusterVector, maxSimilarityVector

end

return AffinityPropagationModel
