-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar &")
    hl.exec_cmd("dunst &")
    hl.exec_cmd("udiskie &")
    hl.exec_cmd("hyprpaper &")
    hl.exec_cmd("wl-paste --type text --watch cliphist store &")
    hl.exec_cmd("wl-paste --type image --watch cliphist store &")
    hl.exec_cmd("walker --gapplication-service")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'")
    hl.exec_cmd("set-wallpaper-dynamic-loop &")
    hl.exec_cmd("systemctl --user start elephant")
end)
