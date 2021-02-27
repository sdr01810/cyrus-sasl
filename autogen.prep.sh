#!/bin/bash
## Prepare for autogen: installs expected packages
##
## Typical use:
##
##     ./autogen.prep.sh
##
##     ./autogen.sh --prefix=/opt/cyrus-sasl
##

set -e

set -o pipefail

##
## from <https://github.com/sdr01810/snippets--sh>:
## 

function check_os_package_format_is() { # value

	local value=${1:?missing value} ; shift 1

	local value_actual=$(get_os_package_format)

	case "${value_actual}" in
	("${value:?}")
		;;
	('')
		echo 1>&2 "$(get_script_message_prefix)cannot determine OS package format"
		return 2
	(*)
		echo 1>&2 "$(get_script_message_prefix)unsupported OS package format: ${value_actual:?}"
		return 2
	esac
}

function get_os_package_format() {

	local result=

	if false ; then :
	elif os_release_is_like debian ; then

		result=deb

	elif os_release_is_like fedora ; then

		result=rpm
	fi

	echo "${result}"
}

function get_os_release() { # variable_name ...

	local os_release_fpn=/etc/os-release

	[[ -e ${os_release_fpn} ]] || return 2

	##

	local variable_name

	for variable_name in "$@" ; do
	(
		source "${os_release_fpn:?}" || return $?

		echo ${!variable_name}
	)
	done
}

function get_script_message_prefix() {

	local result=$(get_script_name)

	echo "${result}${result:+: }"
}

function get_script_name() {

	local result=

	result=${result:-${this_script_name}}
	#^-- programming convention

	result=${result:-${0}}
	#^-- platform convention

	echo "${result}"
}

function install_package() { # [package_name...]

	if [ $# -gt 0 ] ; then
	(
		## for environment variable settings:
		## <https://wiki.debian.org/Multistrap/Environment>

		export DEBCONF_NONINTERACTIVE_SEEN=true
		export DEBIAN_FRONTEND=noninteractive

		export LC_ALL=C LANGUAGE=C LANG=C

		set -x

		sudo_pass_through apt-get --quiet --yes install "$@"
	)
	fi
}

function os_release_is_like() { # value

	local value=${1:?missing value} ; shift 1

	local result=false # unless proven otherwise

	if false ; then :
	elif [[ -f /etc/${value:?}_version ]] ; then

		# archetype: /etc/debian_version

		result=true

	elif [[ -f /etc/${value:?}-release ]] ; then

		# archetype: /etc/fedora-release

		result=true

	elif [[ ": $(get_os_release ID) :" == :" ${value:?} ": ]] ; then

		result=true

	elif [[ ": $(get_os_release ID_LIKE) :" == :*" ${value:?} "*: ]] ; then

		result=true
	fi

	"${result:?}"
}

function sudo_pass_through() { # ...

	if [ "$(id -u)" -ne 0 ] ; then

		sudo "$@"
		return $?
	fi

	while [ $# -gt 0 ] ; do
	case "${1}" in
	--)
		shift 1
		;;
	-*|-)
		(unset error ; : "${error:?unsupported sudo(8) option: ${1}}")
		return $?
		;;
	*)
		break
		;;
	esac;done

	"$@"
}

function xx() { # ...

	echo 1>&2 "${PS4:-+}" "$@"

	"$@"
}

##
## core logic:
##

function setup_build_env_for_cyrus_sasl() {

	local packages=()

	local rig_for_basic_build=true

	local rig_for_running_tests=false # TODO: make default true

	! "${rig_for_basic_build:?}" || packages+=(

		build-essential

		autoconf
		autoconf-doc
		autogen
		autogen-doc
		automake
		autotools-dev
		libtool
		libtool-doc
	)

	! "${rig_for_running_tests:?}" || packages+=(

		libnss-wrapper
		libsocket-wrapper

		krb5-kdc
		krb5-doc

		#^-- TODO: confirm all packages needed to run tests have been specified
	)

	install_package "${packages[@]}"
}

function main() {

	check_os_package_format_is deb
	#^-- TODO: add support for rpm-based systems

	setup_build_env_for_cyrus_sasl
}

! [[ ${0} == ${BASH_SOURCE} ]] || main "$@"

