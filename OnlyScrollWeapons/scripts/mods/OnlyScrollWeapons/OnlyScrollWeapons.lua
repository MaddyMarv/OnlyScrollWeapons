local mod = get_mod("OnlyScrollWeapons")
local HumanInputHandler = require("scripts/managers/player/player_game_states/human_input_handler")
local PlayerUnitVisualLoadout = require("scripts/extension_systems/visual_loadout/utilities/player_unit_visual_loadout")

local SCROLL_DOWN_IDX = 10
local SCROLL_UP_IDX = 11
local WIELD_1_IDX = 12
local WIELD_2_IDX = 13

mod:hook(HumanInputHandler, "pre_update", function(func, self, dt, t, input_service, ui_interaction_action)
	func(self, dt, t, input_service, ui_interaction_action)

	if not mod:is_enabled() then
		return
	end

	local cache = self._ephemeral_action_cache
	local scroll_down = cache[SCROLL_DOWN_IDX]
	local scroll_up = cache[SCROLL_UP_IDX]

	if not scroll_down and not scroll_up then
		return
	end

	local player = self._player
	local player_unit = player and player.player_unit

	if not player_unit or not ALIVE[player_unit] then
		return
	end

	local unit_data = ScriptUnit.has_extension(player_unit, "unit_data_system")

	if not unit_data then
		return
	end

	local inv = unit_data:read_component("inventory")
	local wielded_slot = inv and inv.wielded_slot
	local action_unwield_comp = unit_data:read_component("action_unwield")

	if action_unwield_comp and action_unwield_comp.slot_to_wield and action_unwield_comp.slot_to_wield ~= "none" then
		wielded_slot = action_unwield_comp.slot_to_wield
	end

	local mode = mod:get("scroll_mode") or "cycle"
	local target_slot

	if mode == "cycle" then
		if wielded_slot == "slot_primary" then
			target_slot = "slot_secondary"
		elseif wielded_slot == "slot_secondary" then
			target_slot = "slot_primary"
		else
			target_slot = mod:get("non_weapon_scroll_target") or "slot_primary"
		end
	else
		local invert = mod:get("invert_direction") or false
		local wants_primary = (scroll_up and not invert) or (scroll_down and invert)
		local desired_slot = wants_primary and "slot_primary" or "slot_secondary"

		if wielded_slot == desired_slot then
			if mod:get("directional_cycle_on_repeat") then
				target_slot = wants_primary and "slot_secondary" or "slot_primary"
			else
				cache[SCROLL_DOWN_IDX] = false
				cache[SCROLL_UP_IDX] = false
				return
			end
		else
			target_slot = desired_slot
		end
	end

	cache[SCROLL_DOWN_IDX] = false
	cache[SCROLL_UP_IDX] = false

	if target_slot == "slot_primary" then
		cache[WIELD_1_IDX] = true
	elseif target_slot == "slot_secondary" then
		cache[WIELD_2_IDX] = true
	end
end)

mod:hook(PlayerUnitVisualLoadout, "slot_name_from_wield_input", function(func, wield_input, inventory_component, visual_loadout_extension, weapon_extension, ability_extension, input_extension)
	if not mod:is_enabled() then
		return func(wield_input, inventory_component, visual_loadout_extension, weapon_extension, ability_extension, input_extension)
	end

	local is_scroll_down = wield_input == "wield_scroll_down"
	local is_scroll_up = wield_input == "wield_scroll_up"

	if not is_scroll_down and not is_scroll_up then
		return func(wield_input, inventory_component, visual_loadout_extension, weapon_extension, ability_extension, input_extension)
	end

	local wielded_slot = inventory_component.wielded_slot
	local mode = mod:get("scroll_mode") or "cycle"
	local target_slot

	if mode == "cycle" then
		if wielded_slot == "slot_primary" then
			target_slot = "slot_secondary"
		elseif wielded_slot == "slot_secondary" then
			target_slot = "slot_primary"
		else
			target_slot = mod:get("non_weapon_scroll_target") or "slot_primary"
		end
	else
		local invert = mod:get("invert_direction") or false
		local wants_primary = (is_scroll_up and not invert) or (is_scroll_down and invert)
		local desired_slot = wants_primary and "slot_primary" or "slot_secondary"

		if wielded_slot == desired_slot then
			if mod:get("directional_cycle_on_repeat") then
				target_slot = wants_primary and "slot_secondary" or "slot_primary"
			else
				return wielded_slot
			end
		else
			target_slot = desired_slot
		end
	end

	if visual_loadout_extension:can_wield(target_slot) then
		return target_slot
	end

	return func(wield_input, inventory_component, visual_loadout_extension, weapon_extension, ability_extension, input_extension)
end)
