#!/bin/bash

set -eu

# user_exists returns zero if the UID exists
function user_exists {
	[[ -n $(getent passwd "$1" 2>/dev/null) ]] && return 0 || return 1;
}

# Create a user and group to match the host
function create_user_and_group {
	if [[ -z "${HOST_UID+x}" ]] || [[ -x "${HOST_GID+x}" ]]; then
		local readonly DEFAULT_UID=$(id -u)
		local readonly DEFAULT_GID=$(id -g)
		echo "entrypoint.sh : running as default user ${DEFAULT_UID}:${DEFAULT_GID}..."
		return 1
	fi
	if [[ -z "${HOST_UNAME+x}" ]]; then
	    HOST_UNAME="host"
	fi

	if user_exists ${HOST_UID}; then
	    echo "entrypoint.sh : user already exists : ${HOST_UID}"
	    return 0
	fi

	echo "entrypoint.sh : configuring user '${HOST_UNAME}' : ${HOST_UID}:${HOST_GID}..."

	addgroup -g ${HOST_GID} -S "${HOST_UNAME}"
	if [[ -d "/home/${HOST_UNAME}" ]]; then
	    echo "entrypoint.sh : adding user with existing home directory..."
		adduser --uid ${HOST_UID} --disabled-password --gecos "" --home "/home/${HOST_UNAME}" --ingroup ${HOST_UNAME} --no-create-home "${HOST_UNAME}" "${HOST_UNAME}"	
		chown ${HOST_UID}:${HOST_GID} "/home/${HOST_UNAME}"
		if [[ -d "/home/${HOST_UNAME}/.ssh" ]]; then
		    chown ${HOST_UID}:${HOST_GID} "/home/${HOST_UNAME}/.ssh"
	    fi
	else
	    echo "entrypoint.sh : adding user and creating home directory..."
		adduser --uid ${HOST_UID} --disabled-password --gecos "" --home "/home/${HOST_UNAME}" --ingroup ${HOST_UNAME} "${HOST_UNAME}"
	fi
	export HOME="/home/${HOST_UNAME}"
	return 0
}

# Create a user and group to match the host
if create_user_and_group; then
    echo "entrypoint.sh : switching to user '${HOST_UNAME}' (${HOST_UID}:${HOST_GID})..."
	if [[ $# -gt 0 ]]; then
		exec su-exec ${HOST_UID} "$@"
	else
		exec su-exec ${HOST_UID} bash
	fi
else
	if [[ $# -gt 0 ]]; then
		exec -- "$@"
	else
		exec -- bash
	fi
fi