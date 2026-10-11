-- Unit-3 Hyprland configuration (Hyprland 0.55+ Lua API)

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("env QT_MEDIA_BACKEND=ffmpeg QT_QPA_PLATFORM=wayland QT_WAYLAND_DISABLE_WINDOWDECORATION=1 /usr/bin/qs")
    hl.exec_cmd("pkill dunst")
    hl.exec_cmd("pkill mako")
    hl.exec_cmd("pkill swaync")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1 && ~/.config/quickshell/scripts/display_mode.sh restore && ~/.config/quickshell/setwallpaper.sh restore")
    hl.exec_cmd("pgrep -x hypridle >/dev/null || hypridle")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,ssh,pkcs11")
    hl.exec_cmd("~/.config/quickshell/lock.sh")
    hl.exec_cmd("udiskie")
    hl.exec_cmd("/usr/bin/waybar")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("~/.config/quickshell/wave-check.sh")
    hl.exec_cmd("~/.config/quickshell/scripts/battery-watch.sh")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
end)

hl.on("monitor.added", function()
    hl.exec_cmd("sleep 1 && ~/.config/quickshell/scripts/display_mode.sh restore && ~/.config/quickshell/setwallpaper.sh restore")
end)

-- Waybar 0.15 uses legacy workspace dispatchers that are incompatible with
-- Hyprland's Lua provider. Refresh the custom workspace buttons on changes.
local function refresh_waybar_workspaces()
    hl.exec_cmd("pkill -RTMIN+9 waybar")
end

hl.on("workspace.active", refresh_waybar_workspaces)
hl.on("workspace.created", refresh_waybar_workspaces)
hl.on("workspace.removed", refresh_waybar_workspaces)
hl.on("workspace.move_to_monitor", refresh_waybar_workspaces)

-- Environment
hl.env("PATH", "/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin")
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
        },
    },
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 1,
        col = {
            active_border = "rgba(EBE3D1ee)",
            inactive_border = "rgba(1D1913aa)",
        },
        layout = "dwindle",
    },
    decoration = {
        rounding = 0,
        blur = {
            enabled = false,
        },
        shadow = {
            enabled = false,
        },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
        mfact = 0.55,
    },
})

hl.curve("niercurve", {
    type = "bezier",
    points = { { 0.4, 0 }, { 0.2, 1 } },
})

hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "niercurve", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "niercurve", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "niercurve" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "niercurve", style = "slidevert" })

-- Quickshell and application window rules
hl.window_rule({ match = { class = "^(quickshell)$" }, float = true })
hl.window_rule({ match = { class = "^(quickshell)$" }, pin = true })
hl.window_rule({ match = { class = "^(quickshell)$" }, no_blur = true })
hl.window_rule({ match = { class = "^(quickshell)$" }, no_shadow = true })

-- Launcher and Quickshell
hl.bind("SUPER + Super_L", hl.dsp.exec_cmd("echo t >> /tmp/qs-menu"), { release = true })
hl.bind("SUPER + Tab", hl.dsp.exec_cmd("~/.config/quickshell/ctrl.sh"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("~/.config/quickshell/lock.sh"), { release = true })
hl.bind("SUPER + Return", hl.dsp.exec_cmd("/usr/bin/kitty"))
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("~/.config/quickshell/player.sh"))
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("~/.config/quickshell/scripts/visualizer_toggle.sh toggle"))

-- Applications
hl.bind("SUPER + M", hl.dsp.exec_cmd("youtube-music"))
hl.bind("SUPER + R", hl.dsp.exec_cmd("pkill qs"))
hl.bind("SUPER + P", hl.dsp.exec_cmd("~/.config/quickshell/wallpaper.sh"))
hl.bind("SUPER + W", hl.dsp.exec_cmd("brave"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("dolphin"))

-- Window management
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + Escape", hl.dsp.exit())
hl.bind("SUPER + D", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + B", function()
    hl.config({ general = { layout = "master" } })
end)
hl.bind("SUPER + SHIFT + B", function()
    hl.config({ general = { layout = "dwindle" } })
end)

-- Focus and directional movement
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))
hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

-- Special workspace
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))

-- Workspaces: SUPER switches, SUPER+ALT moves the active window
for workspace = 1, 10 do
    local key = workspace % 10
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind("SUPER + ALT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + ALT + Page_Up", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("SUPER + ALT + Page_Down", hl.dsp.window.move({ workspace = "+1" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Audio and brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" ~/Screenshots/$(date +%Y%m%d_%H%M%S).png]]))
hl.bind("SUPER + Print", hl.dsp.exec_cmd([[mkdir -p ~/Screenshots && grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" ~/Screenshots/$(date +%Y%m%d_%H%M%S).png]]))

-- Personal overrides are kept in a separate file and preserved by the installer.
require("user")
