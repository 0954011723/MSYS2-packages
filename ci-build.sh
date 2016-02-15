#!/bin/bash

# AppVeyor and Drone Continuous Integration for MSYS2
# Author: Renato Silva <br.renatosilva@gmail.com>
# Author: Qian Hong <fracting@gmail.com>

# Functions
success() { echo "Build success: ${@}"; exit 0; }
failure() { echo "Build failure: ${@}"; exit 1; }

# Prepare
gitmail="$(git config --global user.email)"
gitname="$(git config --global user.name)"
gitrevert() { git config --global user.email "${gitmail}"; git config --global user.name "${gitname}" }
trap gitrevert EXIT
git config --global user.email 'ci@msys2.org'
git config --global user.name 'MSYS2 Continuous Integration'

# Detect
cd "$(dirname "$0")"
files=($(git show --pretty=format: --name-only $(git log -1 --pretty=format:%P | cut -d' ' -f1)..HEAD | sort -u))
for file in "${files[@]}"; do
    [[ "${file}" = */PKGBUILD ]] && recipes+=("${file%/PKGBUILD}")
done
test -n "${files}"   || failure 'Could not detect changed files.'
test -z "${recipes}" && success 'No changes in package recipes.'
echo
echo "Going to build changed recipes: ${recipes[@]}"
echo

# Refresh
# ignore cache, force refresh database
pacman --sync --refresh --refresh --sysupgrade --noconfirm --noprogressbar

# Build
for recipe in "${recipes[@]}"; do
    cd "${recipe}"
    echo
    echo "Build recipe: ${recipe}"
    echo
    makepkg --syncdeps --noconfirm --noprogressbar --noextract --noprepare --nobuild || failure "Could not install deps for ${recipe}."
    echo
    makepkg --skippgpcheck --nocheck || failure "Could not build ${recipe}."
    cd - > /dev/null
done

# Install
pacman --upgrade --noconfirm */*.pkg.tar.xz
