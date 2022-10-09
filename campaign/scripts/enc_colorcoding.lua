--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
-- luacheck: globals onValueChanged getName encumbranceColors getValue setColor

function encumbranceColors()
	if window.usearmormaxstatbonus.getValue() == 0 then
		setColor(ColorManager.COLOR_FULL)
	else
		local nodeEnc = getDatabaseNode().getParent()
		local sArmorStat = getName():gsub('armor', '')
		if DB.getValue(nodeEnc, sArmorStat .. 'fromenc') == DB.getValue(nodeEnc, 'armor' .. sArmorStat) then
			setColor(ColorManager.COLOR_HEALTH_CRIT_WOUNDS)
		else
			setColor(ColorManager.COLOR_FULL)
		end
	end
end

function onValueChanged(...)
	if super and super.onValueChanged then super.onValueChanged(...) end
	encumbranceColors()
end

function onInit()
	if super and super.onInit then super.onInit() end
	onValueChanged()
end
