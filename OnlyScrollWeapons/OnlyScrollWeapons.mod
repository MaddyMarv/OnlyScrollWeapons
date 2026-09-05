return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`OnlyScrollWeapons` encountered an error loading the Darktide Mod Framework.")

		new_mod("OnlyScrollWeapons", {
			mod_script       = "OnlyScrollWeapons/scripts/mods/OnlyScrollWeapons/OnlyScrollWeapons",
			mod_data         = "OnlyScrollWeapons/scripts/mods/OnlyScrollWeapons/OnlyScrollWeapons_data",
			mod_localization = "OnlyScrollWeapons/scripts/mods/OnlyScrollWeapons/OnlyScrollWeapons_localization",
		})
	end,
	packages = {},
}
