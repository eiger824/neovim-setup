#!/bin/bash

# Nvim build directory
nvim_build_dir_default='~/nvim-build'
nvim_build_dir=
nvim_binary_dir=
# Nvim source directory
nvim_src_dir_default='~/neovim'
nvim_src_dir=
# Nvim default configuration directory
nvim_config_dir_default='~/.config/nvim'
nvim_config_dir=

info()
{
    echo -e "[INFO] $@"
}

err()
{
    echo -e "[ERROR] $@" >&2
}

die()
{
    local _rc
    _rc="$1"
    shift
    err "$@"
    exit ${_rc}
}

symlink_lang_client_json_settings_file()
{
    echo ln -s $(pwd)/files/settings.json ${nvim_config_dir}/settings.json
}

symlink_nvim_init_file()
{
    echo ln -s $(pwd)/files/init.vim ${nvim_config_dir}/init.vim
}

build_nvim_from_src()
{
    local _cpus
    _cpus=$(lscpu | \grep '^CPU(s)' | sed 's/.*\([0-9]\+\)/\1/g')
    _cpus=${_cpus:-"4"}

    echo git clone https://github.com/neovim/neovim ${nvim_src_dir}
    echo cd ${nvim_src_dir}
    echo make -j${_cpus} CMAKE_INSTALL_PREFIX=${nvim_build_dir}
    echo make install
}

add_nvim_to_path()
{
    echo "export PATH=${nvim_binary_dir}:\$PATH >> ~/.bashrc"
    echo source ~/.bashrc
}

install_nvim_plugins()
{
    echo nvim +PlugInstall +UpdateRemotePlugins +qa
}

usage()
{
    cat << EOF
Usage $(basename $0) [OPTIONS]

Where OPTIONS:
    -b, --build  <dir>  Build directory for neovim  (defaults to: ${nvim_build_dir_default})
    -c, --config <dir>  Default neovim configuration directory (defaults to: ${nvim_config_dir_default})
    -h, --help          Show this help and exit
    -s, --source <dir>  Source directory for neovim (defaults to: ${nvim_src_dir_default})
EOF
}

set_defaults()
{
    nvim_config_dir=${nvim_config_dir:-${nvim_config_dir_default}}
    nvim_build_dir=${nvim_build_dir:-${nvim_build_dir_default}}
    nvim_binary_dir=${nvim_build_dir}/bin
    nvim_src_dir=${nvim_src_dir:-${nvim_src_dir_default}}
}

parse_opts()
{
    local _args
    local _opts

    _args="$@"
    _opts=$(getopt -o b:c:s:h --long build: --long config: --long source: --long help -- ${_args})
    [ $? -ne 0 ] && return 1
    eval set -- ${_opts}
    while true; do
        case $1 in
            -b|--build)
                shift
                nvim_build_dir="$1"
                break
                ;;
            -c|--config)
                shift
                nvim_config_dir="$1"
                break
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -s|--source)
                shift
                nvim_src_dir="$1"
                break
                ;;
            --)
                shift
                break
                ;;
        esac
        shift
    done

    # Set defaults if not provided by cmdline
    set_defaults

    return $?
}

print_vars()
{
    cat << EOF
Running install script with options:
Neovim Source Directory: ${nvim_src_dir}
Neovim Binary Directory: ${nvim_build_dir}
Neovim Config Directory: ${nvim_config_dir}
EOF
}

main()
{
    if ! parse_opts "$@"; then
        die 1 "Error parsing options, exiting now!"
    fi

    print_vars

    if ! command -v nvim &> /dev/null; then
        info "Installing neovim"
        build_nvim_from_src
        add_nvim_to_path
    fi

    symlink_nvim_init_file
    symlink_lang_client_json_settings_file
    install_nvim_plugins
}

main "$@"
