local mod = get_mod("OnlyScrollWeapons")
local HumanInputHandler = require("scripts/managers/player/player_game_states/human_input_handler")
local PlayerUnitVisualLoadout = require("scripts/extension_systems/visual_loadout/utilities/player_unit_visual_loadout")

local SCROLL_DOWN_IDX = 10
local SCROLL_UP_IDX = 11
local WIELD_1_IDX = 12
local WIELD_2_IDX = 13

local WEAPON_SCROLL_ORDER = {
	"slot_secondary",
	"slot_primary",
	slot_secondary = 1,
	slot_primary = 2,
}

local NOTCH_RESET_TIME = 0.15
local last_wield_t = -100
local accumulated_notches = 0
local last_notch_t = 0

local function _reset_state()
	last_wield_t = -100
	accumulated_notches = 0
	last_notch_t = 0
end

mod.on_disabled = function(initial_call)
	_reset_state()
end

mod.on_game_state_changed = function(status, state_name)
	_reset_state()
end

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

	local now = t or (Managers.time and Managers.time:has_timer("gameplay") and Managers.time:time("gameplay")) or 0
	local cooldown = mod:get("scroll_cooldown") or 0.20

	if cooldown > 0 and now < last_wield_t + cooldown then
		cache[SCROLL_DOWN_IDX] = false
		cache[SCROLL_UP_IDX] = false
		accumulated_notches = 0
		return
	end

	local threshold = mod:get("scroll_threshold") or 1

	if threshold > 1 then
		if now - last_notch_t > NOTCH_RESET_TIME then
			accumulated_notches = 0
		end

		accumulated_notches = accumulated_notches + 1
		last_notch_t = now

		if accumulated_notches < threshold then
			cache[SCROLL_DOWN_IDX] = false
			cache[SCROLL_UP_IDX] = false
			return
		end
	end

	accumulated_notches = 0

	local player = self._player
	local player_unit = player and player.player_unit

	if not player_unit or not ALIVE[player_unit] then
		cache[SCROLL_DOWN_IDX] = false
		cache[SCROLL_UP_IDX] = false
		return
	end

	local unit_data = ScriptUnit.has_extension(player_unit, "unit_data_system")

	if not unit_data then
		cache[SCROLL_DOWN_IDX] = false
		cache[SCROLL_UP_IDX] = false
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
		local slot_index = WEAPON_SCROLL_ORDER[wielded_slot]

		if slot_index then
			local wrap = true
			local input_settings_table = self._input_settings_table

			if input_settings_table and input_settings_table.weapon_switch_scroll_wrap ~= nil then
				wrap = input_settings_table.weapon_switch_scroll_wrap
			elseif Managers.save then
				local account_data = Managers.save:account_data()

				if account_data and account_data.input_settings and account_data.input_settings.weapon_switch_scroll_wrap ~= nil then
					wrap = account_data.input_settings.weapon_switch_scroll_wrap
				end
			end

			local index_change = scroll_up and 1 or -1
			local next_slot_index = slot_index + index_change

			if wrap then
				if math.index_wrapper then
					next_slot_index = math.index_wrapper(next_slot_index, 2)
				else
					next_slot_index = ((next_slot_index - 1) % 2) + 1
				end
			end

			target_slot = WEAPON_SCROLL_ORDER[next_slot_index]

			if not target_slot or target_slot == wielded_slot then
				cache[SCROLL_DOWN_IDX] = false
				cache[SCROLL_UP_IDX] = false
				return
			end
		else
			target_slot = mod:get("non_weapon_scroll_target") or "slot_primary"
		end
	else
		local invert = mod:get("invert_direction") or false
		local wants_primary = (scroll_down and not invert) or (scroll_up and invert)
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
	last_wield_t = now

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

	local now = Managers.time and Managers.time:has_timer("gameplay") and Managers.time:time("gameplay") or 0
	local cooldown = mod:get("scroll_cooldown") or 0.20

	if cooldown > 0 and now > 0 and now < last_wield_t + cooldown then
		return inventory_component.wielded_slot
	end

	local wielded_slot = inventory_component.wielded_slot
	local mode = mod:get("scroll_mode") or "cycle"
	local target_slot

	if mode == "cycle" then
		local slot_index = WEAPON_SCROLL_ORDER[wielded_slot]

		if slot_index then
			local wrap = input_extension and input_extension:get("weapon_switch_scroll_wrap")

			if wrap == nil then
				wrap = true
			end

			local index_change = is_scroll_up and 1 or -1
			local next_slot_index = slot_index + index_change

			if wrap then
				if math.index_wrapper then
					next_slot_index = math.index_wrapper(next_slot_index, 2)
				else
					next_slot_index = ((next_slot_index - 1) % 2) + 1
				end
			end

			target_slot = WEAPON_SCROLL_ORDER[next_slot_index]

			if not target_slot or target_slot == wielded_slot then
				return wielded_slot
			end
		else
			target_slot = mod:get("non_weapon_scroll_target") or "slot_primary"
		end
	else
		local invert = mod:get("invert_direction") or false
		local wants_primary = (is_scroll_down and not invert) or (is_scroll_up and invert)
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
		last_wield_t = now
		return target_slot
	end

	return func(wield_input, inventory_component, visual_loadout_extension, weapon_extension, ability_extension, input_extension)
end)
