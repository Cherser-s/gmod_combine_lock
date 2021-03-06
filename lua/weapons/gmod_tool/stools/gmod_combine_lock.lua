TOOL.Category		= "Construction"
TOOL.Name			= "#tool.gmod_combine_lock.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""
--TOOL.Tab			= "Wire"




if CLIENT then
	language.Add( "tool.gmod_combine_lock.name", "Combine sensor lock (Wire)" )
	language.Add( "tool.gmod_combine_lock.desc", "Spawns a secure lock." )
	language.Add( "CombineLockTool_use_with_door","Use lock with door")
	language.Add( "tool.gmod_combine_lock.1", "Primary: Create/Update Button. Secondary: Attach lock to the door." )
	language.Add("tool.gmod_combine_lock.2","Secondary: Attach lock to the door.")
	language.Add( "CombineLockTool_entityout", "Output Last User" )
	language.Add( "CombineLockTool_Whitelist", "Use Wire Whitelists" )
	language.Add( "CombineLockTool_value_on", "Value On:" )
	language.Add( "CombineLockTool_value_off", "Value Off:" )
	language.Add( "Undone_CombineLock", "Undone Combine Lock" )
	language.Add("Cleanup_combine_locks", "Wired Combine Locks")
	language.Add("Cleaned_combine_locks", "Cleaned up all Wire Combine Locks")
	language.Add("SBoxLimit_combine_locks", "You've reached the combine lock limit!")
else
    CreateConVar("sbox_maxcombine_locks", 10)
end

local DoorTable={}
DoorTable["prop_dynamic"]={}
DoorTable["prop_dynamic"][1]= "models/combine_gate_vehicle.mdl"
DoorTable["prop_dynamic"][2]= "models/props_combine/combine_door01.mdl"
DoorTable["prop_dynamic"][3]= "models/combine_gate_citizen.mdl"
DoorTable["prop_dynamic"][4]= "models/props_lab/elevatordoor.mdl"
DoorTable["prop_dynamic"][5]= "models/props_doors/doorklab01.mdl"


local function IsDoor(ent)
	if not ent:IsValid() then return false end
	local cl=ent:GetClass()
	local model=ent:GetModel()
	if cl=="func_door" or cl=="func_door_rotating" or cl=="prop_door_rotating" then return true end
	if cl=="prop_dynamic" then 
		for K,V in pairs(DoorTable["prop_dynamic"]) do
			if model==V then 
				return true 
			end 
		end
	end
	return false
end






if SERVER then
	AddCSLuaFile("include/bone_binder/DoorBoneBinder.lua")
	function TOOL:Deploy()
		self.EntTmp=nil
		self:SetStage(1)
	end
	
	function TOOL:GetConVars() 
		return self:GetClientNumber( "use_with_door" ) ~= 0, self:GetClientNumber( "value_off" ), self:GetClientNumber( "value_on" ),
			self:GetClientInfo( "description" ), self:GetClientNumber( "entityout" ) ~= 0,self:GetClientNumber( "Whitelist") ~= 0,
			self:GetClientNumber( "AimBone") ,self:GetClientNumber( "Attach") 
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end



function TOOL:Reload(trace)
	if self:GetStage()~=1 then return false end
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) or 
	not (trace.Entity:IsValid() and 
	trace.Entity:GetClass()=="gmod_combine_lock" and trace.Entity:GetOwner()==self:GetOwner()) then 
		return false 
	end

	if CLIENT then return true end
	if not trace.Entity:GetNWBool("attach_to_door",false) 
		or trace.Entity:GetParent()==trace.Entity.attached_door then 
		return false 
	end
	trace.Entity:Unlink()
	return true
end




TOOL.ClientConVar = {
    use_with_door="0",
	value_off = "0",
	value_on = "1",
	description = "",
	entityout = "0",
	Whitelist = "0",
	AimBone="0",
	Attach="-1"
}

function TOOL.BuildCPanel(panel)
	--WireToolHelpers.MakePresetControl(panel, "gmod_combine_lock")
	if WireLib then
	panel:CheckBox("#CombineLockTool_use_with_door", "gmod_combine_lock_use_with_door")
	panel:CheckBox("#CombineLockTool_entityout", "gmod_combine_lock_entityout")
	panel:CheckBox("#CombineLockTool_Whitelist", "gmod_combine_lock_Whitelist")
	panel:NumSlider("#CombineLockTool_value_on", "gmod_combine_lock_value_on", -10, 10, 1)
	panel:NumSlider("#CombineLockTool_value_off", "gmod_combine_lock_value_off", -10, 10, 1)
end
end

function TOOL:LeftClick(trace)

	if self:GetStage()~=1 or (not trace.HitPos) or (trace.Entity:IsPlayer()) then 
		return false 
	end
	if CLIENT then 
		return true 
	end
	local ply=self:GetOwner()
	local door=self:GetClientNumber("use_with_door")
	local  value_off = self:GetClientNumber("value_off")
	local value_on = self:GetClientNumber("value_on")
	local description = self:GetClientNumber("description")
	local entityout = self:GetClientNumber("entityout")
	local Whitelist = tobool(self:GetClientNumber("Whitelist"))
	if trace.Entity:IsValid() then
		if trace.Entity:GetClass()== "gmod_combine_lock" then 
			if trace.Entity:GetOwner()~=ply then 
				return false
			end
			trace.Entity:Setup(ply,door, value_off, value_on, description, entityout,Whitelist)
			return true
		elseif trace.Entity:GetOwner() then
			local plyy=trace.Entity:GetOwner()
			if (plyy:IsPlayer() and (plyy~=ply)) then
				return false 
			end
		end	
	end
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch,Ang.roll= Ang.roll,-Ang.pitch
	Ang.yaw = Ang.yaw-90
    if ( not ply:CheckLimit( "combine_locks" ) ) then 
		return false 
	end
	
	local gmod_combine_lock = ents.Create( "gmod_combine_lock" )
	if (not gmod_combine_lock:IsValid()) then 
		return false 
	end

	gmod_combine_lock:SetAngles( Ang )
	gmod_combine_lock:SetPos( trace.HitPos )
	gmod_combine_lock:Spawn()
	gmod_combine_lock:Setup(ply,door, value_off, value_on, description, entityout,Whitelist)
	gmod_combine_lock:Activate()
	
	ply:AddCount( "combine_locks", gmod_combine_lock )
	local min = gmod_combine_lock:OBBMins()
	gmod_combine_lock:SetPos( trace.HitPos - trace.HitNormal * min.z/2.8 )
	
	
	ply:AddCleanup( "combine_locks", gmod_combine_lock )
	
	local bonenum=self:GetClientNumber("AimBone")
	local isattachment=self:GetClientNumber("Attach")
	
	if not IsDoor(trace.Entity) or isattachment == -1 then 
		if WireLib then
			if trace.Entity:IsValid() and IsValid(trace.Entity:GetPhysicsObject()) then
				local const = WireLib.Weld(gmod_combine_lock, trace.Entity, trace.PhysicsBone, true)
			end
			undo.Create("CombineLock")
			undo.AddEntity( gmod_combine_lock )
			undo.AddEntity( const )
			undo.SetPlayer( ply )
			undo.Finish()
		else
			undo.Create("CombineLock")
			if trace.Entity:IsValid() and IsValid(trace.Entity:GetPhysicsObject()) then
				constraint.Weld(gmod_combine_lock,trace.Entity,0,0,0,true,false)
				undo.AddFunction(function(ent) constraint.RemoveAll(ent) end,gmod_combine_lock)
			end
			undo.AddEntity(gmod_combine_lock)
			undo.SetPlayer(ply)
			undo.Finish()
		end
	else
		gmod_combine_lock:AttachToDoor(trace.Entity,tobool(isattachment),bonenum)	
	end
	
    return true
end


function TOOL:RightClick(trace)
	if (not trace.HitPos) or trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	local ent=trace.Entity

	if not (ent and ent:IsValid()) then 
		return false
	end
	local ply=self:GetOwner()
	
	if ent:GetOwner() then
		local pll=ent:GetOwner()
		if (pll:IsPlayer() and (not pll==ply)) then
			return false end
	end
	local stage=self:GetStage()
	if stage==1 then 
		if ent:GetClass()~="gmod_combine_lock" then 
			return false 
		end
		self.EntTmp=ent
		self:SetStage(2)
	elseif stage==2 then
		if not IsValid(self.EntTmp) then 
			return false 
		end
		if not IsDoor(ent) then
			return false 
		end
		self.EntTmp:Link(ent)
		self:SetStage(1)
	end
	return true
end


if CLIENT then 
	include("include/bone_binder/DoorBoneBinder.lua")
	
	function DrawCircleI( x, y, radius, seg )
		local cir = {}

		table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
		for i = 0, seg do
			local a = math.rad( ( i / seg ) * -360 )
			table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
		end

		local a = math.rad( 0 ) -- This is need for non absolute segment counts
		table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

		surface.DrawPoly( cir )
	end

local button=KEY_T
local mater=Material("vgui/white")
local IsBoneCV
local AimBoneCV
timer.Simple(1,function() mater:SetInt("$ignorez",1)
	IsBoneCV=GetConVar("gmod_combine_lock_Attach")
	AimBoneCV=GetConVar("gmod_combine_lock_AimBone")
end)


local sizerect=15
local radius=10
local offset=20
local ply=LocalPlayer()
local font="Default"
local colore1=Color(255,0,0,255)
local colore2=Color(0,0,255,255)
local colore3=Color(120,120,120,255)

local function IsInCenterRad(x,y,r)
	local rr = r or radius
	local cx,cy = input.GetCursorPos()
	if math.abs(cx-x)<=rr and math.abs(cy-y)<=rr then return true end
	return false
end 



local function IsInCenterRect(x,y)
	if math.abs(ScrW()/2-x)<=sizerect and math.abs(ScrH()/2-y)<=sizerect then return true end
	return false
end 

function TOOL:Deploy()
	self.AimEntInfo=COMBINE_LOCK.Bone_Binder()
	IsBoneCV:SetInt(-1)
	AimBoneCV:SetInt(0)
end

function TOOL:Think()
	local ply=self:GetOwner()
	if not ply:Alive() then
		return 
	end
	--binding bone
	local save_bone = input.IsKeyDown(button)
	
	local ent=ply:GetEyeTrace().Entity
	if not (ent and ent:IsValid()) then 
		save_bone = false 
	end
	
	if (self.AimEntInfo and self.AimEntInfo:GetEntity() and (ent~= self.AimEntInfo:GetEntity() or (not ent:IsValid()))) then 
		save_bone = false
	end
	
	if save_bone then
		if IsDoor(ent) and not self.AimEntInfo:GetEntity() then
			--bind new bone or attachment
			local bonecount=ent:GetBoneCount()
			for i=0,bonecount-1,1 do
				local data=ent:GetBonePosition(i)
				local scr=Vector(data[1],data[2],data[3]):ToScreen()
				if IsInCenterRad(scr.x,scr.y) then  
					IsBoneCV:SetInt(1)
					AimBoneCV:SetInt(i)	
					self.AimEntInfo = COMBINE_LOCK.Bone_Binder(ent,i,true)
					return
				end
			end
				
			local attachments=ent:GetAttachments()
			if attachments and #attachments>0 then
				--attachments
			
				for K,V in pairs(attachments) do

					local data=ent:GetAttachment(V["id"])
					local scr=data.Pos:ToScreen()
					if IsInCenterRad(scr.x,scr.y) then 
							
						self.AimEntInfo = COMBINE_LOCK.Bone_Binder(ent,V["id"],false)
						IsBoneCV:SetInt(0)
						AimBoneCV:SetInt(V["id"])
						return
					end
				end
			end
		end
	elseif not self.AimEntInfo or self.AimEntInfo:GetEntity() then
		self.AimEntInfo=COMBINE_LOCK.Bone_Binder()
		IsBoneCV:SetInt(-1)
		AimBoneCV:SetInt(0)
	end
end

function TOOL:DrawHUD()
	local ply=self:GetOwner()
	if not ply:Alive() then
		return 
	end
	
	local ent=ply:GetEyeTrace().Entity
	if not (ent and ent:IsValid()) then 
		return
	end
	
	if IsDoor(ent) then
		local bonecount=ent:GetBoneCount()
		
		if self.AimEntInfo:GetEntity() then
			surface.SetMaterial(mater)
			surface.SetDrawColor(colore3)
			local x,y = input.GetCursorPos()
			local text = ""
			
			if self.AimEntInfo:GetIsBone() then
				local data=self.AimEntInfo:GetEntity():GetBonePosition(self.AimEntInfo:GetBoneId())
				scr = Vector(data[1],data[2],data[3]):ToScreen()
				text = self.AimEntInfo:GetEntity():GetBoneName(self.AimEntInfo:GetBoneId())
			else
				local data=self.AimEntInfo:GetEntity():GetAttachment(self.AimEntInfo:GetBoneId())
				scr = data.Pos:ToScreen()
				
			end
			
			surface.DrawLine(x,y,scr.x,scr.y)
			surface.SetDrawColor(Color(0,255,0))			
			surface.SetTextPos(scr.x,scr.y+offset)
			surface.SetTextColor(Color(20,150,20))
			surface.DrawText(text)
			if self.AimEntInfo:GetIsBone() then
				DrawCircleI(scr.x,scr.y,radius,360)
			else 
				surface.DrawRect(scr.x,scr.y,sizerect,sizerect)
			end	
			
		else
			surface.SetMaterial(mater)
			surface.SetFont(font)
			if bonecount>1 then
				surface.SetDrawColor(colore1)
				surface.SetTextColor(colore1)
				for i=0,bonecount-1,1 do
					local data=ent:GetBonePosition(i)
					local scr=Vector(data[1],data[2],data[3]):ToScreen()
					
					DrawCircleI(scr.x,scr.y,radius,360)
					surface.SetTextPos(scr.x,scr.y+offset)
					surface.DrawText(ent:GetBoneName(i))
				end
			end
			
			local attachments=ent:GetAttachments()
			if attachments and #attachments>0 then
				--optimize
				surface.SetDrawColor(colore2)
				surface.SetTextColor(colore2)
				for K,V in pairs(attachments) do

					local data=ent:GetAttachment(V["id"])
					local scr=data.Pos:ToScreen()
					
					surface.DrawRect(scr.x,scr.y,sizerect,sizerect)
					surface.SetTextPos(scr.x,scr.y+offset)
					surface.DrawText(V["name"])
				
				end
			end
		end
	end
end

end
cleanup.Register("combine_locks")