# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'
. "$HOME/.cargo/env"

# Development environment configurations
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin:$HOME/.cargo/bin:$HOME/.local/bin"

# Rust configuration (China mirrors if needed)
export RUSTUP_DIST_SERVER="${RUSTUP_DIST_SERVER:-https://static.rust-lang.org}"
export RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-https://static.rust-lang.org/rustup}"

# Go configuration
export GO111MODULE=on
export GOPROXY="${GOPROXY:-https://proxy.golang.org,direct}"

# Node.js configuration
export NPM_CONFIG_REGISTRY="${NPM_CONFIG_REGISTRY:-https://registry.npmjs.org}"

# Python virtual environment
export WORKON_HOME="$HOME/.virtualenvs"

# JDK configuration
export JAVA_HOME="/usr/lib/jvm/default"
export PATH="$PATH:$JAVA_HOME/bin"


. "$HOME/.local/share/../bin/env"
source ~/.bash_aliases

# Aliases mirrored from fish config
alias ls='exa --icons --group-directories-first'
alias ll='exa -lah --icons --group-directories-first'
alias lt='exa --tree --icons --group-directories-first'
alias la='exa -lah --icons --group-directories-first'
alias l='exa -lh --icons --group-directories-first'

alias update-system='sudo torsocks pacman -Syyu'
alias yays='torsocks yay'
alias update-dns='/home/ehsator/dotfiles/scripts/update_dns.sh'
alias update-warp='/home/ehsator/dotfiles/scripts/update-warp'

alias g='git'
alias gst='git status'
alias gd='git diff'
alias gco='git checkout'

alias warp-proxy='~/.local/bin/warp-proxy'
alias nautilus='cosmic-files'
alias musage='~/.local/bin/ram_monitor'
alias nvim-proxy='~/.local/bin/with-proxy nvim'
alias with-proxy='~/.local/bin/with-proxy'
alias vmview-xephyr='/home/ehsator/dotfiles/scripts/vmview-xephyr'
alias ollama-svc='~/.local/bin/ollama-svc'
alias fabric-tui='~/.local/bin/fabric-tui'
alias add_wallpaper='~/.local/bin/add_wallpaper'
alias gemini-proxy='torsocks gemini'

alias cwbuild='cargo build --target x86_64-pc-windows-gnu'
alias cbuild='cargo build'
alias run-selfcare='cargo run --bin selfcare'
alias crun='cargo run'
alias ccheck='cargo check'
alias final-windows-build='./build-windows.sh --sign --cert-path "/home/ehsator/Documents/selfcare/certs/selfcare_codesign.pfx" --cert-pass "CHOOSE_A_STRONG_PASSWORD"'

# Dropbox OAuth Credentials for Docura (Added on Mon Oct 13 03:44:58 PM +0330 2025)
export DROPBOX_CLIENT_ID="oni7s2m0zhzjqb1"
export DROPBOX_CLIENT_SECRET="r9oyjntvotwlp4x"
export DROPBOX_REDIRECT_URI="https://wof-softwares.github.io/Docura/oauth-redirect.html"


# Docura Dropbox Build Environment Alias
alias docura_build_env='export DROPBOX_CLIENT_ID="oni7s2m0zhzjqb1" && export DROPBOX_CLIENT_SECRET="r9oyjntvotwlp4x" && export DROPBOX_REDIRECT_URI="https://wof-softwares.github.io/Docura/oauth-redirect.html" && echo "✅ Docura Dropbox environment variables loaded!" && echo "  DROPBOX_CLIENT_ID: $DROPBOX_CLIENT_ID" && echo "  DROPBOX_REDIRECT_URI: $DROPBOX_REDIRECT_URI"'

# VPN Aliases
alias vpn-start="cd /home/ehsator/Documents/VPN && ./start_all.sh"
alias vpn-stop="cd /home/ehsator/Documents/VPN && ./stop_all.sh"
alias vpn-check="cd /home/ehsator/Documents/VPN && ./check_all.sh"
alias vpn-status="cd /home/ehsator/Documents/VPN && ./check_all.sh"

# Individual service aliases
alias ssh-tunnel="cd /home/ehsator/Documents/VPN && ./start_tunnel.sh"
alias shadowsocks="cd /home/ehsator/Documents/VPN && ./start_shadowsocks.sh"

alias yay='paru'

___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi
alias gitlab-token='~/.local/bin/gitlab-token.sh'
