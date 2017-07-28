ENT.Type = "anim"
if WireLib then
ENT.Base = "base_wire_entity"
else 
ENT.Base = "base_entity"
end
ENT.PrintName		= "Combine Lock"
ENT.Author			= "Cherser"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:SetupDataTables()
	self:NetworkVar("Bool",0,"SpriteAllow")
	self:NetworkVar("Bool",1,"IsOn")
	self:SetSpriteAllow(false)
	self:SetIsOn(false)
end
