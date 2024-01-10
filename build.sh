#!/bin/bash

function build_alpine_bash {
    local readonly no_cache_flag=${1}
	local readonly package_name=${2}
	local readonly package_push=${3}
	local readonly package_version=${4}
    local readonly package_is_latest=${5:-}

    # Initialise docker environment
    procat_ci_docker_init

    local readonly base_image="${PROCAT_CI_REGISTRY_SERVER}/procat/docker/alpine-linux:${package_version}"
    local readonly build_args="--build-arg base_image=${base_image}"

    # Build the docker image
	procat_ci_docker_build_image ${no_cache_flag} ${package_name} ${package_push} ${package_version} ${package_is_latest} "${build_args}"
}

# configure_ci_environment is used to configure the CI environment variables
function configure_ci_environment {
    #
    # Check the pre-requisite environment variables have been set
    # PROCAT_CI_SCRIPTS_PATH would typically be set in .bashrc or .profile
    # 
    if [ -z ${PROCAT_CI_SCRIPTS_PATH+x} ]; then
        echo "ERROR: A required CI environment variable has not been set : PROCAT_CI_SCRIPTS_PATH"
        echo "       Has '~/.procat_ci_env.sh' been sourced into ~/.bashrc or ~/.profile?"
        env | grep "PROCAT_CI"
        return 1
    fi

    # Configure the build environment if it hasn't been configured already
    source "${PROCAT_CI_SCRIPTS_PATH}/set_ci_env.sh"
}

function build {
    #
    # configure_ci_environment is used to configure the CI environment variables
    # and load the CI common functions
    #
    configure_ci_environment || return $?

    # For testing purposes, default the package name
	if [ -z "${1-}" ]; then
        local package_name="${PROCAT_CI_REGISTRY_SERVER}/procat/docker/alpine-bash"
        pc_log "package_name (default)           : $package_name"
	else
		local package_name=${1}
        pc_log "package_name                     : $package_name"
    fi

    # For testing purposes, default the package version
	if [ -z "${2-}" ]; then
        local package_version="3.19.0"
        pc_log "package_version (default)        : $package_version"
	else
		local package_version=${2}
        pc_log "package_version                  : $package_version"
    fi
    pc_log ""

	# Determine whether the --no-cache command line option has been specified.
	# If it has, attempts to download files from the internet are always made.
	if [ -z "${3-}" ]; then
		local no_cache_flag="false"
	else
		local no_cache_flag=$([ "$3" == "--no-cache" ] && echo "true" || echo "false")
	fi

	build_alpine_bash ${no_cache_flag} ${package_name} push ${package_version} latest
}

# $1 : (Mandatory) Package Name (registry.projectcatalysts.prv/procat/docker/alpine-bash)
# $2 : (Mandatory) Package Version (e.g. 3.14.2)
# $3 : (Optional) --no-cache
build ${1:-} ${2:-} ${3:-}
