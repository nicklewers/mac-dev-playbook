local wezterm = require 'wezterm'
local appearance = require 'appearance'
local act = wezterm.action
local config = wezterm.config_builder()

if appearance.is_dark() then
  config.color_scheme = 'Tokyo Night'
else
  config.color_scheme = 'Tokyo Night Day'
end

config.font = wezterm.font('JetBrains Mono')
config.font_size = 13

config.window_background_opacity = 0.95
config.macos_window_background_blur = 30
config.window_decorations = "RESIZE|INTEGRATED_BUTTONS"
config.window_frame = {
  font = wezterm.font({ family = 'JetBrains Mono', weight = 'Bold' }),
  font_size = 11,
}


-- local function segments_for_right_status(window)
--   return {
--     window:active_workspace(),
--   }
-- end


local function segments_for_right_status(window, pane)
    local cwd = ""
    local cwd_uri = pane:get_current_working_dir()

    if type(cwd_uri) == 'userdata' then
      cwd = cwd_uri.file_path
      hostname = cwd_uri.host or wezterm.hostname()
    end

    return {
      cwd,
      wezterm.strftime('%a %b %-d %H:%M'),
      wezterm.hostname(),
    }
  end
  
  wezterm.on('update-status', function(window, pane)
    local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
    local segments = segments_for_right_status(window, pane)
  
    local color_scheme = window:effective_config().resolved_palette
    -- Note the use of wezterm.color.parse here, this returns
    -- a Color object, which comes with functionality for lightening
    -- or darkening the colour (amongst other things).
    local bg = wezterm.color.parse(color_scheme.background)
    local fg = color_scheme.foreground
  
    -- Each powerline segment is going to be coloured progressively
    -- darker/lighter depending on whether we're on a dark/light colour
    -- scheme. Let's establish the "from" and "to" bounds of our gradient.
    local gradient_to, gradient_from = bg
    if appearance.is_dark() then
      gradient_from = gradient_to:lighten(0.2)
    else
      gradient_from = gradient_to:darken(0.2)
    end
  
    -- Yes, WezTerm supports creating gradients, because why not?! Although
    -- they'd usually be used for setting high fidelity gradients on your terminal's
    -- background, we'll use them here to give us a sample of the powerline segment
    -- colours we need.
    local gradient = wezterm.color.gradient(
      {
        orientation = 'Horizontal',
        colors = { gradient_from, gradient_to },
      },
      #segments -- only gives us as many colours as we have segments.
    )
  
    -- We'll build up the elements to send to wezterm.format in this table.
    local elements = {}
  
    for i, seg in ipairs(segments) do
      local is_first = i == 1
  
      if is_first then
        table.insert(elements, { Background = { Color = 'none' } })
      end
      table.insert(elements, { Foreground = { Color = gradient[i] } })
      table.insert(elements, { Text = SOLID_LEFT_ARROW })
  
      table.insert(elements, { Foreground = { Color = fg } })
      table.insert(elements, { Background = { Color = gradient[i] } })
      table.insert(elements, { Text = ' ' .. seg .. ' ' })
    end
  
    window:set_right_status(wezterm.format(elements))
  end)

config.set_environment_variables = {
  PATH = '/opt/homebrew/bin:' .. os.getenv('PATH')
}


config.keys = {
   {
     key = 'k',
     mods = 'SUPER',
     action = act.Multiple {
       act.ClearScrollback 'ScrollbackAndViewport',
       act.SendKey { key = 'L', mods = 'CTRL' },
     },
   },
 }
 
-- add a local_config module for machine specific configuration that
-- shouldn't be committed to the repo.
local has_local_config, local_config = pcall(require, "local_config")
if has_local_config then
  local_config.apply_to_config(config)
end

return config