function fish_prompt
    # Save the exit status
    set -l last_status $status
    
    # Dracula color palette
    set -l bg_dark "282a36"
    set -l current_line "44475a"
    set -l foreground "f8f8f2"
    set -l comment "6272a4"
    set -l cyan "8be9fd"
    set -l green "50fa7b"
    set -l orange "ffb86c"
    set -l pink "ff79c6"
    set -l purple "bd93f9"
    set -l red "ff5555"
    set -l yellow "f1fa8c"

    # Iceland-style segments function
    function print_segment
        set -l bg_color $argv[1]
        set -l fg_color $argv[2]
        set -l content $argv[3]
        set -l next_bg_color $argv[4]
        
        if test -n "$content"
            # Print segment with background
            set_color -b $bg_color $fg_color
            echo -n " $content "
            
            # Print separator
            if test -n "$next_bg_color"
                set_color -b $next_bg_color $bg_color
                echo -n ""
            else
                set_color normal
                set_color $bg_color
                echo -n ""
            end
        end
    end

    # User segment (only show if root or SSH)
    set -l user_segment ""
    if test (id -u) -eq 0
        set user_segment "󰀃 $USER"
    else if test -n "$SSH_CONNECTION"
        set user_segment "󰣀 $USER@$hostname"
    end

    # Directory segment with fancy icons
    set -l current_dir (prompt_pwd)
    set -l dir_icon ""
    
    # Smart directory icons
    if test "$PWD" = "$HOME"
        set dir_icon "󰋜"
    else if string match -q "*/Documents/*" $PWD
        set dir_icon "󰈙"
    else if string match -q "*/Downloads/*" $PWD
        set dir_icon "󰇚"
    else if string match -q "*/GitHub/*" $PWD; or string match -q "*/.git*" $PWD
        set dir_icon "󰊢"
    else if string match -q "*/Projects/*" $PWD
        set dir_icon "󰲋"
    else if string match -q "*/Pictures/*" $PWD
        set dir_icon "󰋩"
    else if string match -q "*/Music/*" $PWD
        set dir_icon "󰝚"
    else if string match -q "*/Videos/*" $PWD
        set dir_icon "󰕧"
    else if string match -q "*/Desktop/*" $PWD
        set dir_icon "󰇄"
    else if test -w "$PWD"
        set dir_icon "󰉋"
    else
        set dir_icon "󰉐"
    end
    
    set -l dir_segment "$dir_icon $current_dir"

    # Git segment with detailed status
    set -l git_segment ""
    set -l git_bg_color $comment
    
    if git rev-parse --git-dir >/dev/null 2>&1
        set -l git_branch (git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        set -l git_status (git status --porcelain 2>/dev/null)
        set -l git_remote_status ""
        
        # Get remote status
        set -l ahead_behind (git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
        if test -n "$ahead_behind"
            set -l ahead (echo $ahead_behind | cut -f1)
            set -l behind (echo $ahead_behind | cut -f2)
            
            if test $ahead -gt 0
                set git_remote_status "$git_remote_status󰶣$ahead"
            end
            if test $behind -gt 0
                set git_remote_status "$git_remote_status󰶡$behind"
            end
        end
        
        # Git status indicators
        set -l git_indicators ""
        set -l clean true
        
        if test -n "$git_status"
            set clean false
            # Count different types of changes
            set -l staged (echo "$git_status" | grep -c '^[MADRC]')
            set -l modified (echo "$git_status" | grep -c '^.[MD]')
            set -l untracked (echo "$git_status" | grep -c '^??')
            set -l deleted (echo "$git_status" | grep -c '^.D')
            set -l renamed (echo "$git_status" | grep -c '^R')
            set -l conflicts (echo "$git_status" | grep -c '^UU\|^AA\|^DD')
            
            if test $staged -gt 0
                set git_indicators "$git_indicators󰐗$staged"
            end
            if test $modified -gt 0
                set git_indicators "$git_indicators󰏫$modified"
            end
            if test $untracked -gt 0
                set git_indicators "$git_indicators󰋗$untracked"
            end
            if test $deleted -gt 0
                set git_indicators "$git_indicators󰍴$deleted"
            end
            if test $renamed -gt 0
                set git_indicators "$git_indicators󰕍$renamed"
            end
            if test $conflicts -gt 0
                set git_indicators "$git_indicators󰞇$conflicts"
                set git_bg_color $red
            end
        end
        
        # Set git background color based on status
        if test $clean = true
            set git_bg_color $green
        else
            set git_bg_color $yellow
        end
        
        # Branch icon based on branch name
        set -l branch_icon ""
        if test "$git_branch" = "main"; or test "$git_branch" = "master"
            set branch_icon "󰊢"
        else if string match -q "feature/*" $git_branch
            set branch_icon "󰑃"
        else if string match -q "bugfix/*" $git_branch; or string match -q "fix/*" $git_branch
            set branch_icon "󰃤"
        else if string match -q "develop*" $git_branch; or test "$git_branch" = "dev"
            set branch_icon "󰮂"
        else if string match -q "release/*" $git_branch
            set branch_icon "󰿅"
        else
            set branch_icon "󰘬"
        end
        
        set git_segment "$branch_icon $git_branch$git_remote_status$git_indicators"
    end

    # Status segment (only if last command failed)
    set -l status_segment ""
    set -l status_bg_color $red
    if test $last_status -ne 0
        set status_segment "󰅗 $last_status"
    end

    # Virtual environment segment
    set -l venv_segment ""
    if test -n "$VIRTUAL_ENV"
        set venv_segment "󰌠 "(basename "$VIRTUAL_ENV")
    end

    # Time segment
    set -l time_segment "󰥔 "(date +"%H:%M")

    # Build the prompt
    echo -n ""
    
    # Print segments
    if test -n "$user_segment"
        print_segment $red $foreground "$user_segment" $purple
    end
    
    if test -n "$venv_segment"
        print_segment $purple $bg_dark "$venv_segment" $cyan
    end
    
    print_segment $cyan $bg_dark "$dir_segment" (test -n "$git_segment"; and echo $git_bg_color; or echo "")
    
    if test -n "$git_segment"
        print_segment $git_bg_color $bg_dark "$git_segment" (test -n "$status_segment"; and echo $status_bg_color; or echo "")
    end
    
    if test -n "$status_segment"
        print_segment $status_bg_color $foreground "$status_segment" ""
    end
    
    # Reset colors and add space
    set_color normal
    echo -n " "
end