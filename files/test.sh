#!/bin/bash

some_func()
{
    echo "This function is here to show you its colors"
}

print()
{
    [[ -z "$1" ]] && echo "Foo!" || echo "$1"
    
}

inc_by_1()
{
    local -n var=$1
    ((var++))
}

# This is a comment
some_func

my_index=37
print $my_index

inc_by_1 my_index
print $my_index

echo "Done!"
