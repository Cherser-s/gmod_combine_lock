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
ENT.Editable		= true
ENT.Category        = "Other"
ENT.Spawnable		= true
ENT.AdminOnly		= false

function ENT:SetupDataTables()
	self:NetworkVar("Bool",0,"SpriteAllow")
	self:NetworkVar("Bool",1,"IsOn")
	self:NetworkVar("Bool",2,"ShowSprite",{ KeyName = "showsprite", Edit = {type = "Boolean", order = 1,category = "Sprite properties"}})
	self:NetworkVar("Vector",0,"AllowedColor",{ KeyName = "allowedcolor", Edit = {type = "VectorColor", order = 0,category = "Sprite properties"}})
	self:NetworkVar("Vector",1,"OpenColor",{ KeyName = "opencolor", Edit = {type = "VectorColor", order = 2,category = "Sprite properties"}})
	self:NetworkVar("Vector",2,"ClosedColor",{ KeyName = "closedcolor", Edit = {type = "VectorColor", order = 3,category = "Sprite properties"}})
	self:NetworkVar("Float",0,"SpriteSize",{KeyName = "spritesize",Edit = {type = "Float",order = 4,min = 1,max = 15,category = "Sprite properties"}})
	self:SetSpriteAllow(false)
	self:SetIsOn(false)
end


properties.Add("gmod_combine_lock_show_editor",{
	MenuLabel = "Show editor",
	Order	  = 999,
	MenuIcon  = "icon16/book_edit.png",
	Filter = function( self, ent, ply)
		if not (IsValid(ent) and ent:GetClass()=="gmod_combine_lock") then
			return false
		else 
			return true
		end
	end,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )

		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()

	end,
	Receive = function( self, length, player ) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()
		ent:OpenMenuCl(player)
	end

})