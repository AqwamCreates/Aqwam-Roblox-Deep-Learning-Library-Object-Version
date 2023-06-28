local BaseModel = require(script.Parent.BaseModel)

AgglomerativeHierarchicalModel = {}

AgglomerativeHierarchicalModel.__index = AgglomerativeHierarchicalModel

setmetatable(AgglomerativeHierarchicalModel, BaseModel)

local AqwamMatrixLibrary = require(script.Parent.Parent.AqwamRobloxMatrixLibraryLinker.Value)

local defaultMaxNumberOfIterations = 500

local defaultHighestCost = math.huge

local defaultLowestCost = -math.huge

local defaultNumberOfClusters = 1

local defaultDistanceFunction = "euclidean"

local defaultLinkageFunction = "minimum"

local defaultStopWhenModelParametersDoesNotChange = false

local distanceFunctionList = {

	["manhattan"] = function (x1, x2)

		local part1 = AqwamMatrixLibrary:subtract(x1, x2)

		part1 = AqwamMatrixLibrary:applyFunction(math.abs, part1)

		local distance = AqwamMatrixLibrary:sum(part1)

		return distance 

	end,

	["euclidean"] = function (x1, x2)

		local part1 = AqwamMatrixLibrary:subtract(x1, x2)

		local part2 = AqwamMatrixLibrary:power(part1, 2)

		local part3 = AqwamMatrixLibrary:sum(part2)

		local distance = math.sqrt(part3)

		return distance 

	end,

}


local function calculateDistance(vector1, vector2, distanceFunction)

	return distanceFunctionList[distanceFunction](vector1, vector2) 

end


local function createClusterDistanceMatrix(clusters, distanceFunction)

	local numberOfData = #clusters

	local distanceMatrix = AqwamMatrixLibrary:createMatrix(numberOfData, numberOfData)

	for i = 1, numberOfData, 1 do

		for j = 1, numberOfData, 1 do
			
			if (i ~= j) then
				
				distanceMatrix[i][j] = calculateDistance({clusters[i]}, {clusters[j]} , distanceFunction)
				
			end

		end

	end

	return distanceMatrix

end

local function createNewMergedDistanceMatrix(clusterDistanceMatrix, clusterIndex1, clusterIndex2)
	
	local numberOfData = #clusterDistanceMatrix
	
	local newClusterDistanceMatrix = {}
	
	for i = 1, numberOfData, 1 do
		
		if (i == clusterIndex1) or (i == clusterIndex2) then continue end
		
		local newClusterDistanceVector = {}
		
		for j = 1, numberOfData, 1 do
			
			if (j == clusterIndex1) or (j == clusterIndex2) then continue end
			
			table.insert(newClusterDistanceVector, clusterDistanceMatrix[i][j])
			
		end
		
		table.insert(newClusterDistanceMatrix, newClusterDistanceVector)
		
	end
	
	local newRow = {}
	
	for i = 1, (numberOfData - 1) do
		
		table.insert(newRow, 0)
		
	end
	
	table.insert(newClusterDistanceMatrix, newRow)
	
	for i = 1, (numberOfData - 1) do

		table.insert(newClusterDistanceMatrix[i], 0)

	end
	
	return newClusterDistanceMatrix
	
end

local function applyFunctionToFirstRowAndColumnOfDistanceMatrix(functionToApply, clusterDistanceMatrix, newClusterDistanceMatrix, clusterIndex1, clusterIndex2)
	
	local totalDistance = 0
	
	local newColumnIndex = 1

	local newRowIndex = 1
	
	local numberOfClusters = #clusterDistanceMatrix
	
	for column = 1, numberOfClusters, 1 do

		if (column == clusterIndex1) or (column == clusterIndex2) then continue end

		local distance = functionToApply(clusterDistanceMatrix[clusterIndex1][column],  clusterDistanceMatrix[clusterIndex2][column])

		newClusterDistanceMatrix[numberOfClusters - 1][newColumnIndex] = distance

		newColumnIndex += 1

	end

	for row = 1, numberOfClusters, 1 do

		if (row == clusterIndex1) or (row == clusterIndex2) then continue end

		local distance = functionToApply(clusterDistanceMatrix[row][clusterIndex1],  clusterDistanceMatrix[row][clusterIndex2])

		newClusterDistanceMatrix[newRowIndex][numberOfClusters - 1] = distance

		totalDistance += distance

		newRowIndex += 1

	end
	
	return newClusterDistanceMatrix, totalDistance
	
end

-----------------------------------------------------------------------------------------------------------------------

local function minimumLinkage(clusterDistanceMatrix, clusterIndex1, clusterIndex2)
	
	local newClusterDistanceMatrix = createNewMergedDistanceMatrix(clusterDistanceMatrix, clusterIndex1, clusterIndex2)
	
	local newClusterDistanceMatrix, totalDistance = applyFunctionToFirstRowAndColumnOfDistanceMatrix(math.min, clusterDistanceMatrix, newClusterDistanceMatrix, clusterIndex1, clusterIndex2)
	
	return newClusterDistanceMatrix, totalDistance
	
end

local function maximumLinkage(clusterDistanceMatrix, clusterIndex1, clusterIndex2)

	local newClusterDistanceMatrix = createNewMergedDistanceMatrix(clusterDistanceMatrix, clusterIndex1, clusterIndex2)

	local newClusterDistanceMatrix, totalDistance = applyFunctionToFirstRowAndColumnOfDistanceMatrix(math.max, clusterDistanceMatrix, newClusterDistanceMatrix, clusterIndex1, clusterIndex2)

	return newClusterDistanceMatrix, totalDistance

end

local function groupAverageLinkage(clusterDistanceMatrix, clusterIndex1, clusterIndex2)
	
	local weightedGroupAverage = function (x, y) return (x + y) / 2 end
	
	local newClusterDistanceMatrix = createNewMergedDistanceMatrix(clusterDistanceMatrix, clusterIndex1, clusterIndex2)
	
	local newClusterDistanceMatrix, totalDistance = applyFunctionToFirstRowAndColumnOfDistanceMatrix(weightedGroupAverage, clusterDistanceMatrix, newClusterDistanceMatrix, clusterIndex1, clusterIndex2)

	return newClusterDistanceMatrix, totalDistance

end

-----------------------------------------------------------------------------------------------------------------------

local function findClosestClusters(clusterDistanceMatrix)

	local distance

	local minimumClusterDistance = math.huge

	local clusterIndex1 = nil

	local clusterIndex2 = nil

	for i = 1, #clusterDistanceMatrix, 1 do

		for j = i + 1, #clusterDistanceMatrix, 1 do

			distance = clusterDistanceMatrix[i][j]

			if (distance < minimumClusterDistance) then

				minimumClusterDistance = distance

				clusterIndex1 = i

				clusterIndex2 = j

			end

		end

	end

	return clusterIndex1, clusterIndex2

end

local function updateDistanceMatrix(linkageFunction, clusters, clusterDistanceMatrix, clusterIndex1, clusterIndex2)
	
	local clusterVector
	
	local distance
	
	if (linkageFunction == "minimum") then

		return minimumLinkage(clusterDistanceMatrix, clusterIndex1, clusterIndex2)

	elseif (linkageFunction == "maximum") then

		return maximumLinkage(clusterDistanceMatrix, clusterIndex1, clusterIndex2)
		
	elseif (linkageFunction == "groupAverage") then
		
		return groupAverageLinkage(clusterDistanceMatrix, clusterIndex1, clusterIndex2)
		
	else
		
		error("Invalid linkage!")
		
	end
	
end

local function createNewClusters(clusters, clusterIndex1Combine, clusterIndex2ToCombine)
	
	local newClusters = {}
	
	local cluster1 = {clusters[clusterIndex1Combine]}
	
	local cluster2 = {clusters[clusterIndex2ToCombine]}
	
	local combinedCluster = AqwamMatrixLibrary:add(cluster1, cluster2)
	
	local clusterToBeAdded = AqwamMatrixLibrary:divide(combinedCluster, 2)
	
	for i = 1, #clusters, 1 do
		
		if (i ~= clusterIndex1Combine) and (i ~= clusterIndex2ToCombine) then table.insert(newClusters, clusters[i]) end
		
	end
		
	table.insert(newClusters, clusterToBeAdded[1])
	
	return newClusters
	
end

local function areModelParametersMatricesEqualInSizeAndValues(ModelParameters, PreviousModelParameters)
	
	local areModelParametersEqual = false
	
	if (PreviousModelParameters == nil) then return areModelParametersEqual end

	if (#ModelParameters ~= #PreviousModelParameters) or (#ModelParameters[1] ~= #PreviousModelParameters[1]) then return areModelParametersEqual end

	areModelParametersEqual = AqwamMatrixLibrary:areMatricesEqual(ModelParameters, PreviousModelParameters)
	
	return areModelParametersEqual
	
end

function AgglomerativeHierarchicalModel.new(numberOfClusters, distanceFunction, linkageFunction, highestCost, lowestCost, stopWhenModelParametersDoesNotChange)
	
	local NewAgglomerativeHierarchicalModel = BaseModel.new()
	
	setmetatable(NewAgglomerativeHierarchicalModel, AgglomerativeHierarchicalModel)

	NewAgglomerativeHierarchicalModel.highestCost = highestCost or defaultHighestCost
	
	NewAgglomerativeHierarchicalModel.lowestCost = lowestCost or defaultLowestCost

	NewAgglomerativeHierarchicalModel.distanceFunction = distanceFunction or defaultDistanceFunction
	
	NewAgglomerativeHierarchicalModel.linkageFunction = linkageFunction or defaultLinkageFunction

	NewAgglomerativeHierarchicalModel.numberOfClusters = numberOfClusters or defaultNumberOfClusters
	
	NewAgglomerativeHierarchicalModel.stopWhenModelParametersDoesNotChange =  BaseModel:getBooleanOrDefaultOption(stopWhenModelParametersDoesNotChange, defaultStopWhenModelParametersDoesNotChange)
	
	return NewAgglomerativeHierarchicalModel
	
end

function AgglomerativeHierarchicalModel:setParameters(numberOfClusters, distanceFunction, linkageFunction, highestCost, lowestCost, stopWhenModelParametersDoesNotChange)

	self.highestCost = highestCost or self.highestCost
	
	self.lowestCost = lowestCost or self.lowestCost

	self.distanceFunction = distanceFunction or self.distanceFunction
	
	self.linkageFunction = linkageFunction or defaultLinkageFunction

	self.numberOfClusters = numberOfClusters or self.numberOfClusters

	self.stopWhenModelParametersDoesNotChange =  self:getBooleanOrDefaultOption(stopWhenModelParametersDoesNotChange, self.stopWhenModelParametersDoesNotChange)

end

function AgglomerativeHierarchicalModel:train(featureMatrix)
	
	local clusterIndex1
	
	local clusterIndex2
	
	local minimumDistance
	
	local isOutsideCostBounds
	
	local numberOfIterations = 0
	
	local cost = 0
	
	local costArray = {}
	
	local PreviousModelParameters
	
	local clusterDistanceMatrix
	
	local clusterIndex1
	
	local clusterIndex2
	
	local distance
	
	local areModelParametersEqual = false
	
	local clusters = AqwamMatrixLibrary:copy(featureMatrix)
	
	local newCluster
	
	if self.ModelParameters then
		
		if (#featureMatrix[1] ~= #self.ModelParameters[1]) then error("The number of features are not the same as the model parameters!") end
		
		clusters = AqwamMatrixLibrary:verticalConcatenate(self.ModelParameters, clusters)
		
	end
	
	clusterDistanceMatrix = createClusterDistanceMatrix(clusters, self.distanceFunction)
	
	repeat
		
		self:iterationWait()
		
		numberOfIterations += 1
		
		clusterIndex1, clusterIndex2 = findClosestClusters(clusterDistanceMatrix)

		clusters = createNewClusters(clusters, clusterIndex1, clusterIndex2)
		
		clusterDistanceMatrix, distance = updateDistanceMatrix(self.linkageFunction, clusters, clusterDistanceMatrix, clusterIndex1, clusterIndex2)
		
		self.ModelParameters = clusters
		
		cost = distance

		table.insert(costArray, cost)
		
		self:printCostAndNumberOfIterations(cost, numberOfIterations)
		
		areModelParametersEqual = areModelParametersMatricesEqualInSizeAndValues(self.ModelParameters, PreviousModelParameters)
		
		isOutsideCostBounds = (cost <= self.lowestCost) or (cost >= self.highestCost)
		
		PreviousModelParameters = self.ModelParameters
		
	until isOutsideCostBounds or (#clusters == self.numberOfClusters) or (#clusters == 1) or (areModelParametersEqual and self.stopWhenModelParametersDoesNotChange)
	
	self.ModelParameters = clusters
	
	return costArray
	
end

function AgglomerativeHierarchicalModel:predict(featureMatrix)
	
	local distance
	
	local closestCluster
	
	local clusterVector
	
	local minimumDistance = math.huge
	
	for i, cluster in ipairs(self.ModelParameters) do
		
		clusterVector = {cluster}
		
		distance = calculateDistance(featureMatrix, clusterVector, self.distanceFunction)
		
		if (distance < minimumDistance) then
			
			minimumDistance = distance
			
			closestCluster = i
			
		end
		
	end

	return closestCluster, minimumDistance
	
end

return AgglomerativeHierarchicalModel
