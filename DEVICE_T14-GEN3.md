# Device: t14-gen3

## Hardware Specs

- **Model:** Lenovo ThinkPad T14 Gen 3
- **CPU:** AMD Ryzen (Add specific model)
- **GPU:** AMD Radeon Graphics
- **RAM:** (Add RAM amount)
- **Display:** 2.8K (2880x1800) @ 90Hz

## Device-Specific Settings

### Display Configuration

```bash
# Monitor resolution and scaling
# File: .config/hypr/monitors.conf
monitor=eDP-1,2880x1800@90,0x0,1.5
```

### Power Management

- Battery optimizations: Yes
- TLP profile: balanced
- TLP scripts available in `/scripts/switch-to-tlp`

### Input Devices

- Touchpad: Yes (built-in ThinkPad precision touchpad)
- TrackPoint: Yes
- Keyboard: ThinkPad keyboard with backlight

## Custom Tweaks

### Applied on 2025-11-08

- 2.8K display scaling set to 1.5x for optimal readability
- Power management optimized for battery life
- AMD-specific TLP profile configured
- Waybar configured for laptop-specific modules (battery, network)

## Known Issues

- (Document any device-specific issues or workarounds here)

## Branch Information

- **Branch:** `t14-gen3`
- **Initial setup:** 2025-11-08
- **Last updated:** 2025-11-08

## Notes

This is the primary development machine. All universal improvements should be tested here first, then cherry-picked to `main` and other device branches.
