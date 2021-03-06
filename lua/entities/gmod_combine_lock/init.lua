include("shared.lua")
include('include/lock_Whitelist/LockWhitelist.lua')
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
if WireLib then
DEFINE_BASECLASS( "base_wire_entity" )
ENT.WireDebugName	= "Combine button"
end

ENT.PrintName       = "Combine Lock"
util.AddNetworkString("gmod_combine_lock_send_whitelist")
util.AddNetworkString("gmod_combine_lock_receive_whitelist")
COMBINE_LOCK = COMBINE_LOCK or {}

local model="models/props_combine/combine_lock01.mdl"


local function IsDoor(ent)
	local cl=ent:GetClass()
	if (cl=="func_door" or cl=="func_door_rotating" or cl=="prop_door_rotating") then
		return true
	end
	if cl=="prop_dynamic" then
		return IsAutoDoor(ent)
	end
	return false
end

function COMBINE_LOCK.PasteEnt( pl, Data, ... )//duplicate entity
	Data.Class = scripted_ents.Get(Data.Class).ClassName
	if IsValid(pl) and not pl:CheckLimit("combine_locks") then return false end

	local ent = ents.Create( Data.Class )
	if not IsValid(ent) then return false end

	duplicator.DoGeneric( ent, Data )
	ent:Spawn()
	ent:Activate()
	duplicator.DoGenericPhysics( ent, pl, Data ) -- Is deprecated, but is the only way to access duplicator.EntityPhysics.Load (its local)

	ent:SetPlayer(pl)
	if ent.DupeDeploy then ent:DupeDeploy(pl,nil,...) end

	if IsValid(pl) then pl:AddCount("combine_locks", ent ) end

	local phys = ent:GetPhysicsObject()

	if IsValid(phys) then
		if Data.frozen then phys:EnableMotion(false) end
		if Data.nocollide then phys:EnableCollisions(false) end
	end

	return ent
end


local DoorTable={}
DoorTable["prop_dynamic"]={}
DoorTable["prop_dynamic"][1]= "models/combine_gate_vehicle.mdl"
DoorTable["prop_dynamic"][2]= "models/props_combine/combine_door01.mdl"
DoorTable["prop_dynamic"][3]= "models/combine_gate_citizen.mdl"
DoorTable["prop_dynamic"][4]= "models/props_lab/elevatordoor.mdl"
DoorTable["prop_dynamic"][5]= "models/props_doors/doorklab01.mdl"

function IsAutoDoor(ent)
	local mod=ent:GetModel()
	for K,V in pairs(DoorTable["prop_dynamic"]) do
		if mod==V then
			return true
		end
	end
	return false
end



function ENT:Initialize()
	self:SetModel(model)
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	self.IsAutoDoor=false
	self.LastTrigger = 0
	if WireLib then
		self.Outputs = Wire_CreateOutputs(self, { "Out" })
	end

	self:SetSpriteSize(5)
end

function ENT:AttachToDoor(door,isbone,id)
	if not (self:GetNW2Bool("attach_to_door",false) and door:IsValid()) then
		return
	end
	if isbone then
		self:FollowBone(door,id)
	else
		self:SetMoveType(MOVETYPE_NONE)
		self:SetParent(door,id)
	end

	self:Link(door)
end

function ENT:TriggerDoor()
	if not self:GetNW2Bool("attach_to_door",false) then
		return
	end
	local ent=self.attached_door
	if not ent then return end
	if not ent:IsValid() then return end
	if self.IsAutoDoor then
		if self:GetIsOn() then
			ent:Fire("setanimation","open",0)
		else
			ent:Fire("setanimation","close",0)

		end
	else
		if self:GetIsOn() then
			ent:Fire("unlock")
		else
			ent:Fire("close")
			ent:Fire("lock")
		end
	end
end

function ENT:OpenMenuCl(caller)
	if self:IsOwner(caller) then
		net.Start("gmod_combine_lock_send_whitelist")
		net.WriteEntity(self)
		net.WriteTable(self.Whitelist)
		net.Send(caller)
	end
end


net.Receive("gmod_combine_lock_receive_whitelist",function(len,ply)
	local ent = net.ReadEntity()
	local whitelist = net.ReadTable()
	if ent.SetWhitelistData then
		ent:SetWhitelistData(whitelist,ply)
	end
end)

function ENT:SetWhitelistData(data,sender)

	if self.Whitelist:CheckOwner(sender) then
		self.Whitelist:SetWhitelistData(data)
	end
end


function ENT:DupeDeploy(ply,door, value_off, value_on, description,entityout, Whitelist_type,Whitelist)
	self:Setup(ply,door, value_off, value_on, description,entityout, Whitelist_type,Whitelist)
end
--just in case it will be spawnable from main menu
function ENT:SpawnFunction(ply,trace,class)
	if ( not trace.Hit ) then return end

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
	gmod_combine_lock:Setup(ply)
	gmod_combine_lock:Activate()

	ply:AddCount( "combine_locks", gmod_combine_lock )
	local min = gmod_combine_lock:OBBMins()
	gmod_combine_lock:SetPos( trace.HitPos - trace.HitNormal * min.z/2.8 )



	ply:AddCleanup( "combine_locks", gmod_combine_lock )
	return gmod_combine_lock
end

function ENT:Setup(ply,door, value_off, value_on, description,entityout, Whitelist_type,Whitelist)

	if not WireLib then
		self:SetNW2Bool("attach_to_door",true)
		self.Whitelist_type=false

		self.Whitelist = COMBINE_LOCK.Whitelist(Whitelist)
		if ply then
			self.Whitelist:AddOwner(ply)
		end
		return
	end
	self.Owner=ply
	self:SetNW2Bool("attach_to_door",tobool(door))
	self.value_off=value_off or 0
	self.value_on=value_on or 1
	self.entityout=entityout or 0
	self.Whitelist_type=Whitelist_type or false
	
	if entityout==1 then
		WireLib.AdjustSpecialOutputs(self, { "Out",  "Last_Player" }, { "NORMAL" , "ENTITY" })
		Wire_TriggerOutput(self, "Last_Player", nil)
	else
		Wire_AdjustOutputs(self, { "Out" })
	end

	if self:GetIsOn() then
		Wire_TriggerOutput(self, "Out",self.value_on)
	else
		Wire_TriggerOutput(self, "Out",self.value_off)
	end

	if self.Whitelist_type then
		WireLib.CreateInputs(self, { "Allowed [ARRAY]","Blacklist [ARRAY]" })
	else
		self.Whitelist = COMBINE_LOCK.Whitelist(Whitelist)
		if ply then
			self.Whitelist:AddOwner(ply)
		end
	end
end



function ENT:Use(caller,activator,useType,value)
	if not (caller:IsPlayer() and activator~=self and IsValid(self)) then return end

	local trace=util.TraceLine(util.GetPlayerTrace(caller))
	if (self~=trace.Entity) then return end

	if not self.Whitelist_type then
		if caller:KeyDown(IN_WALK) then

			self:OpenMenuCl(caller)
			return
		end
	end

	self:OpenLock(caller)
end

function ENT:OpenLock(ply)

	local trigger = true

	--check if we cooldown passed
	if self.LastTrigger > CurTime() then
		return
	end
	--if player passed as an arg, check the rules
	if isentity(ply) then
		if self.Whitelist_type then
			trigger=self:WireCheck(ply)
		else
			trigger=self.Whitelist:CheckRule(ply)
		end
	end

	if trigger then
		self.LastTrigger = CurTime() + self:GetWaitTime()
		self:TriggerLock(ply)
		self:EmitSound(self:GetAllowSound())

		self:SetSpriteAllow(true)

	else
		self:EmitSound(self:GetDenySound())
	end
end

if WireLib then
	function ENT:WireCheck(ply)
		local tab=self.Inputs.Blacklist.Value
		for K,V in pairs(tab) do
			if not (IsEntity(V) and V:IsPlayer()) then continue end
			if ply==V then return false end
		end
		local tab2=self.Inputs.Allowed.Value
		for K,V in pairs(tab2) do
			if not (IsEntity(V) and V:IsPlayer()) then continue end
			if ply==V then return true end
		end
		return false
	end
end

function ENT:Backdoor()
	self:OpenLock()
end


function ENT:IsOwner(ply)
	if self.Whitelist_type then
		return false
	end

	return self.Whitelist:CheckOwner(ply)
end

if WireLib then
	function ENT:Think()
		self.BaseClass.Think(self)
		if self:GetSpriteAllow() and self.LastTrigger<=CurTime() then
			self:SetSpriteAllow(false)
		end
	end
else
	function ENT:Think()
		if self:GetSpriteAllow() and self.LastTrigger<=CurTime() then
			self:SetSpriteAllow(false)
		end
	end
end

--triggers the entity's outputs
function ENT:TriggerLock(ply)
	if (not IsValid(self)) then return end
	local on=self:GetIsOn()
	if WireLib then
		if not on then
			self.ValueWire = self.value_on
		else
			self.ValueWire = self.value_off
		end

		Wire_TriggerOutput(self, "Out", self.ValueWire)

		if self.entityout==1 and isentity(ply) and ply:IsPlayer() then
			Wire_TriggerOutput(self, "Last_Player", ply)
		end
	end
	self:SetIsOn(not on)
	self:TriggerDoor()

end

function ENT:Link(door)
	if not self:GetNW2Bool("attach_to_door",false) then return end
	if not IsDoor(door) then return end
	self.IsAutoDoor= IsAutoDoor(door)
	self.attached_door=door
end

function ENT:Unlink()
	if not self:GetNW2Bool("attach_to_door",false) then return end
	self.attached_door=nil
	self.IsAutoDoor=false
end

duplicator.RegisterEntityClass("gmod_combine_lock", COMBINE_LOCK.PasteEnt, "Data","value_off", "value_on", "description", "entityout","Whitelist_type","Whitelist" )
--if there is no Wiremod installed
