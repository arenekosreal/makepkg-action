#!/usr/bin/bash

set -e -o pipefail

declare -ra SUDO=(sudo -u builder)
declare -ra GPG=(gpg --batch --yes)
declare -ra CP=(cp -a --no-preserve=ownership)
declare -ra MAKEPKG=(makepkg --syncdeps --noconfirm)
declare -r STARTDIR=/startdir

if [[ -e "$GITHUB_WORKSPACE/$INPUT_REPO/$INPUT_REPO_NAME.db" ]] \
&& ! pacman-conf --repo="$INPUT_REPO_NAME" > /dev/null 2>&1
then
    echo "Adding custom repository:"
    {
        echo "[$INPUT_REPO_NAME]"
        echo "Server = file://$GITHUB_WORKSPACE/$INPUT_REPO"
        echo "SigLevel = Optional TrustAll"
    } | tee -a /etc/pacman.conf
fi

if [[ ! -d /etc/pacman.d/gnupg ]]
then
    pacman-key --init
    pacman-key --populate
fi

pacman -Syu --noconfirm

if [[ -d "$INPUT_STARTDIR/keys/pgp" ]]
then
    find "$INPUT_STARTDIR/keys/pgp" -maxdepth 1 -mindepth 1 -type f -name "*.asc" \
        -printf "Importing %f...\n" \
        -exec "${SUDO[@]}" "${GPG[@]}" --import {} \;
fi

if [[ -d "$GITHUB_WORKSPACE/$INPUT_SRCDEST" ]]
then
    "${SUDO[@]}" "${CP[@]}" "$GITHUB_WORKSPACE/$INPUT_SRCDEST/"* /srcdest
fi
"${SUDO[@]}" "${CP[@]}" "$GITHUB_WORKSPACE/$INPUT_STARTDIR/"* /startdir

declare preserve_env="BUILDDIR,PKGDEST,SRCDEST,LOGDEST,SOURCE_DATE_EPOCH,BUILDTOOL,BUILDTOOLVER"
if [[ -n "$INPUT_PRESERVE_ENV" ]]
then
    preserve_env+=",$INPUT_PRESERVE_ENV"
fi

export BUILDDIR=/build PKGDEST=/pkgdest SRCDEST=/srcdest LOGDEST=/logdest

mkdir -p "$(dirname "$GITHUB_WORKSPACE/$INPUT_STDOUT")"
cd "$STARTDIR"
"${SUDO[@]}" "--preserve-env=$preserve_env" \
    "${MAKEPKG[@]}" "$@" | tee "$GITHUB_WORKSPACE/$INPUT_STDOUT"
cd -

rm -rf "${GITHUB_WORKSPACE:?}/$INPUT_PKGDEST" \
       "${GITHUB_WORKSPACE:?}/$INPUT_LOGDEST" \
       "${GITHUB_WORKSPACE:?}/$INPUT_SRCDEST" \
       "${GITHUB_WORKSPACE:?}/$INPUT_STARTDIR/"*
mkdir -p "$GITHUB_WORKSPACE/$INPUT_PKGDEST" \
         "$GITHUB_WORKSPACE/$INPUT_LOGDEST" \
         "$GITHUB_WORKSPACE/$INPUT_SRCDEST" \
         "$GITHUB_WORKSPACE/$INPUT_STARTDIR"
find $PKGDEST -mindepth 1 -maxdepth 1 -type f -name "*.pkg.tar.*" \
    -exec "${CP[@]}" -v -t "$GITHUB_WORKSPACE/$INPUT_PKGDEST" {} +
find $LOGDEST -mindepth 1 -maxdepth 1 -type f -name "*.log" \
    -exec "${CP[@]}" -v -t "$GITHUB_WORKSPACE/$INPUT_LOGDEST" {} +
find $SRCDEST -mindepth 1 \
    -exec "${CP[@]}" -v -t "$GITHUB_WORKSPACE/$INPUT_SRCDEST" {} +
find $STARTDIR -mindepth 1 -maxdepth 1 -type f \
    -exec "${CP[@]}" -v -t "$GITHUB_WORKSPACE/$INPUT_STARTDIR" {} +
