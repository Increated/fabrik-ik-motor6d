-- Initialize Object Class
local Package = script:FindFirstAncestorOfClass("Folder")
local Object = require(Package.BaseRedirect)

local FabrikConstraint = Object.new("FabrikConstraint")

-- Creates a constraint with axis that depend on the part
function FabrikConstraint.new(Part)
    local obj = FabrikConstraint:make()

    --If there is a part, relative constraint axis is set accordingly
    if Part then
    obj.Part = Part
    obj.PartInitialCFrame = Part.CFrame
    obj.CenterAxis = Part.CFrame.LookVector
    obj.XAxis = Part.CFrame.RightVector
    obj.YAxis = Part.CFrame.UpVector
    end

    obj.DebugMode = true
    obj.DebugPartCreated = false
    obj.DebugPart = nil

    return obj
end

--[[
    The method all constraints should inherit
    empty as each constraint has it's own special constraint method
]]
function FabrikConstraint:ConstrainLimbVector()


end


--[[
    Method for the constraints to inherit if you want to the axis to change
    Currently broken because of the weld constraint changing the model's CFrame also
]]
function FabrikConstraint:RotateCFrameOrientation(goalCFrameRotation) 

    --disable the weld constraint first to prevent it moving
    self.Part:FindFirstChild("WeldConstraint").Enabled = false

    --Change the constraint
    self.Part.CFrame = CFrame.new(self.Part.CFrame.Position)*goalCFrameRotation 

    --Disable the weld Constraint
    self.Part:FindFirstChild("WeldConstraint").Enabled = true

end

--[[
    Methods to set and get the current axis of the part
    fairly activity intensive goes from 1-2% to 4-6% max
    Also problem as it requires the part motor to update 
]]
function FabrikConstraint:UpdateAxis()

    self.CenterAxis = self.Part.CFrame.LookVector
    self.XAxis = self.Part.CFrame.RightVector
    self.YAxis = self.Part.CFrame.UpVector

end

function FabrikConstraint:UpdateJointAxis(jointPosition,jointAxis)

    if self.DebugMode and not self.DebugPartCreated then
        --creates the part and parents it to the workspace
        self.DebugPart = Instance.new("WedgePart")
        self.DebugPart.CFrame = CFrame.new(jointPosition)*(jointAxis-jointAxis.Position)
        self.DebugPart.Size = Vector3.new(1,1,2)
        self.DebugPart.Anchored = true
        self.DebugPart.Parent = workspace
        self.DebugPartCreated = true
    elseif self.DebugMode then
        
        --ok it works
        local jointCFrameAtMotor = (jointAxis-jointAxis.Position)
        --self.DebugPart.CFrame = CFrame.new(jointPosition)*jointCFrameAtMotor

        local initialRotation = self.PartInitialCFrame-self.PartInitialCFrame.Position
        --now needs to be relative to the part constraints
        local ConstraintAxisRotation = jointCFrameAtMotor:ToWorldSpace(initialRotation)-jointCFrameAtMotor:ToWorldSpace(initialRotation).Position
        self.DebugPart.CFrame = ConstraintAxisRotation+self.Part.CFrame.Position

        self.CenterAxis = ConstraintAxisRotation.LookVector
        self.XAxis = ConstraintAxisRotation.RightVector
        self.YAxis =ConstraintAxisRotation.UpVector
    end

end


function FabrikConstraint:UpdateYAxis()

    self.YAxis = self.Part.CFrame.UpVector

end

function FabrikConstraint:UpdateXAxis()

    self.XAxis = self.Part.CFrame.RightVector

end

function FabrikConstraint:UpdateCenterAxis()

    self.CenterAxis = self.Part.CFrame.LookVector

end


return FabrikConstraint
