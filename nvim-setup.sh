#!/bin/bash

# Nvim build directory
nvim_build_dir_default="~/nvim-build"
nvim_build_dir=
nvim_binary_dir=
# Nvim source directory
nvim_src_dir_default="~/neovim"
nvim_src_dir=
# Nvim default configuration directory
nvim_config_dir_default="~/.config/nvim"
nvim_config_dir=
# Run or print
dry_run=0
verbose=0

nvim_setup_usage()
{
    cat << EOF
Usage $(basename $0) [OPTIONS]

Where OPTIONS:
    -b, --build  <dir>  Build directory for neovim  (defaults to: ${nvim_build_dir_default})
    -c, --config <dir>  Default neovim configuration directory (defaults to: ${nvim_config_dir_default})
    -d, --dry-run       Don't execute any commands. Instead, print out on standard output
                        what would've been ran
    -h, --help          Show this help and exit
    -s, --source <dir>  Source directory for neovim (defaults to: ${nvim_src_dir_default})
    -v, --verbose       Run the script with verbosity
EOF
}

nvim_setup_info()
{
    echo -e "[INFO] $@"
}

nvim_setup_err()
{
    echo -e "[ERROR] $@" >&2
}

nvim_setup_die()
{
    local _rc
    _rc="$1"
    shift
    nvim_setup_err "$@"
    exit ${_rc}
}

nvim_setup_get_shellrc()
{
    local -n shellrc=$1
    local ret
    
    ret=1
    if [[ ${SHELL} =~ bash ]]; then
        shellrc="$HOME/.bashrc"
        ret=0
    elif [[ ${SHELL} =~ zsh ]]; then
        shellrc="$HOME/.zshrc"
        ret=0
    elif [[ ${SHELL} =~ tcsh ]]; then
        shellrc="$HOME/.tcshrc"
        ret=0
    elif [[ ${SHELL} =~ csh ]]; then
        shellrc="$HOME/.cshrc"
        ret=0
    elif [[ ${SHELL} =~ ksh ]]; then
        shellrc="$HOME/.kshrc"
        ret=0
    # Leave /bin/sh for the last
    elif [[ ${SHELL} =~ sh ]]; then
        shellrc="$HOME/.profile"
        ret=0
    fi
    return ${ret}
}

nvim_setup_exec_cmd()
{
    local _cmd
    _cmd="$@"

    if [ ${dry_run} -eq 1 ]; then
        echo "${_cmd}"
    else
        if [ ${verbose} -eq 1 ]; then
            eval "${_cmd}"
        else
            eval "${_cmd}" &> /dev/null
        fi
        return $?
    fi
}

nvim_setup_symlink_lang_client_json_settings_file()
{
    nvim_setup_info "Symlinking neovim language client settings.json file"
    nvim_setup_exec_cmd "ln -s $(pwd)/files/settings.json ${nvim_config_dir}/settings.json"
}

nvim_setup_symlink_nvim_init_file()
{
    nvim_setup_info "Symlinking neovim init file"
    nvim_setup_exec_cmd "ln -s $(pwd)/files/init.vim ${nvim_config_dir}/init.vim"
}

nvim_setup_build_nvim_from_src()
{
    local _cpus
    _cpus=$(lscpu | \grep '^CPU(s)' | sed 's/.*\([0-9]\+\)/\1/g')
    _cpus=${_cpus:-"4"}

    nvim_setup_info "Cloning neovim"
    nvim_setup_exec_cmd git clone https://github.com/neovim/neovim ${nvim_src_dir}
    nvim_setup_exec_cmd pushd ${nvim_src_dir}
    nvim_setup_info "Building neovim + dependencies"
    nvim_setup_exec_cmd make -j${_cpus} CMAKE_INSTALL_PREFIX=${nvim_build_dir}
    nvim_setup_info "Instaling neovim"
    nvim_setup_exec_cmd make install
    nvim_setup_exec_cmd popd
}

nvim_setup_add_nvim_to_path()
{
    nvim_setup_info "Adding neovim to PATH"
    local _shellrc
    nvim_setup_get_shellrc _shellrc
    # Add nvim to PATH
    nvim_setup_exec_cmd 'echo -e "\n# Add nvim to PATH\nexport PATH=${nvim_binary_dir}:\$PATH" >> '${_shellrc}''
}

nvim_setup_check_nvim_in_path()
{
    nvim_setup_info "Verifying that neovim is in PATH"
    nvim_setup_exec_cmd ''$SHELL' -c "command -v nvim &> /dev/null"'
    nvim_setup_exec_cmd return $?
}

nvim_setup_create_dirs()
{
    nvim_setup_info "Checking if any old config dirs are present"
    # Config directory
    if [[ -d "${nvim_config_dir}" ]]; then
        nvim_setup_info "Backing up existing neovim config dir"
        nvim_setup_exec_cmd mv ${nvim_config_dir} ${nvim_config_dir}.old
    fi
    nvim_setup_exec_cmd mkdir -p ${nvim_config_dir}
}

nvim_setup_install_vimplug()
{
    nvim_setup_info "Installing vim-plug"
    nvim_setup_exec_cmd "curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
}

nvim_setup_install_nvim_plugins()
{
    nvim_setup_info "Installing neovim plugins! Press any key to continue"
    read -n 1 tmp
    if [ ${dry_run} -eq 1 ]; then
        echo nvim +PlugInstall +UpdateRemotePlugins +qa
    else
        nvim +PlugInstall +UpdateRemotePlugins +qa
    fi
}

nvim_setup_install_python_3()
{
    nvim_setup_info "Installing Python 3 bindings for neovim"
    nvim_setup_exec_cmd "python3 -m pip install --user --upgrade pynvim "
}

nvim_setup_set_defaults()
{
    nvim_config_dir=${nvim_config_dir:-${nvim_config_dir_default}}
    nvim_build_dir=${nvim_build_dir:-${nvim_build_dir_default}}
    nvim_binary_dir=${nvim_build_dir}/bin
    nvim_src_dir=${nvim_src_dir:-${nvim_src_dir_default}}
}

nvim_setup_parse_opts()
{
    local _args
    local _opts

    _args="$@"
    _opts=$(getopt -o b:c:ds:vh --long build: --long config: --long dry-run --long source: --long help --long verbose -- ${_args})
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
            -d|--dry-run)
                dry_run=1
                break
                ;;
            -h|--help)
                nvim_setup_usage
                exit 0
                ;;
            -s|--source)
                shift
                nvim_src_dir="$1"
                break
                ;;
            -v|--verbose)
                verbose=1
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
    nvim_setup_set_defaults

    return $?
}

nvim_setup_print_vars()
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
    if ! nvim_setup_parse_opts "$@"; then
        nvim_setup_die 1 "Error parsing options, exiting now!"
    fi

    nvim_setup_print_vars

    if ! command -v nvim &> /dev/null; then
        nvim_setup_build_nvim_from_src
        nvim_setup_add_nvim_to_path
        nvim_setup_create_dirs
        nvim_setup_install_vimplug
	nvim_setup_install_python_3
    fi

    if ! nvim_setup_check_nvim_in_path; then
        nvim_setup_die 2 "Neovim still not found in PATH, exiting now!"
    fi

    nvim_setup_symlink_nvim_init_file
    nvim_setup_symlink_lang_client_json_settings_file
    nvim_setup_install_nvim_plugins

    ret=$?

    nvim_setup_info "Done!"

    return ${ret}
}

main "$@"
