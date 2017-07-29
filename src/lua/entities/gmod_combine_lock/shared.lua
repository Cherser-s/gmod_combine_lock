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

ENT.Category        = "Other"
ENT.Spawnable			= true
ENT.AdminSpawnable		= true

function ENT:SetupDataTables()
	self:NetworkVar("Bool",0,"SpriteAllow")
	self:NetworkVar("Bool",1,"IsOn")
	self:SetSpriteAllow(false)
	self:SetIsOn(false)
end
