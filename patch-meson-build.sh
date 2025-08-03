#!/bin/bash

# Path to the meson.build file
MESON_BUILD=~/jhbuild/checkout/spice-gtk-0.42/src/meson.build

# Create a backup of the original file if it doesn't exist
if [ ! -f "${MESON_BUILD}.original" ]; then
    cp "${MESON_BUILD}" "${MESON_BUILD}.original"
fi

# Create a temporary file for the patched content
TMP_FILE=$(mktemp)

# Process the original file
{
    # Copy everything before the version script logic
    sed -n '1,/spice_gtk_version_script = /p' "${MESON_BUILD}.original" | head -n -1
    
    # Add our macOS-specific version script handling
    echo '  # macOS-specific version script handling'
    echo '  spice_gtk_has_version_script = false'
    echo '  spice_gtk_version_script = []'
    
    # Skip the original version script logic and process the rest
    sed -n '/spice_gtk_version_script = /,$p' "${MESON_BUILD}.original" | \
        tail -n +2 | \
        sed -e 's/if not spice_gtk_has_version_script/if false # Disabled for macOS/g' \
            -e 's/if compiler.has_link_argument(spice_gtk_version_script)/if false # Disabled for macOS/g' \
            -e 's/link_args : \[spice_gtk_version_script\],/link_args : [], # Disabled for macOS/g'
} > "${TMP_FILE}"

# Replace the original file with our patched version
mv "${TMP_FILE}" "${MESON_BUILD}"
echo "Successfully patched ${MESON_BUILD} for macOS"
