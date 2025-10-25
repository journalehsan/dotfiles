# Custom Scripts

This directory contains custom shell and executable scripts that are symbolically linked to `~/.local/bin/` for easy access in your PATH.

## Scripts Management

These scripts are linked using the `restore_local_bin.sh` script which creates symbolic links from `~/dotfiles/scripts/` to `~/.local/bin/`.

To restore these links on a new system:
```bash
~/dotfiles/restore_local_bin.sh
```

## Adding New Scripts

To add a new script:
1. Place the script file in this directory
2. Run `~/dotfiles/restore_local_bin.sh` to create the symbolic link
3. The script will be accessible from your PATH as `script_name`