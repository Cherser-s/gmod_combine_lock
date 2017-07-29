
if not COMBINE_LOCK then 
	COMBINE_LOCK = {}
end

COMBINE_LOCK.RULE_EDITOR = {
	Init = function(self)
		self.Scroller = vgui.Create("DScrollPanel",self)
		self.Scroller:Dock(LEFT)
		self.Scroller:SetPaintBackground( true )
		self.Scroller:SetBackgroundColor( Color( 100, 100, 100 ) )
		self.RuleList = vgui.Create("DListLayout",self.Scroller)
		self.RuleList:Dock(TOP)
		self.RuleList:MakeDroppable("rule_list_item")
		self.RuleList.OnModified = function(listlayout)
			local rules = {}
			for K,V in ipairs(listlayout:GetChildren()) do
				if V.GetRule then
					table.insert(rules,V:GetRule())
				end
			end
			self.Whitelist.Rules = rules
		end
		self.button_panel = vgui.Create("DListLayout",self)
		self.button_panel:Dock(RIGHT)
		self.add_button = vgui.Create("DButton")
		self.add_button:SetText("Add")
		self.add_button:SetImage("icon16/application_add.png")
		self.add_button:SetTall(25)	
		self.add_button:DockMargin(5,10,5,10)	
		self.add_button.DoClick=function(caller)
			self:CreateEditorDialog()
		end
		self.button_panel:Add(self.add_button)
		
		self.edit_button = vgui.Create("DButton")
		self.edit_button:SetText("Edit")
		self.edit_button:SetImage("icon16/application_edit.png")
		self.edit_button:SetTall(25)	
		self.edit_button:DockMargin(5,10,5,10)	
		self.edit_button.DoClick=function(caller)
			if self.RuleList.SelectedItem then
				local val = self.RuleList.SelectedItem:GetRule()
				local index = table.KeyFromValue(self.Whitelist.Rules,val)
				self:CreateEditorDialog(val,index)
			end
		end
		
		self.button_panel:Add(self.edit_button)
		
		self.delete_button = vgui.Create("DButton")
		self.delete_button:SetText("Delete")
		self.delete_button:SetImage("icon16/application_delete.png")
		self.delete_button:SetTall(25)	
		self.delete_button:DockMargin(5,10,5,10)	
		self.delete_button.DoClick=function(caller)
			if self.RuleList.SelectedItem then
				local panel = self.RuleList.SelectedItem
				self.RuleList.SelectedItem = nil
				local val = panel:GetRule()
				table.RemoveByValue(self.RuleList:GetChildren(),panel)
				table.RemoveByValue(self.Whitelist.Rules,val)
				panel:Remove()
				
			end
		end
		
		self.button_panel:Add(self.delete_button)
		
		self.RuleList.OnChildSelect = function(listlayout,item,state)
			if state then
				if listlayout.SelectedItem then
					listlayout.SelectedItem:SetSelected(false)
				end
				listlayout.SelectedItem = item
			end
		end
	end,
	PerformLayout =function(self)
		local w,h = self:GetSize()
		self.Scroller:SetWidth(w*0.8)
		self.button_panel:SetWidth(w*0.2)	
		--self.RuleList:SetWidth(self.Scroller:InnerWidth())
	end,
	CreateRuleItem = function()
		
		local panel = vgui.Create("DPanel")
		panel:SetTall(90)
		panel:DockMargin(5,5,5,5)
		function panel:Paint(w,h)
			if self:IsSelected() then
				surface.SetDrawColor(Color(0,0,255))
				surface.DrawRect(0,0,w,h)
			end
			
			surface.SetDrawColor(Color(255,255,255))
			surface.DrawRect(2,2,w-4,h-4)
			
			if self.AttachedRule then
				if self.AttachedRule.Allow then
					surface.SetDrawColor(Color(0,255,0))
				else
					surface.SetDrawColor(Color(255,0,0))
				end
				
				surface.DrawRect(2,2,10,h-4)
			end
			
		end
		panel:SetSelectable(true)
		panel.label = vgui.Create("DLabel",panel)
		panel.label:Dock(FILL)
		panel.label:DockMargin(20,5,5,5)
		panel.label:SetTextColor(Color(20,20,20))
		function panel:SetRule(Rule)
			self.AttachedRule = Rule
			local data = COMBINE_LOCK.RULE_EDITOR.RuleListItem[Rule.Type](Rule)
			local text = "Type: "..Rule.Type..", Allow if matches: "..tostring(Rule.Allow)
			if (data~="") then
				text = text..", "..data
			end
			panel.label:SetText(text)
		end
		
		function panel:GetRule()
			return self.AttachedRule
		end
		
		local oldPanelOnMousePressed = panel.OnMousePressed
		
		function panel:OnMousePressed(mouse)
			if mouse == MOUSE_LEFT then
				self:SetSelected(true)
			end
			oldPanelOnMousePressed(self,mouse)
		end
		
		function panel:OnSelect(state)
			local parent = self:GetParent()
			if parent and parent.OnChildSelect then
				parent:OnChildSelect(self,state)
			end
		end

		local oldpanelSetSelected = panel.SetSelected
		function panel:SetSelected(state)
			if self:IsSelectable() then
				self:OnSelect(state)
			end
			oldpanelSetSelected(self,state)
		end
		return panel
	end,
	CreateEditorDialog = function(self,Rule,index)
		local frame = vgui.Create("combine_lock_rule_edit_dialog")
		frame:SetSize(300,400)
		frame:Center()
		frame:SetTitle("Rule editor")
		frame:SetRule(table.Copy(Rule))
		frame:SetOnFinishedCallback({
			OnSuccess = function(caller,rule)
				if Rule~=nil then
					self.RuleList:GetChildren()[index]:SetRule(rule)
					self.Whitelist.Rules[index] = rule
				else
					table.insert(self.Whitelist.Rules,rule)
					local panel = self.CreateRuleItem()
					panel:SetRule(rule)
					self.RuleList:Add(panel)
				end
			end,
			OnFail = function(caller,rule)
				
			end
		})
		frame:MakePopup()
	end,
	
	SetData = function(self,whitelist)
					
				
		self.Whitelist = whitelist
		--also set it to children editors
		self.RuleList:Clear()
		
		--now add all items
		for K,V in pairs(self.Whitelist.Rules) do
			local panel = self.CreateRuleItem()
			panel:SetRule(V)
			
			self.RuleList:Add(panel)
			
		end
	end,
	
	GetData = function(self)
		return self.Whitelist
	end,
	
	RuleListItem = {
		Admin = function(Rule)
			return ""
		end,
		SuperAdmin = function(Rule)
			return ""
		end,
		SteamId = function(Rule)
			return "Steam Ids: "..string.Implode(",",Rule.ids)
		end,
		Team = function(Rule)
			return "Team names: "..string.Implode(",",Rule.teams)
		end
		
	}
}


vgui.Register("combine_lock_editor_rule",COMBINE_LOCK.RULE_EDITOR,"DPanel")