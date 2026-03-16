# home.nix

This repo is where I keep the Nix config I actually use day to day.

At the moment it covers three targets:
- `battlecruiser`, my NixOS desktop
- `drone`, my macOS machine
- `live`, a bootable NixOS image

The shared configuration lives in `system/`. Machine-specific overrides live in `machines/`.

## Hyprland keybindings

The shortcut list below is for the Hyprland setup on Linux. The macOS side is in here too, but it does not use these bindings. `Super` is the main modifier key, usually the Windows key.

### Everyday stuff

| Keybinding | What it does |
| --- | --- |
| `Pause` | Lock the screen |
| `PrintScreen` | Screenshot an area |
| `Shift + PrintScreen` | Screenshot the whole screen |
| `Super + Space` | Open the app launcher |
| `Super + Tab` | Switch keyboard layout |
| `Super + Shift + V` | Pick from clipboard history and paste the selection |
| `Super + Esc` | Open the notification panel |
| `Super + Shift + Esc` | Clear notifications |

### Apps

| Keybinding | What it does |
| --- | --- |
| `Super + Enter` | Open the terminal |
| `Super + B` | Open the default browser |
| `Super + D` | Open Discord |
| `Super + E` | Open the file manager |
| `Super + M` | Open the music player |
| `Super + O` | Open Obsidian |
| `Super + P` | Open Pinta |
| `Super + T` | Open Todoist |
| `Super + Shift + C` | Open Calculator |
| `Super + Shift + S` | Open Steam when gaming is enabled |
| `Super + Shift + T` | Open Streamlink Twitch GUI |

### Web apps

| Keybinding | What it does |
| --- | --- |
| `Super + C` | Open ChatGPT |
| `Super + G` | Open GitHub notifications |
| `Super + W` | Open WhatsApp Web |
| `Super + X` | Open the X compose window |
| `Super + Y` | Open YouTube subscriptions |
| `Super + Shift + F` | Open Fastmail |
| `Super + Shift + G` | Open Grok |
| `Super + Shift + Y` | Open YNAB |

### System tools

| Keybinding | What it does |
| --- | --- |
| `Super + Ctrl + A` | Open the audio controls |
| `Super + Ctrl + B` | Open Bluetooth settings |
| `Super + Ctrl + D` | Open lazydocker |
| `Super + Ctrl + E` | Open yazi |
| `Super + Ctrl + Esc` | Open the power menu |
| `Super + Ctrl + N` | Open the network editor |
| `Super + Ctrl + P` | Open the PipeWire patchbay |
| `Super + Ctrl + S` | Open btop |
| `Super + Ctrl + W` | Open the Wi-Fi manager |

### Media and hardware keys

| Keybinding | What it does |
| --- | --- |
| `Audio Raise Volume` | Raise output volume |
| `Audio Lower Volume` | Lower output volume |
| `Audio Mute` | Toggle output mute |
| `Audio Mic Mute` | Toggle microphone mute |
| `Brightness Up` | Raise display brightness |
| `Brightness Down` | Lower display brightness |
| `Caps Lock` | Show the Caps Lock on-screen indicator |

### Window management

| Keybinding | What it does |
| --- | --- |
| `Super + h/j/k/l` | Move focus left/down/up/right |
| `Super + Shift + h/j/k/l` | Move the current window left/down/up/right |
| `Super + F` | Toggle fullscreen |
| `Super + Q` | Close the active window |
| `Super + Shift + Q` | Enter window kill mode |
| `Super + Shift + Space` | Toggle floating mode |
| `Super + 1-9` | Switch workspaces |
| `Super + Shift + 1-9` | Send the current window to a workspace |
| `Super + Left Mouse Drag` | Move a window |
| `Super + Right Mouse Drag` | Resize a window |

`battlecruiser` also adds monitor-specific bindings: `Super + Ctrl + 1-6` focuses workspaces `1-6` on the current monitor.
