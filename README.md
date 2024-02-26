[![Release Build](https://github.com/bmos/FG-PFRPG-Encumbrance-Penalties/actions/workflows/release.yml/badge.svg)](https://github.com/bmos/FG-PFRPG-Encumbrance-Penalties/actions/workflows/release.yml) [![Luacheck](https://github.com/bmos/FG-PFRPG-Encumbrance-Penalties/actions/workflows/luacheck.yml/badge.svg)](https://github.com/bmos/FG-PFRPG-Encumbrance-Penalties/actions/workflows/luacheck.yml)

# Encumbrance Penalties
This extension enhances functionality related to carrying capacity and weight/armor encumbrance.

# Features
* Update carrying capacities when strength-modifying effects are applied/changed/removed. Currently supported: 'STR: N' (3.5E ONLY - increases strength score and carrying capacity), 'CARRY: N' (increases strength score only for calculating carrying capacity), 'CARRYMULT: N' (multiplies carrying capacity such as for ant haul).
* Automate encumbrance penalties based on total weight and current carrying capacity. The penalties are now colored to indicate their source. Red is for encumbrance based on weight and black is for armor.
* Auto-change speed based on weight encumbrance, some supported conditions, and SPEED: N effects. Ignore speed penalties from armor or encumbrance for Slow and Steady trait.
* Include the [Armor Expert trait](https://www.d20pfsrd.com/traits/combat-traits/armor-expert/), [Muscle of the Society trait](https://www.d20pfsrd.com/traits/combat-traits/muscle-of-the-society/), and [Armor Training fighter class feature](https://www.d20pfsrd.com/classes/Core-Classes/Fighter/#Armor_Training_Ex) in carry capacity and armor calculations.
* Automate [barbarian's Fast Movement](https://www.aonprd.com/ClassDisplay.aspx?ItemName=Barbarian).

# Compatibility and Instructions
This extension has been tested with [FantasyGrounds Unity](https://www.fantasygrounds.com/home/FantasyGroundsUnity.php) v4.5.0 (2024-02-21).
