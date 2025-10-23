# Build and Run Script

This script automates the complete workflow of building and running the RoktUXHelper Example app on the iOS Simulator.

## Purpose

The `build-and-run.sh` script provides a one-command solution to:

1. Update the experience.json with latest layout schemas
2. Build the Example app for iOS Simulator
3. Install the app on a simulator
4. Launch the app automatically

This eliminates the need to manually perform these steps through Xcode or separate commands.

## Usage

### Make the script executable (first time only)

```bash
chmod +x build-and-run.sh
```

### Run the script

```bash
./build-and-run.sh
```

## What it does

### Step 1: Update Experience JSON

- Runs `node update-experience.js` to sync layout schemas
- Ensures the app uses the latest layout configurations from `outer_layout.json` and `layout_variant.json`

### Step 2: Simulator Detection

- Checks for any currently booted simulator
- If none found, looks for iPhone 16 with iOS 18.2
- Falls back to any available iPhone simulator
- Automatically boots the selected simulator if needed

### Step 3: Build the App

- Builds the Example app using xcodebuild
- Uses Debug configuration for faster builds
- Targets iOS Simulator (no code signing required)
- Outputs clean build progress with filtered logs

### Step 4: Locate App Bundle

- Finds the built .app bundle in the derived data directory
- Verifies the build produced a valid app package

### Step 5: Install and Launch

- Installs the app on the selected simulator
- Launches the app automatically
- Displays the simulator UUID and bundle ID for reference

## Configuration

You can modify these variables at the top of the script:

```bash
PROJECT_PATH="Example/Example.xcodeproj"   # Path to Xcode project
SCHEME="Example"                            # Build scheme name
BUNDLE_ID="com.rokt.roktuxhelperdemo.Example"  # App bundle identifier
```

## Prerequisites

- **macOS** with Xcode installed
- **Xcode Command Line Tools** installed

  ```bash
  xcode-select --install
  ```

- **Node.js** (for the experience.json update step)
- At least one **iOS Simulator** configured in Xcode

## Output

The script provides colored, step-by-step output:

- 🔵 **Blue**: Informational messages and headers
- 🟡 **Yellow**: Progress indicators for each step
- 🟢 **Green**: Success messages
- 🔴 **Red**: Error messages

Example successful output:

```text
=====================================
RoktUXHelper Build & Run Script
=====================================

[1/5] Updating experience.json with layout schemas...
✓ Experience.json updated successfully

[2/5] Checking for booted simulator...
✓ Using booted simulator: 12345678-1234-1234-1234-123456789ABC

[3/5] Building Example app for simulator...
✓ Build succeeded

[4/5] Locating app bundle...
App bundle: build/Build/Products/Debug-iphonesimulator/Example.app

[5/5] Installing and launching app...
✓ App installed successfully
✓ App launched successfully

=====================================
✓ All steps completed successfully!
=====================================

Simulator UUID: 12345678-1234-1234-1234-123456789ABC
Bundle ID: com.rokt.roktuxhelperdemo.Example

The Example app is now running in the simulator.
You can interact with it or run automated tests.
```

## Error Handling

The script will exit immediately on any error (`set -e`) with descriptive messages:

- **Experience update fails**: Invalid JSON or missing files
- **No simulator found**: No iOS simulators available
- **Build fails**: Compilation errors or missing dependencies
- **App bundle not found**: Build didn't produce expected output
- **Installation fails**: Simulator issues or invalid bundle
- **Launch fails**: Bundle ID mismatch or simulator state issues

## Benefits

- **Time Saving**: Single command replaces multiple manual steps
- **Consistency**: Same build process every time
- **Developer Friendly**: Clear output and error messages
- **Integration Ready**: Can be used in local development or CI/CD pipelines
- **Automatic Updates**: Always syncs latest layout schemas before building

## Use Cases

### Daily Development

```bash
# After making changes to layout files or Swift code
./build-and-run.sh
```

### Testing Layout Changes

```bash
# 1. Edit outer_layout.json or layout_variant.json
# 2. Run the script to see changes in the app
./build-and-run.sh
```

### Clean Build and Run

```bash
# The script automatically performs a clean build
./build-and-run.sh
```

### Automated Testing Preparation

```bash
# Build and launch, then run UI tests
./build-and-run.sh
# App is now running in simulator, ready for testing
```

## Troubleshooting

### "No booted simulator found" and script can't boot one

**Solution**: Open Xcode and create/boot a simulator manually

```bash
open -a Simulator
```

### "Build failed" with signing errors

**Solution**: The script disables code signing for simulators, but verify:

- You're not accidentally targeting a physical device
- The project configuration is correct

### "Failed to launch app" - Bundle ID mismatch

**Solution**: Check the BUNDLE_ID variable matches your project's bundle identifier:

1. Open `Example.xcodeproj` in Xcode
2. Select the Example target
3. Check the Bundle Identifier in General tab
4. Update BUNDLE_ID in the script if different

### Script hangs during build

**Solution**:

- Check for Xcode popup dialogs that need attention
- Ensure no other builds are running
- Try cleaning manually: `rm -rf build/`

## Comparison with Manual Workflow

**Manual Process** (7 steps):

1. Run `node update-experience.js`
2. Open Xcode
3. Select simulator
4. Product → Clean Build Folder
5. Product → Build
6. Wait for build
7. Product → Run

**With Script** (1 step):

1. `./build-and-run.sh` ✨

## Related Files

- `update-experience.js` - Updates experience.json (called by this script)
- `UPDATE_EXPERIENCE_README.md` - Documentation for the experience update script
- `Example/Example.xcodeproj` - The Xcode project being built
- `Example/Example/Resources/` - Contains layout JSON files

## Requirements

- **Shell**: bash (standard on macOS)
- **Xcode**: Version 12.0 or later
- **iOS Simulator**: iOS 12.0 or later
- **Node.js**: For JSON processing
- **Disk Space**: ~500MB for build artifacts
