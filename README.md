# Catelier

A theme for [YASB](https://github.com/amnweb/yasb) (Yet Another Status Bar) on Windows, built on the [Catppuccin Mocha](https://catppuccin.com/) palette and made for the [komorebi](https://github.com/LGUG2Z/komorebi) tiling window manager.

This is not an official Catppuccin port.

<!-- Screenshot: take one with YASB's built-in tool (right-click the bar → Take Screenshot) and save it as images/catelier.png -->

## Design

- **A floating top bar of pills.** Widgets are grouped into rounded pills: launcher, window manager, active window, clock, media, system metrics, controls, status and power.
- **Three levels of emphasis.** The time, focused workspace and active window title use the brightest text. Media, controls and status icons are a step dimmer. Metrics are dimmest, so they're there when you look and quiet when you don't.
- **Color means state.** Lavender marks focus, peach marks something waiting for you (GitHub notifications), and red marks a critical reading or the power button. Everything else is neutral.
- **Nothing on the bar changes width.** Numbers use a monospace font with fixed minimum widths, and details open in popups instead of swapping labels.
- **One look for every popup.** Calendar, CPU, memory, GPU, network, disk, Wi-Fi, Bluetooth, volume, media, control center, GitHub, system tray and power menu all share the same surfaces, spacing and buttons.

On the primary monitor you get the full bar. Other monitors get a slim bar with the launcher, workspaces, active window and clock.

## Requirements

- [YASB](https://github.com/amnweb/yasb) 2.0.7 or later
- [komorebi](https://github.com/LGUG2Z/komorebi) for the workspace, layout and stack widgets. Without it they hide themselves and the rest of the bar still works.
- Fonts:
  - [Inter](https://rsms.me/inter/) for text
  - [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads), both the **Mono** and **Propo** variants, for numbers and icons
  - Segoe Fluent Icons, which comes with Windows 11

You can install the two Nerd Fonts with Scoop:

```powershell
scoop bucket add nerd-fonts
scoop install nerd-fonts/JetBrainsMono-NF-Mono nerd-fonts/JetBrainsMono-NF-Propo
```

## Install

Run this in PowerShell:

```powershell
irm https://raw.githubusercontent.com/simsrw73/catelier/main/install.ps1 | iex
```

The script copies `config.yaml` and `styles.css` into your YASB config folder (`%YASB_CONFIG_HOME%`, or `%USERPROFILE%\.config\yasb` if that isn't set). It backs up any existing files first, as `config.yaml.<timestamp>.bak` and `styles.css.<timestamp>.bak`.

To keep your own `config.yaml` and only take the styles, clone the repository and run:

```powershell
.\install.ps1 -StylesOnly
```

Only the widgets in Catelier's config are styled, so you may need to adjust class names in your own config.

To install by hand, copy `config.yaml` and `styles.css` into your YASB config folder and restart YASB.

## Customize

- **Disk:** the disk widget shows drive `C`. To list more drives in its popup, add them to `volume_labels` under the `disk` widget in `config.yaml`, for example `["C", "D"]`.
- **GitHub:** the GitHub widget signs in with OAuth the first time you open it. It's hidden until you have unread notifications.
- **Colors:** every color is a variable at the top of `styles.css`. A few popup border colors are set in `config.yaml` as `border_color: "#313244"` (Catppuccin `surface0`).
- **Fonts:** change `--font-text`, `--font-mono` and `--font-icon` at the top of `styles.css`.

## Credits

Colors are from [Catppuccin](https://github.com/catppuccin/catppuccin), which is MIT-licensed. See [LICENSE](LICENSE).
