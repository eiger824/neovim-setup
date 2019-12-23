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
# Nvim default shared data directory
nvim_shada_dir_default="~/.local/share/nvim"
# Nvim status file
nvim_setup_status_file="$(pwd)/.nvim_installation_status"
# CCLS source dir
ccls_src_dir_default="~/ccls"
ccls_src_dir=
# Run or print
dry_run=0
verbose=0
clean=0
system_libclang_default="~/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-18.04"
system_libclang=

nvim_setup_usage()
{
    cat << EOF
Usage $(basename $0) [OPTIONS]

Where OPTIONS:
    -b, --build  <dir>          Build directory for neovim  (defaults to: ${nvim_build_dir_default})
    -c, --config <dir>          Default neovim configuration directory (defaults to: ${nvim_config_dir_default})
    -C, --clean                 Clean all files/directories generated by this script. It will also remove all
                                PATH modifications/expansions done
    -d, --dry-run               Don't execute any commands. Instead, print out on standard output
                                what would've been ran
    -h, --help                  Show this help and exit
    -l, --system-libclang <dir> Use the system's libclang, instead of the prebuild binaries from LLVM
                                (default: OFF)
    -n, --ccls-source     <dir> Source directory for CCLS (defaults to: ${ccls_src_dir_default})
    -s, --nvim-source     <dir> Source directory for neovim (defaults to: ${nvim_src_dir_default})
    -v, --verbose               Run the script with verbosity
EOF
}

nvim_setup_info()
{
    echo -e "\e[92m[INFO]\e[39m $@"
}

nvim_setup_err()
{
    echo -e "\e[91m[ERROR]\e[39m $@" >&2
}

nvim_setup_warn()
{
    echo -e "\e[93m[WARNING]\e[39m $@" >&2
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
    nvim_setup_info "Installing neovim"
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

nvim_setup_check_cmd_in_path()
{
    local _cmd
    _cmd="$1"
    nvim_setup_info "Verifying that ${_cmd} is in PATH"
    nvim_setup_exec_cmd ''$SHELL' -c "command -v '${_cmd}' &> /dev/null"'
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
    nvim_setup_exec_cmd "curl -fLo ${nvim_shada_dir_default}/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
}

nvim_setup_install_nvim_plugins()
{
    nvim_setup_info "Installing neovim plugins!"
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

nvim_setup_download_libclang_binaries()
{
    local _clang_name
    local _shellrc
    _clang_name="clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-18.04"
    nvim_setup_info "Getting latest CLANG prebuilt binaries"
    nvim_setup_exec_cmd pushd ~
    nvim_setup_exec_cmd "wget http://releases.llvm.org/9.0.0/${_clang_name}.tar.xz"
    nvim_setup_exec_cmd "tar xvf ~/${_clang_name}.tar.xz"
    nvim_setup_exec_cmd popd
}

nvim_setup_build_ccls()
{
    nvim_setup_info "Cloning CCLS"
    nvim_setup_exec_cmd "git clone --depth=1 --recursive https://github.com/MaskRay/ccls ${ccls_src_dir}"
    nvim_setup_exec_cmd pushd ${ccls_src_dir} 
    nvim_setup_info "Configuring CCLS"
    nvim_setup_exec_cmd \
        "cmake -H. -BRelease -DCMAKE_BUILD_TYPE=Release -DUSE_SYSTEM_RAPIDJSON=OFF -DCMAKE_PREFIX_PATH=${system_libclang}"
    nvim_setup_info "Building CCLS"
    nvim_setup_exec_cmd "cmake --build Release"
    nvim_setup_exec_cmd popd
    nvim_setup_info "Adding CCLS binary to path"
    nvim_setup_get_shellrc _shellrc
    # Add nvim to PATH
    nvim_setup_exec_cmd 'echo -e "\n# Add CCLS to PATH\nexport PATH=${ccls_src_dir}/Release:\$PATH" >> '${_shellrc}''
}

nvim_setup_parse_prev_installation_vars()
{
    if [ $# -ne 4 ]; then
        die "Wrong number of args sent to function"
    fi

    local -n config_dir="$1"
    local -n build_dir="$2"
    local -n src_dir="$3"
    local -n ccls_dir="$4"

    if [[ ! -f ${nvim_setup_status_file} ]]; then
        die "Installation file not found, bailing out"
    fi

    config_dir=$(\grep ^nvim_config_dir= ${nvim_setup_status_file} | cut -d= -f2)
    build_dir=$(\grep ^nvim_build_dir= ${nvim_setup_status_file} | cut -d= -f2)
    src_dir=$(\grep ^nvim_src_dir= ${nvim_setup_status_file} | cut -d= -f2)
    ccls_dir=$(\grep ^ccls_src_dir= ${nvim_setup_status_file} | cut -d= -f2)
}

nvim_setup_clean()
{
    if [[ -f ${nvim_setup_status_file} ]]; then
        nvim_setup_parse_prev_installation_vars \
            nvim_config_dir nvim_build_dir nvim_src_dir ccls_src_dir
    fi

    nvim_setup_info "Cleaning all generated files / directories"
    nvim_setup_exec_cmd "rm -rf ${nvim_config_dir} ${nvim_build_dir} ${nvim_src_dir} ${nvim_shada_dir_default} ${ccls_src_dir}"
    nvim_setup_info "Cleaning installation status file"
    nvim_setup_exec_cmd "rm -f ${nvim_setup_status_file}"
    nvim_setup_info "Cleaning PATH"
    local _shellrc
    nvim_setup_get_shellrc _shellrc
    if nvim_setup_exec_cmd "grep \"^# Add [A-Za-z]\+\" ${_shellrc}"; then
        nvim_setup_exec_cmd "sed -i -r -e '/^# Add [a-zA-Z]+/d' -e '/^export PATH=.*(nvim|ccls).*/d' ${_shellrc}"
    fi
    nvim_setup_info "Done"
}

nvim_setup_set_defaults()
{
    nvim_config_dir=${nvim_config_dir:-${nvim_config_dir_default}}
    nvim_build_dir=${nvim_build_dir:-${nvim_build_dir_default}}
    nvim_binary_dir=${nvim_build_dir}/bin
    nvim_src_dir=${nvim_src_dir:-${nvim_src_dir_default}}
    ccls_src_dir=${ccls_src_dir:-${ccls_src_dir_default}}
    system_libclang=${system_libclang:-${system_libclang_default}}
}

nvim_setup_parse_opts()
{
    local _args
    local _opts

    _args="$@"
    _opts=$(getopt -o b:c:Cds:n:l:vh \
        --long build: \
        --long config: \
        --long clean \
        --long dry-run \
        --long nvim-source: \
        --long ccls-source: \
        --long system-libclang: \
        --long help \
        --long verbose \
        -- ${_args})
    [ $? -ne 0 ] && return 1
    eval set -- ${_opts}
    while true; do
        case $1 in
            -b|--build)
                shift
                nvim_build_dir="$1"
                ;;
            -c|--config)
                shift
                nvim_config_dir="$1"
                ;;
            -C|--clean)
                clean=1
                ;;
            -d|--dry-run)
                dry_run=1
                ;;
            -h|--help)
                nvim_setup_usage
                exit 0
                ;;
            -s|--nvim-source)
                shift
                nvim_src_dir="$1"
                ;;
            -n|--ccls-source)
                shift
                ccls_src_dir="$1"
                ;;
            -l|--system-libclang)
                shift
                system_libclang="$1"
                ;;
            -v|--verbose)
                verbose=1
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

nvim_setup_print_and_save_config()
{
    # First, remove any existing setup files
    nvim_setup_exec_cmd "rm -f ${nvim_setup_status_file}"
    cat << EOF
+---------------------------------------------+
| Running install script with options:
| Neovim Source Directory: ${nvim_src_dir}
| Neovim Binary Directory: ${nvim_build_dir}
| Neovim Config Directory: ${nvim_config_dir}
| CCLS Source Directory:   ${ccls_src_dir}
| libclang path:           ${system_libclang}
+---------------------------------------------+

EOF
    if [ $clean -eq 0 ]; then
        if [[ -f ${nvim_setup_status_file} ]]; then
            nvim_setup_warn "A previous installation file was found, backing up"
            nvim_setup_exec_cmd "mv ${nvim_setup_status_file}{,.bkup}"
        fi
        if [ $dry_run -eq 0 ]; then
            # Save this settings in the status file
            cat > ${nvim_setup_status_file} << EOF
# Autogenerated file, do not remove or edit
# Generated on $(date -R)
nvim_src_dir=${nvim_src_dir}
nvim_build_dir=${nvim_build_dir}
nvim_config_dir=${nvim_config_dir}
ccls_src_dir=${ccls_src_dir}
system_libclang=${system_libclang}
EOF
            # Change permissions to only read for user + group
            chmod 0440 ${nvim_setup_status_file}
        fi
    fi
}

nvim_setup_check_bash_version()
{
    local _bash_version
    local _bash_version_major
    local _bash_version_minor
    local _bash_version_mgc

    nvim_setup_info "Checking right bash version"
    _bash_version=$(sed "s/\([0-9]\.[0-9]\).*$/\1/g" <<< $BASH_VERSION)

    if [[ ! $_bash_version =~ [0-9]\.[0-9] ]]; then
        nvim_setup_warn "Could not parse the BASH_VERSION env variable (are you even running bash?)"
        return 1
    fi

    _bash_version_major=$(cut -d. -f 1 <<< $_bash_version)
    _bash_version_minor=$(cut -d. -f 2 <<< $_bash_version)
    
    _bash_version_mgc=$(( 10*${_bash_version_major} + ${_bash_version_minor} ))

    if [ $_bash_version_mgc -lt 43 ] ; then
	    nvim_setup_warn "bash version $_bash_version detected"
        return 3
    fi

    return 0
}

nvim_setup_check_python3_version()
{
    local _py3ver
    local _py3ver_major
    local _py3ver_minor
    local _py3ver_mgc
    
    _py3ver=$(python3 --version 2>&1 | tr -dc '0-9\.')
    _py3ver_major=$(cut -d. -f1 <<< $_py3ver)
    _py3ver_minor=$(cut -d. -f2 <<< $_py3ver)

    _py3ver_mgc=$(( 10*${_py3ver_major} + ${_py3ver_minor} ))

    if [ $_py3ver_mgc -lt 36 ]; then
        nvim_setup_warn "python3 version ${_py3ver} detected"
        return 1
    fi

    return 0
}

main()
{
    if ! nvim_setup_parse_opts "$@"; then
        nvim_setup_die 1 "Error parsing options, exiting now!"
    fi

    # First: make sure we are running a bash >= 4.3, where local references where introduced
    if ! nvim_setup_check_bash_version; then
        nvim_setup_die 1 "Need to be running a version of bash >= 4.3. Aborting now"
    fi
    
    # Next: python3 >= 3.6, for deoplete
    if ! nvim_setup_check_python3_version; then
        nvim_setup_die 1 "Need to be running a version of python3 >= 3.6. Aborting now"
    fi

    if [ $clean -eq 1 ]; then
        nvim_setup_clean
        exit 0
    fi

    nvim_setup_print_and_save_config

    if ! command -v nvim &> /dev/null; then
        nvim_setup_build_nvim_from_src
        nvim_setup_add_nvim_to_path
        nvim_setup_create_dirs
        nvim_setup_install_vimplug
        nvim_setup_install_python_3
        if [[ "${system_libclang}" == "${system_libclang_default}" ]]; then
            nvim_setup_download_libclang_binaries
        else
            nvim_setup_info "Using system libclang in: ${system_libclang}"
        fi
        nvim_setup_build_ccls
    fi

    if ! nvim_setup_check_cmd_in_path "nvim"; then
        nvim_setup_die 2 "Neovim still not found in PATH, exiting now!"
    fi

    if ! nvim_setup_check_cmd_in_path "ccls"; then
        nvim_setup_die 2 "CCLS still not found in PATH, exiting now!"
    fi

    nvim_setup_symlink_nvim_init_file
    nvim_setup_symlink_lang_client_json_settings_file
    nvim_setup_install_nvim_plugins

    ret=$?

    nvim_setup_info "Done!"

    return ${ret}
}

main "$@"
