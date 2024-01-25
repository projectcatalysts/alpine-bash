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
	if [[ -z "${HOST_USER+x}" ]]; then
	    HOST_USER="host"
	fi

	if user_exists ${HOST_UID}; then
	    echo "entrypoint.sh : user already exists : ${HOST_UID}"
	    return 0
	fi

	echo "entrypoint.sh : configuring user '${HOST_USER}' : ${HOST_UID}:${HOST_GID}..."

	addgroup -g ${HOST_GID} -S "${HOST_USER}"
	if [[ -d "/home/${HOST_USER}" ]]; then
	    echo "entrypoint.sh : adding user with existing home directory..."
		adduser --uid ${HOST_UID} --disabled-password --gecos "" --home "/home/${HOST_USER}" --ingroup ${HOST_USER} --no-create-home "${HOST_USER}" "${HOST_USER}"	
		chown ${HOST_UID}:${HOST_GID} "/home/${HOST_USER}"
	else
	    echo "entrypoint.sh : adding user and creating home directory..."
		adduser --uid ${HOST_UID} --disabled-password --gecos "" --home "/home/${HOST_USER}" --ingroup ${HOST_USER} "${HOST_USER}"
	fi
	export HOME="/home/${HOST_USER}"
	#
	# Ensure the user is not asked for a password when using sudo for the commands defined in sudoers_commands
	#
	local sudoers_commands=()
	if [[ "${HOST_USER_SUDO_APK:-}" == "REQUIRED" ]]; then
		echo "entrypoint.sh : configuring user '${HOST_USER}' for sudo : apk"
		local sudoers_commands+=('/sbin/apk')
	fi
	if [ ${#sudoers_commands[@]} -gt 0 ]; then
		# The user requires sudo privileges
		apk update
		apk add --no-cache sudo
		local c
		for c in "${sudoers_commands[@]}"; do
		    echo "${HOST_USER} ALL=(ALL) NOPASSWD:${c}" >> /etc/sudoers
		done
	fi
	return 0
}

# Create a user and group to match the host
if create_user_and_group; then
    echo "entrypoint.sh : switching to user '${HOST_USER}' (${HOST_UID}:${HOST_GID})..."
	# If there is no known_hosts file for the user, copy the known_hosts from the root user
	if [[ ! -f "/home/${HOST_USER}/.ssh/known_hosts" ]]; then
	    if [[ -f "/root/.ssh/known_hosts" ]]; then
			echo "entrypoint.sh : creating /home/${HOST_USER}/.ssh/known_hosts..."	
			if [[ ! -d "/home/${HOST_USER}/.ssh" ]]; then
				mkdir -p "/home/${HOST_USER}/.ssh"
			    chown ${HOST_UID}:${HOST_GID} "/home/${HOST_USER}/.ssh"
	    	fi
		    cp "/root/.ssh/known_hosts" "/home/${HOST_USER}/.ssh/known_hosts"
			chown ${HOST_UID}:${HOST_GID} "/home/${HOST_USER}/.ssh/known_hosts"
		fi
	fi
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