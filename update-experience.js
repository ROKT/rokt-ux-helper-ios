#!/usr/bin/env node

/**
 * Script to update experience.json with layout schemas from separate files
 *
 * This script:
 * 1. Reads outer_layout.json and layout_variant.json
 * 2. Minifies the JSON (removes whitespace)
 * 3. Updates experience.json with the minified schemas as strings
 */

const fs = require("fs");
const path = require("path");

// File paths
const EXPERIENCE_PATH = path.join(
  __dirname,
  "Example/Example/Resources/experience.json",
);
const OUTER_LAYOUT_PATH = path.join(
  __dirname,
  "Example/Example/Resources/outer_layout.json",
);
const LAYOUT_VARIANT_PATH = path.join(
  __dirname,
  "Example/Example/Resources/layout_variant.json",
);

/**
 * Minify JSON by parsing and stringifying without whitespace
 */
function minifyJSON(jsonContent) {
  const parsed = JSON.parse(jsonContent);
  return JSON.stringify(parsed);
}

/**
 * Main function to update experience.json
 */
function updateExperience() {
  try {
    console.log("Reading files...");

    // Read all files
    const experienceContent = fs.readFileSync(EXPERIENCE_PATH, "utf8");
    const outerLayoutContent = fs.readFileSync(OUTER_LAYOUT_PATH, "utf8");
    const layoutVariantContent = fs.readFileSync(LAYOUT_VARIANT_PATH, "utf8");

    console.log("Minifying JSON schemas...");

    // Minify the layout JSONs
    const outerLayoutMinified = minifyJSON(outerLayoutContent);
    const layoutVariantMinified = minifyJSON(layoutVariantContent);

    console.log("Parsing experience.json...");

    // Parse experience.json
    const experience = JSON.parse(experienceContent);

    // Validate structure exists
    if (!experience.plugins || !experience.plugins[0]) {
      throw new Error(
        "Invalid experience.json structure: plugins[0] not found",
      );
    }

    if (!experience.plugins[0].plugin) {
      throw new Error(
        "Invalid experience.json structure: plugins[0].plugin not found",
      );
    }

    if (!experience.plugins[0].plugin.config) {
      throw new Error(
        "Invalid experience.json structure: plugins[0].plugin.config not found",
      );
    }

    if (
      !experience.plugins[0].plugin.config.slots ||
      !experience.plugins[0].plugin.config.slots[0]
    ) {
      throw new Error(
        "Invalid experience.json structure: plugins[0].plugin.config.slots[0] not found",
      );
    }

    if (!experience.plugins[0].plugin.config.slots[0].layoutVariant) {
      throw new Error(
        "Invalid experience.json structure: plugins[0].plugin.config.slots[0].layoutVariant not found",
      );
    }

    console.log("Updating schemas...");

    // Update the schemas
    experience.plugins[0].plugin.config.slots[0].layoutVariant.layoutVariantSchema =
      layoutVariantMinified;
    experience.plugins[0].plugin.config.outerLayoutSchema = outerLayoutMinified;

    console.log("Writing updated experience.json...");

    // Write back to experience.json with pretty formatting
    fs.writeFileSync(
      EXPERIENCE_PATH,
      JSON.stringify(experience, null, 2) + "\n",
      "utf8",
    );

    console.log("✅ Successfully updated experience.json!");
    console.log(
      `   - outerLayoutSchema: ${outerLayoutMinified.length} characters`,
    );
    console.log(
      `   - layoutVariantSchema: ${layoutVariantMinified.length} characters`,
    );
  } catch (error) {
    console.error("❌ Error updating experience.json:", error.message);
    process.exit(1);
  }
}

// Run the script
if (require.main === module) {
  updateExperience();
}

module.exports = { updateExperience };
