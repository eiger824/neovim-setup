# Neovim installation script

This script will install neovim from source and set up CCLS + Language Client Neovim for
C/C++ autocomplete + syntax correction

## Prerequisites

The following are needed before running this script:

    - Git
    - Working gcc
    - Clang + Libs
    - Python3 Pip
    - A cup of coffee

## Usage
```
Usage nvim-setup.sh [OPTIONS]

Where OPTIONS:
    -b, --build  <dir>  Build directory for neovim  (defaults to: ~/nvim-build)
    -c, --config <dir>  Default neovim configuration directory (defaults to: ~/.config/nvim)
    -d, --dry-run       Don't execute any commands. Instead, print out on standard output
                        what would've been ran
    -h, --help          Show this help and exit
    -s, --source <dir>  Source directory for neovim (defaults to: ~/neovim)
    -v, --verbose       Run the script with verbosity
```
