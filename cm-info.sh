#!/usr/bin/env bash

# =====================================================
# cm-info.sh
# =====================================================
#
# Copyright 2017 Cloudera, Inc.
#
# DISCLAIMER
#
# Please note: This script is released for use "AS IS" without any warranties
# of any kind, including, but not limited to their installation, use, or
# performance. We disclaim any and all warranties, either express or implied,
# including but not limited to any warranty of noninfringement,
# merchantability, and/ or fitness for a particular purpose. We do not warrant
# that the technology will meet your requirements, that the operation thereof
# will be uninterrupted or error-free, or that any errors will be corrected.
#
# Any use of these scripts and tools is at your own risk. There is no guarantee
# that they have been through thorough testing in a comparable environment and
# we are not responsible for any damage or data loss incurred with their use.
#
# You are responsible for reviewing and testing any scripts you run thoroughly
# before use in any non-testing environment.

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

VER=1.2.0

# -------------------------------------------------------------------------
# <JSON.sh>
# Adapted from https://github.com/dominictarr/JSON.sh/blob/master/JSON.sh

throw() {
    echo "$*" >&2
    exit 1
}

JSON_tokenize () {
    local GREP

    if echo "test string" | grep -E -ao --color=never "test" >/dev/null 2>&1; then
        GREP='grep -E -ao --color=never'
    else
        GREP='grep -E -ao'
    fi

    local ESCAPE='(\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
    local CHAR='[^[:cntrl:]"\\]'

    local STRING="\"$CHAR*($ESCAPE$CHAR*)*\""
    local NUMBER='-?(0|[1-9][0-9]*)([.][0-9]*)?([eE][+-]?[0-9]*)?'
    local KEYWORD='null|false|true'
    local SPACE='[[:space:]]+'

    ${GREP} "$STRING|$NUMBER|$KEYWORD|$SPACE|." | grep -E -v "^$SPACE$"
}

JSON_parse () {
    read -r token
    JSON_parse_value
    read -r token
    case "$token" in
        '') ;;
        *) throw "EXPECTED EOF GOT $token" ;;
    esac
}

JSON_parse_value () {
    local jpath="${1:+$1,}${2:-}" isleaf=0 isempty=0 value=
    case "$token" in
        '{') JSON_parse_object "$jpath" ;;
        '[') JSON_parse_array  "$jpath" ;;
        # At this point, the only valid single-character tokens are digits.
        ''|[!0-9]) throw "EXPECTED value GOT ${token:-EOF}" ;;
        *) value=${token}
        isleaf=1
        [ "$value" = '""' ] && isempty=1
        ;;
    esac
    [ "$value" = '' ] && return
    [ "$isleaf" -eq 1 ] && [ ${isempty} -eq 0 ] && printf "[%s]\t%s\n" "$jpath" "$value"
    :
}

JSON_parse_array () {
    local index=0 ary=''
    read -r token
    case "$token" in
        ']') ;;
        *)
        while :; do
            JSON_parse_value "$1" "$index"
            index=$((index+1))
            ary="$ary""$value"
            read -r token
            case "$token" in
                ']') break ;;
                ',') ary="$ary," ;;
                *) throw "EXPECTED , or ] GOT ${token:-EOF}" ;;
            esac
            read -r token
        done
        ;;
    esac
}

JSON_parse_object () {
    local key
    local obj=''
    read -r token
    case "$token" in
        '}') ;;
        *)
        while :; do
            case "$token" in
                '"'*'"') key=${token} ;;
                *) throw "EXPECTED string GOT ${token:-EOF}" ;;
            esac
            read -r token
            case "$token" in
                ':') ;;
                *) throw "EXPECTED : GOT ${token:-EOF}" ;;
            esac
            read -r token
            JSON_parse_value "$1" "$key"
            obj="$obj$key:$value"
            read -r token
            case "$token" in
                '}') break ;;
                ',') obj="$obj," ;;
                *) throw "EXPECTED , or } GOT ${token:-EOF}" ;;
            esac
            read -r token
        done
        ;;
    esac
}

# </JSON.sh>
# -------------------------------------------------------------------------

function info() {
    echo "$(date) [$(tput setaf 2)INFO $(tput sgr0)] $*"
}

function err() {
    echo "$(date) [$(tput setab 1)ERROR$(tput sgr0)] $*"
}

function die() {
    err "$@"
    exit 2
}

function usage() {
    local SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
    echo
    echo "Cloudera Manager Info Collector v$VER"
    echo
    echo "$(tput bold)USAGE:$(tput sgr0)"
    echo "  ./${SCRIPT_NAME} [OPTIONS]"
    echo
    echo "$(tput bold)MANDATORY OPTIONS:$(tput sgr0)"
    echo "  $(tput bold)-h, --host $(tput sgr0)url"
    echo "        Cloudera Manager URL (e.g. http://cm-mycluster.com:7180)"
    echo
    echo "  $(tput bold)-u, --user $(tput sgr0)username"
    echo "        Cloudera Manager admin username"
    echo
    echo "$(tput bold)OPTIONS:$(tput sgr0)"
    echo "  $(tput bold)-p, --password $(tput sgr0)password"
    echo "        Cloudera Manager admin password. Will be prompted if unspecified."
    exit 1
}

function validate_cm_url() {
    local url_test
    local regex='(http|https?)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'

    if [[ ${OPT_URL} =~ $regex ]]; then
        url_test=$(curl -k --silent --head --fail "${OPT_URL}" || true)
        if [ ! -z "${url_test}" ]; then
            info "Cloudera Manager seems to be running"
        else
            die "Can't connect to Cloudera Manager. Check URL and firewalls."
        fi
    else
        err  "Invalid Cloudera Manager URL '$OPT_URL'"
        exit 1
    fi
}

function cleanup {
    rm -rf "${temp_dir}"
}

function cm_api_base() {
    local path="$1"
    shift
    curl -k -s -u "$OPT_USER:$OPT_PASSWORD" "$OPT_URL/api/$path" "$@"
}

function cm_api() {
    local path="$1"
    shift
    cm_api_base "$api_ver/$path" "$@"
}

function get_cm_config() {
    info "Getting Cloudera Manager config"
    cm_api "cm/config?view=full" > "$tar_dir/cm_config.json"
}

function get_cm_role_configs() {
    info "Getting Cloudera Manager role configs"
    for role in $(cm_api cm/service/roles | JSON_tokenize | JSON_parse | grep roleConfigGroupName | cut -f8 -d '"' | sort -u); do
        info " - Getting role config for $role"
        cm_api "cm/service/roleConfigGroups/$role/config?view=full" > "$tar_dir/cm_service_config_$role.json"
    done
}

function get_deployment_configs() {
    info "Getting redacted deployment configs"
    cm_api "cm/deployment?view=export_redacted" > "$tar_dir/cm_deployment.json"
}

function get_cluster_configs() {
    local cluster_list=$(cm_api clusters | JSON_tokenize | JSON_parse | grep 'displayName' | cut -f6 -d '"')
    IFS=$'\n'
    for cluster in ${cluster_list}; do
        unset IFS
        info "Processing $cluster..."

        # URL encode spaces in cluster name
        cluster_url="${cluster// /%20}"
        mkdir -p "$tar_dir/$cluster"

        local services=$(cm_api "clusters/$cluster_url/services" | JSON_tokenize | JSON_parse | grep 'name' | cut -f6 -d'"' | grep -v 'name' | sort)
        for service in $services; do
            info " - Getting service config for $service"
            cm_api "clusters/$cluster_url/services/$service/config?view=full" > "$tar_dir/$cluster/service_config_$service.json"
            for role in $(cm_api "clusters/$cluster_url/services/$service/roles" | JSON_tokenize | JSON_parse | grep 'roleConfigGroupName' | cut -f8 -d '"' | sort -u); do
                cm_api "clusters/$cluster_url/services/$service/roleConfigGroups/$role/config?view=full" > "$tar_dir/$cluster/service_config_${service}_$role.json"
            done
        done

        for host in $(cm_api "clusters/$cluster_url/hosts" | JSON_tokenize | JSON_parse | grep 'hostId' | cut -f6 -d '"'); do
            host_json=$(cm_api "hosts/$host")
            hostname=$(echo "$host_json" | JSON_tokenize | JSON_parse | grep hostname | cut -f4 -d '"')
            info " - Got host config for $hostname"
            echo "$host_json" > "$tar_dir/$cluster/host_$hostname.json"
        done
    done
}

function create_tarball() {
    local tarball="${tar_basename}.tar.bz2"
    tar jcf "$tarball" -C "${temp_dir}" "${tar_basename}"
    info "Wrote to $tarball"
}

OPT_USAGE=
OPT_URL=
OPT_USER=
OPT_PASSWORD=

if [[ $# -eq 0 ]]; then
    usage
    die
fi

while [[ $# -gt 0 ]]; do
    KEY=$1
    shift
    case ${KEY} in
        -h|--host)     OPT_URL="$1";      shift;;
        -u|--user)     OPT_USER="$1";     shift;;
        -p|--password) OPT_PASSWORD="$1"; shift;;
        --help)        OPT_USAGE=true;;
        *)             OPT_USAGE=true
                       err "Unknown option: ${KEY}"
                       break;;
    esac
done

if [[ -z ${OPT_URL} ]]; then
    die "Missing Cloudera Manager URL. See usage."
elif [[ -z ${OPT_USER} ]]; then
    die "Missing Cloudera Manager username. See usage."
elif [[ ${OPT_USAGE} ]]; then
    usage
else
    validate_cm_url
	if [[ -z ${OPT_PASSWORD} ]]; then
        read -r -s -p "Enter password: " OPT_PASSWORD
        echo
	fi
fi

hostname=$(basename ${OPT_URL})
hostname=$(echo ${hostname} | cut -d':' -f1)
tar_base=${hostname}

temp_dir=$(mktemp -d)
trap cleanup EXIT
if [ ! "${temp_dir}" ] || [ ! -d "${temp_dir}" ]; then
    die "Can't create temp directory"
fi

tar_basename="${tar_base}".$(date '+%Y%m%d-%H%M')
tar_dir="${temp_dir}/${tar_basename}"
mkdir -p "$tar_dir"

api_ver=$(cm_api_base version)

get_cm_config
get_cm_role_configs
get_deployment_configs
get_cluster_configs
create_tarball
