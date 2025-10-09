#!/usr/bin/env bash

GITHUB_WORKSPACE=${GITHUB_WORKSPACE:-$(pwd)}
OSXCROSS_WORKSPACE=${OSXCROSS_WORKSPACE:-${GITHUB_WORKSPACE}/osxcross}

# Find all installed Xcode in /Applications
XCODEDIRS=($(find /Applications -maxdepth 1 -type d -name "Xcode*.app" | sort))

# Loop through each Xcode path
for XCODEDIR in "${XCODEDIRS[@]}"; do
	export XCODEDIR
	${OSXCROSS_WORKSPACE}/tools/gen_sdk_package.sh
	unset XCODEDIR
done

# Move all generated tarballs and pkgs to a separate directory
mv ./*.tar.* ${OSXCROSS_WORKSPACE}/tarballs/
mv ./*.pkg ${OSXCROSS_WORKSPACE}/tarballs/ || true
