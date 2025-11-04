if status is-interactive
    # Theme settings
    set -g theme_display_git yes
    set -g theme_display_git_dirty yes
    set -g theme_display_git_untracked yes
    set -g theme_display_git_ahead_verbose yes
    set -g theme_display_git_dirty_verbose yes
    set -g theme_display_git_master_branch yes
    set -g theme_git_worktree_support yes
    set -g theme_display_docker_machine yes
    set -g theme_display_virtualenv yes
    set -g theme_display_ruby yes
    set -g theme_display_node yes
    set -g theme_display_user ssh
    set -g theme_display_hostname ssh
    set -g theme_display_vi yes
    set -g theme_display_date yes
    set -g theme_display_cmd_duration yes
    set -g theme_title_display_process yes
    set -g theme_title_display_path yes
    set -g theme_title_use_abbreviated_path yes
    set -g theme_date_format "+%F %H:%M"
    set -g theme_avoid_ambiguous_glyphs yes
    set -g theme_powerline_fonts yes
    set -g theme_nerd_fonts yes
    set -g theme_show_exit_status yes
    set -g theme_color_scheme dark
    set -g fish_prompt_pwd_dir_length 0

    # Set agnoster as the theme with customizations
    set -g theme_color_scheme terminal-dark
    set -g fish_prompt_pwd_dir_length 1

    # Agnoster theme settings
    set -g agnoster_path_bg 314863
    set -g agnoster_git_bg 5f8787
    set -g theme_display_ruby no
    set -g theme_display_virtualenv yes
    set -g theme_powerline_fonts yes
    set -g theme_nerd_fonts yes
    set -g theme_color_scheme dark

    # Nice aliases with exa (modern ls replacement)
    alias ls='exa --icons --group-directories-first'
    alias ll='exa -lah --icons --group-directories-first'
    alias lt='exa --tree --icons --group-directories-first'
    alias la='exa -lah --icons --group-directories-first'
    alias l='exa -lh --icons --group-directories-first'

    # System update aliases
    alias update-system='sudo torsocks pacman -Syyu'
    alias yays='torsocks yay'

    # Git aliases
    alias g='git'
    alias gst='git status'
    alias gd='git diff'
    alias gco='git checkout'

    # Warp with proxy
    alias warp-proxy='~/.local/bin/warp-proxy'

    # Enable Vi mode
    fish_vi_key_bindings

    # Enable syntax highlighting
    set -g fish_color_autosuggestion '555'  'brblack'
    set -g fish_color_cancel -r
    set -g fish_color_command --bold
    set -g fish_color_comment red
    set -g fish_color_cwd green
    set -g fish_color_cwd_root red
    set -g fish_color_end brmagenta
    set -g fish_color_error brred
    set -g fish_color_escape 'bryellow'  '--bold'
    set -g fish_color_history_current --bold
    set -g fish_color_host normal
    set -g fish_color_match --background=brblue
    set -g fish_color_normal normal
    set -g fish_color_operator bryellow
    set -g fish_color_param cyan
    set -g fish_color_quote yellow
    set -g fish_color_redirection brblue
    set -g fish_color_search_match 'bryellow'  '--background=brblack'
    set -g fish_color_selection 'white'  '--bold'  '--background=brblack'
    set -g fish_color_status red
    set -g fish_color_user brgreen
    set -g fish_color_valid_path --underline
end

alias yay="paru"
alias nautilus="cosmic-files"
alias musage="~/.local/bin/ram_monitor"
# GTK theme setting
gsettings set org.gnome.desktop.interface gtk-theme 'Dracula'

# Qt theme configuration - Override system Kvantum setting
set -x QT_QPA_PLATFORMTHEME qt5ct
set -x QT_QPA_PLATFORMTHEME_QT6 qt6ct
set -e QT_STYLE_OVERRIDE Darkly  # Remove system Kvantum override

# Docura Dropbox environment variables (auto-load)
set -gx DROPBOX_CLIENT_ID "oni7s2m0zhzjqb1"
set -gx DROPBOX_CLIENT_SECRET "r9oyjntvotwlp4x"
set -gx DROPBOX_REDIRECT_URI "https://wof-softwares.github.io/Docura/oauth-redirect.html"

# VPN Aliases
alias vpn-start="cd /home/ehsantork/Documents/VPN && ./start_all.sh"
alias vpn-stop="cd /home/ehsantork/Documents/VPN && ./stop_all.sh"
alias vpn-check="cd /home/ehsantork/Documents/VPN && ./check_all.sh"
alias vpn-status="cd /home/ehsantork/Documents/VPN && ./check_all.sh"

# Individual service aliases
alias ssh-tunnel="cd /home/ehsantork/Documents/VPN && ./start_tunnel.sh"
alias shadowsocks="cd /home/ehsantork/Documents/VPN && ./start_shadowsocks.sh"

# Proxy configuration for fish shell
# Add these aliases to use proxy with various commands

# Alias to run nvim with proxy
alias nvim-proxy='~/.local/bin/with-proxy nvim'

# Generic alias to run any command with proxy
alias with-proxy='~/.local/bin/with-proxy'

# Set proxy function that exports variables to current shell
function set-proxy
    set -gx ALL_PROXY socks5://127.0.0.1:1080
    set -gx HTTP_PROXY socks5://127.0.0.1:1080
    set -gx HTTPS_PROXY socks5://127.0.0.1:1080
    set -gx http_proxy socks5://127.0.0.1:1080
    set -gx https_proxy socks5://127.0.0.1:1080
    echo "✅ Proxy environment variables set (SOCKS5: 127.0.0.1:1080)"
end

# Function to unset proxy variables
function unset-proxy
    set -e ALL_PROXY
    set -e HTTP_PROXY
    set -e HTTPS_PROXY
    set -e http_proxy
    set -e https_proxy
    echo "Proxy environment variables unset"
end

# Rust path switcher - prefer rustup over system rust
function change_rust_path
    set -gx PATH $HOME/.cargo/bin $PATH
    echo "✓ Switched to rustup Rust (home)"
    echo "  rustc: "(which rustc)
    echo "  cargo: "(which cargo)
    rustc --version
end

# Optionally set as default (uncomment to always use rustup)
# set -gx PATH $HOME/.cargo/bin $PATH
