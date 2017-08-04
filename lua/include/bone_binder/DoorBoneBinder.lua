
if not COMBINE_LOCK then 
	COMBINE_LOCK = {}
end
local Bone_Binder = {}
Bone_Binder.__index = Bone_Binder

AccessorFunc(Bone_Binder,"ent","Entity")
AccessorFunc(Bone_Binder,"bone_part","BoneId",FORCE_NUMBER)
AccessorFunc(Bone_Binder,"is_bone","IsBone",FORCE_BOOL)
function Bone_Binder:New(ent,bone_part,is_bone)
	local newinst = {}	
	setmetatable(newinst,Bone_Binder)
	
	newinst:SetBoneId(bone_part)
	newinst:SetIsBone(is_bone)
	newinst:SetEntity(ent)
	
	return newinst
end


setmetatable(Bone_Binder,{__call = Bone_Binder.New})
COMBINE_LOCK.Bone_Binder = Bone_Binder