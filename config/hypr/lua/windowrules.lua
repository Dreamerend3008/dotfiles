local function merge(base, extra)
    local out = {}
    for k, v in pairs(base) do
        out[k] = v
    end
    for k, v in pairs(extra) do
        out[k] = v
    end
    return out
end

local function wr(name, match, effects)
    hl.window_rule(merge({
        name = name,
        match = match,
    }, effects))
end

local function lr(name, namespace, effects)
    hl.layer_rule(merge({
        name = name,
        match = { namespace = namespace },
    }, effects))
end

local float_titles = {
    "^(Open File)$",
    "^(Save File)$",
    "^(Open Folder)$",
    "^(Save As)$",
    "^(Confirm to replace files)$",
    "^(File Operation Progress)$",
    "^(Volume Control)$",
    "^(About)(.*)$",
    "^(Properties)$",
}

for i, title in ipairs(float_titles) do
    wr("float-title-" .. i, { title = title }, { float = true })
end

local float_classes = {
    "^(pavucontrol)$",
    "^(nm-connection-editor)$",
    "^(blueman-manager)$",
    "^(polkit-kde-authentication-agent-1)$",
    "^(polkit-gnome-authentication-agent-1)$",
    "^(org.kde.polkit-kde-authentication-agent-1)$",
    "^(xdg-desktop-portal-gtk)$",
    "^(zenity)$",
    "^(file-roller)$",
    "^(nwg-look)$",
    "^(qt5ct)$",
    "^(qt6ct)$",
    "^(org.gnome.Calculator)$",
    "^(gnome-calculator)$",
    "^(qalculate-gtk)$",
    "^(qalculate-qt)$",
    "^(org.kde.kcalc)$",
    "^(org.gnome.Settings)$",
    "^(org.gnome.SystemMonitor)$",
    "^(org.kde.ark)$",
    "^(org.freedesktop.impl.portal.desktop.kde)$",
    "^(org.freedesktop.impl.portal.desktop.gtk)$",
    "^(waypaper)$",
    "^(wlogout)$",
}

for i, class in ipairs(float_classes) do
    wr("float-class-" .. i, { class = class }, { float = true })
end

wr("float-thunar-progress", { class = "^(thunar)$", title = "^(File Operation Progress)$" }, { float = true })
wr("float-thunar-replace", { class = "^(thunar)$", title = "^(Confirm to replace files)$" }, { float = true })
wr("float-nautilus-properties", { class = "^(org.gnome.Nautilus)$", title = "^(Properties)$" }, { float = true })

wr("calc-size", { class = "^(qalculate-gtk|qalculate-qt|org.kde.kcalc)$" }, { size = "520 620" })
wr("calc-center", { class = "^(qalculate-gtk|qalculate-qt|org.kde.kcalc)$" }, { center = true })

wr("pip-float", { title = "^(Picture-in-Picture)$" }, { float = true })
wr("pip-pin", { title = "^(Picture-in-Picture)$" }, { pin = true })
wr("pip-size", { title = "^(Picture-in-Picture)$" }, { size = "420 236" })
wr("pip-move", { title = "^(Picture-in-Picture)$" }, { move = "100%-440 50" })
wr("pip-no-dim", { title = "^(Picture-in-Picture)$" }, { no_dim = true })
wr("pip-opacity", { title = "^(Picture-in-Picture)$" }, { opacity = "1.0 override 1.0 override" })

wr("xwaylandvideobridge-opacity", { class = "^(xwaylandvideobridge)$" }, { opacity = "0.0 override" })
wr("xwaylandvideobridge-no-anim", { class = "^(xwaylandvideobridge)$" }, { no_anim = true })
wr("xwaylandvideobridge-no-focus", { class = "^(xwaylandvideobridge)$" }, { no_initial_focus = true })
wr("xwaylandvideobridge-max-size", { class = "^(xwaylandvideobridge)$" }, { max_size = "1 1" })
wr("xwaylandvideobridge-no-blur", { class = "^(xwaylandvideobridge)$" }, { no_blur = true })

local opacity_rules = {
    { "^(firefox)$", "0.90 0.85" },
    { "^(ghostty)$", "0.95 0.90" },
    { "^(kitty)$", "0.95 0.90" },
    { "^(Alacritty)$", "0.95 0.90" },
    { "^(code-oss)$", "0.90 0.85" },
    { "^(Code)$", "0.90 0.85" },
    { "^(code-url-handler)$", "0.90 0.85" },
    { "^(discord)$", "0.85 0.80" },
    { "^(Spotify)$", "0.90 0.85" },
    { "^(spotify)$", "0.90 0.85" },
    { "^(Steam)$", "0.85 0.80" },
    { "^(thunar)$", "0.90 0.85" },
    { "^(org.gnome.Nautilus)$", "0.90 0.85" },
}

for i, item in ipairs(opacity_rules) do
    wr("opacity-class-" .. i, { class = item[1] }, { opacity = item[2] })
end

local full_opacity = {
    { "class", "^(mpv)$" },
    { "class", "^(imv)$" },
    { "class", "^(org.gnome.Loupe)$" },
    { "title", "^(.*YouTube.*)$" },
}

for i, item in ipairs(full_opacity) do
    wr("opacity-override-" .. i, { [item[1]] = item[2] }, { opacity = "1.0 override 1.0 override" })
end

wr("idle-inhibit-firefox", { class = "^(firefox)$" }, { idle_inhibit = "fullscreen" })
wr("idle-inhibit-mpv-fullscreen", { class = "^(mpv)$" }, { idle_inhibit = "fullscreen" })
wr("idle-inhibit-vlc", { class = "^(vlc)$" }, { idle_inhibit = "fullscreen" })
wr("idle-inhibit-mpv-focus", { class = "^(mpv)$" }, { idle_inhibit = "focus" })

local steam_titles = {
    "^(Friends List)$",
    "^(Steam Settings)$",
    "^(Steam - News)$",
    "^(Screenshot Manager)$",
}

for i, title in ipairs(steam_titles) do
    wr("steam-float-" .. i, { class = "^(Steam)$", title = title }, { float = true })
end

wr("wlogout-fullscreen", { class = "^(wlogout)$" }, { fullscreen = true })

lr("rofi-blur", "^(rofi)$", { blur = true })
lr("waybar-blur", "^(waybar)$", { blur = true })
lr("dunst-blur", "^(dunst)$", { blur = true })
lr("logout-dialog-blur", "^(logout_dialog)$", { blur = true })
lr("rofi-ignore-alpha", "^(rofi)$", { ignore_alpha = 0.0 })
lr("waybar-ignore-alpha-0", "^(waybar)$", { ignore_alpha = 0.0 })
lr("dunst-ignore-alpha", "^(dunst)$", { ignore_alpha = 0.0 })
lr("logout-dialog-ignore-alpha", "^(logout_dialog)$", { ignore_alpha = 0.0 })
lr("waybar-ignore-alpha-50", "^(waybar)$", { ignore_alpha = 0.5 })
