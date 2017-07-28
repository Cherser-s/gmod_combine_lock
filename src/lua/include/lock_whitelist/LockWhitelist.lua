
COMBINE_LOCK = COMBINE_LOCK or {}


COMBINE_LOCK.IsSteamID=function(text)
	local finder=string.match(text,"STEAM_0:[%d]+:[%d]+")
	return finder
end

COMBINE_LOCK.RuleTypes = {
	Admin = {
		Check=function(ply,data)
			return ply:IsAdmin()
		end,
		CheckRule = function(Rule)
			return true
		end,
		Desc = "Allow or restrict admins using this lock. SuperAdmins will also get affected."
	},
	SuperAdmin = {
		Check = function(ply,data)
			return ply:IsSuperAdmin()
		end,
		CheckRule = function(Rule)
			return true
		end,
		Desc = "Allow or restrict superadmins using this lock."
	},
	SteamId = {
		Check =
		function(ply,data)
			
			local sid = ply:SteamID()
			for K,V in ipairs(data.ids) do
				if V==sid then 
					return true 
				end
			end
			return false
		end,
		CheckRule = function(Rule)
		
			
			if not istable(Rule.ids) or #Rule.ids == 0 then
				return false 
			end
			for K,V in ipairs(Rule.ids) do
				--check steam id
				if not (isstring(V) and COMBINE_LOCK.IsSteamID(V)) then 
					return false
				end
			end
			return true
		end,
		Desc = "Allow players with specified steam ids use the entity."
	},
	Team = {
		Check = function(ply,data)
			local teamn=team.GetName(ply:Team())
			for K,V in pairs(data.teams) do
				if teamn==V then
					return true 
				end 
			end
		end,
		CheckRule = function(Rule)
			if #Rule.teams == 0 then
				return false 
			end
			for K,V in ipairs(Rule.teams) do
				--check steam id
				if not isstring(V) then 
					return false
				end
			end
			return true
		end,
		Desc = "Allow players from specified team use the entity."
	}
}
local Whitelist = {}
Whitelist.__index = Whitelist

function Whitelist:New(copy)
	local instance = {}
	if not (copy and Whitelist.CheckWhitelist(copy)) then
		instance.Rules = {}
			
		instance.Owners = {}
		instance.Owners.player_ids={}
		instance.Owners.player_rules = {Admins = false, SuperAdmins = false}
	else 
		instance.Owners = copy.Owners
		instance.Rules = copy.Rules
	end
		
	setmetatable(instance,Whitelist)
	
	return instance
end
	
function Whitelist:CheckRule(ply)
	for K,Rule in ipairs(self.Rules) do
		if (COMBINE_LOCK.RuleTypes[Rule.Type].Check(ply,Rule)) then 
			return Rule.Allow
		end
			
	end
	return false
end
	
function Whitelist:CheckOwner(ply)
	if (self.Owners.player_rules.Admins and ply:IsAdmin()) 
		or (self.Owners.player_rules.SuperAdmins and ply:IsSuperAdmin())
	then 
		return true
	end
	local sid = ply:SteamID()
	for K,OwnerId in ipairs(self.Owners.player_ids) do
		if OwnerId==sid then
			return true
		end
	end
	return false
end

function Whitelist:SetWhitelistData(data)
	if self.CheckWhitelist(data) then
		self.Owners = data.Owners
		self.Rules = data.Rules
	end
end
	
Whitelist.CheckWhitelist = function(data)
		--check owner table
	for K,Owner in ipairs(data.Owners.player_ids) do
		if not (isstring(Owner) and COMBINE_LOCK.IsSteamID(Owner)) then 
			return false 
		end
	end
		
	if not (isbool(data.Owners.player_rules.Admins) and isbool(data.Owners.player_rules.SuperAdmins)) then 
		return false
	end
			
	for K,Rule in ipairs(data.Rules) do
		if not Whitelist.IsRule(Rule) then 
			return false
		end
	end
	return true
end

function Whitelist:IsAllowedAdminsEdit()
	return self.Owners.player_rules.Admins 
end

function Whitelist:IsAllowedSuperAdminsEdit()
	return self.Owners.player_rules.SuperAdmins 
end	

function Whitelist:AllowAdminsEdit(val)
	self.Owners.player_rules.Admins = val
end

function Whitelist:AllowSuperAdminsEdit(val)
	self.Owners.player_rules.SuperAdmins = val
end	
	
function Whitelist:AddOwner(ply)
		
	if isentity(ply) and ply:IsPlayer() then
		return self:AddOwner(ply:SteamID())
	elseif isstring(ply) and COMBINE_LOCK.IsSteamID(ply) then
		if not table.HasValue(self.Owners.player_ids,ply) then
			table.insert(self.Owners.player_ids,ply)
			return true
		else 
			return false
		end
			
	else 
		error("Expected string or player, got "..type(ply))
	end
end
function Whitelist:RemoveOwner(ply)
	if isentity(ply) and ply:IsPlayer() then
		self:RemoveOwner(ply:SteamID())
	elseif isstring(ply) and COMBINE_LOCK.IsSteamID(ply) then
		table.RemoveByValue(self.Owners.player_ids,ply)
	else 
		error("Expected string or player, got "..type(ply))
	end
end
	
function Whitelist:AllowAdmins(bool)
	self.Owners.player_rules.Admins = bool
end
function Whitelist:AllowSuperAdmins(bool)
	self.Owners.player_rules.SuperAdmins = bool
end
	--static
Whitelist.IsRule = function(Rule)
		--[[if not isstring(Rule.Type) then
			return false 
		end]]
	local rulehandler = COMBINE_LOCK.RuleTypes[Rule.Type]
	return isbool(Rule.Allow) and rulehandler and rulehandler.CheckRule(Rule)
end


setmetatable(Whitelist,{
	
	__call =  Whitelist.New

	})
COMBINE_LOCK.Whitelist = Whitelist