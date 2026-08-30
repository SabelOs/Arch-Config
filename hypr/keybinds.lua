---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("walker"))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("code"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("spotify"))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("obsidian"))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("firefox --new-window https://web.whatsapp.com/"))
hl.bind(mainMod .. " + SHIFT + ALT + G", hl.dsp.exec_cmd("firefox --new-tab https://web.whatsapp.com/"))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.exec_cmd("firefox --new-window https://ha.soeke.net/"))
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("power-menu"))
hl.bind(mainMod .. " + ALT + SPACE", hl.dsp.exec_cmd("main-menu"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("toggle-trackpad"))
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

hl.bind("CTRL + ALT + B", hl.dsp.exec_cmd("kitty-tui -e bluetui"))
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd("kitty-tui -e btop"))
hl.bind("CTRL + ALT + A", hl.dsp.exec_cmd("kitty-tui -e wiremix"))
hl.bind("CTRL + ALT + C", hl.dsp.exec_cmd("kitty-tui -e calcurse"))

hl.bind(mainMod .. " + LEFT",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + RIGHT", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + UP",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + DOWN",  hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({mode = "fullscreen", action = "toggle",}))
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + TAB",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + CTRL + TAB", hl.dsp.exec_cmd("hyprctl dispatch workspace previous"))

hl.bind("ALT + TAB",       hl.dsp.exec_cmd("hyprctl dispatch cyclenext"))
hl.bind("ALT + SHIFT + TAB", hl.dsp.exec_cmd("hyprctl dispatch cyclenext prev"))
hl.bind("ALT + TAB",       hl.dsp.exec_cmd("hyprctl dispatch bringactivetotop"))

hl.bind(mainMod .. " + SHIFT + LEFT",  hl.dsp.exec_cmd("hyprctl dispatch swapwindow l"))
hl.bind(mainMod .. " + SHIFT + RIGHT", hl.dsp.exec_cmd("hyprctl dispatch swapwindow r"))
hl.bind(mainMod .. " + SHIFT + UP",    hl.dsp.exec_cmd("hyprctl dispatch swapwindow u"))
hl.bind(mainMod .. " + SHIFT + DOWN",  hl.dsp.exec_cmd("hyprctl dispatch swapwindow d"))

hl.bind(mainMod .. " + MINUS", hl.dsp.exec_cmd("hyprctl dispatch resizeactive -100 0"))
hl.bind(mainMod .. " + EQUAL", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 100 0"))
hl.bind(mainMod .. " + SHIFT + MINUS", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -100"))
hl.bind(mainMod .. " + SHIFT + EQUAL", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 100"))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("CTRL + ALT + DELETE", hl.dsp.exec_cmd("hyprshutdown --no-exit"))
hl.bind(mainMod .. " + CTRL + V", hl.dsp.exec_cmd("cliphist list | walker -d"))

hl.bind("XF86PowerOff", hl.dsp.exec_cmd("power-menu"), { locked = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("screen-cutout"))
hl.bind(mainMod .. " + C",
    hl.dsp.send_shortcut({ mods = "CTRL", key = "INSERT" }))

hl.bind(mainMod .. " + V",
    hl.dsp.send_shortcut({ mods = "SHIFT", key = "INSERT" }))