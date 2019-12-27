#!/bin/bash

dry_run=0
verbose=0
git_rev=

nvim_update_usage()
{
    cat << EOF
Usage $(basename $0) [OPTIONS]

Where OPTIONS:
    -d, --dry-run           Don't execute any commands. Instead, print out on standard output
    -h, --help              Show this help and exit
    -r, --revision [SHASUM] Desired neovim revision from Git
    -v, --verbose           Run the script with verbosity
EOF
}

nvim_update_parse_opts()
{
    local _args
    local _opts
    
    _args="$@"
    _opts=$(getopt -o dhr:v \
        --long help \
        --long dry-run \
        --long revision:\
        --long verbose \
        -- ${_args})
    [ $? -ne 0 ] && return 1
    eval set -- ${_opts}
    while true; do
        case $1 in
            -d|--dry-run)
                dry_run=1
                ;;
            -h|--help)
                nvim_update_usage
                exit 0
                ;;
            -r|--revision)
                shift
                git_rev="$1"
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

    return 0
}

# Wrapper around the shared command executor
nvim_update_exec_cmd()
{
    nvim_cmn_exec_cmd ${dry_run} ${verbose} "$@"
}

nvim_update_checkout_revision()
{
    local _rev
    _rev="$1"

    nvim_update_exec_cmd git reset --hard ${_rev}
}

nvim_update_nvim()
{
    # Get latest nvim source/install dirs
    local _nvim_src_dir
    local _nvim_install_dir
    local _cpus

    _nvim_install_dir=$(\grep ^nvim_build_dir= ${nvim_setup_status_file} | cut -d= -f2)
    _nvim_src_dir=$(\grep ^nvim_src_dir= ${nvim_setup_status_file} | cut -d= -f2)

    _cpus=$(nvim_cmn_get_nr_cpus)

    nvim_cmn_info "Entering $_nvim_src_dir"
    nvim_update_exec_cmd pushd "$_nvim_src_dir"

    nvim_cmn_info "Cleaning previous build"
    nvim_update_exec_cmd make distclean

    if [[ -n "${git_rev}" ]]; then
        nvim_cmn_info "Checking out revision ${git_rev}"
        nvim_update_checkout_revision ${git_rev}
    fi

    nvim_cmn_info "Building neovim + deps"
    nvim_update_exec_cmd make -j${_cpus} CMAKE_INSTALL_PREFIX=$_nvim_install_dir

    nvim_cmn_info "Installing neovim in $_nvim_install_dir"
    nvim_update_exec_cmd make install
    nvim_update_exec_cmd popd
}

main()
{ 
    source files/nvim-common.src

    if ! nvim_update_parse_opts "$@"; then
        nvim_cmn_die 1 "Error parsing options, exiting now!"
    fi

    if [[ ! -f ${nvim_setup_status_file} ]]; then
        nvim_cmn_die 2 "No previous installation was run (did you forget to run the nvim-setup.sh first?)"
    fi

    nvim_update_nvim
}

main "$@"
