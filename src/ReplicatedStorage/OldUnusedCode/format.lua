-- Obtains the CFrame rotation calculation for CFrame.fromAxis
local limbVectorRelativeToOriginal = previousLimbCF:VectorToWorldSpace(originalVectorLimb)
local dotProductAngle = limbVectorRelativeToOriginal.Unit:Dot(currentVectorLimb.Unit)
local safetyClamp = math.clamp(dotProductAngle, -1, 1)
local limbRotationAngle = math.acos(safetyClamp)
local limbRotationAxis = limbVectorRelativeToOriginal:Cross(currentVectorLimb) -- obtain the rotation axis
