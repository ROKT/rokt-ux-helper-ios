#!/bin/bash

# Build and Run Script for RoktUXHelper Example App
# This script:
# 1. Updates experience.json with layout schemas
# 2. Builds the Example app for iOS Simulator
# 3. Installs the app on a booted simulator
# 4. Launches the app

set -e # Exit on any error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_PATH="Example/Example.xcodeproj"
SCHEME="Example"
BUNDLE_ID="com.rokt.roktuxhelperdemo.Example"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}RoktUXHelper Build & Run Script${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Step 1: Update experience.json
echo -e "${YELLOW}[1/5] Updating experience.json with layout schemas...${NC}"
if node update-experience.js; then
	echo -e "${GREEN}✓ Experience.json updated successfully${NC}"
else
	echo -e "${RED}✗ Failed to update experience.json${NC}"
	exit 1
fi
echo ""

# Step 2: Find a booted simulator or use a default one
echo -e "${YELLOW}[2/5] Checking for booted simulator...${NC}"

# Try to find a booted simulator
BOOTED_SIM=$(xcrun simctl list devices | grep "Booted" | head -1 | grep -o '([A-F0-9-]\{36\})' | tr -d '()' || true)

if [[ -z ${BOOTED_SIM} ]]; then
	echo -e "${YELLOW}No booted simulator found. Looking for iPhone 16...${NC}"
	# Find iPhone 16 with iOS 18.2
	SIM_UUID=$(xcrun simctl list devices | grep "iPhone 16 (" | grep "18.2" | head -1 | grep -o '([A-F0-9-]\{36\})' | tr -d '()' || true)

	if [[ -z ${SIM_UUID} ]]; then
		echo -e "${YELLOW}iPhone 16 (iOS 18.2) not found. Using first available iPhone...${NC}"
		SIM_UUID=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | head -1 | grep -o '([A-F0-9-]\{36\})' | tr -d '()' || true)
	fi

	if [[ -z ${SIM_UUID} ]]; then
		echo -e "${RED}✗ No suitable simulator found${NC}"
		exit 1
	fi

	echo -e "${BLUE}Booting simulator: ${SIM_UUID}${NC}"
	xcrun simctl boot "${SIM_UUID}" 2>/dev/null || true
	open -a Simulator
	sleep 3 # Wait for simulator to boot
else
	SIM_UUID="${BOOTED_SIM}"
	echo -e "${GREEN}✓ Using booted simulator: ${SIM_UUID}${NC}"
fi
echo ""

# Step 3: Build the app
echo -e "${YELLOW}[3/5] Building Example app for simulator...${NC}"
xcodebuild \
	-project "${PROJECT_PATH}" \
	-scheme "${SCHEME}" \
	-configuration Debug \
	-sdk iphonesimulator \
	-destination "id=${SIM_UUID}" \
	-derivedDataPath "build" \
	clean build \
	CODE_SIGN_IDENTITY="" \
	CODE_SIGNING_REQUIRED=NO \
	CODE_SIGNING_ALLOWED=NO |
	grep -E '(error|warning|Building|Compiling|Linking|^$)' || true

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
	echo -e "${GREEN}✓ Build succeeded${NC}"
else
	echo -e "${RED}✗ Build failed${NC}"
	exit 1
fi
echo ""

# Step 4: Find the app bundle
echo -e "${YELLOW}[4/5] Locating app bundle...${NC}"
APP_PATH=$(find build/Build/Products/Debug-iphonesimulator -name "*.app" -depth 1 | head -1 || true)

if [[ -z ${APP_PATH} ]]; then
	echo -e "${RED}✗ Could not find app bundle${NC}"
	exit 1
fi

echo -e "${BLUE}App bundle: ${APP_PATH}${NC}"
echo ""

# Step 5: Install and launch the app
echo -e "${YELLOW}[5/5] Installing and launching app...${NC}"

# Install the app
if xcrun simctl install "${SIM_UUID}" "${APP_PATH}"; then
	echo -e "${GREEN}✓ App installed successfully${NC}"
else
	echo -e "${RED}✗ Failed to install app${NC}"
	exit 1
fi

# Launch the app
if xcrun simctl launch "${SIM_UUID}" "${BUNDLE_ID}"; then
	echo -e "${GREEN}✓ App launched successfully${NC}"
else
	echo -e "${RED}✗ Failed to launch app${NC}"
	exit 1
fi

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}✓ All steps completed successfully!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${BLUE}Simulator UUID: ${NC}${SIM_UUID}"
echo -e "${BLUE}Bundle ID: ${NC}${BUNDLE_ID}"
echo ""
echo -e "${YELLOW}The Example app is now running in the simulator.${NC}"
echo -e "${YELLOW}You can interact with it or run automated tests.${NC}"
