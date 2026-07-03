hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(cba6f7ff)", "rgba(b4befeff)" }, angle = 45 },
            inactive_border = "rgba(313244aa)",
        },
        resize_on_border = true,
        extend_border_grab_area = 15,
        hover_icon_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 12,
        active_opacity = 1.0,
        inactive_opacity = 0.92,
        fullscreen_opacity = 1.0,
        dim_inactive = false,
        dim_strength = 0.15,
        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            noise = 0.02,
            contrast = 0.9,
            brightness = 0.8,
            vibrancy = 0.17,
            vibrancy_darkness = 0.0,
            new_optimizations = true,
            xray = false,
            special = false,
            popups = true,
        },
        shadow = {
            enabled = true,
            range = 20,
            render_power = 3,
            color = "rgba(11111bee)",
            color_inactive = "rgba(11111b88)",
            offset = { 0, 2 },
            scale = 1.0,
        },
    },
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = true,
        force_split = 0,
        special_scale_factor = 0.8,
    },
    master = {
        new_status = "master",
        orientation = "left",
        mfact = 0.55,
        special_scale_factor = 0.8,
    },
    group = {
        insert_after_current = true,
        focus_removed_window = true,
        col = {
            border_active = "rgba(cba6f7ff)",
            border_inactive = "rgba(313244aa)",
            border_locked_active = "rgba(f9e2afff)",
            border_locked_inactive = "rgba(313244aa)",
        },
        groupbar = {
            enabled = true,
            height = 14,
            font_size = 10,
            render_titles = true,
            scrolling = true,
            text_color = "rgb(205, 214, 244)",
            col = {
                active = "rgba(cba6f7ff)",
                inactive = "rgba(313244aa)",
                locked_active = "rgba(f9e2afff)",
                locked_inactive = "rgba(313244aa)",
            },
        },
    },
    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles = true,
        scroll_event_delay = 300,
        movefocus_cycles_fullscreen = false,
    },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 0,
        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
        on_focus_under_fullscreen = 2,
        focus_on_activate = false,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        allow_session_lock_restore = true,
        initial_workspace_tracking = 1,
    },
    xwayland = {
        force_zero_scaling = true,
    },
})

hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0 }, { 0.35, 1 } } })
hl.curve("easeOutBack", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1 } } })
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("easeInOutSine", { type = "bezier", points = { { 0.37, 0 }, { 0.63, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "easeOutBack", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "easeOutBack", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "easeOutExpo", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "easeOutQuint" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 4, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 6, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 6, bezier = "easeOutExpo" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "easeOutExpo" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "linear", style = "loop" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "easeOutExpo", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "easeOutBack", style = "slidevert" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 4, bezier = "easeOutExpo" })
