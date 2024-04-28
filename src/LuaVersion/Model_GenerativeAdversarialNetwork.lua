GenerativeAdversarialNetworkModel = {}

GenerativeAdversarialNetworkModel.__index = GenerativeAdversarialNetworkModel

local AqwamMatrixLibrary = require("AqwamMatrixLibrary")

local defaultMaxNumberOfIterations = 500

function GenerativeAdversarialNetworkModel.new(maxNumberOfIterations)
	
	local NewGenerativeAdversarialNetworkModel = {}
	
	setmetatable(NewGenerativeAdversarialNetworkModel, GenerativeAdversarialNetworkModel)
	
	NewGenerativeAdversarialNetworkModel.maxNumberOfIterations = maxNumberOfIterations or defaultMaxNumberOfIterations
	
	NewGenerativeAdversarialNetworkModel.isOutputPrinted = true
	
	NewGenerativeAdversarialNetworkModel.Generator = nil
	
	NewGenerativeAdversarialNetworkModel.Discriminator = nil
	
	return NewGenerativeAdversarialNetworkModel
	
end

function GenerativeAdversarialNetworkModel:setParameters(maxNumberOfIterations)
	
	self.maxNumberOfIterations = maxNumberOfIterations or self.maxNumberOfIterations
	
end

function GenerativeAdversarialNetworkModel:setDiscriminator(Discriminator)
	
	self.Discriminator = Discriminator
	
end

function GenerativeAdversarialNetworkModel:setGenerator(Generator)
	
	self.Generator = Generator
	
end

function GenerativeAdversarialNetworkModel:setPrintOutput(option)
	
	if (option == false) then

		self.isOutputPrinted = false

	else

		self.isOutputPrinted = true

	end
	
end

function GenerativeAdversarialNetworkModel:train(realFeatureMatrix, noiseFeatureMatrix)
	
	local Discriminator = self.Discriminator
	
	local Generator = self.Generator
	
	if (not Discriminator) then error("No discriminator neural network.") end
	
	if (not Generator) then error("No generator neural network.") end
	
	local discriminatorNumberOfLayers = Generator:getNumberOfLayers()

	local generatorNumberOfLayers = Generator:getNumberOfLayers()
	
	local discriminatorInputNumberOfFeatures, discriminatorInputHasBias = Discriminator:getLayer(1)
	
	local generatorInputNumberOfFeatures, generatorInputHasBias = Generator:getLayer(1)
	
	local discriminatorOutputNumberOfFeatures, discriminatorOutputHasBias = Discriminator:getLayer(discriminatorNumberOfLayers)

	local generatorOutputNumberOfFeatures, generatorOutputHasBias = Generator:getLayer(generatorNumberOfLayers)
	
	discriminatorInputNumberOfFeatures = discriminatorInputNumberOfFeatures + ((discriminatorInputHasBias and 1) or 0)

	generatorInputNumberOfFeatures = generatorInputNumberOfFeatures + ((generatorInputHasBias and 1) or 0)
	
	discriminatorOutputNumberOfFeatures = discriminatorOutputNumberOfFeatures + ((discriminatorOutputHasBias and 1) or 0)
	
	generatorOutputNumberOfFeatures = generatorOutputNumberOfFeatures + ((generatorOutputHasBias and 1) or 0)
	
	if (generatorOutputNumberOfFeatures ~= discriminatorInputNumberOfFeatures) then error("The generator's output layer and the discriminator's input layer must contain the same number of neurons.") end
	
	if (discriminatorOutputNumberOfFeatures ~= 1) then error("The number of neurons at the discriminator's output layer must be equal to 1.") end
	
	if (#realFeatureMatrix ~= #noiseFeatureMatrix) then error("Both feature matrices must contain same number of data.") end
	
	if (#noiseFeatureMatrix[1] ~= generatorInputNumberOfFeatures) then error("The number of columns in noise feature matrix must contain the same number as the number of neurons in generator's input layer.") end
	
	if (#realFeatureMatrix[1] ~= discriminatorInputNumberOfFeatures) then error("The number of columns in real feature matrix must contain the same number as the number of neurons in discriminator's input layer.") end

	local discriminatorInputMatrix = AqwamMatrixLibrary:createMatrix(1, discriminatorInputNumberOfFeatures, 1)

	local generatorInputMatrix = AqwamMatrixLibrary:createMatrix(1, generatorInputNumberOfFeatures, 1)
	
	local functionToApplyToDiscriminator = function (discriminatorRealLabel, discriminatorGeneratedLabel) return -(math.log(discriminatorRealLabel) + math.log(1 - discriminatorGeneratedLabel)) end
	
	local functionToApplyToGenerator = function (discriminatorGeneratedLabel) return math.log(1 - discriminatorGeneratedLabel) end
	
	local numberOfIterations = 0
	
	local maxNumberOfIterations = self.maxNumberOfIterations
	
	local isOutputPrinted = self.isOutputPrinted

	repeat
		
		task.wait()
		
		local generatedLabelMatrix = Generator:predict(noiseFeatureMatrix, true)
		
		local discriminatorGeneratedLabelMatrix = Discriminator:predict(generatedLabelMatrix, true)
		
		local discriminatorRealLabelMatrix = Discriminator:predict(realFeatureMatrix, true)
		
		local discriminatorLossMatrix = AqwamMatrixLibrary:applyFunction(functionToApplyToDiscriminator, discriminatorRealLabelMatrix, discriminatorGeneratedLabelMatrix)
		
		local generatorLossMatrix = AqwamMatrixLibrary:applyFunction(functionToApplyToGenerator, discriminatorGeneratedLabelMatrix)
		
		local meanDiscriminatorLossMatrix = AqwamMatrixLibrary:verticalMean(discriminatorLossMatrix)
		
		local meanGeneratorLossVector = AqwamMatrixLibrary:verticalMean(generatorLossMatrix)
		
		meanGeneratorLossVector = AqwamMatrixLibrary:createMatrix(1, generatorOutputNumberOfFeatures, meanGeneratorLossVector[1][1])
		
		Discriminator:forwardPropagate(discriminatorInputMatrix, true)
		
		Discriminator:backPropagate(meanDiscriminatorLossMatrix, true)
		
		Generator:forwardPropagate(generatorInputMatrix, true)
		
		Generator:backPropagate(meanGeneratorLossVector, true)
		
		numberOfIterations = numberOfIterations + 1
		
		if (isOutputPrinted) then print("Iteration: " .. numberOfIterations .. "\t\tDiscriminator Cost: " .. meanDiscriminatorLossMatrix[1][1]) end
		
	until (numberOfIterations >= maxNumberOfIterations)
	
end

function GenerativeAdversarialNetworkModel:evaluate(featureMatrix)
	
	return self.Discriminator:predict(featureMatrix, true)
	
end

function GenerativeAdversarialNetworkModel:generate(noiseFeatureMatrix)
	
	return self.Generator:predict(noiseFeatureMatrix, true)
	
end

function GenerativeAdversarialNetworkModel:getGenerator()

	return self.Generator

end

function GenerativeAdversarialNetworkModel:getDiscriminator()

	return self.Discriminator

end

return GenerativeAdversarialNetworkModel
