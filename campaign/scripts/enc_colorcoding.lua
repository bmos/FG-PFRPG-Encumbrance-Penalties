--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- luacheck: globals onValueChanged
function onValueChanged()
	local sArmorStat = getName():gsub('armor', '')
	local nMaxStat = DB.getValue(getDatabaseNode().getParent(), 'armor' .. sArmorStat)
	local nMaxStatFromEnc = DB.getValue(getDatabaseNode().getParent(), sArmorStat .. 'fromenc')
	if window.usearmormaxstatbonus.getValue() == 0 then
		window.armormaxstatbonus.setColor(ColorManager.COLOR_FULL)
	else
		if nMaxStatFromEnc == nMaxStat then
			window.armormaxstatbonus.setColor(ColorManager.COLOR_HEALTH_CRIT_WOUNDS)
		else
			window.armormaxstatbonus.setColor(ColorManager.COLOR_FULL)
		end
	end
end

function onInit() onValueChanged() end
