local function ResetStats()
        Ext.Stats.LoadStatsFile("Public/Psion/Stats/Generated/Data/ClassFeatures_Psion.txt", false)
        Ext.Stats.LoadStatsFile("Public/Psion/Stats/Generated/Data/EnhancementDiscipline_Psion.txt", false)
end

Ext.Events.ResetCompleted:Subscribe(ResetStats)--]]

-- Psi Point Restoration
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (character, status, _, _)
	if status == "TUT_RESTORATION" or status == "ALCH_POTION_REST_SLEEP_GREATER_RESTORATION" and Osi.IsTagged(character,"PSION") == 1 then
		Osi.ApplyStatus(character,"PSIPOINT_RESOURCE_RESTORE",6.0,0)
	end
end)

-- Psychic Drain Setup
Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "before", function (caster, target, spell, _, _, _)
	if spell == "Target_PsychicDrain" or spell == "Target_PsychicDrain_3" or spell == "Target_PsychicDrain_4" or spell == "Target_PsychicDrain_5" or spell == "Target_PsychicDrain_6" or spell == "Target_PsychicDrain_7" or spell == "Target_PsychicDrain_8" or spell == "Target_PsychicDrain_9" then
		local hp = GetHitpoints(target)
--		local num = IntegerToString(hp)
--		Osi.ShowNotification(caster,num)
		Osi.SetVarInteger(target,"BeforePDHP",hp)
    end
end)

-- Psychic Drain THP
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (character, status, causee, _)
	if status == "PSYCHIC_DRAIN" then
		local previoushp = GetVarInteger(character, "BeforePDHP")
		local currenthp = GetHitpoints(character)
--		local num = IntegerToString(previoushp)
--		Osi.ShowNotification(character,num)
		local hp = 0
		hp = math.floor((previoushp - currenthp)/2)
		local pdstatus = "PSYCHIC_DRAIN_" .. hp
		Osi.ApplyStatus(causee, pdstatus, -1.0, 1, causee)
    end
end)

-- Physical Surge
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (character, status, _, _)
	if (status == "ENHANCING_SURGE_DAMAGE" or status == "BONUS_ENHANCING_SURGE_DAMAGE") and HasPassive(character,"PsionicTalents_PhysicalSurge") == 1 then
		local str = GetAbility(character,"Strength")
		local dex = GetAbility(character,"Dexterity")
		local int = GetAbility(character,"Intelligence")
		if Osi.HasActiveStatus(character,"PHYSICALSURGE_STRENGTH") == 1 and int > str then
			local strStatus = "PHYSICALSURGE_STRENGTH_" .. int
			local intStatus = "PHYSICALSURGE_INTELLIGENCE_" .. int-str
			Osi.ApplyStatus(character,strStatus,6.0,1,character)
			Osi.ApplyStatus(character,intStatus,6.0,1,character)
		elseif Osi.HasActiveStatus(character,"PHYSICALSURGE_DEXTERITY") == 1 and int > dex then
			local dexStatus = "PHYSICALSURGE_DEXTERITY_" .. int
			local intStatus = "PHYSICALSURGE_INTELLIGENCE_" .. int-dex
			Osi.ApplyStatus(character,dexStatus,6.0,1,character)
			Osi.ApplyStatus(character,intStatus,6.0,1,character)
		end
    end
end)

local Psion = {
    WarPsion = {
            Target_TelekineticForce = "WAR_PSION_TELEKINETIC_FORCE",
			Target_TelepathicIntrusion = "WAR_PSION_TELEPATHIC_INTRUSION",
			Projectile_ElementalBlast = "WAR_PSION_ELEMENTAL_BLAST",
			Projectile_ElementalBlast_Fire_Specialization = "WAR_PSION_ELEMENTAL_BLAST_FIRE_SPECIALIZATION",
			Projectile_ElementalBlast_Cold_Specialization = "WAR_PSION_ELEMENTAL_BLAST_COLD_SPECIALIZATION",
			Projectile_ElementalBlast_Lightning_Specialization = "WAR_PSION_ELEMENTAL_BLAST_LIGHTNING_SPECIALIZATION",
			Target_MindLeech = "WAR_PSION_MIND_LEECH"
    }
}

-- War Psion Save Load
Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(level, _)
    if level ~= "SYS_CC_I" then
		local party = Osi.DB_Players:Get(nil)
		for _,p in pairs(party) do
			for spell,status in pairs(Psion.WarPsion) do
				if Osi.HasPassive(p[1],"WarPsion_OpportunitySpell") == 1 and Osi.HasSpell(p[1],spell) == 1 and Osi.HasActiveStatus(p[1],status) == 0 then
					Osi.ApplyStatus(p[1],status,-1.0,1,p[1])
				elseif Osi.HasPassive(p[1],"WarPsion_OpportunitySpell") == 0 and Osi.HasActiveStatus(p[1],status) == 1 then
					Osi.RemoveStatus(p[1],status)
				end
			end
		end
    end
end)

function DelayedCall(delayInMs, func)
    local startTime = Ext.Utils.MonotonicTime()
    local handlerId;
    handlerId = Ext.Events.Tick:Subscribe(function()
        local endTime = Ext.Utils.MonotonicTime()
        if (endTime - startTime > delayInMs) then
            Ext.Events.Tick:Unsubscribe(handlerId)
            func()
        end
    end) 
end

-- War Psion Level Up
Ext.Osiris.RegisterListener("LeveledUp", 1, "after", function(character)
	DelayedCall(1000, function ()
	for spell,status in pairs(Psion.WarPsion) do
		if Osi.HasPassive(character,"WarPsion_OpportunitySpell") == 1 and Osi.HasSpell(character,spell) == 1 and Osi.HasActiveStatus(character,status) == 0 then
			Osi.ApplyStatus(character,status,-1.0,1,character)
		elseif Osi.HasPassive(character,"WarPsion_OpportunitySpell") == 0 and Osi.HasActiveStatus(character,status) == 1 then
			Osi.RemoveStatus(character,status)
    		end
		end
    end)
end)

-- War Psion Specialization Change
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(character, specstatus, _, _)
	if specstatus == "FIRE_SPECIALIZATION" or specstatus == "COLD_SPECIALIZATION" or specstatus == "LIGHTNING_SPECIALIZATION" then
		DelayedCall(500, function ()
		for spell,status in pairs(Psion.WarPsion) do
			if Osi.HasPassive(character,"WarPsion_OpportunitySpell") == 1 and Osi.HasSpell(character,spell) == 1 and Osi.HasActiveStatus(character,status) == 0 then
				Osi.ApplyStatus(character,status,-1.0,1,character)
			elseif Osi.HasPassive(character,"WarPsion_OpportunitySpell") == 0 and Osi.HasActiveStatus(character,status) == 1 then
				Osi.RemoveStatus(character,status)
			    end
		    end
	    end)
	end
end)

-- Revive Dark Urge
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(character, status, causee, _)
	if status == "DARK_URGE" then
		if	Osi.IsPlayer(character) == 1 then
			Osi.PROC_GLO_PartyMembers_Remove(character, causee, 0)
			Osi.MakeNPC(character)
			Osi.SetOnStage(character,0)
			Osi.DB_Players:Delete(character)
			Osi.PROC_CheckPartyFull()
		else
			Osi.MakePlayer(character,causee,1)
		end
	end
end)

---@param diceAmount integer
---@param faces integer
---@param minDieValue? integer
---@param maxDieValue? integer
---@return integer
function RollDice(diceAmount, faces, minDieValue, maxDieValue)
    local total = 0
    local min = math.min(minDieValue or 1, faces)
    local max = math.min(maxDieValue or faces, faces)
    for i = 1, diceAmount do
        total = total + Ext.Utils.Random(min, max)
    end
    return total
end

local esstatuses = {
		"ENHANCING_SURGE",
		"BONUS_ENHANCING_SURGE",
		"ENHANCING_SURGE_FORTIFYING",
		"BONUS_ENHANCING_SURGE_FORTIFYING",
		"ENHANCING_SURGE_FORTIFYING_2",
		"BONUS_ENHANCING_SURGE_FORTIFYING_2",
		"ENHANCING_SURGE_FORTIFYING_3",
		"BONUS_ENHANCING_SURGE_FORTIFYING_3",
		"ENHANCING_SURGE_FORTIFYING_4",
		"BONUS_ENHANCING_SURGE_FORTIFYING_4",
		"ENHANCING_SURGE_FORTIFYING_5",
		"BONUS_ENHANCING_SURGE_FORTIFYING_5",
		"ENHANCING_SURGE_FORTIFYING_6",
		"BONUS_ENHANCING_SURGE_FORTIFYING_6",
		"ENHANCING_SURGE_FORTIFYING_7",
		"BONUS_ENHANCING_SURGE_FORTIFYING_7",
		"ENHANCING_SURGE_FORTIFYING_8",
		"BONUS_ENHANCING_SURGE_FORTIFYING_8",
		"ENHANCING_SURGE_FORTIFYING_9",
		"BONUS_ENHANCING_SURGE_FORTIFYING_9",
		"ENHANCING_SURGE_FORTIFYING_10",
		"BONUS_ENHANCING_SURGE_FORTIFYING_10",
}

-- Enhancing Surge Temp HP
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (character, status, causee, _)
	for _, esstatus in pairs(esstatuses) do
		if status == esstatus then
			local temphp = Ext.Entity.Get(character).Health.TemporaryHp
			local newstatus = "ENHANCING_SURGE_TEMPHP_" .. temphp
			if HasPassive(character,"PerfectedEnhancement") == 0 then
				Osi.ApplyStatus(character,newstatus,-1.0,1,causee)
			elseif HasPassive(character,"PerfectedEnhancement") == 1 then
				local pb = Ext.Entity.Get(causee).Stats.ProficiencyBonus
				local newstatus = "ENHANCING_SURGE_TEMPHP_" .. temphp + pb
				Osi.ApplyStatus(character,newstatus,-1.0,1,causee)
			end
		end
    end
end)

-- Status Debug Text
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (character, status, _, _)
	if status ~= "INSURFACE" then
	local disname = Osi.GetDisplayName(character)
	local name = Osi.ResolveTranslatedString(disname)
	local str = status .. " status applied to "
	_D(str .. name)
	end
end)

-- Status Debug Text
Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function (character, status, _, _)
	if status ~= "INSURFACE" then
	local disname = Osi.GetDisplayName(character)
	local name = Osi.ResolveTranslatedString(disname)
	local str = status .. " status removed from "
	_D(str .. name)
	end
end)

-- Spell Casting Debug
Ext.Osiris.RegisterListener("UsingSpell", 5, "before", function (caster, spell, _, _, _)
	_D(spell)
end)--]]