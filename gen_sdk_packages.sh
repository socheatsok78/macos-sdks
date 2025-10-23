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

# Flag to skip beta SDKs (default: 1)
SKIP_BETA_SDKS=${SKIP_BETA_SDKS:-1}

# Find all installed Xcode in /Applications
XCODEDIRS=($(find /Applications -maxdepth 1 -type d -name "Xcode*.app" | sort))

# Generate SDK packages for each Xcode installation
for XCODEDIR in "${XCODEDIRS[@]}"; do
	if [[ "${SKIP_BETA_SDKS}" -eq 1 ]] && [[ "${XCODEDIR}" == *"beta"* ]]; then
		echo "[INFO] Skipping Xcode: ${XCODEDIR}"
		continue
	fi
	XCODEDIR=${XCODEDIR} "${OSXCROSS_WORKSPACE}/tools/gen_sdk_package.sh"
done

# Move all generated tarballs and pkgs to a separate directory
mv ./*.tar.* "${OSXCROSS_WORKSPACE}/tarballs/"
