function fish_right_prompt
    # Dracula colors
    set -l comment "6272a4"
    set -l cyan "8be9fd" 
    set -l purple "bd93f9"
    set -l bg_dark "282a36"
    set -l foreground "f8f8f2"
    
    set -l segments ""
    
    # Command duration (if > 1 second)
    if test $CMD_DURATION
        if test $CMD_DURATION -gt 1000
            set -l duration (math $CMD_DURATION / 1000)
            if test $duration -gt 60
                set -l minutes (math -s0 $duration / 60)
                set -l seconds (math -s0 $duration % 60)
                set segments "$segments 󰔟 "$minutes"m"$seconds"s"
            else
                set segments "$segments 󰔟 "$duration"s"
            end
        end
    end
    
    # Current time
    set segments "$segments 󰥔 "(date +"%H:%M")
    
    # Print right prompt with Iceland style
    if test -n "$segments"
        set_color $comment
        echo -n ""
        set_color -b $comment $foreground
        echo -n "$segments "
        set_color normal
    end
end