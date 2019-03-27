if myHero.charName ~= "Ahri" then return end
class "Ahri"

if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
	print("GsoPred. installed Press 2x F6")
	DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronPrediction.lua", COMMON_PATH .. "GamsteronPrediction.lua", function() end)
	while not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") do end
end

require('GamsteronPrediction')

local menu = 1
local TEAM_ALLY = myHero.team
local TEAM_ENEMY = 300 - myHero.team
local TEAM_JUNGLE = 300
local Allies = {}; local Enemies = {}; local Turrets = {}; local Units = {}; local AllyHeroes = {}

local function Ready(spell)
    return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

local function GetMinionCount(range, pos)
    local pos = pos.pos
	local count = 0
	for i = 1,Game.MinionCount() do
	local hero = Game.Minion(i)
	local Range = range * range
		if hero.team ~= TEAM_ALLY and hero.dead == false and GetDistanceSqr(pos, hero.pos) < Range then
		count = count + 1
		end
	end
	return count
end

function CanMove()
	if _G.SDK then
    return _G.SDK.Orbwalker:CanMove()
	elseif _G.gsoSDK then
    return _G.gsoSDK.Orbwalker:CanMove()
	end
end

function CanAttack()
	if _G.SDK then
		_G.SDK.Orbwalker:CanAttack()
	elseif _G.gsoSDK then
		_G.gsoSDK.Orbwalker:CanAttack()
	end
end

function SetAttack(bool)
	if _G.EOWLoaded then
		EOW:SetAttacks(bool)
	elseif _G.SDK then
		_G.SDK.Orbwalker:SetAttack(bool)
	elseif _G.gsoSDK then
		_G.gsoSDK.Orbwalker:SetAttack(bool)
	else
		GOS.BlockAttack = not bool
	end
end

function SetMovement(bool)
	if _G.EOWLoaded then
		EOW:SetMovements(bool)
		EOW:SetAttacks(bool)
	elseif _G.SDK then
		_G.SDK.Orbwalker:SetMovement(bool)
		_G.SDK.Orbwalker:SetAttack(bool)
	elseif _G.gsoSDK then
		_G.gsoSDK.Orbwalker:SetMovement(bool)
		_G.gsoSDK.Orbwalker:SetAttack(bool)
	else
		GOS.BlockMovement = not bool
		GOS.BlockAttack = not bool
	end
end

function DisableOrb()
	if _G.SDK.TargetSelector:GetTarget(900) then
		_G.SDK.Orbwalker:SetMovement(false)
		_G.SDK.Orbwalker:SetAttack(false)
		end
end

function EnableOrb()
	if _G.SDK.TargetSelector:GetTarget(900) then
		_G.SDK.Orbwalker:SetMovement(true)
		_G.SDK.Orbwalker:SetAttack(true)
		end
end

function IsImmobileTarget(unit)
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == 10) and buff.count > 0 then
				return true
			end
		end
		return false
end

local function GetTarget(range)
	local target = nil
		if Orb == 1 then
			target = EOW:GetTarget(range)
		elseif Orb == 2 then
			target = _G.SDK.TargetSelector:GetTarget(range)
		elseif Orb == 3 then
			target = GOS:GetTarget(range)
	    elseif Orb == 4 then
			target = _G.gsoSDK.TS:GetTarget()
		end
		return target
end

local intToMode = {	[0] = "",	[1] = "Combo",	[2] = "Harass",	[3] = "LastHit", [4] = "Clear"	}

	function GetMode()
		if Orb == 1 then
			return intToMode[EOW.CurrentMode]
		elseif Orb == 2 then
			if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
				return "Combo"
			elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
				return "Harass"
			elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
				return "Clear"
			elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
				return "LastHit"
			elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
				return "Flee"
			end
		elseif Orb == 4 then
			if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
				return "Combo"
			elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
				return "Harass"
			elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
				return "Clear"
			elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
				return "LastHit"
			elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
				return "Flee"
			end
		else
			return GOS.GetMode()
		end
	end

function IsUnderTurret(unit)
    for i = 1, Game.TurretCount() do
        local turret = Game.Turret(i)
        local range = (turret.boundingRadius + 750 + unit.boundingRadius / 2)
        if turret.isEnemy and not turret.dead then
            if turret.pos:DistanceTo(unit.pos) < range then
                return true
            end
        end
    end
    return false
end

function GetDistanceSqr(p1, p2)
	if not p1 then return math.huge end
	p2 = p2 or myHero
	local dx = p1.x - p2.x
	local dz = (p1.z or p1.y) - (p2.z or p2.y)
	return dx*dx + dz*dz
end

function GetDistance(p1, p2)
	p2 = p2 or myHero
	return math.sqrt(GetDistanceSqr(p1, p2))
end

local ItemHotKey = {
    [ITEM_1] = HK_ITEM_1,
    [ITEM_2] = HK_ITEM_2,
    [ITEM_3] = HK_ITEM_3,
    [ITEM_4] = HK_ITEM_4,
    [ITEM_5] = HK_ITEM_5,
    [ITEM_6] = HK_ITEM_6,
}

local function GetItemSlot(unit, id)
	for i = ITEM_1, ITEM_7 do
	    if unit:GetItemData(i).itemID == id then
		return i
	    end
	end
	return 0
end

function Ahri:__init()

	if menu ~= 1 then return end
	menu = 2
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	if _G.EOWLoaded then
		Orb = 1
	elseif _G.SDK and _G.SDK.Orbwalker then
		Orb = 2
	elseif _G.gsoSDK then
		Orb = 4
	end
end

function ReturnCursor(pos)
	Control.SetCursorPos(pos)
	DelayAction(EnableMovement,0.1)
end

function LeftClick(pos)
	Control.mouse_event(MOUSEEVENTF_LEFTDOWN)
	Control.mouse_event(MOUSEEVENTF_LEFTUP)
	DelayAction(ReturnCursor,0.05,{pos})
end

---SkillData
local QData =
{
Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 90, Range = 880, Speed = 1700, Collision = false, CollisionTypes = {_G.COLLISION_YASUOWALL}
}

local WData =
{
Type = _G.SPELLTYPE_CIRCLE, Collision = false, Delay = 0.25, Range = 700, Speed = math.huge
}

local EData =
{
Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 50, Range = 975, Speed = 1600, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}
}

local RData =
{
Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 600, Range = 150, Speed = math.huge, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}
}

local function IsValid(unit)
    if (unit and unit.valid and unit.isTargetable and unit.alive and unit.visible and unit.networkID and unit.pathing and unit.health > 0) then
        return true;
    end
    return false;
end

function Ahri:LoadMenu()
	--MainMenu
	self.Menu = MenuElement({type = MENU, id = "Ahri", name = "MKayAhri"})
	--ComboMenu
	self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})
	self.Menu.Combo:MenuElement({id = "UseW", name = "[W]", value = true})
	self.Menu.Combo:MenuElement({id = "UseE", name = "[E]", value = true})
	self.Menu.Combo:MenuElement({type = MENU, id = "UseR", name = "Ult Settings"})
	--HarassMenu
	self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
	self.Menu.Harass:MenuElement({id = "UseQ", name = "[Q]", value = true})
	self.Menu.Harass:MenuElement({id = "UseW", name = "[W]", value = true})
	self.Menu.Harass:MenuElement({id = "UseE", name = "[E]", value = true})
	self.Menu.Harass:MenuElement({id = "Mana", name = "Min Mana to Harass", value = 40, min = 0, max = 100, identifier = "%"})
	--LaneClear Menu
	self.Menu:MenuElement({type = MENU, id = "Clear", name = "Lasthit Clear"})
	self.Menu.Clear:MenuElement({id = "UseQ", name = "[Q]", value = true})
	self.Menu.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear", value = 40, min = 0, max = 100, identifier = "%"})
	--JungleClear
	self.Menu:MenuElement({type = MENU, id = "JClear", name = "JClear"})
	self.Menu.JClear:MenuElement({id = "UseQ", name = "[Q]", value = true})
	self.Menu.JClear:MenuElement({id = "Mana", name = "Min Mana to JungleClear", value = 40, min = 0, max = 100, identifier = "%"})
	--KillSteal
	self.Menu:MenuElement({type = MENU, id = "KillSteal", name = "KillSteal"})
	self.Menu.KillSteal:MenuElement({id = "UseQ", name = "[Q]", value = true})
	self.Menu.KillSteal:MenuElement({id = "UseW", name = "[W]", value = true})
	self.Menu.KillSteal:MenuElement({id = "UseE", name = "[E]", value = true})
	self.Menu.KillSteal:MenuElement({id = "UseIgn", name = "Ignite", value = true})
	--Activator
	self.Menu:MenuElement({type = MENU, id = "Activator", name = "Activator"})
	self.Menu.Activator:MenuElement({id = "GLP", name = "Hextech GLP in ComboMode", value = true})
	--Drawing
	self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawings"})
	self.Menu.Drawing:MenuElement({id = "DrawQ", name = "Draw [Q] Range", value = true})
	self.Menu.Drawing:MenuElement({id = "DrawGLP", name = "Draw [GLP800] Range", value = true})
end

function Ahri:Tick()
	if myHero.dead == false and Game.IsChatOpen() == false then
	local Mode = GetMode()
		if Mode == "Combo" then
			self:GLP800()
			self:Combo()
		elseif Mode == "Harass" then
			self:Harass()
		elseif Mode == "Clear" then
			self:Clear()
			self:JungleClear()
		elseif Mode == "Flee" then
		end
		end
	end

function Ahri:ValidTarget(unit,range)
	return unit and unit.team == TEAM_ENEMY and unit.dead == false and GetDistanceSqr(myHero.pos, unit.pos) <= (range + myHero.boundingRadius + unit.boundingRadius)^2 and unit.isTargetable and unit.isTargetableToTeam and unit.isImmortal == false
end

local function IsValidCreep(unit, range)
    return unit and unit.dead == false and GetDistanceSqr(myHero.pos, unit.pos) <= (range + myHero.boundingRadius + unit.boundingRadius)^2 and unit.isTargetable and unit.isTargetableToTeam and unit.isImmortal == false and unit.visible
end

function Ahri:GLP800()
	local target = GetTarget(1000)
	if target == nil then return end
	local GLP = GetItemSlot(myHero, 3030)
	if IsValid(target) then
		if self.Menu.Activator.GLP:Value() and GLP > 0 and Ready(GLP) then
			if myHero.pos:DistanceTo(target.pos) <= 1050 then
				Control.CastSpell(ItemHotKey[GLP], target.pos)
			end
		end
	end
end

function Ahri:Draw()
	local GLP = GetItemSlot(myHero, 3030)
  if myHero.dead then return end
	if self.Menu.Drawing.DrawQ:Value() and Ready(_Q) then
    Draw.Circle(myHero, 880, 1, Draw.Color(225, 225, 0, 10))
	end
	if self.Menu.Drawing.DrawGLP:Value() and Ready(GLP) then
    Draw.Circle(myHero, 1050, 1, Draw.Color(225, 225, 125, 10))
	end
end

function Ahri:KillSteal()
	local target = GetTarget(1000)
	if target == nil then return end
	local hp = target.health
	local QDmg = getdmg("Q", target, myHero)
	local IGdamage = 80 + 25 * myHero.levelData.lvl
	local GunDmg = GunbladeDMG()
	if IsValid(target) then
		if self.Menu.KillSteal.UseQ:Value() and Ready(_Q) then
			local pred = GetGamsteronPrediction(target, QData, myHero)
			if QDmg >= hp and myHero.pos:DistanceTo(target.pos) <= 880 and pred.Hitchance >= _G.HITCHANCE_HIGH then
				Control.CastSpell(HK_Q, pred.CastPosition)
			end
		end
		if self.Menu.KillSteal.UseW:Value() and Ready(_W) then
			local pred = GetGamsteronPrediction(target, WData, myHero)
			if WDmg >= hp and myHero.pos:DistanceTo(target.pos) <= 700 and pred.Hitchance >= _G.HITCHANCE_HIGH then
				Control.CastSpell(HK_W, pred.CastPosition)
			end
		end
		if self.Menu.KillSteal.UseE:Value() and Ready(_E) then
			local pred = GetGamsteronPrediction(target, EData, myHero)
			if EDmg >= hp and myHero.pos:DistanceTo(target.pos) <= 975 and pred.Hitchance >= _G.HITCHANCE_HIGH then
				Control.CastSpell(HK_E, pred.CastPosition)
			end
		end
	end
end

function Ahri:Combo()
local target = GetTarget(1200)
if target == nil then return end
	if IsValid(target) then
		if self.Menu.Combo.UseQ:Value() and Ready(_Q) then
			local pred = GetGamsteronPrediction(target, QData, myHero)
			if myHero.pos:DistanceTo(target.pos) <= 880 and pred.Hitchance >= _G.HITCHANCE_HIGH then
				Control.CastSpell(HK_Q, pred.CastPosition)
			end
		end
		if self.Menu.Combo.UseW:Value() and Ready(_W) then
			local pred = GetGamsteronPrediction(target, WData, myHero)
			if myHero.pos:DistanceTo(target.pos) <= 700 and pred.Hitchance >= _G.HITCHANCE_HIGH then
				Control.CastSpell(HK_W, pred.CastPosition)
			end
		end
		if self.Menu.Combo.UseE:Value() and Ready(_E) then
			local pred = GetGamsteronPrediction(target, EData, myHero)
			if myHero.pos:DistanceTo(target.pos) <= 975 and pred.Hitchance >= _G.HITCHANCE_HIGH then
				Control.CastSpell(HK_E, pred.CastPosition)
			end
		end
	end
end

function Ahri:Harass()
local target = GetTarget(1000)
if target == nil then return end
	if IsValid(target) and myHero.mana/myHero.maxMana >= self.Menu.Harass.Mana:Value() / 100 then
		if self.Menu.Harass.UseQ:Value() and Ready(_Q) then
			local pred = GetGamsteronPrediction(target, QData, myHero)
			if myHero.pos:DistanceTo(target.pos) <= 880 and pred.Hitchance >= _G.HITCHANCE_HIGH then
				Control.CastSpell(HK_Q, pred.CastPosition)
			end
		end
		if self.Menu.Harass.UseW:Value() and Ready(_W) then
			local pred = GetGamsteronPrediction(target, WData, myHero)
			if myHero.pos:DistanceTo(target.pos) <= 700 and pred.Hitchance >= _G.HITCHANCE_HIGH then
				Control.CastSpell(HK_W, pred.CastPosition)
			end
		end
		if self.Menu.Harass.UseE:Value() and Ready(_E) then
			local pred = GetGamsteronPrediction(target, EData, myHero)
			if myHero.pos:DistanceTo(target.pos) <= 975 and pred.Hitchance >= _G.HITCHANCE_HIGH then
				Control.CastSpell(HK_E, pred.CastPosition)
			end
		end
	end
end

function Ahri:Clear()
	for i = 1, Game.MinionCount() do
    local minion = Game.Minion(i)
	local level = myHero.levelData.lvl
	local HP = minion.health
	local QDmg = getdmg("Q", minion, myHero)
		if IsValidCreep(minion, 1000) and minion.team == TEAM_ENEMY and myHero.mana/myHero.maxMana >= self.Menu.Clear.Mana:Value() / 100 then
			if Ready(_Q) and myHero.pos:DistanceTo(minion.pos) <= 880 and self.Menu.Clear.UseQ:Value() and QDmg > HP then
				Control.CastSpell(HK_Q, minion.pos)
			end
		end
	end
end

function Ahri:JungleClear()
	for i = 1, Game.MinionCount() do
    local minion = Game.Minion(i)
		if IsValidCreep(minion, 1000) and minion.team == TEAM_JUNGLE and myHero.mana/myHero.maxMana >= self.Menu.JClear.Mana:Value() / 100 then
			if Ready(_Q) and myHero.pos:DistanceTo(minion.pos) <= 850 and self.Menu.JClear.UseQ:Value() then
				Control.CastSpell(HK_Q, minion.pos)
			end
		end
	end
end

function OnLoad()
	Ahri()
end
