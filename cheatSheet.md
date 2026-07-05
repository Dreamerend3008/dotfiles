
# ⌨️ Hyprland Keybindings Cheatsheet

## 🪟 Window Management

| Keybind | Action |
|---------|--------|
| `Super + Q` | Close window |
| `Super + V` | Toggle floating |
| `Super + F` | Fullscreen |
| `Super + Shift + F` | Maximize (keep bar) |
| `Super + Alt + F` | Fake fullscreen |
| `Super + Shift + P` | Pin window |
| `Super + P` | Pseudo-tile (dwindle) |
| `Super + J` | Toggle split direction |
| `Super + D` | Toggle split |
| `Super + R` | Enter resize mode (hjkl/arrows, Esc to exit) |

## 🔀 Focus & Movement

| Keybind | Action |
|---------|--------|
| `Super + h/j/k/l` | Move focus (vim-style) |
| `Super + Shift + h/j/k/l` | Move window |
| `Super + Ctrl + h/j/k/l` | Resize window |
| `Alt + Tab` | Cycle windows |
| `Alt + Shift + Tab` | Cycle windows (reverse) |

## 📑 Tab Groups

| Keybind | Action |
|---------|--------|
| `Super + G` | Toggle group |
| `Super + Alt + h/l` | Switch tab in group |
| `Super + Alt + j` | Move window into group |
| `Super + Alt + k` | Move window out of group |

## 🖥️ Workspaces

| Keybind | Action |
|---------|--------|
| `Super + 1-0` | Switch to workspace 1-10 |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + Alt + 1-0` | Move window silently |
| `Super + Tab` | Toggle last workspace |
| `Super + S` | Toggle scratchpad |
| `Super + Shift + S` | Move to scratchpad |
| `Super + Scroll` | Scroll workspaces |
| `Super + Ctrl + ←/→` | Navigate workspaces |

## 🖥️ Multi-Monitor

| Keybind | Action |
|---------|--------|
| `Super + Shift + ]` | Move workspace to next monitor |
| `Super + Shift + [` | Move workspace to prev monitor |
| `Super + Alt + ←/→` | Focus next/prev monitor |

## 🚀 Applications

| Keybind | Action |
|---------|--------|
| `Super + T` or `Super + Enter` | Terminal (Ghostty) |
| `Super + B` | Browser (Firefox) |
| `Super + E` | File manager (Yazi) |
| `Super + Space` | App launcher (Rofi) |

## 📸 Screenshots

| Keybind | Action |
|---------|--------|
| `Super + Shift + S` | Area screenshot |
| `Print` | Full screenshot |
| `Super + Print` | Monitor screenshot |
| `Alt + Print` | Window screenshot |

## 🔧 Utilities

| Keybind | Action |
|---------|--------|
| `Super + ALT + L` | Lock screen |
| `Super + Shift + Q` | Power menu (wlogout) |
| `Super + N` | Toggle notifications |
| `Super + C` | Clipboard history |
| `Super + Shift + C` | Clear clipboard |
| `Super + Shift + W` | Random wallpaper |
| `Super + Shift + G` | Toggle gamemode |

## 🎵 Media & Hardware

| Keybind | Action |
|---------|--------|
| `Vol Up/Down/Mute` | Volume control with OSD |
| `Brightness Up/Down` | Brightness control with OSD |
| `Media Next/Prev/Play` | Media player control |

## 🖱️ Mouse

| Keybind | Action |
|---------|--------|
| `Super + LMB Drag` | Move window |
| `Super + RMB Drag` | Resize window |

## 📱 Touchpad Gestures

| Gesture | Action |
|---------|--------|
| 3-finger swipe left/right | Switch workspace |

---

# SSH Auth GitHub

```
ssh-keygen -t ed25519 -C "something"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```
