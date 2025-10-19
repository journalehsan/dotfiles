function fish_mode_prompt
    # Dracula colors
    set -l red "ff5555"
    set -l green "50fa7b"
    set -l yellow "f1fa8c"
    set -l purple "bd93f9"
    set -l bg_dark "282a36"
    set -l foreground "f8f8f2"
    
    switch $fish_bind_mode
        case default
            # Normal mode (red)
            set_color $red
            echo -n ""
            set_color -b $red $bg_dark
            echo -n " 󰬔 NORMAL "
            set_color normal
            set_color $red
            echo -n ""
            
        case insert
            # Insert mode (green)
            set_color $green
            echo -n ""
            set_color -b $green $bg_dark
            echo -n " 󰦻 INSERT "
            set_color normal  
            set_color $green
            echo -n ""
            
        case replace_one replace
            # Replace mode (yellow)
            set_color $yellow
            echo -n ""
            set_color -b $yellow $bg_dark
            echo -n " 󰛔 REPLACE "
            set_color normal
            set_color $yellow
            echo -n ""
            
        case visual
            # Visual mode (purple)
            set_color $purple
            echo -n ""
            set_color -b $purple $bg_dark  
            echo -n " 󰒅 VISUAL "
            set_color normal
            set_color $purple
            echo -n ""
    end
    
    set_color normal
    echo -n " "
end