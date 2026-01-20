# makepkg-action

Launch `makepkg` in an archlinux-like OS.

## Status

[![Test action](https://github.com/arenekosreal/makepkg-action/actions/workflows/test.yml/badge.svg)](https://github.com/arenekosreal/makepkg-action/actions/workflows/test.yml)

## Features

- Multi-arch support

  You can run this action with `x86_64` and `aarch64` architectures.

  How to:

  Set `runs-on` with proper value like `ubuntu-24.04` or `ubuntu-24.04-arm`, but the latter is only available for public repository now.

- No AUR helper like yay/paru

  Everything is built with a minimal archliux-like OS with `base-devel`, `base` and dependencies specified in `PKGBUILD`.
  Not-in-official-repository dependencies will be installed from a custom repository so pacman can find it directly.

  This means you have to prepare a custom pacman repository yourself to storage those dependencies.
  You can install `pacman-package-manager` and `libarchive-tools` on Ubuntu 24.04 and later, then you can use `repo-add` like what you do on archlinux.
  On those elder runners, you have to build and install pacman yourself.

> [!WARNING]
> Singnatures of packages are not checked. Please ensure you are using those extra dependencies from trusted source.

## Inputs

```yaml
  startdir:
    description: Where is the directory contains PKGBUILD
    required: false
    default: startdir
  pkgdest:
    description: Where to storage built packages
    required: false
    default: pkgdest
  srcdest:
    description: Where to storage downloaded sources
    required: false
    default: srcdest
  logdest:
    description: Where to storage build logs
    required: false
    default: logdest
  args:
    description: The arguments to makepkg.
    required: false
    default: --log
  repo:
    description: Where to storage extra dependencies
    required: false
    default: repo
  repo-name:
    description: The name of repository
    required: false
    default: repo
  preserve-env:
    description: Comma-seperated environment variable list to be passed to makepkg.
    required: false
```

## Outputs

```yaml
  stdout-path:
    description: The path to file in ${{ github.workspace }} contains stdout of makepkg
```

## Examples

```yaml
# Just build the PKGBUILD in ${{ github.workspace }}/startdir
- uses: arenekosreal/makepkg-action@v0.4.0

# Build the PKGBUILD in directory specified
- uses: arenekosreal/makepkg-action@v0.4.0
  with:
    startdir: example # build the PKGBUILD in ${{ github.workspace }}/example
    
# Generate .SRCINFO
- uses: arenekosreal/makepkg-action@v0.4.0
  with:
    startdir: example
    args: --printsrcinfo
    stdout: example/.SRCINFO
```

## FAQ

- Why I need this even ubuntu has `pacman`?

  Trust me, you do not want to mix files managed by pacman and apt-get together.

- Any extra tips?

  If you want to cache generated directory like `srcdest`, etc, you need to run `sudo chown -R $(id -u):$(id -g) srcdest` before caching it.
  Or you will find that your files of that directory's owner may become root, and there may have issue when recovering cache.

  See also:

  https://github.com/actions/runner/issues/1282 
