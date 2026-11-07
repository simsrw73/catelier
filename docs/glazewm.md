# Using Catelier with GlazeWM

Catelier's config is set up for [komorebi](https://github.com/LGUG2Z/komorebi), but `styles.css` also styles YASB's three [GlazeWM](https://github.com/glzr-io/glazewm) widgets. To use GlazeWM instead, swap the window manager widgets in `config.yaml`. The rest of the bar stays the same.

The GlazeWM widgets match the komorebi ones. The focused workspace gets the accent color, and a workspace that's shown on another monitor without focus gets a light highlight. Workspaces with windows are brighter than empty ones. The tiling direction icon shows whether new windows open beside or below the current one, and clicking it switches. The binding mode appears, in peach, only while a mode such as `resize` is on.

## Requirements

- [GlazeWM](https://github.com/glzr-io/glazewm), running. YASB connects to it at `ws://localhost:6123`, GlazeWM's default.
- GlazeWM's own bar turned off, so you don't get two bars. In GlazeWM's `config.yaml`, remove the `zebar` entry from `general.startup_commands`.

## Change config.yaml

### 1. Point the `wm` group at the GlazeWM widgets

Find the `wm` group near the top of `widgets:` and replace its `widgets` list:

```yaml
  wm:
    type: "yasb.grouper.GrouperWidget"
    options:
      class_name: "wm-pill"
      widgets: ["glazewm_binding_mode", "glazewm_tiling_direction", "glazewm_workspaces"]
      collapse_options:
        enabled: false
```

### 2. Add the GlazeWM widgets

Add these under `widgets:`, for example where the komorebi widgets are:

```yaml
  glazewm_binding_mode:
    type: "glazewm.binding_mode.GlazewmBindingModeWidget"
    options:
      label: "<span>{icon}</span>{binding_mode}"
      label_alt: "<span>{icon}</span>{binding_mode}"
      hide_if_no_active: true
      label_if_no_active: ""
      icons:
        none: ""
        resize: "\U000F0A68"
        pause: "\U000F03E4"
      binding_modes_to_cycle_through: ["none", "resize", "pause"]
      callbacks:
        on_left: "next_binding_mode"
        on_middle: "do_nothing"
        on_right: "prev_binding_mode"

  glazewm_tiling_direction:
    type: "glazewm.tiling_direction.GlazewmTilingDirectionWidget"
    options:
      horizontal_label: ""
      vertical_label: ""

  glazewm_workspaces:
    type: "glazewm.workspaces.GlazewmWorkspacesWidget"
    options:
      offline_label: ""
      hide_if_offline: true
      monitor_exclusive: true
      enable_scroll_switching: true
```

The tiling direction icons are the same columns and rows icons the komorebi layout widget uses. Workspace buttons show each workspace's name. To show GlazeWM's `display_name` instead, add `populated_label: "{display_name}"` and `empty_label: "{display_name}"` to `glazewm_workspaces`.

### 3. Remove the komorebi parts

Delete these from `config.yaml`:

- The four komorebi widget definitions: `komorebi_control`, `komorebi_active_layout`, `komorebi_stack` and `komorebi_workspaces`. Once they're out of the `wm` group they no longer show, but removing them keeps the config tidy.
- The `komorebi:` block near the top. It only holds the start, stop and reload commands for the komorebi control menu.

Save the file. If `watch_config` is on, YASB reloads by itself; otherwise restart it.

## Switching back

Put the komorebi widget names back in the `wm` group, restore the komorebi widget definitions and the `komorebi:` block from Catelier's [`config.yaml`](../config.yaml), and remove the GlazeWM widgets.
