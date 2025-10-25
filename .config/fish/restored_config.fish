# Your original aliases (place them here)
# alias vn-sart='your original command here'
# Add any other aliases you had here

# Proxy configuration for fish shell
# Add these aliases to use proxy with various commands

# Alias to run nvim with proxy
alias nvim-proxy='~/.local/bin/with-proxy nvim'

# Generic alias to run any command with proxy
alias with-proxy='~/.local/bin/with-proxy'

# Set proxy function that exports variables to current shell
function set-proxy
    set proxy_host 127.0.0.1  # Replace with your proxy host if different
    set proxy_port 1080       # Replace with your actual Shadowsocks port
    
    # Optionally, allow passing port as parameter
    if test (count $argv) -gt 0
        set proxy_port $argv[1]
    end
    
    set -gx ALL_PROXY socks5://$proxy_host:$proxy_port
    set -gx HTTP_PROXY socks5://$proxy_host:$proxy_port
    set -gx HTTPS_PROXY socks5://$proxy_host:$proxy_port
    echo "Proxy environment variables set for current shell session (socks5://$proxy_host:$proxy_port)"
end

# Function to unset proxy variables
function unset-proxy
    set -e ALL_PROXY
    set -e HTTP_PROXY
    set -e HTTPS_PROXY
    echo "Proxy environment variables unset"
end