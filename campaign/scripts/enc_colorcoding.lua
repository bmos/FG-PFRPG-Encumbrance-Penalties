--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
-- luacheck: globals onValueChanged getName encumbranceColors getValue setColor

function encumbranceColors()
	local sArmorStat = getName():gsub('armor', '')
	local nMaxStat = DB.getValue(getDatabaseNode().getParent(), 'armor' .. sArmorStat)
	local nMaxStatFromEnc = DB.getValue(getDatabaseNode().getParent(), sArmorStat .. 'fromenc')
	if window.usearmormaxstatbonus.getValue() == 0 then
		setColor(ColorManager.COLOR_FULL)
	else
		if nMaxStatFromEnc == nMaxStat then
			setColor(ColorManager.COLOR_HEALTH_CRIT_WOUNDS)
		else
			setColor(ColorManager.COLOR_FULL)
		end
	end
end

function onValueChanged(...)
	if super and super.onValueChanged then super.onValueChanged(...); end
	encumbranceColors()
end

function onInit()
	if super and super.onInit then super.onInit() end
	onValueChanged()
end
