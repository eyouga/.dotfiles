-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- wezterm.gui is not available to the mux server, so take care to
-- do something reasonable when this config is evaluated by the mux
function get_appearance()
	if wezterm.gui then
		return wezterm.gui.get_appearance()
	end
	return "Dark"
end

function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Builtin Solarized Dark"
	else
		return "tokyonight-day"
	end
end

config.color_scheme = scheme_for_appearance(get_appearance())
config.window_background_opacity = 0.8
config.macos_window_background_blur = 20
-- config.kde_window_background_blur = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
if wezterm.target_triple:find("darwin") ~= nil then
	config.window_decorations = "RESIZE"
end
config.window_padding = {
	left = "1cell",
	right = "1cell",
	top = "0.5cell",
	bottom = "0cell",
}

config.colors = {
	tab_bar = {
		background = "rgba(0,0,0,0)",
	},
}

wezterm.on("toggle-tabbar", function(window, _)
	local overrides = window:get_config_overrides() or {}
	if overrides.enable_tab_bar == false then
		wezterm.log_info("tab bar shown")
		overrides.enable_tab_bar = true
	else
		wezterm.log_info("tab bar hidden")
		overrides.enable_tab_bar = false
	end
	window:set_config_overrides(overrides)
end)

config.keys = {
	{ key = "T", mods = "SUPER", action = wezterm.action.EmitEvent("toggle-tabbar") },
}

config.window_frame = {
	inactive_titlebar_bg = "none",
	active_titlebar_bg = "none",
}

-- and finally, return the configuration to wezterm
return config
