#!/bin/bash
#
# RoktUXHelper Size Measurement Script
#
# Builds two otherwise-identical iOS apps and measures the size difference:
#   - SizeTestApp            — a bare SwiftUI app with no dependencies (baseline)
#   - SizeTestAppWithUXHelper — the same app plus the RoktUXHelper dependency
#
# The with-helper app references RoktUXHelper via a local SPM package pointing at
# the repository root, so source changes are picked up automatically. The library
# links statically, so its footprint shows up in the app's main executable and in
# any bundled resources. The "helper impact" is the app-bundle size delta between
# the two apps — an indicative figure for partners integrating the SDK.
#
# Usage: ./measure_size.sh [--json] [--with-helper-only]
#
#   --json               Output results as a single line of JSON (for CI)
#   --with-helper-only   Only build and measure the with-helper app
#

# SC2311/SC2312: these helpers echo a fallback value and their exit status is
# intentionally not propagated; the script targets macOS /bin/bash 3.2.
# shellcheck disable=SC2311,SC2312

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
DERIVED_DATA_DIR="${BUILD_DIR}/DerivedData"

OUTPUT_JSON=false
WITH_HELPER_ONLY=false
for arg in "$@"; do
	case ${arg} in
	--json) OUTPUT_JSON=true ;;
	--with-helper-only) WITH_HELPER_ONLY=true ;;
	*)
		echo "Unknown argument: ${arg}" >&2
		exit 1
		;;
	esac
done

rm -rf "${BUILD_DIR}"
mkdir -p "${DERIVED_DATA_DIR}"

# Size of a directory in KB (0 if missing).
get_dir_size_kb() {
	local dir_path="$1"
	if [[ -d ${dir_path} ]]; then
		du -sk "${dir_path}" 2>/dev/null | cut -f1
	else
		echo "0"
	fi
}

# Size of a file in bytes (0 if missing).
get_file_size_bytes() {
	local file_path="$1"
	if [[ -f ${file_path} ]]; then
		stat -f%z "${file_path}" 2>/dev/null || stat -c%s "${file_path}" 2>/dev/null || echo "0"
	else
		echo "0"
	fi
}

# Build an app, archiving into its own DerivedData. All xcodebuild output goes to
# stderr so stdout stays clean for JSON.
build_app() {
	local project_path="$1"
	local scheme="$2"
	local archive_path="$3"
	local derived_data_path="$4"

	echo "Building ${scheme}..." >&2

	xcodebuild archive \
		-project "${project_path}" \
		-scheme "${scheme}" \
		-configuration Release \
		-destination "generic/platform=iOS" \
		-archivePath "${archive_path}" \
		-derivedDataPath "${derived_data_path}" \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		ONLY_ACTIVE_ARCH=NO \
		-quiet >&2 2>&1 || {
		echo "Warning: Archive failed, falling back to build..." >&2
		xcodebuild build \
			-project "${project_path}" \
			-scheme "${scheme}" \
			-configuration Release \
			-destination "generic/platform=iOS" \
			-derivedDataPath "${derived_data_path}" \
			CODE_SIGN_IDENTITY="-" \
			CODE_SIGNING_REQUIRED=NO \
			CODE_SIGNING_ALLOWED=NO \
			ONLY_ACTIVE_ARCH=NO \
			-quiet >&2 2>&1
	}
}

# Resolve the built .app, preferring the archive then DerivedData.
find_app() {
	local name="$1"
	local archive="${BUILD_DIR}/${name}.xcarchive/Products/Applications/${name}.app"
	if [[ -d ${archive} ]]; then
		echo "${archive}"
	else
		find "${DERIVED_DATA_DIR}/${name}" -name "${name}.app" -type d 2>/dev/null | head -1 || true
	fi
}

# Build baseline app (unless --with-helper-only).
BASELINE_SIZE_KB=0
BASELINE_EXECUTABLE_SIZE=0
if [[ ${WITH_HELPER_ONLY} == "false" ]]; then
	build_app \
		"${SCRIPT_DIR}/SizeTestApp/SizeTestApp.xcodeproj" \
		"SizeTestApp" \
		"${BUILD_DIR}/SizeTestApp.xcarchive" \
		"${DERIVED_DATA_DIR}/SizeTestApp"

	BASELINE_APP="$(find_app "SizeTestApp")"
	if [[ -d ${BASELINE_APP} ]]; then
		BASELINE_SIZE_KB=$(get_dir_size_kb "${BASELINE_APP}")
		BASELINE_EXECUTABLE_SIZE=$(get_file_size_bytes "${BASELINE_APP}/SizeTestApp")
	fi
fi

# Build with-helper app.
build_app \
	"${SCRIPT_DIR}/SizeTestAppWithUXHelper/SizeTestAppWithUXHelper.xcodeproj" \
	"SizeTestAppWithUXHelper" \
	"${BUILD_DIR}/SizeTestAppWithUXHelper.xcarchive" \
	"${DERIVED_DATA_DIR}/SizeTestAppWithUXHelper"

WITHHELPER_APP="$(find_app "SizeTestAppWithUXHelper")"
WITHHELPER_SIZE_KB=0
WITHHELPER_EXECUTABLE_SIZE=0
if [[ -d ${WITHHELPER_APP} ]]; then
	WITHHELPER_SIZE_KB=$(get_dir_size_kb "${WITHHELPER_APP}")
	WITHHELPER_EXECUTABLE_SIZE=$(get_file_size_bytes "${WITHHELPER_APP}/SizeTestAppWithUXHelper")
fi

# RoktUXHelper links statically, so report any bundled resources it ships
# (e.g. a resource bundle) as a best-effort figure.
RESOURCE_BUNDLE_KB=0
if [[ -d ${WITHHELPER_APP} ]]; then
	RB="$(find "${WITHHELPER_APP}" -name "*RoktUXHelper*.bundle" -type d 2>/dev/null | head -1 || true)"
	if [[ -n ${RB} ]] && [[ -d ${RB} ]]; then
		RESOURCE_BUNDLE_KB=$(get_dir_size_kb "${RB}")
	fi
fi

# Helper impact = with-helper app bundle minus baseline app bundle.
HELPER_IMPACT_KB=$((WITHHELPER_SIZE_KB - BASELINE_SIZE_KB))
HELPER_EXECUTABLE_IMPACT=$((WITHHELPER_EXECUTABLE_SIZE - BASELINE_EXECUTABLE_SIZE))

if [[ ${OUTPUT_JSON} == "true" ]]; then
	echo "{\"baseline_app_size_kb\":${BASELINE_SIZE_KB},\"baseline_executable_size_bytes\":${BASELINE_EXECUTABLE_SIZE},\"with_helper_app_size_kb\":${WITHHELPER_SIZE_KB},\"with_helper_executable_size_bytes\":${WITHHELPER_EXECUTABLE_SIZE},\"helper_resource_bundle_kb\":${RESOURCE_BUNDLE_KB},\"helper_impact_kb\":${HELPER_IMPACT_KB},\"helper_executable_impact_bytes\":${HELPER_EXECUTABLE_IMPACT}}"
else
	echo ""
	echo "=== RoktUXHelper Size Measurement Results ==="
	echo ""
	if [[ ${WITH_HELPER_ONLY} == "false" ]]; then
		echo "Baseline App (no dependency):"
		echo "  App bundle size: ${BASELINE_SIZE_KB} KB"
		echo "  Executable size: ${BASELINE_EXECUTABLE_SIZE} bytes"
		echo ""
	fi
	echo "With RoktUXHelper App:"
	echo "  App bundle size: ${WITHHELPER_SIZE_KB} KB"
	echo "  Executable size: ${WITHHELPER_EXECUTABLE_SIZE} bytes"
	if [[ ${RESOURCE_BUNDLE_KB} -gt 0 ]]; then
		echo "  Bundled resources: ${RESOURCE_BUNDLE_KB} KB"
	fi
	echo ""
	if [[ ${WITH_HELPER_ONLY} == "false" ]]; then
		echo "RoktUXHelper Impact (app bundle delta):"
		echo "  Total: ${HELPER_IMPACT_KB} KB"
		echo "  Executable delta: ${HELPER_EXECUTABLE_IMPACT} bytes"
	fi
	echo ""
fi
