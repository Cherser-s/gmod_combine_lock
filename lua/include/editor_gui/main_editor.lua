
if not COMBINE_LOCK then
	COMBINE_LOCK = {}
end
include('include/editor_gui/rule_editor.lua')
include('include/editor_gui/rule_dialog.lua')
include('include/editor_gui/owner_editor.lua')
local PANEL = {}
function PANEL:Init()
	local propsheet = vgui.Create("DPropertySheet",self)
	propsheet:Dock(FILL)

	self.ruleeditor = vgui.Create("combine_lock_editor_rule")
	propsheet:AddSheet("Rules",self.ruleeditor)

	self.ownereditor = vgui.Create("combine_lock_editor_owners")
	propsheet:AddSheet("Owners",self.ownereditor)
--template
	self.propEditor = vgui.Create("DEntityProperties")
	propsheet:AddSheet("Properties",self.propEditor)
end

function PANEL:SetPropertyEntity(ent)
	self.propEditor:SetEntity(ent)
end

function PANEL:SetData(whitelist)
	self.Whitelist = whitelist
	self.ruleeditor:SetData(whitelist)
	self.ownereditor:SetData(whitelist)
end

function PANEL:GetData()
	return self.Whitelist
end

vgui.Register("combine_lock_editor_main",PANEL,"DFrame")
COMBINE_LOCK.MAIN_EDITOR = PANEL
