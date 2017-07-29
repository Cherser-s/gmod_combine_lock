
if not COMBINE_LOCK then 
	COMBINE_LOCK = {}
end
include('include/lock_whitelist/LockWhitelist.lua')
COMBINE_LOCK.CreateRuleEditDialog = function(paneltable)
	paneltable.SetRule = function(self,rule)
		self.Rule = rule
		self.OwnedRule = false
	end
	
	paneltable.GetRule=function(self)
		return self.Rule
	end
	
	
	return data
end
COMBINE_LOCK.RuleEditDialog = {
	Init = function(self)
		self.counter = -1000
		self.Rule = {}
		self.cover = vgui.Create("DPanel",self)
		self.cover:Dock(FILL)
		self.cover.PerformLayout = function(panel)
			local w,h = panel:GetSize()
			if self.Dialog then
				self.Dialog:SetTall(h*0.7)
			end
			self.buttonpanel:SetTall(h*0.1)
		
		end
		self.buttonpanel  = vgui.Create("DPanel",self.cover)
		self.buttonpanel:Dock(BOTTOM)
		self.BackButton = vgui.Create("DButton",self.buttonpanel)
		self.BackButton:SetText("Back")
		self.BackButton:Dock(LEFT)
		self.BackButton:DockMargin(5,5,5,5)
		self.BackButton.DoClick=function()
			if self.counter>-1 then
				self:SetCounter( self.counter - 1 )
				self:PickWindow()
			end
		end
		
		self.NextButton = vgui.Create("DButton",self.buttonpanel)
		self.NextButton:SetText("Next")
		self.NextButton:Dock(RIGHT)
		self.NextButton:DockMargin(5,5,5,5)
		self.NextButton.DoClick=function()
			if self.counter<=0 then
				self:SetCounter( self.counter + 1 )
				self:PickWindow()
			end
		end
		self:SetCounter(-1)
	end,
	OnAllowedNext = function(self,caller)
		self.NextButton:SetEnabled(true)
	end,
	OnDisallowedNext = function(self,caller)
		self.NextButton:SetEnabled(false)
	end,
	GetOnAllowedNext = function(self)
		return {
			Allowed = function(caller)
				self:OnAllowedNext(caller)
			end,
			Disallowed = function(caller)
				self:OnDisallowedNext(caller)	
			end
		}
		
	end,
	SetOnFinishedCallback = function(self,delegate)
		if not (isfunction(delegate.OnSuccess) and isfunction(delegate.OnFail)) then error("expected function got "..type(delegate)) end
		self.OnFinishDialog = delegate
	end,
	OnRemove = function(self)
		if not self.OnFinishDialog then 
			return
		end
		--check if success
		if COMBINE_LOCK.Whitelist.IsRule(self.Rule) then
			self.OnFinishDialog.OnSuccess(self,self.Rule)
		else 
			self.OnFinishDialog.OnFail(self,self.Rule)
		end
	end,
	SetCounter = function(self,counter)
		if counter==self.counter then return end
		
		
		if counter==-1 then 
			self.BackButton:SetEnabled(false)
		else 
			self.BackButton:SetEnabled(true)
		end
		
		if counter>self.counter then
			self.NextButton:SetEnabled(false)
		end
		self.counter = counter
		self:PickWindow()
	end,
	PickWindow = function(self)
		if self.Dialog then 
			self.Dialog:Remove()
		end
		if self.counter>=1 then 
			--check if exceed
			local seqtable = self.Sequences[self.Rule.Type]
			if self.counter>#seqtable then
				--show end
				self:Close()
				return
			else 
				self.Dialog = vgui.CreateFromTable(seqtable[self.counter],self.cover,"RulePanel")
			end
			
		elseif self.counter == -1 then
			--Rule type picker
			self.Dialog = vgui.CreateFromTable(self.RulePicker,self.cover,"RulePanel")
		else 
			--allow type
			self.Dialog = vgui.CreateFromTable(self.AllowPicker,self.cover,"RulePanel")
		end
		self.Dialog:SetCallback(self:GetOnAllowedNext())
		self.Dialog:SetRule(self.Rule)
		self.Dialog:Dock(TOP)
		self:InvalidateLayout()
	end
	
	,SetRule = function(self,rule)
		if rule then
			self.Rule = rule
			if self.Dialog then 
				self.Dialog:SetRule(rule)
			end
			
		end
	end
	,Sequences = {
		Admin = {},
		SuperAdmin = {},
		SteamId = {
			vgui.RegisterTable({
				Init = function(self)
					self.InputStr = vgui.Create("DTextEntry",self)
					self.InputStr:Dock(TOP)
					self.InputStr:DockMargin(10,10,10,10)
					
					self.desc = vgui.Create("DLabel",self)
					self.desc:SetText("Enter steam IDs you want to add separated by comma.")
					self.desc:Dock(BOTTOM)
					self.desc:DockMargin(10,10,10,10)
					
					self.InputStr.OnValueChange=function(control,text)
						local ids = string.Explode(",",text)
						local b = true
						if #ids>0 then							
							for K,V in ipairs(ids) do
								V = string.Trim(V)
								b = b and COMBINE_LOCK.IsSteamID(V)
								
							end
						else 
							b = false
						end
						
						if b then 
							self.Rule.ids = ids
							self.EditorCallback.Allowed(self)
						else 
							self.EditorCallback.Disallowed(self)
						end
					end
				end,
				PerformLayout = function(self)
					local w,h = self:GetSize()
					
				end,
				SetRule = function(self,rule)
					self.Rule = rule
					if (self.Rule.ids and #self.Rule.ids>0) then 
						self.InputStr:SetText(string.Implode(",",self.Rule.ids))
						self.EditorCallback.Allowed(self)
					else
						self.Rule.ids = {}
					end
				end,
				SetCallback = function(self,callback)
					self.EditorCallback = callback
				end
			},"DPanel")
		},
		Team={
			vgui.RegisterTable({
				SetCallback = function(self,callback)
					self.EditorCallback = callback
				end
			},"DPanel")
		}
			
	}
	,RulePicker = vgui.RegisterTable({
		Init = function(self)
			self.type_list = vgui.Create("DListLayout",self)
			self.type_list:Dock(FILL)
			
			function self.type_list:OnChildSelect(caller,state)
				if state and caller ~= self.SelectedPanel then
					if self.SelectedPanel then
						self.SelectedPanel:SetSelected(false)
					end
					self.SelectedPanel = caller
				end
			end
			
			local CreateRuleItem = function()
		
				local panel = vgui.Create("DPanel")
				panel:SetTall(90)
				panel:DockMargin(5,5,5,5)
				function panel:Paint(w,h)
					if self:IsSelected() then
						surface.SetDrawColor(Color(170,255,170))
					else 
						surface.SetDrawColor(Color(170,170,170))
					end
					surface.DrawRect(0,0,w,h)
				end
				panel:SetSelectable(true)
				panel.label = vgui.Create("DLabel",panel)
				panel.label:SetMultiline(true)
				panel.label:Dock(FILL)
				panel.label:DockPadding(5,5,5,5)
					
				function panel:SetRuleType(Rule,Description)
					self.RuleTypeValue = Rule
					self.label:SetText(Description)
				end
				
				function panel:OnMousePressed(mouse)
					if mouse == MOUSE_LEFT then
						self:SetSelected(true)
					end
				end
				
				panel.OnSelect=function(pane,state)
					local parent = pane:GetParent()
					if parent and parent.OnChildSelect then
						parent:OnChildSelect(pane,state)
					end
					if state then
						
						self:ChangeRule(pane.RuleTypeValue)
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
			end
			for K,V in pairs(COMBINE_LOCK.RuleTypes) do
				local type_panel = CreateRuleItem()
				type_panel:SetRuleType(K,V.Desc)
				self.type_list:Add(type_panel)
			end
		end,
		SetCallback = function(self,callback)
			self.EditorCallback = callback
		end,
		ChangeRule = function(self,rule_type)
			self.Rule.Type = rule_type
			self:OnTypeEdited()
		end,
		OnTypeEdited = function(self)
			if isstring(self.Rule.Type) and self.Rule.Type~="" then
				self.EditorCallback.Allowed(self)
			else 
				self.EditorCallback.Disallowed(self)
			end
		end,
		SetRule = function(self,rule)
			self.Rule = rule
			self:OnTypeEdited()
		end
	},"DScrollPanel")
	,AllowPicker = vgui.RegisterTable({
		Init = function(self)
			local function CreatePanel(state)
				
				local panel = vgui.Create("DPanel")
				state = tobool(state)
				panel:SetTall(90)
				panel:DockMargin(5,5,5,5)
				panel:SetSelectable(true)
				function panel:Paint(w,h)
					if self:IsSelected() then
						surface.SetDrawColor(Color(0,0,255))
						surface.DrawRect(0,0,w,h)
					end
					if state then
						surface.SetDrawColor(Color(0,255,0))
					else 
						surface.SetDrawColor(Color(255,0,0))
					end
					surface.DrawRect(2,2,w-4,h-4)
				end
				
				function panel:OnMousePressed(mouse)
					if mouse == MOUSE_LEFT then
						self:SetSelected(true)
					end
				end
				
				panel.OnSelect=function(pane,select_state)
					local parent = pane:GetParent()
					if parent and parent.OnChildSelect then
						parent:OnChildSelect(pane,select_state)
					end
					if select_state then						
						self:ChangeState(state)
					end
				end

				local oldpanelSetSelected = panel.SetSelected
				function panel:SetSelected(state)
					if self:IsSelectable() then
						self:OnSelect(state)
					end
					oldpanelSetSelected(self,state)
				end
				
				local texts = {}
				texts[false] = "Restricts access to this entity if this rule was passed."
				texts[true] = "Unlocks the entity if this rule was passed."
				
				local label  = vgui.Create("DLabel",panel)
				label:SetText(texts[state])
				label:Dock(FILL)
				label:SetTextColor(Color(50,50,50))
				label:DockMargin(10,10,10,10)
				return panel
				
			end
			
			local listt = vgui.Create("DListLayout",self)
			function listt:OnChildSelect(caller,state)
				if state then
					if self.SelectedPanel then
						self.SelectedPanel:SetSelected(false)
					end
					self.SelectedPanel = caller					
				end
			end
			listt:Dock(FILL)
			listt:Add(CreatePanel(false))
			listt:Add(CreatePanel(true))
			
		end,
		ChangeState = function(self,state)
			if isbool(state) then
				self.Rule.Allow = state
				self.EditorCallback.Allowed(self)				
			else
				self.EditorCallback.Disallowed(self)			
			end			
		end,
		SetRule = function(self,rule)
			self.Rule = rule
			if (isbool(rule.Allow)) then
				self.EditorCallback.Allowed(self)
			end
			
		end,
		SetCallback = function(self,callback)
			self.EditorCallback = callback
		end
	},"DScrollPanel")
	
}

vgui.Register("combine_lock_rule_edit_dialog",COMBINE_LOCK.RuleEditDialog,"DFrame")