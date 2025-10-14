return {
	-- Theme
	{ -- You can easily change to a different colorscheme.
		-- Change the name of the colorscheme plugin below, and then
		-- change the command in the config to whatever the name of that colorscheme is.
		--
		-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
		"folke/tokyonight.nvim",
		priority = 1000, -- Make sure to load this before all the other start plugins.
		init = function()
			-- Load the colorscheme here.
			-- Like many other themes, this one has different styles, and you could load
			-- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
			vim.cmd.colorscheme("tokyonight-day")
			-- You can configure highlights by doing something like:
			vim.cmd.hi("Comment gui=none")
		end,
	},
	-- Dark/light theme autoswitch
	{
		"f-person/auto-dark-mode.nvim",
		opts = {
			{
				set_dark_mode = function()
					vim.api.nvim_set_option_value("background", "dark", {})
				end,
				set_light_mode = function()
					vim.api.nvim_set_option_value("background", "light", {})
				end,
				update_interval = 3000,
				fallback = "dark",
			},
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},
	-- Transparency
	{
		"xiyaowong/transparent.nvim",
	},
}
