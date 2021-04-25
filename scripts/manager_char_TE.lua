--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local function onHealthChanged(node)
	calcItemArmorClass_new(node.getParent())
end

local function onSpeedChanged(node)
	calcItemArmorClass_new(node.getChild("..."))
end

--	Summary: Finds the max stat and check penalty penalties based on medium and heavy encumbrance thresholds based on current total encumbrance
--	Argument: number light is medium encumbrance threshold for PC
--	Argument: number medium is heavy encumbrance threshold for PC
--	Argument: number total is current total encumbrance for PC
--	Return: number for max stat penalty based solely on encumbrance (max stat, check penalty)
--	Return: number for check penalty penalty based solely on encumbrance (max stat, check penalty)
local function encumbrancePenalties(nodeChar)
	local light = DB.getValue(nodeChar, "encumbrance.lightload", 0)
	local medium = DB.getValue(nodeChar, "encumbrance.mediumload", 0)
	local total = DB.getValue(nodeChar, "encumbrance.load", 0)

	if total > medium then -- heavy load
		DB.setValue(nodeChar, "encumbrance.encumbrancelevel", "number", 2)
		return TEGlobals.nHeavyMaxStat, TEGlobals.nHeavyCheckPenalty
	elseif total > light then -- medium load
		DB.setValue(nodeChar, "encumbrance.encumbrancelevel", "number", 1)
		return TEGlobals.nMediumMaxStat, TEGlobals.nMediumCheckPenalty
	else -- light load
		DB.setValue(nodeChar, "encumbrance.encumbrancelevel", "number", 0)
		return nil, nil
	end
end

---	This function checks for special abilities.
local function hasSpecialAbility(nodeChar, sSpecAbil)
	if not nodeChar or not sSpecAbil then
		return false
	end

	local sLowerSpecAbil = string.lower(sSpecAbil)
	for _,vNode in pairs(DB.getChildren(nodeChar, "specialabilitylist")) do
		local vLowerSpecAbilName = StringManager.trim(DB.getValue(vNode, "name", ""):lower());
		if vLowerSpecAbilName and string.match(vLowerSpecAbilName, sLowerSpecAbil .. " %d+", 1) or string.match(vLowerSpecAbilName, sLowerSpecAbil, 1) then
			return true
		end
	end

	return false
end

local function isSpeedHalved(rActor, nodeChar)
	return EffectManager35EDS.hasEffectCondition(rActor, "Exhausted")
		or EffectManager35EDS.hasEffectCondition(rActor, "Entangled")
end

local function isSpeedNone(rActor)
	local sStatus = ActorHealthManager.getHealthStatus(rActor) == ActorHealthManager.STATUS_DEAD or ActorHealthManager.getHealthStatus(rActor) == ActorHealthManager.STATUS_DYING
	return sStatus
		or EffectManager35EDS.hasEffectCondition(rActor, "Grappled")
		or EffectManager35EDS.hasEffectCondition(rActor, "Paralyzed")
		or EffectManager35EDS.hasEffectCondition(rActor, "Petrified")
		or EffectManager35EDS.hasEffectCondition(rActor, "Pinned")

end

--	Summary: Determine the total bonus to character"s speed from effects
--	Argument: rActor containing the PC"s charsheet and combattracker nodes
--	Return: total bonus to speed from effects formatted as "SPEED: n" in the combat tracker
local function getSpeedEffects(nodeChar)
	local rActor = ActorManager.resolveActor(nodeChar)
	if not rActor then
		return 0, false, false
	end

	local bSpeedHalved = isSpeedHalved(rActor, nodeChar)
	local bSpeedZero = isSpeedNone(rActor)

	--	Check if the character is disabled (at zero remaining hp)
	if DB.getValue(nodeChar, "hp.total", 0) == DB.getValue(nodeChar, "hp.wounds", 0) then
		bSpeedHalved = true
	end

	local nSpeedAdjFromEffects = EffectManager35EDS.getEffectsBonus(rActor, "SPEED", true)

	return nSpeedAdjFromEffects, bSpeedHalved, bSpeedZero
end

function calcItemArmorClass_new(nodeChar)
	local nMainArmorTotal = 0
	local nMainShieldTotal = 0
	local nMainMaxStatBonus = 999
	local nMainCheckPenalty = 0
	local nMainSpellFailure = 0
	local nMainSpeed30 = 0
	local nMainSpeed20 = 0

	for _,vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "carried", 0) == 2 then
			local bIsArmor, _, sSubtypeLower = ItemManager2.isArmor(vNode)
			if bIsArmor then
				local bID = LibraryData.getIDState("item", vNode, true)

				local nFighterLevel = DB.getValue(CharManager.getClassNode(nodeChar, "Fighter"), "level", 0)
				local bArmorTraining = (hasSpecialAbility(nodeChar, "Armor Training") and nFighterLevel >= 3)
				local bArmorTrainingH = (bArmorTraining and nFighterLevel >= 7)
				local bAdvArmorTraining = (hasSpecialAbility(nodeChar, "Advanced Armor Training"))

				local bIsShield = (sSubtypeLower == "shield")
				if bIsShield then
					if bID then
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, "ac", 0) + DB.getValue(vNode, "bonus", 0)
					else
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, "ac", 0)
					end
				else
					if bID then
						nMainArmorTotal = nMainArmorTotal + DB.getValue(vNode, "ac", 0) + DB.getValue(vNode, "bonus", 0)
					else
						nMainArmorTotal = nMainArmorTotal + DB.getValue(vNode, "ac", 0)
					end

					local bArmorLM = (sSubtypeLower == "light" or sSubtypeLower == "medium")
					local bArmorH = (sSubtypeLower == "heavy")

					local nItemSpeed30 = DB.getValue(vNode, "speed30", 0)
					if (nItemSpeed30 > 0) and (nItemSpeed30 < 30) then
						if bArmorLM and bArmorTraining then nItemSpeed30 = 30 end
						if bArmorH and bArmorTrainingH then nItemSpeed30 = 30 end
						if nMainSpeed30 > 0 then
							nMainSpeed30 = math.min(nMainSpeed30, nItemSpeed30)
						else
							nMainSpeed30 = nItemSpeed30
						end
					end
					local nItemSpeed20 = DB.getValue(vNode, "speed20", 0)
					if (nItemSpeed20 > 0) and (nItemSpeed20 < 30) then
						if bArmorLM and bArmorTraining then nItemSpeed20 = 20 end
						if bArmorH and bArmorTrainingH then nItemSpeed20 = 20 end
						if nMainSpeed20 > 0 then
							nMainSpeed20 = math.min(nMainSpeed20, nItemSpeed20)
						else
							nMainSpeed20 = nItemSpeed20
						end
					end
				end

				local nMaxStatBonus = DB.getValue(vNode, "maxstatbonus", 0)
				if nMaxStatBonus > 0 then
					if not bIsShield and bArmorTraining then
						if nFighterLevel >= 15 and not bAdvArmorTraining then
							nMaxStatBonus = nMaxStatBonus + 4
						elseif nFighterLevel >= 11 and not bAdvArmorTraining then
							nMaxStatBonus = nMaxStatBonus + 3
						elseif bArmorTrainingH and not bAdvArmorTraining then
							nMaxStatBonus = nMaxStatBonus + 2
						else
							nMaxStatBonus = nMaxStatBonus + 1
						end
					end

					if nMaxStatBonus and nMainMaxStatBonus < 999 then
						nMainMaxStatBonus = math.min(nMainMaxStatBonus, nMaxStatBonus)
					else
						nMainMaxStatBonus = nMaxStatBonus
					end
				else
					for _,v in pairs(TEGlobals.tClumsyArmorTypes) do
						if string.find(string.lower(DB.getValue(vNode, "name", 0)), string.lower(v)) then
							nMainMaxStatBonus = 0
							break
						end
					end
				end

				local nCheckPenalty = DB.getValue(vNode, "checkpenalty", 0)
				if nCheckPenalty < 0 then
					if not bIsShield and CharManager.hasTrait(nodeChar, "Armor Expert") then
						nCheckPenalty = nCheckPenalty + 1
					end
					if not bIsShield and bArmorTraining then
						if nFighterLevel >= 15 and not bAdvArmorTraining then
							nCheckPenalty = nCheckPenalty + 4
						elseif nFighterLevel >= 11 and not bAdvArmorTraining then
							nCheckPenalty = nCheckPenalty + 3
						elseif bArmorTrainingH and not bAdvArmorTraining then
							nCheckPenalty = nCheckPenalty + 2
						else
							nCheckPenalty = nCheckPenalty + 1
						end
					end

					if nCheckPenalty < 0 then nMainCheckPenalty = nMainCheckPenalty + nCheckPenalty end
				end

				local nSpellFailure = DB.getValue(vNode, "spellfailure", 0)
				if nSpellFailure > 0 then nMainSpellFailure = nMainSpellFailure + nSpellFailure end
			end
		end
	end

	--	Bring in encumbrance penalties
	local nEncMaxStatBonus, nEncCheckPenalty = encumbrancePenalties(nodeChar)
	if nEncMaxStatBonus then
		nMainMaxStatBonus = math.min(nMainMaxStatBonus, nEncMaxStatBonus)
		DB.setValue(nodeChar, "encumbrance.maxstatbonusfromenc", "number", nEncMaxStatBonus)
	else
		DB.setValue(nodeChar, "encumbrance.maxstatbonusfromenc", "number", nil)
	end
	if nEncCheckPenalty then
		nMainCheckPenalty = math.min(nMainCheckPenalty, nEncCheckPenalty)
		DB.setValue(nodeChar, "encumbrance.checkpenaltyfromenc", "number", nEncCheckPenalty)
	else
		DB.setValue(nodeChar, "encumbrance.checkpenaltyfromenc", "number", nil)
	end

	DB.setValue(nodeChar, "ac.sources.armor", "number", nMainArmorTotal)
	DB.setValue(nodeChar, "ac.sources.shield", "number", nMainShieldTotal)
	DB.setValue(nodeChar, "encumbrance.armormaxstatbonus", "number", nMainMaxStatBonus)

	if nMainMaxStatBonus < 999 or nMainCheckPenalty < 0 then
		DB.setValue(nodeChar, "encumbrance.armormaxstatbonusactive", "number", 0)
		DB.setValue(nodeChar, "encumbrance.armormaxstatbonusactive", "number", 1)
	else
		DB.setValue(nodeChar, "encumbrance.armormaxstatbonusactive", "number", 1)
		DB.setValue(nodeChar, "encumbrance.armormaxstatbonusactive", "number", 0)
	end
	DB.setValue(nodeChar, "encumbrance.armorcheckpenalty", "number", nMainCheckPenalty)
	DB.setValue(nodeChar, "encumbrance.spellfailure", "number", nMainSpellFailure)

	local bApplySpeedPenalty = true
	if CharManager.hasTrait(nodeChar, "Slow and Steady") then
		bApplySpeedPenalty = nil
	end

	local nSpeedAdjFromEffects, bSpeedHalved, bSpeedZero = getSpeedEffects(nodeChar)

	local nSpeedBase = DB.getValue(nodeChar, "speed.base", 0)

	--compute speed including total encumberance speed penalty
	local tEncumbranceSpeed = TEGlobals.tEncumbranceSpeed
	local nSpeedTableIndex = nSpeedBase / 5

	nSpeedTableIndex = nSpeedTableIndex + 0.5 - (nSpeedTableIndex + 0.5) % 1

	local nSpeedPenaltyFromEnc = 0

	if tEncumbranceSpeed[nSpeedTableIndex] then
		nSpeedPenaltyFromEnc = tEncumbranceSpeed[nSpeedTableIndex] - nSpeedBase
	end

	local nSpeedArmor = 0

	if bApplySpeedPenalty == true then
		if (nSpeedBase >= 30) and (nMainSpeed30 > 0) then
			nSpeedArmor = nMainSpeed30 - 30
		elseif (nSpeedBase < 30) and (nMainSpeed20 > 0) then
			nSpeedArmor = nMainSpeed20 - 20
		end

		local nEncumbranceLevel = DB.getValue(nodeChar, "encumbrance.encumbrancelevel", 0)

		if nEncumbranceLevel >= 1 then
			if (nSpeedArmor ~= 0) and (nSpeedPenaltyFromEnc ~= 0)
			then
				nSpeedArmor = math.min(nSpeedPenaltyFromEnc, nSpeedArmor)
			elseif nSpeedPenaltyFromEnc then
				nSpeedArmor = nSpeedPenaltyFromEnc
			end
		end
	end

	DB.setValue(nodeChar, "speed.armor", "number", nSpeedArmor)
	local nSpeedTotal = nSpeedBase + nSpeedArmor + DB.getValue(nodeChar, "speed.misc", 0) + DB.getValue(nodeChar, "speed.temporary", 0) + nSpeedAdjFromEffects
	if bSpeedHalved then nSpeedTotal = nSpeedTotal / 2 elseif bSpeedZero then nSpeedTotal = 0 end
	DB.setValue(nodeChar, "speed.total", "number", nSpeedTotal)
end

function onInit()
	if Session.IsHost then
		DB.addHandler(DB.getPath("charsheet.*.hp"), "onChildUpdate", onHealthChanged)
		DB.addHandler(DB.getPath("charsheet.*.wounds"), "onChildUpdate", onHealthChanged)
		DB.addHandler(DB.getPath("charsheet.*.speed.base"), "onUpdate", onSpeedChanged)
	end

	CharManager.calcItemArmorClass = calcItemArmorClass_new;
end