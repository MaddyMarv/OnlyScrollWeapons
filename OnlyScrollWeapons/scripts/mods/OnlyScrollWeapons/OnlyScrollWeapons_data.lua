local mod = get_mod("OnlyScrollWeapons")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "general_settings",
				type = "group",
				tab = mod:localize("tab_general"),
				sub_widgets = {
					{
						setting_id = "scroll_mode",
						type = "dropdown",
						default_value = "cycle",
						options = {
							{ text = "scroll_mode_cycle", value = "cycle" },
							{ text = "scroll_mode_directional", value = "directional" },
						},
					},
					{
						setting_id = "invert_direction",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "directional_cycle_on_repeat",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "non_weapon_scroll_target",
						type = "dropdown",
						default_value = "slot_primary",
						options = {
							{ text = "target_melee", value = "slot_primary" },
							{ text = "target_gun", value = "slot_secondary" },
						},
					},
				},
			},
		},
	},
}
