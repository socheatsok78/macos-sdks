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
if [[ "${SKIP_BETA_SDKS}" == "0" ]]; then
	echo "::warning::SKIP_BETA_SDKS is set to 0. Beta SDKs will be included."
fi

# Generate SDK packages for each Xcode installation
find /Applications -maxdepth 1 -type d -name "Xcode*.app" | sort | while IFS= read -r XCODEDIR; do
	if [[ "${SKIP_BETA_SDKS}" -eq 1 ]] && [[ "${XCODEDIR}" == *"beta"* ]]; then
		echo "skipping Xcode: ${XCODEDIR}"
		continue
	fi
	XCODEDIR="${XCODEDIR}" "${OSXCROSS_WORKSPACE}/tools/gen_sdk_package.sh"
done

# Loop through generated tarballs and move them to tarballs directory
# NOTE: Only the MAJOR.MINOR SDK versions are included, e.g., MacOSX26.0.sdk.tar.xz
#       anything else will be ignored.
for file in ./MacOSX*.*.sdk.tar.xz; do
	if [[ -f "$file" ]]; then
		_file=$(basename "$file")
		mv "$file" "${OSXCROSS_WORKSPACE}/tarballs/"
		(cd "${OSXCROSS_WORKSPACE}/tarballs" && sha256sum "${_file}" > "${_file}.sha256sum")
	fi
done
