#!/bin/bash

pick_color()
{
    declare -a color_list 
    local idx
    local chosen_color

    color_list=($(ls ~/.local/share/nvim/plugged/awesome-vim-colorschemes/colors | sed s/\.vim//g))

    while true; do
        while true; do
            idx=0
            for color in "${color_list[@]}"; do
                echo $idx: "$color"
                ((idx++))
            done
            echo -n "Make your pick (confirm with a '!' at the end): "
            read ans
            if [[ $ans =~ ^[0-9]+ ]]; then
                local n
                n=$(echo $ans | tr -dc 0-9)
                if [ $n -le $idx ]; then
                    break
                fi
            fi
        done

        chosen_color="${color_list[$n]}"

        echo "Chosen: $chosen_color"

        sed -i -e "s/^colorscheme .*$/colorscheme $chosen_color/g" ./files/init.vim

        # If answer was confirmed with an ending !, exit the loop
        if [[ $ans =~ !$ ]]; then
            break
        fi

        # Open nvim to show appearance
        nvim files/test.sh
    done
}

pick_color
