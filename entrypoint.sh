#!/usr/bin/bash

set -e

export BUILDDIR=/build PKGDEST=/pkgdest SRCDEST=/srcdest

declare PKGDEST_ROOT="$GITHUB_WORKSPACE$PKGDEST" \
        SRCDEST_ROOT="$GITHUB_WORKSPACE$SRCDEST" \
        BUILDDIR_ROOT="$GITHUB_WORKSPACE$INPUT_BUILDDIR"
mkdir -p "$SRCDEST_ROOT" "$PKGDEST_ROOT"

declare SUDO="/usr/bin/sudo -u builder \
           --preserve-env=BUILDDIR \
           --preserve-env=PKGDEST  \
           --preserve-env=SRCDEST  \
           --preserve-env=SOURCE_DATE_EPOCH"
declare GPG="/usr/bin/gpg --batch --yes"

# __log $level $msg
function __log() {
    if [[ $# -lt 2 ]]
    then
        __log error "Invalid arguments for __log. Expect >=2, got $#."
        return 1
    fi
    case "$1" in
        warning|notice|error)
            local -a context
            read -r -a context < <(caller)
            echo "::$1 file=${context[0]},line=${context[1]}::$2"
            ;;
        debug)
            echo "::$1::$2"
            ;;
        *)
            echo "$2"
            ;;
    esac
}

# __ensure_pkgbuild $dir
function __ensure_pkgbuild() {
    if [[ $# -lt 1 ]]
    then
        __log error "Invalid arguments for __ensure_pkgbuild. Expect >=1, got $#."
        return 1
    fi
    if [[ ! -f "$1/PKGBUILD" ]]
    then
        __log error "No PKGBUILD can be found at $1/"
        return 1
    fi
}

# __check_pacman_key
function __check_pacman_key() {
    __log info "Checking pacman-key..."
    if [[ ! -d /etc/pacman.d/gnupg ]]
    then
        pacman-key --init
        pacman-key --populate
    fi
}

# __append_extra_env $env
# WARN: Will modify existing SUDO variable.
# Use it in subshell instead.
function __append_extra_env() {
    if [[ $# -lt 1 ]]
    then
        __log error "Invalid arguments for __append_extra_env. Expect >=1, got $#."
        return 1
    fi
    local env_line
    while read -r env_line
    do
        if [[ "$env_line" =~ ^[a-zA-Z_][0-9a-zA-Z_]*=.* ]]
        then
            local key value
            key="$(echo "$env_line" | cut -d = -f 1 | xargs)"
            value="$(echo "$env_line" | cut -d = -f 2- | xargs)"
            __log info "Exporting environment $key=$value now..."
            export "$key=$value"
            SUDO+=" --preserve-env=$key"
        else
            __log debug "Invalid environment $env_line, skipping..."
        fi
    done <<< "$1"
}

# __prepare_build_environment
function __prepare_build_environment() {
    __log info "Syncing $BUILDDIR_ROOT to $BUILDDIR..."
    $SUDO cp -r "$BUILDDIR_ROOT/." "$BUILDDIR"
    __ensure_pkgbuild "$BUILDDIR"
    __log info "Syncing $SRCDEST_ROOT to $SRCDEST..."
    $SUDO cp -r "$SRCDEST_ROOT/." "$SRCDEST"
    __check_pacman_key
    if [[ -d keys/pgp ]]
    then
        __log info "Importing GnuPG public keys..."
        # shellcheck disable=SC2086
        find keys/pgp -maxdepth 1 -mindepth 1 -type f -regex ".+\.asc$" \
            -exec $SUDO $GPG --import {} \;
    fi
    if [[ -n "$INPUT_REPO" ]] && [[ -e "$GITHUB_WORKSPACE/$INPUT_REPO/$INPUT_REPO.db" ]] && [[ -e "$GITHUB_WORKSPACE/$INPUT_REPO/$INPUT_REPO.files" ]] && ! pacman-conf --repo="$INPUT_REPO" > /dev/null
    then
        __log info "Adding repository at $GITHUB_WORKSPACE/$INPUT_REPO..."
        echo -e "[$INPUT_REPO]\nServer = file://$GITHUB_WORKSPACE/$INPUT_REPO\nSigLevel = Optional TrustAll" | tee -a /etc/pacman.conf
    fi
    pacman -Sy
}

# __post_call_makepkg
function __post_call_makepkg() {
    __log info "Syncing $SRCDEST to $SRCDEST_ROOT..."
    cp -a --no-preserve=ownership "$SRCDEST/." "$SRCDEST_ROOT"
    find "$PKGDEST" -maxdepth 1 -mindepth 1 -type f -regex '.+\.pkg\.tar\.[0-9a-zA-Z]+$' \
        -exec cp --no-preserve=ownership -t "$PKGDEST_ROOT" {} +
}

__prepare_build_environment
(
    pushd "$BUILDDIR"
    __append_extra_env "$INPUT_ENV"
    declare MAKEPKG="$SUDO /usr/bin/makepkg $1"
    __log debug "Invoking $MAKEPKG..."
    if [[ -n "$INPUT_STDOUT" ]]
    then
        $MAKEPKG > "$GITHUB_WORKSPACE/$INPUT_STDOUT"
    else
        $MAKEPKG
    fi
    popd
)
__post_call_makepkg
