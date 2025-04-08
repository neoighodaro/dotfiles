local wezterm = require 'wezterm'

-- Initialize configuration
local config = wezterm.config_builder and wezterm.config_builder() or {}

-----------------------------------------------------------
-- Theme & Appearance
-----------------------------------------------------------

-- Dynamic color scheme based on system theme
local function color_scheme_for_appearance(appearance)
    if appearance:find "Dark" then
        return "Ef-Maris-Dark"
    else
        return "Ef-Day"
    end
end

config.color_scheme = color_scheme_for_appearance(wezterm.gui.get_appearance())

config.default_prog = { 'zsh', '-c', 'zellij da -y && zellij' }

-- Font settings
config.font = wezterm.font({ family = 'Hack Nerd Font' })
config.font_size = 14

-- Window appearance
config.window_decorations = "RESIZE"
config.initial_cols = 120
config.initial_rows = 120
config.window_background_opacity = 0.9999
config.macos_window_background_blur = 30

-- Window padding
config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
}

-----------------------------------------------------------
-- Behavior Settings
-----------------------------------------------------------

config.hide_tab_bar_if_only_one_tab = true
config.native_macos_fullscreen_mode = false
config.window_close_confirmation = 'NeverPrompt'

-----------------------------------------------------------
-- Environment Configuration
-----------------------------------------------------------

config.set_environment_variables = {
    PATH = '/opt/homebrew/bin:' .. os.getenv('PATH')
}

-----------------------------------------------------------
-- Key Bindings
-----------------------------------------------------------

-- config.disable_default_key_bindings = true

config.keys = {
    -- Word navigation
    {
        key = "LeftArrow",
        mods = "OPT",
        action = wezterm.action{SendString="\x1bb"}  -- backward-word
    },
    {
        key = "RightArrow",
        mods = "OPT",
        action = wezterm.action{SendString="\x1bf"}  -- forward-word
    },

    -- Line navigation
    {
        key = "LeftArrow",
        mods = "SUPER",
        action = wezterm.action{SendString="\x01"}   -- beginning of line
    },
    {
        key = "RightArrow",
        mods = "SUPER",
        action = wezterm.action{SendString="\x05"}   -- end of line
    },

    -- Quick Select
    {
        key = 'A',
        mods = 'CTRL|SHIFT',
        action = wezterm.action.QuickSelect
    },

    -- Open config in VS Code
    {
        key = ',',
        mods = 'SUPER',
        action = wezterm.action.SpawnCommandInNewWindow({
            cwd = wezterm.home_dir,
            args = { 'code', wezterm.config_file },
        }),
    },

    -- Close window
    {
        key = 'q',
        mods = 'SUPER',
        action = wezterm.action.CloseCurrentTab { confirm = false }
    }
}

-----------------------------------------------------------
-- Mouse Bindings
-----------------------------------------------------------

config.mouse_bindings = {
    -- CMD + Click to open links
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'SUPER',
        action = wezterm.action.OpenLinkAtMouseCursor,
    },
}

-- Commented out Teal theme for future reference
--[[
config.colors = {
    foreground = "#CBE0F0",
    background = "#061e2e",
    cursor_bg = "#78f6ec",
    cursor_border = "#47FF9C",
    cursor_fg = "#113445",
    selection_bg = "#f7ca95",
    selection_fg = "#033259",
    ansi = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#0FC5ED", "#a277ff", "#24EAF7", "#24EAF7" },
    brights = { "#214969" , "#E52E2E", "#44FFB1", "#FFE073", "#A277FF", "#a277ff", "#24EAF7", "#24EAF7" },
}
--]]

return config
