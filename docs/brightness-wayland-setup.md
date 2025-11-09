# Brightness Control on Wayland

## Current Setup

Using **swayosd-client** for brightness control because it has proper permissions configured.

## What We Tried

### brightnessctl Permissions Issue

`brightnessctl` requires write access to `/sys/class/backlight/intel_backlight/brightness` which is owned by root.

### Steps Taken to Fix brightnessctl

1. **Added user to video group:**
   ```bash
   sudo usermod -aG video $USER
   ```

2. **Created udev rule** (`/etc/udev/rules.d/90-backlight.rules`):
   ```
   ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video $sys$devpath/brightness", RUN+="/bin/chmod g+w $sys$devpath/brightness"
   ```

3. **Reloaded udev rules:**
   ```bash
   sudo udevadm control --reload-rules && sudo udevadm trigger
   ```

4. **IMPORTANT:** Must log out and back in for group membership to take effect

### Testing After Logout

After logging back in, test if brightnessctl works:
```bash
brightnessctl set 50%
brightnessctl set +5%
brightnessctl set 5%-
```

## Alternative Approaches

### Option 1: Use swayosd (Current)
- Pros: Works out of the box, handles permissions
- Cons: ~30MB RAM, extra dependency

### Option 2: Use brightnessctl directly (After fixing permissions)
```bash
# In hyprland bindings
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5% && notify-send "Brightness: $(brightnessctl | grep -oP '\(\K[0-9]+(?=%))%"
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%- && notify-send "Brightness: $(brightnessctl | grep -oP '\(\K[0-9]+(?=%))%"
```

### Option 3: Use light utility
```bash
sudo pacman -S light
# Automatically handles permissions via SUID
```

## Current Bindings

Located in `~/.config/hypr/bindings.conf`:
- Volume/Mute: Custom `notify-osd` script + mako notifications
- Brightness: `notify-osd` wrapper calling `swayosd-client`

## Script Location

`~/.local/bin/notify-osd` - Handles volume and brightness notifications

## Next Steps

After next login, if brightnessctl works:
1. Test: `brightnessctl set 50%`
2. Update `notify-osd` script to use brightnessctl
3. Disable swayosd: `systemctl --user disable swayosd-server`
