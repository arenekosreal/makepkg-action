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

## Inputs

- builddir

  Required: true

  Description: The directory which is relative to github.workspace and contains PKGBUILD.

- args

  Required: false

  Description: The arguments to makepkg.

- env:

  Required: false

  Description: The extra enironments splitted in newline.

- stdout:

  Required: false

  Description: Where to save stdout

- repo:

  Required: false

  Description: Custom repository to storage extra depends.

- updatepkgbuild

  Required: false

  Description: If sync updated PKGBUILD to builddir. Useful when you just bump pkgver.

  Default: false

## FAQ

- Why I need this even ubuntu has `pacman`?

  Trust me, you do not want to mix files managed by pacman and apt-get together.

- Any extra tips?

  If you want to cache `srcdest`, Run `sudo chown -R $(id -u):$(id -g) srcdest` before caching it.
  Or you will find that your files of that directory's owner may become root, and there may have issue when recovering cache.

  See also:

  https://github.com/actions/runner/issues/1282 
