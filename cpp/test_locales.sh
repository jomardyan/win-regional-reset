#!/bin/bash
# Test script for C++ regional_settings_reset demo mode

set -e

for locale in pl-PL en-US de-DE fr-FR es-ES ja-JP xx-XX; do
    echo "Testing locale: $locale"
    ./regional_settings_reset $locale
    echo "---"
done
