include('shared.lua')
include('include/editor_gui/main_editor.lua')
include('include/lock_whitelist/LockWhitelist.lua')
surface.CreateFont("GUIFONT",{font="Arial",size=25})


local mater=Material('sprites/glow04')

local function CreateMat()
	if not mater then
	mater=Material('sprites/glow04')
	end
	mater:SetInt("$spriterendermode",7)
	mater:SetInt("$ignorez",0)
	mater:SetInt("$illumfactor",8)
	mater:SetFloat("$alpha",1)
	mater:SetInt("$nocull",1)
end
timer.Simple(2,CreateMat)

local ply=LocalPlayer()
local sprite_position=Vector(-3.8,6.8,-8.5)
local sprite_color=Color(0,255,0,180)
local sprite_size=5

function ENT:Initialize()

end

net.Receive("gmod_combine_lock_send_whitelist",function()
	local ent = net.ReadEntity()
	local whitelist = COMBINE_LOCK.Whitelist(net.ReadTable())
	
	local frame = vgui.Create("combine_lock_editor_main")
	frame:SetSize(350,400)
	frame:Center()
	frame:SetData(whitelist)
	
	function frame:OnClose()
		--send data back
		net.Start("gmod_combine_lock_receive_whitelist")
		net.WriteEntity(ent)
		net.WriteTable(whitelist)
		net.SendToServer()
	end
	
	frame:MakePopup()
	
	
end)



function ENT:Draw()
	self.Entity:DrawModel()
	if (self:GetSpriteAllow()) then
		local vect=self:LocalToWorld(sprite_position)

		render.SetMaterial(mater)
		render.DrawSprite(vect,sprite_size,sprite_size,sprite_color)

	end
end