
if not COMBINE_LOCK then 
	COMBINE_LOCK = {}
end
include('include/editor_gui/rule_editor.lua')
include('include/editor_gui/rule_dialog.lua')
include('include/editor_gui/owner_editor.lua')
COMBINE_LOCK.MAIN_EDITOR = {
	Init = function(self)
		local propsheet = vgui.Create("DPropertySheet",self)
		propsheet:Dock(FILL)
		
		self.ruleeditor = vgui.Create("combine_lock_editor_rule")
		propsheet:AddSheet("Rules",self.ruleeditor)
		
		self.ownereditor = vgui.Create("combine_lock_editor_owners")
		propsheet:AddSheet("Owners",self.ownereditor)
	end,
	
	SetData = function(self,whitelist)
		self.Whitelist = whitelist
		self.ruleeditor:SetData(whitelist)
		self.ownereditor:SetData(whitelist)
		--also set it to children editors
	end,
	
	GetData = function(self)
		return self.Whitelist
	end
}


vgui.Register("combine_lock_editor_main",COMBINE_LOCK.MAIN_EDITOR,"DFrame")