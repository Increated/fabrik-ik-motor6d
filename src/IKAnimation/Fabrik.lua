--There is a bug where v1New is returned as nil idk why
--fixed due to return statements on the fabrik algo
--refer to diagram in tablet for information on which points are which
--Add a function to constrain in a cone
--inputs are angle of elevation
local function backwards(originCF, targetPos, v1,v2,v3)
	
	local pointThree = originCF.p + v1 + v2
	
	--Construct the v3 into the new form closer to the goal
	--vecNew is temporary storage for the new direction vector
	local vecNew = pointThree-targetPos
	
	local v3New = vecNew.Unit * v3.Magnitude
	
	--reconstruct chain from targetPos
	local vecFromPos = targetPos + v3New
	
	local pointTwo = originCF.p + v1

	--Construct the v2 with new direction
	vecNew = vecFromPos - pointTwo
	
	local v2New = vecNew.Unit * v2.Magnitude
	
	--Rereconstruct the chain
	local vecTwoFromPos = vecFromPos + v2New
	
	vecNew = originCF.p - vecTwoFromPos

	local v1New = vecNew.Unit * v1.Magnitude
	
	return originCF, targetPos,v1New,v2New,v3New
	--new  vector chain goes from goal towards the start position
	
end
--Function assumes backwards has been done
--Also assumes vector chain starts from target Pos towards the hip joint
local function forwards(originCF, targetPos, v1,v2,v3)
	
	local pointTwo = targetPos+v3+v2
	
	local vecNew = pointTwo-originCF.p
	
	--obtain new v1 pointing from start to goal in the chain
	local v1New = vecNew.Unit*v1.Magnitude	
	
	--Build chain from start
	local vecFromOrigin = originCF.p + v1New
	
	local pointTwo = targetPos+v3
	
	vecNew = pointTwo-vecFromOrigin
	
	local v2New = vecNew.Unit*v2.Magnitude
	
	--Build up on the chain
	local vecTwoFromOrigin = vecFromOrigin + v2New
	
	
	vecNew = targetPos-vecTwoFromOrigin
	
	local v3New = vecNew.Unit*v3.Magnitude
	
	return originCF, targetPos,v1New,v2New,v3New
end

--Does the cylinder constraining
local function cylinderConstraint(centerAxis,limbVector)
	
	--ellipse height and width of the constraint
	local height
	local width 
	
	local projection = centerAxis.Unit:Dot(limbVector)*centerAxis.Unit

	
	return limbVector
end

--Intended to function after the forwards chain 
--refer to the doodle to explain
local function constraintForwards(originCF, targetPos, v1,v2,v3)
	--Elipse constraint for the v2 limb
	local heightV2 = 1
	local widthV2 = 1
	
	--Obtain the new vectors if unchanged by the constraints
	local v1New = v1
	local v2New = v2
	local v3New = v3
	
	--look vector = along the vector limb v1 y axis
	--Up vector = x axis
	--right vector = z axis
	local refCF = CFrame.new(Vector3.new(),v1)
	local limbAxis = -refCF.LookVector
	
	--cone center
	local xAxisRef = -refCF.UpVector
	
	--the projection point
	local projection = xAxisRef.Unit:Dot(v2)*(1/xAxisRef.Magnitude)*xAxisRef.Unit

	--get the projection point to the v2 limb
	local translate = v2-projection
	
	--Get the angle via cross product
	local cross = limbAxis.Unit:Cross(translate.Unit)
	local angleFromLook = math.asin(cross.Magnitude)
	
	--now place it in a 2d plane
	--xyz is now 2d plane
	local xPoint = translate.Magnitude * math.sin(angleFromLook)
	local yPoint = translate.Magnitude * math.cos(angleFromLook)
	
	local angleToXAxis = math.atan(yPoint/xPoint)

	--Now its time to constraint the xy points if outside the ellipse constraint
	local ellipseEquation = (xPoint^2)/(0.5*widthV2)+(yPoint^2)/(0.5*heightV2)
	--if the point is outside the ellipse then fix does the constraint fix
	if ellipseEquation > 1 then
		--change the point from outside the ellipse to inside the ellipse
		xPoint = (0.5*widthV2)*math.cos(angleToXAxis)
		yPoint = (0.5*heightV2)*math.sin(angleToXAxis)
		
		--Now we conver it back to a 3d vector
		local newMagnitude = math.sqrt(xPoint^2+yPoint^2)
		--Gets the new direction of the v2 limb  
		local translateNew = translate.Unit * newMagnitude
		local newDir =projection+translateNew
		--Constructs the new v2 with the new direction
		v2New = newDir.Unit *v2.Magnitude
	end
	
	return originCF, targetPos, v1New,v2New,v3New
	
end

local function fabrikAlgo(tolerance,originCF, targetPos, v1, v2,v3)	
	
	--get the magnitude of the leg parts
	local v1Mag = v1.Magnitude
	local v2Mag = v2.Magnitude
	local v3Mag = v3.Magnitude
	--Get total length of the arm
	local maxLength = v1Mag+v2Mag+v3Mag
	--Get the distance from hip Joint to the target position
	local targetToJoint = targetPos-originCF.p
	local targetLength = targetToJoint.Magnitude
	
	--perform 1 iteration of the fabrik chain
	--1 backwards then 1 forwards and get the new vector representing the motor6d limbs
	--iterate = forwards(backwards(originCF, targetPos, v1, v2,v3))
	--local originCF,targetPos,v1New,v2New,v3New = constraintForwards(forwards(backwards(originCF, targetPos, v1, v2,v3)))
	local originCF,targetPos,v1New,v2New,v3New = forwards(backwards(originCF, targetPos, v1, v2,v3))
	--initialze measure feet to where it should be
	local feetJoint = originCF.p+v1New+v2New+v3New
	local feetToTarget = targetPos-feetJoint
	
	
	--Target point is too far away from the max length the leg can reach
	if targetLength > maxLength then
		
		v1New = targetToJoint.Unit * v1Mag
		v2New = targetToJoint.Unit * v2Mag
		v3New = targetToJoint.Unit * v3Mag
		
		return  v1New,v2New,v3New

		
	else
		--target point is "reachable"
		--if Distance is more than tolerance than iterate again
		if feetToTarget.Magnitude > tolerance  then			
			--originCF,targetPos,v1New,v2New,v3New = constraintForwards(forwards(backwards(originCF, targetPos, v1New,v2New,v3New)))
			originCF,targetPos,v1New,v2New,v3New = forwards(backwards(originCF, targetPos, v1New,v2New,v3New))
			feetJoint = originCF.p+v1New+v2New+v3New
			feetToTarget = targetPos-feetJoint	
			return v1New,v2New,v3New
		else
			--This was the problem no return statement lol 
			--so it returned nil if the feet was within tolerance
			return v1New,v2New,v3New

		end
		
	end
	
	
end

----

return fabrikAlgo