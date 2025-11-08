# Dotfiles Branch Strategy

## Recommended Structure

```
main (shared baseline)
├── t14-gen3 (Lenovo ThinkPad T14 Gen3 - this device)
├── laptop (another device)
└── desktop (yet another device)
```

## Branch Purposes

### `main` branch
- **Purpose:** Shared baseline configuration that works on all devices
- **Contains:** Common configs, scripts, themes that don't need device-specific tweaks
- **When to update:** When you make improvements that benefit all devices
- **Who uses it:** Nobody directly - it's a template

### Device branches (e.g., `t14-gen3`)
- **Purpose:** Device-specific configurations
- **Contains:** Everything from `main` + device-specific overrides
- **When to update:** When you tweak settings for this specific device
- **Who uses it:** The actual device for daily use

## Migration Plan

### Option 1: Keep Current Setup (Simple)

If `main` is already heavily customized for your T14:

```bash
# Rename main to t14-gen3 (keep history)
git branch -m main t14-gen3
git push origin t14-gen3
git push origin --delete main

# Create new clean main from an earlier commit
git checkout <early-commit-with-baseline-configs>
git checkout -b main
git push origin main -u

# Set t14-gen3 as default for this machine
git checkout t14-gen3
```

### Option 2: Branch from Current Main (Recommended)

Keep `main` as-is and create device branch:

```bash
# Create t14-gen3 branch from current main
git checkout -b t14-gen3
git push origin t14-gen3 -u

# Now you can clean up main
git checkout main
# Remove device-specific stuff, keep only common configs
# Push cleaned main
```

## Workflow After Setup

### Making device-specific changes

```bash
# Work on your T14
git checkout t14-gen3
# Make changes (monitor configs, device-specific scripts, etc.)
git add .
git commit -m "T14: Adjust display scaling for 2.8K screen"
git push origin t14-gen3
```

### Making universal improvements

```bash
# Work on t14-gen3 as usual
git checkout t14-gen3
# Notice a nvim plugin that's useful for everyone
vim .config/nvim/lua/plugins/new-plugin.lua
git add .config/nvim/
git commit -m "Add useful nvim plugin"

# Cherry-pick to main
git checkout main
git cherry-pick <commit-hash>
git push origin main

# Apply to other devices
git checkout laptop
git cherry-pick <commit-hash>
git push origin laptop
```

### Syncing main updates to device branches

```bash
# When main gets updates (like nvim fixes)
git checkout t14-gen3
git merge main
# Or: git rebase main (cleaner history)
git push origin t14-gen3
```

## Best Practices

### ✓ DO

- Keep `main` minimal and universal
- Make device-specific changes on device branches
- Cherry-pick useful changes from device → main → other devices
- Use descriptive branch names (`t14-gen3`, not `laptop1`)
- Document device-specific quirks in branch (e.g., `T14_NOTES.md`)

### ✗ DON'T

- Make device-specific changes directly on `main`
- Merge everything from device branches back to main
- Use `main` as your daily driver branch
- Forget to sync important improvements to other branches

## Example Scenarios

### Scenario 1: Monitor Configuration

```bash
# T14 has 2.8K screen, needs specific scaling
git checkout t14-gen3
vim .config/hypr/monitors.conf  # Set scale=1.5
git commit -m "T14: Configure 2.8K display scaling"
# Don't push to main - this is device-specific
```

### Scenario 2: Useful Script

```bash
# Created a battery optimization script
git checkout t14-gen3
vim scripts/optimize-battery
git commit -m "Add battery optimization script"

# This is useful for all laptops!
git checkout main
git cherry-pick HEAD@{1}
# Now apply to other laptop branches
```

### Scenario 3: Nvim Plugin Discovery

```bash
# Found awesome plugin on T14
git checkout t14-gen3
vim .config/nvim/lua/plugins/awesome.lua
git commit -m "Add awesome-plugin for markdown"

# Share with all devices
git checkout main
git cherry-pick <commit>
./apply-nvim-to-branch.sh laptop
./apply-nvim-to-branch.sh desktop
```

## Quick Reference Commands

```bash
# Switch to device branch
git checkout t14-gen3

# Update from main
git merge main

# Share change to main
git checkout main
git cherry-pick <commit-hash>

# Apply main updates to all devices
for branch in t14-gen3 laptop desktop; do
  git checkout $branch
  git merge main
  git push origin $branch
done
git checkout t14-gen3  # return to current device
```

## File Organization Tips

```
dotfiles/
├── .config/
│   ├── nvim/          # Shared across all (on main)
│   ├── fish/          # Shared across all (on main)
│   └── hypr/          # Device-specific (different per branch)
├── scripts/
│   ├── common/        # Universal scripts (on main)
│   └── device/        # Device-specific (per branch)
└── docs/
    └── T14_SETUP.md   # Device-specific notes (per branch)
```
