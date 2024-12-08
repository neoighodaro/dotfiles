-- Helper function:
-- returns color scheme dependant on operating system theme setting (dark/light)
-- local function color_scheme_for_appearance(appearance)
--   if appearance:find "Dark" then
--     return "Tokyo Night"
--   else
--     return "Tokyo Night Day"
--   end
-- end

-- Pull in WezTerm API
local wezterm = require 'wezterm'

-- Initialize actual config
local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Appearance
config.font_size = 14.0
-- config.color_scheme = color_scheme_for_appearance(wezterm.gui.get_appearance())
config.window_decorations = "RESIZE"
-- config.window_background_opacity = 1.0
config.hide_tab_bar_if_only_one_tab = true
config.native_macos_fullscreen_mode = false
config.macos_window_background_blur = 30
config.initial_cols = 120
config.initial_rows = 120
config.window_close_confirmation = 'NeverPrompt'


config.colors = {
	foreground = "#CBE0F0",
	background = "#061e2e",
	cursor_bg = "#78f6ec",
	cursor_border = "#47FF9C",
	cursor_fg = "#113445",
	selection_bg = "#033259",
	selection_fg = "#CBE0F0",
	ansi = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#0FC5ED", "#a277ff", "#24EAF7", "#24EAF7" },
	brights = { "#214969" , "#E52E2E", "#44FFB1", "#FFE073", "#A277FF", "#a277ff", "#24EAF7", "#24EAF7" },
}

config.window_background_opacity = 0.75
config.macos_window_background_blur = 20


-- Keybindings
config.keys = {
  -- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
  { key="LeftArrow", mods="OPT", action=wezterm.action{SendString="\x1bb"} },
  -- Make Option-Right equivalent to Alt-f; forward-word
  { key="RightArrow", mods="OPT", action=wezterm.action{SendString="\x1bf"} },
  -- Jump to the beginning of the line (Cmd-Left)
  { key="LeftArrow", mods="SUPER", action=wezterm.action{SendString="\x01"} },
  -- Jump to the end of the line (Cmd-Right)
  { key="RightArrow", mods="SUPER", action=wezterm.action{SendString="\x05"} },
  -- QuickSelect keybind (CTRL-SHIFT-Space)
  { key = 'A', mods = 'CTRL|SHIFT', action = wezterm.action.QuickSelect },
  -- Quickly open config file with common macOS keybind
  {
    key = ',',
    mods = 'SUPER',
    action = wezterm.action.SpawnCommandInNewWindow({
      cwd = os.getenv 'WEZTERM_CONFIG_DIR',
      args = { os.getenv 'SHELL', '-c', '$VISUAL $WEZTERM_CONFIG_FILE' },
    }),
  },
}

config.mouse_bindings = {
    -- Ctrl-click will open the link under the mouse cursor
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'CTRL',
        action = wezterm.action.OpenLinkAtMouseCursor,
    },
}

-- Return config to WezTerm
return config
