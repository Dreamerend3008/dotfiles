local env = {
    { "XCURSOR_SIZE", "24" },
    { "XCURSOR_THEME", "Bibata-Modern-Ice" },
    { "HYPRCURSOR_SIZE", "24" },
    { "HYPRCURSOR_THEME", "Bibata-Modern-Ice" },
    { "XDG_CURRENT_DESKTOP", "Hyprland" },
    { "XDG_SESSION_TYPE", "wayland" },
    { "XDG_SESSION_DESKTOP", "Hyprland" },
    { "GDK_BACKEND", "wayland,x11,*" },
    { "SDL_VIDEODRIVER", "wayland" },
    { "CLUTTER_BACKEND", "wayland" },
    { "QT_AUTO_SCREEN_SCALE_FACTOR", "1" },
    { "QT_QPA_PLATFORM", "wayland;xcb" },
    { "QT_WAYLAND_DISABLE_WINDOWDECORATION", "1" },
    { "QT_QPA_PLATFORMTHEME", "qt6ct" },
    { "MOZ_ENABLE_WAYLAND", "1" },
    { "MOZ_DBUS_REMOTE", "1" },
    { "ELECTRON_OZONE_PLATFORM_HINT", "auto" },
    { "_JAVA_AWT_WM_NONREPARENTING", "1" },
}

for _, item in ipairs(env) do
    hl.env(item[1], item[2])
end
