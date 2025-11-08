# Apply Nvim Config to Other Branches

This guide explains how to apply the nvim configuration fixes to your other device-specific branches.

## Quick Method (Automated)

Use the provided script:

```bash
./apply-nvim-to-branch.sh <branch-name>
```

Example:
```bash
./apply-nvim-to-branch.sh laptop
./apply-nvim-to-branch.sh desktop
./apply-nvim-to-branch.sh work-machine
```

## Manual Method (More Control)

### Step 1: Switch to target branch

```bash
git checkout <branch-name>
```

### Step 2: Cherry-pick nvim config files

This commit adds all the nvim configuration files:

```bash
git cherry-pick 0669e42
```

**Commit:** `0669e42` - Fix nvim config tracking - convert from gitlink to regular files
- Adds all `.config/nvim/` files (init.lua, plugins, etc.)

### Step 3: Apply install.sh improvements (partial)

Commit `e4c328f` has mixed changes. Extract only the files you need:

```bash
# Get only .gitignore and install.sh from the commit
git show e4c328f:.gitignore > .gitignore
git show e4c328f:install.sh > install.sh

# Commit the changes
git add .gitignore install.sh
git commit -m "Improve install.sh with nvim config verification checks

Cherry-picked from e4c328f (only .gitignore and install.sh)"
```

**What this adds:**
- `.gitignore`: Better comments about nested .git directories
- `install.sh`: Pre-install check for empty nvim configs + post-install verification

### Step 4: Cherry-pick final install.sh fix

```bash
git cherry-pick 1ecd2d6
```

**Commit:** `1ecd2d6` - Fix install.sh: correct arithmetic expressions and add -L flag
- Fixes `((count++))` expressions that break with `set -e`
- Adds `-L` flag to `find` commands to follow symlinks

### Step 5: Verify and push

```bash
# Check the changes
git log --oneline -5

# Test the install script
./install.sh

# If everything looks good, push
git push origin <branch-name>
```

## What Gets Applied

✓ Complete nvim configuration (AstroNvim setup with your customizations)
✓ Improved install.sh with verification checks
✓ Updated .gitignore with better comments

## What Doesn't Get Applied

✗ Other device-specific configs from `e4c328f` (hypr, waybar, gtk, etc.)

## Troubleshooting

### Merge Conflicts

If you get conflicts during cherry-pick:

```bash
# Fix conflicts in the files
nvim <conflicted-file>

# Mark as resolved
git add <conflicted-file>

# Continue the cherry-pick
git cherry-pick --continue
```

### Abort and Start Over

```bash
git cherry-pick --abort
git reset --hard HEAD
```

## Commits Reference

- **0669e42**: Nvim config files only
- **e4c328f**: Mixed commit (extract .gitignore and install.sh only)
- **1ecd2d6**: Install.sh final fix

## Alternative: Simple Cherry-Pick (if install.sh is similar)

If your other branches have similar install.sh, you can try:

```bash
git checkout <branch-name>
git cherry-pick 0669e42 1ecd2d6
```

This skips the middle commit entirely if you don't need the verification improvements.
