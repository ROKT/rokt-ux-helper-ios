# Update Experience Script

This script automates the process of updating the `experience.json` file with layout schemas from separate files.

## Purpose

The script takes the contents of:

- `outer_layout.json` - Used for the outer layout configuration
- `layout_variant.json` - Used for the layout variant configuration

Then minifies them (removes all whitespace) and embeds them as JSON strings into the appropriate locations in `experience.json`:

- `plugins[0].plugin.config.outerLayoutSchema`
- `plugins[0].plugin.config.slots[0].layoutVariant.layoutVariantSchema`

## Usage

### Run the script

```bash
node update-experience.js
```

Or if made executable:

```bash
./update-experience.js
```

## What it does

1. **Reads** the three JSON files:

   - `Example/Example/Resources/experience.json`
   - `Example/Example/Resources/outer_layout.json`
   - `Example/Example/Resources/layout_variant.json`

2. **Minifies** the layout JSON files (removes all formatting/whitespace)

3. **Updates** the experience.json with the minified schemas as string values

4. **Writes** the updated experience.json back to disk with pretty formatting

## Benefits

- **Separation of Concerns**: Keep layout schemas in separate, readable files
- **Easier Editing**: Edit `outer_layout.json` and `layout_variant.json` with proper formatting
- **Automatic Minification**: No need to manually minify or escape JSON strings
- **Validation**: The script validates that the JSON is valid before updating

## Example Workflow

1. Edit `Example/Example/Resources/outer_layout.json` or `layout_variant.json` with your changes
2. Run `node update-experience.js`
3. The `experience.json` file is automatically updated with the minified schemas
4. Commit all three files to version control

## Error Handling

The script will exit with an error if:

- Any of the required files are missing
- The JSON files contain invalid JSON syntax
- The experience.json structure doesn't match the expected format

## Requirements

- Node.js (uses built-in `fs` and `path` modules only)
