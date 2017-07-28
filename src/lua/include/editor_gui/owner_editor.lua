
local PANEL = {}
function PANEL:Init()

	self.menu = vgui.Create("DMenuBar",self)
	self.menu:DockMargin( -3, -6, 0, 0 )
	
	local addmenu=self.menu:AddMenu("Add")
	addmenu:AddOption("Add by Steam ID",function()
		self:MakeStringDialog("",function(ply) self:AddPlayer(ply) end)
	end)
	addmenu:AddOption("Add player",function()
		self:MakePlayerDialog(function(ply) self:AddPlayer(ply) end)
	end)
	
	self.ScrPanel = vgui.Create("DScrollPanel",self)
	self.ScrPanel:Dock(BOTTOM)
	self.OwnerList =  vgui.Create("DListLayout")
	self.OwnerList:Dock(TOP)
	
	
	self.ScrPanel:AddItem(self.OwnerList)
	self.CboxPanel = vgui.Create("DPanel",self)
	self.CboxPanel:Dock(TOP)
	
	self.AdminCbx = vgui.Create("DCheckBoxLabel",self.CboxPanel)
	self.AdminCbx:Dock(BOTTOM)
	self.AdminCbx:SetText("Allow admins to edit properties of this entity")
	self.AdminCbx:DockMargin(10,10,10,10)
	self.AdminCbx.OnChange =function(cbox,val)
		self.Whitelist:AllowAdminsEdit(val)
	end
	
	self.SAdminCbx = vgui.Create("DCheckBoxLabel",self.CboxPanel)
	self.SAdminCbx:Dock(TOP)
	self.SAdminCbx:DockMargin(10,10,10,10)
	self.SAdminCbx:SetText("Allow superadmins to edit properties of this entity")
	self.SAdminCbx.OnChange =function(cbox,val)
		self.Whitelist:AllowSuperAdminsEdit(val)
	end
	
end

function PANEL:createItemPanel()
	local item = vgui.Create("DPanel")
	item:SetHeight(70)
	
	local nameLabel = vgui.Create("DLabel",item)
	nameLabel:Dock(TOP)
	nameLabel:DockMargin(10,5,10,5)
	nameLabel:SetTextColor(Color(0,0,0))
	local idlabel = vgui.Create("DLabel",item)
	idlabel:Dock(BOTTOM)
	idlabel:DockMargin(10,5,10,5)
	idlabel:SetTextColor(Color(0,0,0))
	function item:SetSteamId(id)
		self.mSteamId = id
		idlabel:SetText(id)
		local ply = player.GetBySteamID(id)
		if ply then
			nameLabel:SetText(ply:Nick())
		else
			nameLabel:SetText("Unable to get player's data because he is not online.")
		end
	end
	
	function item:GetSteamId()
		return self.mSteamId
	end
	
	item.OnMousePressed=function(panel,mouse)
		local menu = DermaMenu()
		menu:AddOption("Delete",function() 
			panel:Remove() 
			end)
		local editopt = menu:AddSubMenu("Edit")
		
		local function editSteamID(id)
			local key = table.KeyFromValue(self.Whitelist.Owners.player_ids,panel:GetSteamId())
			if key then
				self.Whitelist.Owners.player_ids[key] = id
				panel:SetSteamId(id)
			end
		end
		
		steamIdedit = editopt:AddOption("By SteamID",function()
			self:MakeStringDialog(panel:GetSteamId(),editSteamID)
		end)
		nickEdit = editopt:AddOption("By nickname",function()
			self:MakePlayerDialog(function(ply)
				editSteamID(ply:SteamID())
			end)			
		end)
		menu:Open()
	end
	
	return item
end

function PANEL:AddPlayer(ply)
	local steamID
	if isstring(ply) then
		steamID = ply		
	elseif isentity(ply) and ply:IsPlayer() then 
		steamID = ply:SteamID()
	else 
		return
	end
	if self.Whitelist:AddOwner(steamID) then
		local item = self:createItemPanel()
		item:SetSteamId(steamID)
		self.OwnerList:Add(item)
	end
end

function PANEL:MakeStringDialog(default,callback)
	Derma_StringRequest("Add Steam ID","Enter the valid steam id:",default,function(text)
		if COMBINE_LOCK.IsSteamID(text) then 
			callback(text)
		else
			Derma_Message("You have entered invalid steam ID","Message","OK")
		end
	end)
end

function PANEL:MakePlayerDialog(callback)
	local frame = vgui.Create("DFrame")
	frame:SetSize(300,150)
	frame:SetTitle("Add a player")
	local p  = vgui.Create("DPanel",frame)
	p:Dock(FILL)	
	
	local plypanel = vgui.Create("DComboBox",p)
	plypanel:Dock(TOP)
	plypanel:SetValue("Select any player you want to add")
	for K,V in pairs(player.GetAll()) do
		plypanel:AddChoice(V:Nick(),V)
	end
	
	local okbutton = vgui.Create("DButton",p)
	okbutton:Dock(BOTTOM)
	okbutton:SetText("OK")
	
	okbutton.DoClick = function(panel)
		str,ply = plypanel:GetSelected()
		if ply then
			callback(ply)
			frame:Close()
		end
	end
	
	frame:Center()
	frame:MakePopup()
end

function PANEL:PerformLayout()
	local w,h = self:GetSize()
	self.ScrPanel:SetHeight(h*0.7)
	self.CboxPanel:SetHeight(h*0.2)
end

function PANEL:SetData(data)
	self.Whitelist = data
	self.SAdminCbx:SetChecked(data:IsAllowedSuperAdminsEdit())
	self.AdminCbx:SetChecked(data:IsAllowedAdminsEdit())
	for K,V in ipairs(self.Whitelist.Owners.player_ids) do
		local item = self:createItemPanel()
		item:SetSteamId(V)
		self.OwnerList:Add(item)
	end
end
vgui.Register("combine_lock_editor_owners",PANEL,"DPanel")