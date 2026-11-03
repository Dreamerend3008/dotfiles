local apps = require("lua/programs")
local mainMod = apps.mainMod
local home = os.getenv("HOME")

local function bind(keys, dispatcher, opts)
    hl.bind(keys, dispatcher, opts)
end

bind(mainMod .. " + Q", hl.dsp.window.close())
bind(mainMod .. " + SHIFT + M", hl.dsp.exit())
bind(mainMod .. " + V", hl.dsp.window.float())
bind(mainMod .. " + P", hl.dsp.window.pseudo())
bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
bind(mainMod .. " + ALT + F", hl.dsp.window.fullscreen_state({ internal = 0, client = 2, action = "toggle" }))
bind(mainMod .. " + SHIFT + P", hl.dsp.window.pin())
bind(mainMod .. " + D", hl.dsp.layout("togglesplit"))

bind(mainMod .. " + T", hl.dsp.exec_cmd(apps.terminal))
bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(apps.terminal))
bind(mainMod .. " + B", hl.dsp.exec_cmd(apps.browser))
bind(mainMod .. " + E", hl.dsp.exec_cmd(apps.terminal .. " -e " .. apps.fileManager))
bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(apps.menu))

bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(home .. "/dotfiles/config/hypr/scripts/screenshot.sh area"))
bind("Print", hl.dsp.exec_cmd(home .. "/dotfiles/config/hypr/scripts/screenshot.sh full"))
bind(mainMod .. " + Print", hl.dsp.exec_cmd(home .. "/dotfiles/config/hypr/scripts/screenshot.sh monitor"))
bind("ALT + Print", hl.dsp.exec_cmd(home .. "/dotfiles/config/hypr/scripts/screenshot.sh window"))

bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd("hyprlock --grace 5"))
bind(mainMod .. " + N", hl.dsp.exec_cmd("dunstctl set-paused toggle"))
bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("wlogout -b 2"))
bind(mainMod .. " + C", hl.dsp.exec_cmd("cliphist list | rofi -dmenu -theme catppuccin-mocha | cliphist decode | wl-copy"))
bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("cliphist wipe"))
bind(mainMod .. " + W", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/wallpaper.sh"))
bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/gamemode.sh"))
bind(mainMod .. " + SHIFT + SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))

for i, mode in ipairs({ "toggle", "warm", "warmer", "cool", "off" }) do
    bind(mainMod .. " + SHIFT + F" .. (7 + i), hl.dsp.exec_cmd(home .. "/dotfiles/config/hypr/scripts/eyecare.sh " .. mode))
end

for _, item in ipairs({
    { "h", "left" },
    { "l", "right" },
    { "k", "up" },
    { "j", "down" },
    { "left", "left" },
    { "right", "right" },
    { "up", "up" },
    { "down", "down" },
}) do
    bind(mainMod .. " + " .. item[1], hl.dsp.focus({ direction = item[2] }))
end

for _, item in ipairs({
    { "h", "left" },
    { "l", "right" },
    { "k", "up" },
    { "j", "down" },
    { "left", "left" },
    { "right", "right" },
    { "up", "up" },
    { "down", "down" },
}) do
    bind(mainMod .. " + SHIFT + " .. item[1], hl.dsp.window.move({ direction = item[2] }))
end

for _, item in ipairs({
    { "h", -30, 0 },
    { "l", 30, 0 },
    { "k", 0, -30 },
    { "j", 0, 30 },
    { "left", -30, 0 },
    { "right", 30, 0 },
    { "up", 0, -30 },
    { "down", 0, 30 },
}) do
    bind(mainMod .. " + CTRL + " .. item[1], hl.dsp.window.resize({ x = item[2], y = item[3], relative = true }), { repeating = true })
end

bind("ALT + Tab", hl.dsp.window.cycle_next({ next = true }))
bind("ALT + Tab", hl.dsp.window.bring_to_top(), { non_consuming = true })
bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

bind(mainMod .. " + G", hl.dsp.group.toggle())
bind(mainMod .. " + ALT + h", hl.dsp.group.prev())
bind(mainMod .. " + ALT + l", hl.dsp.group.next())
bind(mainMod .. " + ALT + j", hl.dsp.window.move({ into_group = "down" }))
bind(mainMod .. " + ALT + k", hl.dsp.window.move({ out_of_group = true }))

for i = 1, 10 do
    local key = tostring(i % 10)
    bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = tostring(i) }))
    bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
    bind(mainMod .. " + ALT + " .. key, hl.dsp.window.move({ workspace = tostring(i), follow = false }))
end

bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:magic" }))

bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))
bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + CTRL + left", hl.dsp.focus({ workspace = "e-1" }))

bind(mainMod .. " + SHIFT + bracketright", hl.dsp.workspace.move({ monitor = "+1" }))
bind(mainMod .. " + SHIFT + bracketleft", hl.dsp.workspace.move({ monitor = "-1" }))
bind(mainMod .. " + ALT + right", hl.dsp.focus({ monitor = "+1" }))
bind(mainMod .. " + ALT + left", hl.dsp.focus({ monitor = "-1" }))

bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/volume.sh up"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/volume.sh down"), { locked = true, repeating = true })
bind("XF86AudioMute", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/volume.sh mute"), { locked = true, repeating = true })
bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/brightness.sh up"), { locked = true, repeating = true })
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/brightness.sh down"), { locked = true, repeating = true })
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

bind(mainMod .. " + R", hl.dsp.submap("resize"))

hl.define_submap("resize", "reset", function()
    for _, item in ipairs({
        { "h", -30, 0 },
        { "l", 30, 0 },
        { "k", 0, -30 },
        { "j", 0, 30 },
        { "left", -30, 0 },
        { "right", 30, 0 },
        { "up", 0, -30 },
        { "down", 0, 30 },
    }) do
        bind(item[1], hl.dsp.window.resize({ x = item[2], y = item[3], relative = true }), { repeating = true })
    end
    bind("escape", hl.dsp.submap("reset"))
    bind("Return", hl.dsp.submap("reset"))
end)
