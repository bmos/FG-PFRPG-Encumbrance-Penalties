--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
---	Determine the total bonus to carrying capacity from effects STR or CARRY
--	@param rActor a table containing relevant paths and information on this PC
--	@return nStrEffectMod the PC's current strength score after all bonuses are applied
local function getStrEffectBonus(rActor, nodeChar)
	if not rActor then return 0 end

	local nStrEffectMod = EffectManager35EDS.getEffectsBonus(rActor, 'CARRY', true)
	if EffectManager35EDS.hasEffectCondition(rActor, 'Exhausted') then
		nStrEffectMod = nStrEffectMod - 6
	elseif EffectManager35EDS.hasEffectCondition(rActor, 'Fatigued') then
		nStrEffectMod = nStrEffectMod - 2
	end
	-- include STR effects in calculating carrying capacity
	if not DataCommon.isPFRPG() then nStrEffectMod = nStrEffectMod + (EffectManager35EDS.getEffectsBonus(rActor, 'STR', true) or 0) end

	DB.setValue(nodeChar, 'encumbrance.strbonusfromeffects', 'number', nStrEffectMod)

	return nStrEffectMod
end

function onEncumbranceLimitChanged(nodeChar)
	local rActor = ActorManager.resolveActor(nodeChar)

	local nHeavy = 0

	local nStrength = DB.getValue(nodeChar, 'abilities.strength.score', 10)

	local nStrengthDamage = 0
	if not DataCommon.isPFRPG() then nStrengthDamage = DB.getValue(nodeChar, 'abilities.strength.damage', 0) end

	if DB.getValue(nodeChar, 'encumbrance.stradj', 0) == 0 and CharManager.hasTrait(nodeChar, 'Muscle of the Society') then
		DB.removeHandler(DB.getPath(nodeChar, 'encumbrance.stradj'), 'onUpdate', onStrengthChanged)
		DB.setValue(nodeChar, 'encumbrance.stradj', 2)
		DB.addHandler(DB.getPath(nodeChar, 'encumbrance.stradj'), 'onUpdate', onStrengthChanged)
	end

	nStrength = nStrength + getStrEffectBonus(rActor, nodeChar) - nStrengthDamage + DB.getValue(nodeChar, 'encumbrance.stradj', 0)
	if EffectManager35EDS.hasEffectCondition(rActor, 'Paralyzed') then nStrength = 0 end

	if nStrength > 0 then
		if nStrength <= 10 then
			nHeavy = nStrength * 10
		else
			nHeavy = 1.25 * math.pow(2, math.floor(nStrength / 5)) * math.floor((20 * math.pow(2, math.fmod(nStrength, 5) / 5)) + 0.5)
		end
	end

	nHeavy = math.floor(nHeavy * DB.getValue(nodeChar, 'encumbrance.carrymult', 1))

	-- Check for carrying capacity multiplier attached to PC on combat tracker. If found, multiply their carrying capacity.
	local nCarryMult = EffectManager35EDS.getEffectsBonus(rActor, 'CARRYMULT', true) or 0
	if nCarryMult ~= 0 then nHeavy = nHeavy * nCarryMult end

	local nLight = math.floor(nHeavy / 3)
	local nMedium = math.floor((nHeavy / 3) * 2)
	local nLiftOver = nHeavy
	local nLiftOff = nHeavy * 2
	local nPushDrag = nHeavy * 5

	local nSize = ActorManager35E.getSize(rActor)
	if (nSize < 0) then
		local nMult = 0
		if (nSize == -1) then
			nMult = 0.75
		elseif (nSize == -2) then
			nMult = 0.5
		elseif (nSize == -3) then
			nMult = .25
		elseif (nSize == -4) then
			nMult = .125
		end

		nLight = math.floor(((nLight * nMult) * 100) + 0.5) / 100
		nMedium = math.floor(((nMedium * nMult) * 100) + 0.5) / 100
		nHeavy = math.floor(((nHeavy * nMult) * 100) + 0.5) / 100
		nLiftOver = math.floor(((nLiftOver * nMult) * 100) + 0.5) / 100
		nLiftOff = math.floor(((nLiftOff * nMult) * 100) + 0.5) / 100
		nPushDrag = math.floor(((nPushDrag * nMult) * 100) + 0.5) / 100
	elseif (nSize > 0) then
		local nMult = math.pow(2, nSize)

		nLight = nLight * nMult
		nMedium = nMedium * nMult
		nHeavy = nHeavy * nMult
		nLiftOver = nLiftOver * nMult
		nLiftOff = nLiftOff * nMult
		nPushDrag = nPushDrag * nMult
	end

	DB.setValue(nodeChar, 'encumbrance.lightload', 'number', nLight)
	DB.setValue(nodeChar, 'encumbrance.mediumload', 'number', nMedium)
	DB.setValue(nodeChar, 'encumbrance.heavyload', 'number', nHeavy)
	DB.setValue(nodeChar, 'encumbrance.liftoverhead', 'number', nLiftOver)
	DB.setValue(nodeChar, 'encumbrance.liftoffground', 'number', nLiftOff)
	DB.setValue(nodeChar, 'encumbrance.pushordrag', 'number', nPushDrag)
end

local function onEffectChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode().getChild('...'))
	local nodeChar = ActorManager.getCreatureNode(rActor)
	onEncumbranceLimitChanged(nodeChar)
end

local function onEffectRemoved()
	local rActor = ActorManager.resolveActor(getDatabaseNode().getParent())
	local nodeChar = ActorManager.getCreatureNode(rActor)
	onEncumbranceLimitChanged(nodeChar)
end

local function onStrengthChanged()
	-- Debug.chat(getDatabaseNode())
	onEncumbranceLimitChanged(getDatabaseNode())
	CharManager.calcItemArmorClass(getDatabaseNode())
end

function onInit()
	onEncumbranceLimitChanged(getDatabaseNode())

	local nodePC = getDatabaseNode()
	DB.addHandler(DB.getPath(nodePC, 'abilities.strength'), 'onChildUpdate', onStrengthChanged)
	DB.addHandler(DB.getPath(nodePC, 'size'), 'onUpdate', onEncumbranceLimitChanged)
	DB.addHandler(DB.getPath(nodePC, 'encumbrance.carrymult'), 'onUpdate', onStrengthChanged)
	DB.addHandler(DB.getPath(nodePC, 'encumbrance.stradj'), 'onUpdate', onStrengthChanged)

	local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(nodePC))
	DB.addHandler(DB.getPath(nodeCT, 'effects.*.label'), 'onUpdate', onEffectChanged)
	DB.addHandler(DB.getPath(nodeCT, 'effects.*.isactive'), 'onUpdate', onEffectChanged)
	DB.addHandler(DB.getPath(nodeCT, 'effects'), 'onChildDeleted', onEffectRemoved)
end

function onClose()
	local nodePC = getDatabaseNode()
	DB.removeHandler(DB.getPath(nodePC, 'abilities.strength'), 'onChildUpdate', onStrengthChanged)
	DB.removeHandler(DB.getPath(nodePC, 'size'), 'onUpdate', onEncumbranceLimitChanged)
	DB.removeHandler(DB.getPath(nodePC, 'encumbrance.carrymult'), 'onUpdate', onStrengthChanged)
	DB.removeHandler(DB.getPath(nodePC, 'encumbrance.stradj'), 'onUpdate', onStrengthChanged)

	local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(nodePC))
	DB.removeHandler(DB.getPath(nodeCT, 'effects.*.label'), 'onUpdate', onEffectChanged)
	DB.removeHandler(DB.getPath(nodeCT, 'effects.*.isactive'), 'onUpdate', onEffectChanged)
	DB.removeHandler(DB.getPath(nodeCT, 'effects'), 'onChildDeleted', onEffectRemoved)
end
