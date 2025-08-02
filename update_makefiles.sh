#!/bin/bash

# Update all Makefiles to use correct PREFIX setting
find $(HOME)/spice -name "Makefile" -type f | while read makefile; do
    # Check if the file contains an install target
    if grep -q "install" "$makefile"; then
        # Add or update PREFIX setting
        if ! grep -q "PREFIX=" "$makefile"; then
            # Add PREFIX at the top of the file
            sed -i '' '1i\
PREFIX = $(HOME)/spice
' "$makefile"
        else
            # Update existing PREFIX setting
            sed -i '' 's/PREFIX = .*/PREFIX = \/Users\/kalou\/spice/' "$makefile"
        fi
    fi
done
