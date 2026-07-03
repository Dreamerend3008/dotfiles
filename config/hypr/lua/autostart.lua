local apps = require("lua/programs")

hl.on("hyprland.start", function()
    local cmds = {
        "sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "sleep 1 && systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "sleep 2 && /usr/lib/xdg-desktop-portal-hyprland &",
        "sleep 2 && /usr/lib/xdg-desktop-portal &",
        "hyprctl setcursor Bibata-Modern-Ice 24",
        "gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'",
        "gsettings set org.gnome.desktop.interface cursor-size 24",
        "gsettings set org.gnome.desktop.interface gtk-theme 'Catppuccin-Mocha-Standard-Mauve-Dark'",
        "gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'",
        "gsettings set org.gnome.desktop.interface font-name 'Fira Sans 11'",
        "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'",
        "waybar",
        "dunst",
        "hypridle",
        os.getenv("HOME") .. "/dotfiles/config/hypr/scripts/eyecare.sh on",
        "hyprpaper",
        "wl-paste --type text --watch cliphist store",
        "wl-paste --type image --watch cliphist store",
        "nm-applet --indicator",
        "/usr/lib/polkit-kde-authentication-agent-1 || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
    }

    for _, cmd in ipairs(cmds) do
        hl.exec_cmd(cmd)
    end
end)
