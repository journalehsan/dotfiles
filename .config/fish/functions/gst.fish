function gst --description "Enhanced git status with colors and icons"
    # Check if we're in a git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "󰊢 Not a git repository"
        return 1
    end
    
    # Dracula colors
    set -l green "50fa7b"
    set -l yellow "f1fa8c"
    set -l red "ff5555"
    set -l cyan "8be9fd"
    set -l purple "bd93f9"
    set -l comment "6272a4"
    
    # Get git information
    set -l branch (git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    set -l git_status (git status --porcelain)
    
    # Header
    set_color $purple --bold
    echo "󰊢 Git Repository Status"
    set_color normal
    
    # Branch info
    set_color $cyan
    echo -n "󰘬 Branch: "
    set_color $purple --bold
    echo $branch
    
    # Remote status
    set -l ahead_behind (git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
    if test -n "$ahead_behind"
        set -l ahead (echo $ahead_behind | cut -f1)
        set -l behind (echo $ahead_behind | cut -f2)
        
        set_color $cyan
        echo -n "󰕒 Remote: "
        
        if test $ahead -gt 0; and test $behind -gt 0
            set_color $yellow
            echo "󰶣 $ahead ahead, 󰶡 $behind behind"
        else if test $ahead -gt 0
            set_color $green
            echo "󰶣 $ahead ahead"
        else if test $behind -gt 0
            set_color $red
            echo "󰶡 $behind behind"
        else
            set_color $green
            echo "󰄬 Up to date"
        end
    else
        set_color $comment
        echo "󰌘 No remote tracking branch"
    end
    
    echo ""
    
    # Detailed status
    if test -z "$git_status"
        set_color $green
        echo "󰄬 Working tree clean"
    else
        echo "📋 Changes:"
        
        # Parse status
        echo "$git_status" | while read -l line
            set -l status_code (string sub -l 2 $line)
            set -l filename (string sub -s 4 $line)
            
            # Staged changes (first character)
            set -l staged (string sub -l 1 $status_code)
            # Working directory changes (second character) 
            set -l unstaged (string sub -s 2 -l 1 $status_code)
            
            echo -n "  "
            
            # Color and icon based on status
            switch $staged$unstaged
                case 'M '
                    set_color $green
                    echo -n "󰐗 staged: "
                case ' M'
                    set_color $yellow  
                    echo -n "󰏫 modified: "
                case 'MM'
                    set_color $yellow
                    echo -n "󰏫 mixed: "
                case 'A '
                    set_color $green
                    echo -n "󰐗 added: "
                case 'D '
                    set_color $red
                    echo -n "󰍴 deleted: "
                case ' D'
                    set_color $red
                    echo -n "󰍴 deleted: "
                case 'R '
                    set_color $purple
                    echo -n "󰕍 renamed: "
                case '??'
                    set_color $comment
                    echo -n "󰋗 untracked: "
                case 'UU'
                    set_color $red --bold
                    echo -n "󰞇 conflict: "
                case '*'
                    set_color $comment
                    echo -n "󰘧 other: "
            end
            
            set_color normal
            echo $filename
        end
        
        # Summary counts
        echo ""
        set -l staged_count (echo "$git_status" | grep -c '^[MADRC]')
        set -l modified_count (echo "$git_status" | grep -c '^.[MD]')
        set -l untracked_count (echo "$git_status" | grep -c '^??')
        
        if test $staged_count -gt 0
            set_color $green
            echo "󰐗 $staged_count staged"
        end
        if test $modified_count -gt 0
            set_color $yellow
            echo "󰏫 $modified_count modified"
        end
        if test $untracked_count -gt 0
            set_color $comment
            echo "󰋗 $untracked_count untracked"
        end
    end
    
    set_color normal
end