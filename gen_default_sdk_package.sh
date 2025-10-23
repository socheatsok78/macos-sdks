#!/usr/bin/env bash

GITHUB_WORKSPACE=${GITHUB_WORKSPACE:-$(pwd)}
OSXCROSS_WORKSPACE=${OSXCROSS_WORKSPACE:-${GITHUB_WORKSPACE}/osxcross}

# Clone or update osxcross repository (skip if running in CI)
if [[ -z "${CI}" ]]; then
	if [ ! -d "$OSXCROSS_WORKSPACE" ]; then
		git clone --depth=1 --single-branch https://github.com/tpoechtrager/osxcross.git "$OSXCROSS_WORKSPACE"
	fi
	(cd "$OSXCROSS_WORKSPACE" || exit 1; git pull)
fi

# Generate the SDK package using default Xcode
# Get macOS product version (major.minor)
PRODUCT_VERSION=$(sw_vers -productVersion | awk -F '.' '{print $1 "." $2}')
XCODEDIR="/Applications/Xcode.app" 

# Check if Xcode is installed
if [ ! -d "${XCODEDIR}" ]; then
	echo "::error::Xcode.app not found in /Applications. Please install Xcode."
	exit 1
fi

# Generate the SDK package
XCODEDIR="${XCODEDIR}" "${OSXCROSS_WORKSPACE}/tools/gen_sdk_package.sh"

# Check if the SDK package was created successfully
if [ ! -f "./MacOSX${PRODUCT_VERSION}.sdk.tar.xz" ]; then
	echo "::error::SDK package generation failed. The MacOSX${PRODUCT_VERSION}.sdk.tar.xz file not found."
	exit 1
fi

# Create tarballs directory if it doesn't exist
mkdir -p tarballs

# Move the generated SDK package to tarballs directory
mv "MacOSX${PRODUCT_VERSION}.sdk.tar.xz" tarballs/

# Generate SHA256 checksum
cd tarballs && {
	sha256sum "MacOSX${PRODUCT_VERSION}.sdk.tar.xz" > sha256sum.txt
	cd ..
}

# Cleanup unused tarballs
rm ./MacOSX*.sdk.tar.xz || true
